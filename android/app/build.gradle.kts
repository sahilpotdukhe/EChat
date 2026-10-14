plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.echat"
    // permission_handler_android needs SDK 37; Flutter's default is lower.
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.echat"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // Agora ships optional add-ons that are loaded only when their feature is
    // switched on. EChat uses plain voice/video calls, so leave out the ones
    // it never turns on (~30 MB per CPU type). Noise suppression, echo
    // cancellation and the video codecs stay.
    packaging {
        jniLibs {
            excludes += listOf(
                "lib/*/libagora_audio_beauty_extension.so",
                "lib/*/libagora_clear_vision_extension.so",
                "lib/*/libagora_content_inspect_extension.so",
                "lib/*/libagora_face_capture_extension.so",
                "lib/*/libagora_face_detection_extension.so",
                "lib/*/libagora_lip_sync_extension.so",
                "lib/*/libagora_screen_capture_extension.so",
                "lib/*/libagora_segmentation_extension.so",
                "lib/*/libagora_spatial_audio_extension.so",
                "lib/*/libagora_video_quality_analyzer_extension.so",
            )
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
