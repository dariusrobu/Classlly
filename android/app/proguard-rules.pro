# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /Users/robudarius/Library/Android/sdk/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.kts.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools-proguard.html

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn io.flutter.embedding.**

# Hive
-keep class com.robudarius.classlly.data.models.** { *; }
-keep class com.robudarius.classlly.data.models.**Adapter { *; }
-keep class io.hive.** { *; }

# Supabase / PostgREST
-keep class com.supabase.** { *; }
-dontwarn com.supabase.**

# JNI
-keepclasseswithmembernames class * {
    native <methods>;
}
