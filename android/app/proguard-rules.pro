# ==============================================================================
# Android Core Components & ContentProviders (Fixes ClassNotFoundException on cold boot)
# ==============================================================================
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider { *; }

# Firebase SDK & Plugins (Explicitly keep FlutterFirebaseMessagingInitProvider)
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.firestore.** { *; }
-keep class io.flutter.plugins.firebase.analytics.** { *; }

# Google Play Billing & In-App Purchase
-keep class com.android.billingclient.** { *; }
-keep class io.flutter.plugins.inapppurchase.** { *; }

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }

# Flutter Engine, Facade & Plugin Registrant
-keep class com.trtech.expense_tracker.MainActivity { *; }
-keep class io.flutter.facade.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

# Keep native methods called by Flutter engine / JNI
-keepclasseswithmembers class * {
    native <methods>;
}

# Flutter Local Notifications, WorkManager & Biometrics
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.biometric.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.activity.** { *; }
-keep class androidx.fragment.app.** { *; }
-dontwarn androidx.activity.**
-dontwarn androidx.fragment.app.**


# Attributes & Serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**

# Suppress harmless third-party build warnings
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.gms.ads.**
-dontwarn com.android.billingclient.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
