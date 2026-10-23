/// Player page served to friends' browsers (Android, iPhone, laptop).
///
/// Receives 16-bit stereo PCM over a WebSocket and schedules it with the Web
/// Audio API behind a small jitter buffer. Each scheduled chunk is acked so
/// the phone can drop listeners whose Wi-Fi cannot keep up.
const peerReceiverPage = r'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#0C0A16">
<title>SoundShare Live</title>
<style>
  :root {
    --bg: #0C0A16; --surface: #16132A; --surface-2: #1E1A38;
    --text: #F4F2FF; --muted: #A29DBB; --line: rgba(255,255,255,.08);
    --brand: #7A5AF8; --brand-2: #3B82F6; --live: #34D399; --warn: #F59E0B;
  }
  @media (prefers-color-scheme: light) {
    :root { --bg: #F6F4FF; --surface: #FFFFFF; --surface-2: #EFEBFF;
      --text: #17132C; --muted: #625C80; --line: rgba(23,19,44,.08); }
  }
  * { box-sizing: border-box; margin: 0; }
  html, body { height: 100%; }
  body {
    background: var(--bg); color: var(--text);
    font: 16px/1.45 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    display: grid; place-items: center; padding: 16px;
    -webkit-tap-highlight-color: transparent;
  }
  .glow { position: fixed; inset: -30% -20% auto; height: 70vh; pointer-events: none;
    background: radial-gradient(closest-side, rgba(122,90,248,.35), transparent 70%);
    filter: blur(20px); z-index: 0; }
  .card { position: relative; z-index: 1; width: 100%; max-width: 420px;
    background: linear-gradient(180deg, var(--surface), var(--surface-2));
    border: 1px solid var(--line); border-radius: 28px; padding: 28px 22px 22px;
    box-shadow: 0 24px 60px rgba(0,0,0,.35); text-align: center; }
  .brand { display: inline-flex; gap: 8px; align-items: center; font-weight: 700;
    letter-spacing: .2px; color: var(--muted); font-size: 13px; }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--muted); }
  .dot.live { background: var(--live); box-shadow: 0 0 0 0 rgba(52,211,153,.6);
    animation: pulse 1.6s infinite; }
  .dot.warn { background: var(--warn); }
  @keyframes pulse { 70% { box-shadow: 0 0 0 10px rgba(52,211,153,0); }
    100% { box-shadow: 0 0 0 0 rgba(52,211,153,0); } }
  h1 { font-size: 28px; line-height: 1.15; margin: 14px 0 6px; letter-spacing: -.4px; }
  .sub { color: var(--muted); font-size: 14px; min-height: 40px; }
  canvas { width: 100%; height: 120px; margin: 22px 0 18px; display: block; }
  .play { width: 100%; border: 0; border-radius: 18px; padding: 17px; cursor: pointer;
    font: 700 17px/1 inherit; color: #fff;
    background: linear-gradient(135deg, var(--brand), var(--brand-2));
    box-shadow: 0 12px 28px rgba(122,90,248,.45);
    transition: transform .15s ease, box-shadow .15s ease, filter .15s ease; }
  .play:active { transform: scale(.98); }
  .play:focus-visible { outline: 3px solid var(--brand-2); outline-offset: 3px; }
  .play.stop { background: var(--surface-2); color: var(--text); box-shadow: none;
    border: 1px solid var(--line); }
  .row { display: flex; align-items: center; gap: 12px; margin-top: 18px; color: var(--muted);
    font-size: 13px; }
  input[type=range] { flex: 1; accent-color: var(--brand); }
  .meta { display: flex; justify-content: space-between; margin-top: 14px;
    color: var(--muted); font-size: 12px; font-variant-numeric: tabular-nums; }
  .get { display: block; margin-top: 18px; padding-top: 16px; border-top: 1px solid var(--line);
    color: var(--muted); font-size: 13px; text-decoration: none; }
  .get b { color: var(--brand); }
  @media (prefers-reduced-motion: reduce) { .dot.live { animation: none; } }
</style>
</head>
<body>
<div class="glow"></div>
<main class="card">
  <div class="brand"><span id="dot" class="dot"></span><span id="state">Ready</span></div>
  <h1>Listen along</h1>
  <p class="sub" id="sub">Tap play to hear what your friend is playing, in sync.</p>
  <canvas id="viz" aria-hidden="true"></canvas>
  <button class="play" id="btn">▶&nbsp; Tap to listen</button>
  <div class="row"><span>🔈</span>
    <input id="vol" type="range" min="0" max="1" step="0.01" value="1" aria-label="Volume">
    <span>🔊</span></div>
  <div class="meta"><span id="lat">Delay —</span><span id="q">Wi-Fi —</span></div>
  <a class="get" href="https://play.google.com/store/apps/details?id=com.soundshare.soundshare"
     target="_blank" rel="noopener">Share your own music with <b>SoundShare</b> — free on Google Play</a>
</main>
<script>
(() => {
  const TARGET = 0.25;   // seconds of audio kept buffered
  const MAX_AHEAD = 1.2; // beyond this we drop to catch up
  const $ = id => document.getElementById(id);
  const btn = $('btn'), dot = $('dot'), state = $('state'), sub = $('sub');
  let ctx, gain, analyser, ws, rate = 48000, next = 0, wanted = false;
  let retry = 0, wakeLock = null, dropped = 0, received = 0;

  function setStatus(kind, label, text) {
    dot.className = 'dot' + (kind ? ' ' + kind : '');
    state.textContent = label;
    if (text) sub.textContent = text;
  }

  async function start() {
    wanted = true;
    if (!ctx) {
      ctx = new (window.AudioContext || window.webkitAudioContext)({ latencyHint: 'playback' });
      gain = ctx.createGain();
      analyser = ctx.createAnalyser();
      analyser.fftSize = 128;
      gain.connect(analyser); analyser.connect(ctx.destination);
      gain.gain.value = +$('vol').value;
      draw();
    }
    // iPhone: play even with the ringer switch on silent (Safari 16.4+)
    if (navigator.audioSession) navigator.audioSession.type = 'playback';
    await ctx.resume();
    keepAwake();
    btn.textContent = '■  Stop';
    btn.classList.add('stop');
    connect();
  }

  function stop() {
    wanted = false;
    if (ws) ws.close();
    if (ctx) ctx.suspend();
    if (wakeLock) { wakeLock.release(); wakeLock = null; }
    btn.textContent = '▶  Tap to listen';
    btn.classList.remove('stop');
    setStatus('', 'Paused', 'Tap play to listen again.');
  }

  function connect() {
    setStatus('warn', 'Connecting…', 'Joining your friend\'s stream…');
    ws = new WebSocket('ws://' + location.host + '/ws');
    ws.binaryType = 'arraybuffer';
    ws.onmessage = e => {
      if (typeof e.data === 'string') {
        const msg = JSON.parse(e.data);
        if (msg.type === 'format') rate = msg.sampleRate;
        return;
      }
      schedule(e.data);
      ws.send('ack');
    };
    ws.onopen = () => {
      retry = 0; next = 0;
      setStatus('live', 'Live', 'Playing in sync. Keep this page open.');
    };
    ws.onclose = () => {
      if (!wanted) return;
      setStatus('warn', 'Reconnecting…', 'Lost the stream — trying again.');
      setTimeout(connect, Math.min(4000, 500 * 2 ** retry++));
    };
  }

  function schedule(buf) {
    const pcm = new Int16Array(buf);
    const frames = pcm.length >> 1;
    if (!frames) return;
    received++;
    const now = ctx.currentTime;
    if (next < now + 0.03) next = now + TARGET;           // starting or underrun
    if (next > now + MAX_AHEAD) { dropped++; return; }    // too far behind
    const audio = ctx.createBuffer(2, frames, rate);
    const l = audio.getChannelData(0), r = audio.getChannelData(1);
    for (let i = 0, j = 0; i < frames; i++, j += 2) {
      l[i] = pcm[j] / 32768; r[i] = pcm[j + 1] / 32768;
    }
    const src = ctx.createBufferSource();
    src.buffer = audio;
    src.connect(gain);
    src.start(next);
    next += audio.duration;
    if (received % 25 === 0) showStats(now);
  }

  function showStats(now) {
    const ms = Math.round(((next - now) + (ctx.outputLatency || ctx.baseLatency || 0)) * 1000);
    $('lat').textContent = 'Delay ' + ms + ' ms';
    const loss = dropped / Math.max(1, received);
    $('q').textContent = 'Wi-Fi ' + (loss < 0.01 ? 'excellent' : loss < 0.05 ? 'good' : 'weak');
  }

  async function keepAwake() {
    try { if ('wakeLock' in navigator) wakeLock = await navigator.wakeLock.request('screen'); }
    catch (_) {}
  }
  document.addEventListener('visibilitychange', () => {
    if (wanted && document.visibilityState === 'visible') { keepAwake(); ctx && ctx.resume(); }
  });

  // Simple spectrum bars; static when the visitor prefers reduced motion
  const canvas = $('viz'), g = canvas.getContext('2d');
  const still = matchMedia('(prefers-reduced-motion: reduce)').matches;
  function draw() {
    const dpr = devicePixelRatio || 1, w = canvas.clientWidth, h = canvas.clientHeight;
    if (canvas.width !== w * dpr) { canvas.width = w * dpr; canvas.height = h * dpr; }
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.clearRect(0, 0, w, h);
    const bins = new Uint8Array(analyser ? analyser.frequencyBinCount : 32);
    if (analyser) analyser.getByteFrequencyData(bins);
    const n = 32, bw = w / n, grad = g.createLinearGradient(0, h, 0, 0);
    grad.addColorStop(0, '#7A5AF8'); grad.addColorStop(1, '#3B82F6');
    g.fillStyle = grad;
    for (let i = 0; i < n; i++) {
      const v = Math.max(0.06, bins[i] / 255);
      const bh = v * h;
      g.beginPath();
      g.roundRect ? g.roundRect(i * bw + 2, h - bh, bw - 4, bh, 4)
                  : g.rect(i * bw + 2, h - bh, bw - 4, bh);
      g.fill();
    }
    if (!still) requestAnimationFrame(draw);
  }
  draw();

  btn.addEventListener('click', () => (wanted ? stop() : start()));
  $('vol').addEventListener('input', e => { if (gain) gain.gain.value = +e.target.value; });
})();
</script>
</body>
</html>
''';
