plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "co.byite.soongong"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications ≥ 10 requires core library desugaring
        // (docs/versions.md). Version per the plugin README (22.x): 2.1.4.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "co.byite.soongong"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Flavors (S01 §4-2): dev → co.byite.soongong.dev / prod → co.byite.soongong.
    // Client config is injected with --dart-define-from-file=env/app.<flavor>.json (D12);
    // the flavor itself only changes the application id and the launcher label.
    // The label (@string/app_name) lives in src/<flavor>/res/values/strings.xml —
    // AGP 9 disables `resValue` by default (S01b).
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        create("prod") {
            dimension = "env"
        }
    }

    buildTypes {
        release {
            // TODO(S15): release signing config (android/key.properties, gitignored).
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
