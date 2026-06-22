import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.study_bible"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.crazymevt.studybible"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionName = flutter.versionName
        // Derive a monotonically increasing versionCode from the CalVer version
        // name (yy.m.d) plus the daily build counter. The pubspec "+N" build
        // number resets to 1 each new day, so using it directly as versionCode
        // makes it go backwards across day boundaries — which Android rejects as
        // a downgrade, forcing an uninstall/reinstall. Encoding the date keeps it
        // strictly increasing. e.g. 26.6.22+1 -> 26062201.
        val ver = flutter.versionName.split(".").map { it.toInt() }
        versionCode = ((ver[0] * 100 + ver[1]) * 100 + ver[2]) * 100 + flutter.versionCode
    }

    // Release signing is read from android/key.properties (gitignored). Locally
    // you create it once; in CI it is written from repository secrets. The
    // keystore itself is never committed.
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use the release key when key.properties is present (local dev and CI
            // from secrets); otherwise fall back to debug signing so builds without
            // the key still produce an installable APK instead of failing.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
