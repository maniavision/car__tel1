# Stripe standard keep rules
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }

# Keep React Native Stripe SDK classes (flutter_stripe uses this under the hood)
-dontwarn com.reactnativestripesdk.**
-keep class com.reactnativestripesdk.** { *; }