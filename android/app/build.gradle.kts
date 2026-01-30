import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.projectDir.parentFile.resolve("android/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("Could not find key.properties at ${keystorePropertiesFile.absolutePath}")
}

android {
    namespace = "com.robudarius.classlly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        getByName("debug") {
            // Use debug keys for debug builds if needed
        }
        create("release") {
            keyAlias = keystoreProperties["keyAlias"]?.toString()?.trim()?.removeSurrounding("\"")
            keyPassword = keystoreProperties["keyPassword"]?.toString()?.trim()?.removeSurrounding("\"")
            storePassword = keystoreProperties["storePassword"]?.toString()?.trim()?.removeSurrounding("\"")
            val storePath = keystoreProperties["storeFile"]?.toString()?.trim()?.removeSurrounding("\"")
            if (storePath != null) {
                var sFile = file(storePath)
                if (!sFile.exists()) {
                    sFile = projectDir.resolve(storePath)
                }
                if (!sFile.exists()) {
                    sFile = projectDir.parentFile.resolve(storePath)
                }
                
                if (!sFile.exists()) {
                    throw GradleException("Could not find keystore file at ${sFile.absolutePath}")
                }
                storeFile = sFile
            } else {
                throw GradleException("storeFile property is missing in key.properties")
            }
        }
    }

    defaultConfig {
        applicationId = "com.robudarius.classlly"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
}