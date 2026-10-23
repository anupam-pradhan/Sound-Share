import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'peer_receiver_page.dart';

/// Local web server that lets anyone on the same Wi-Fi or hotspot listen in a
/// browser: `GET /` serves the player page, `GET /ws` streams live PCM over a
/// WebSocket, `GET /status` reports the listener count.
class PeerStreamServer {
  static const _firstPort = 8888;
  static const _portAttempts = 12;

  /// Chunks queued for a slow listener before it is dropped (~1 s of audio).
  static const _maxPendingChunks = 50;

  HttpServer? _http;
  final Set<_Listener> _listeners = {};
  final _countController = StreamController<int>.broadcast();
  int _sampleRate = 48000;

  Stream<int> get listenerCount => _countController.stream;

  /// Starts serving and returns the URL friends should open, or null when no
  /// Wi-Fi / hotspot address or free port was found.
  Future<String?> start() async {
    await stop();
    final ip = await _localAddress();
    if (ip == null) return null;
    for (var i = 0; i < _portAttempts; i++) {
      final port = _firstPort + i;
      try {
        final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
        _http = server;
        server.listen(_handle, onError: (Object e) => debugPrint('Peer server: $e'));
        return 'http://$ip:$port';
      } on SocketException {
        continue;
      }
    }
    return null;
  }

  /// Sets the PCM format announced to listeners that join from now on.
  set sampleRate(int rate) => _sampleRate = rate;

  /// Sends one chunk of 16-bit interleaved stereo PCM to every listener.
  void broadcast(Uint8List chunk) {
    for (final listener in _listeners.toList()) {
      if (listener.pending >= _maxPendingChunks) {
        // Too far behind (weak Wi-Fi): drop it; its page reconnects and resyncs
        _drop(listener);
        continue;
      }
      listener.send(chunk);
    }
  }

  Future<void> stop() async {
    for (final listener in _listeners.toList()) {
      _drop(listener);
    }
    await _http?.close(force: true);
    _http = null;
  }

  void dispose() {
    stop();
    _countController.close();
  }

  Future<void> _handle(HttpRequest request) async {
    switch (request.uri.path) {
      case '/ws':
        if (!WebSocketTransformer.isUpgradeRequest(request)) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }
        final socket = await WebSocketTransformer.upgrade(request);
        _addListener(socket);
      case '/status':
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'listeners': _listeners.length}));
        await request.response.close();
      default:
        request.response.headers
          ..contentType = ContentType.html
          ..set(HttpHeaders.cacheControlHeader, 'no-store');
        request.response.write(peerReceiverPage);
        await request.response.close();
    }
  }

  void _addListener(WebSocket socket) {
    final listener = _Listener(socket);
    _listeners.add(listener);
    _countController.add(_listeners.length);
    socket.add(jsonEncode({'type': 'format', 'sampleRate': _sampleRate, 'channels': 2}));
    socket.listen(
      (message) {
        // The page acknowledges each chunk it has scheduled
        if (message == 'ack') listener.acked();
      },
      onDone: () => _drop(listener),
      onError: (Object _) => _drop(listener),
      cancelOnError: true,
    );
  }

  void _drop(_Listener listener) {
    if (!_listeners.remove(listener)) return;
    listener.socket.close();
    if (!_countController.isClosed) _countController.add(_listeners.length);
  }

  /// Picks the phone's Wi-Fi or hotspot IPv4 address.
  static Future<String?> _localAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      int rank(NetworkInterface i) {
        final n = i.name.toLowerCase();
        if (n.startsWith('ap') || n.startsWith('swlan')) return 0; // hotspot
        if (n.startsWith('wlan')) return 1; // Wi-Fi
        return 2; // mobile data etc. — friends usually can't reach these
      }

      final sorted = [...interfaces]..sort((a, b) => rank(a) - rank(b));
      for (final iface in sorted) {
        if (rank(iface) == 2) continue;
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) return addr.address;
        }
      }
    } on SocketException catch (e) {
      debugPrint('Peer server: no network: $e');
    }
    return null;
  }
}

class _Listener {
  _Listener(this.socket);
  final WebSocket socket;
  int pending = 0;

  void send(Uint8List chunk) {
    pending++;
    socket.add(chunk);
  }

  void acked() {
    if (pending > 0) pending--;
  }
}
