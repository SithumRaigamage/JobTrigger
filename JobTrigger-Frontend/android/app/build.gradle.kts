import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// AUD-15: the release key comes from android/key.properties (git-ignored,
// see docs/deployment.md). Without that file, release builds fall back to
// the debug key with a warning: fine for a local check, never for a store.
val releaseKeyFile = rootProject.file("key.properties")
val releaseKey = Properties().apply {
    if (releaseKeyFile.exists()) FileInputStream(releaseKeyFile).use { load(it) }
}

fun releaseKeyValue(name: String): String =
    releaseKey.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("android/key.properties is missing '$name'")

android {
    namespace = "com.sraig.jobtrigger"
    // Not flutter.compileSdkVersion (36): flutter_secure_storage 11 requires
    // compiling against 37, or checkDebugAarMetadata fails (AUD-40).
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time APIs below API 26.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.sraig.jobtrigger"
        // Hardcoded (not flutter.minSdkVersion) because flutter_secure_storage's
        // own Android module declares minSdk 24 — going lower would fail the
        // manifest merge. 24 also happens to match the current Flutter template
        // floor, so this isn't a below-default choice, just an explicit one.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKeyFile.exists()) {
            create("release") {
                storeFile = rootProject.file(releaseKeyValue("storeFile"))
                storePassword = releaseKeyValue("storePassword")
                keyAlias = releaseKeyValue("keyAlias")
                keyPassword = releaseKeyValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeyFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "WARNING: android/key.properties not found, so release " +
                        "builds are signed with the DEBUG key. Such a build " +
                        "can't go to the Play Store. See docs/deployment.md.",
                )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
