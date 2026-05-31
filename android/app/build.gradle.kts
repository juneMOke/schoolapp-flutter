import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val ciKeystorePropertiesPath =
    System.getenv("ANDROID_KEYSTORE_PROPERTIES_PATH")
        ?.trim()
        ?.takeIf { it.isNotEmpty() }

val keystorePropertiesCandidates = listOfNotNull(
    ciKeystorePropertiesPath?.let(::File),
    rootProject.file("key.properties"),
    project.file("../key.properties"),
    project.file("key.properties"),
)

val keystorePropertiesFile = keystorePropertiesCandidates.firstOrNull { it.exists() }
if (keystorePropertiesFile != null) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val keystorePath =
    (keystoreProperties["storeFile"] as String?)
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: System.getenv("ANDROID_KEYSTORE_PATH")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
val keystorePassword =
    (keystoreProperties["storePassword"] as String?)
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
val keyAlias =
    (keystoreProperties["keyAlias"] as String?)
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: System.getenv("ANDROID_KEY_ALIAS")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
val keyPassword =
    (keystoreProperties["keyPassword"] as String?)
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: System.getenv("ANDROID_KEY_PASSWORD")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }

val hasReleaseSigningCredentials =
    !keystorePath.isNullOrBlank() &&
        !keystorePassword.isNullOrBlank() &&
        !keyAlias.isNullOrBlank() &&
        !keyPassword.isNullOrBlank()

val isProdReleaseTaskRequested =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("prodrelease", ignoreCase = true)
    }

android {
    signingConfigs {
        if (hasReleaseSigningCredentials) {
            create("release") {
                storeFile = file(keystorePath!!)
                storePassword = keystorePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
            }
        }
    }

    namespace = "com.junethink.school_app_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.junethink.school_app_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "School App Dev")
        }

        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "School App Staging")
        }

        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "School App")
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigningCredentials) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                if (isProdReleaseTaskRequested) {
                    throw GradleException(
                        "Missing Android release signing credentials for prod release. " +
                            "Provide key.properties or ANDROID_KEYSTORE_PATH / ANDROID_KEYSTORE_PASSWORD / " +
                            "ANDROID_KEY_ALIAS / ANDROID_KEY_PASSWORD.",
                    )
                }
                // Fallback local pour release non-prod uniquement.
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
