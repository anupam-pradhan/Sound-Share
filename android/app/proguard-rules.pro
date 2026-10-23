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

# WorkManager (pulled in by Google Mobile Ads) builds its Room database by
# reflection at app start. R8 stripped WorkDatabase_Impl, crashing launch with
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(...); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.startup.** { *; }

# Google Mobile Ads / UMP and Firebase use reflection for adapters and init
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.gms.**
