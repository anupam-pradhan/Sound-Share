# Add project specific ProGuard rules here.
# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# flutter_blue_plus
-keep class com.boskokg.flutter_blue_plus.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# SoundShare native channel & engine
-keep class com.soundshare.soundshare.** { *; }

# Play Core deferred components suppression
-dontwarn com.google.android.play.core.**
