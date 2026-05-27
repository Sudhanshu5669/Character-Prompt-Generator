import com.android.build.gradle.internal.api.ApkVariantOutputImpl

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.promptgen.prompt_generator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.promptgen.prompt_generator"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    applicationVariants.configureEach {
        val variant = this
        variant.outputs.configureEach {
            val output = this as? ApkVariantOutputImpl
            output?.outputFileName = "prompt_generator.apk"
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

tasks.whenTaskAdded {
    if (name.startsWith("assemble")) {
        doLast {
            val variantName = name.substringAfter("assemble")
            val variantLower = variantName.lowercase()
            val apkFile = File(project.buildDir, "outputs/apk/$variantLower/prompt_generator.apk")
            if (apkFile.exists()) {
                val flutterApkDir = File(project.buildDir, "outputs/flutter-apk")
                if (!flutterApkDir.exists()) {
                    flutterApkDir.mkdirs()
                }
                val destFile1 = File(flutterApkDir, "prompt_generator.apk")
                val destFile2 = File(flutterApkDir, "prompt generator.apk")
                apkFile.copyTo(destFile1, overwrite = true)
                apkFile.copyTo(destFile2, overwrite = true)
                println("SUCCESS: Copied custom APK to: ${destFile1.absolutePath}")
                println("SUCCESS: Copied custom APK to: ${destFile2.absolutePath}")
            }
        }
    }
}
