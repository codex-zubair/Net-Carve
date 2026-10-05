# NetCarve keeps release builds small and fast. The app has no reflection,
# no serialization and no network stack, so most rules are conservative.

# Keep Flutter embedding entry points.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep AndroidX / Material components referenced from XML.
-keep class androidx.** { *; }
-dontwarn androidx.**

# url_launcher uses intents only; nothing to keep explicitly.
-dontwarn org.jetbrains.annotations.**

# Optional Play Core deferred-component APIs referenced by the Flutter engine
# but unused by NetCarve. R8 only needs to be told these are optional.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }