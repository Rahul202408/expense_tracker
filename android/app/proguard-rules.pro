# ==============================================================================
# Flutter & Application Rules
# ==============================================================================
-keep class com.trtech.expense_tracker.MainActivity { *; }

-keep class io.flutter.facade.** { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

# Keep native methods called by Flutter engine / JNI
-keepclasseswithmembers class * {
    native <methods>;
}

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Attributes & Serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**

# ==============================================================================
# Firebase, Google Play Services, AdMob & Billing
# NOTE: These official SDKs bundle their own Consumer Proguard Rules inside their AARs.
# We intentionally do NOT use blanket '-keep class com.google.** { *; }' so R8 can
# safely optimize and obfuscate internal code, maintaining DEX obfuscation well above 25%.
# ==============================================================================
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.gms.ads.**
-dontwarn com.android.billingclient.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
