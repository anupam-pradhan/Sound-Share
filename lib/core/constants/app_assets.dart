/// Centralized asset path constants for SoundShare.
/// All assets live under `assets/images/`.
class AppAssets {
  AppAssets._();

  /// SoundShare brand logo (512×512 PNG, RGBA).
  /// Use with `Image.asset(AppAssets.logo, fit: BoxFit.contain)`.
  static const String logo = 'assets/images/soundshare_logo.png';

  /// App icon source (1024×1024 PNG, RGB).
  /// Used for launcher icon generation — not displayed in-app.
  static const String appIcon = 'assets/images/app_icon.png';
}
