import 'spatial_audio_models.dart';

/// Abstract service contract for the 3D Spatial Audio and Binaural Renderer.
abstract class SpatialAudioService {
  /// Check OS and hardware spatial audio capabilities
  Future<SpatialAudioCapabilities> getCapabilities();

  /// Enable 3D spatial audio processing
  Future<bool> enable();

  /// Disable 3D spatial audio processing
  Future<void> disable();

  /// Set 3D normalized position (X: -1.0 to 1.0, Y: -1.0 to 1.0, Z: -1.0 to 1.0)
  Future<void> setPosition({
    required double x,
    required double y,
    required double z,
  });

  /// Set virtual listener distance (0.1 Near to 1.0 Far)
  Future<void> setDistance(double distance);

  /// Set binaural immersion / spatial envelopment (0.0 to 1.0)
  Future<void> setImmersion(double value);

  /// Set virtual acoustic environment (Studio, Cinema, Live, Open Space)
  Future<void> setRoom(RoomType room);

  /// Set elevation / height angle (-1.0 to 1.0)
  Future<void> setElevation(double elevation);

  /// Enable orientation sensor-based head tracking
  Future<bool> enableHeadTracking();

  /// Disable head tracking
  Future<void> disableHeadTracking();

  /// Play native 3D spatial audio orbital test sequence (Left -> Center -> Right -> Back -> Center)
  Future<void> startTestAudio();

  /// Stream of real-time spatial state updates and head tracking orientation
  Stream<SpatialAudioState> get state;

  /// Dispose service resources
  void dispose();
}
