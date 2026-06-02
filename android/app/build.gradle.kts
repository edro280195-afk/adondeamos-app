plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.adondeamos.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // -------------------------------------------------------------------------
    // Carga de keystore desde key.properties
    // -------------------------------------------------------------------------
    def keystorePropertiesFile = rootProject.file("key.properties")
    def keystoreProperties = new Properties()
    def hasKeystore = keystorePropertiesFile.exists()
    if (hasKeystore) {
        keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        if (hasKeystore) {
            release {
                keyAlias = keystoreProperties['keyAlias']
                keyPassword = keystoreProperties['keyPassword']
                storeFile = keystoreProperties['storeFile'] != null
                    ? file(keystoreProperties['storeFile'])
                    : null
                storePassword = keystoreProperties['storePassword']
            }
        }
    }

    defaultConfig {
        applicationId = "com.adondeamos.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = hasKeystore
                ? signingConfigs.release
                : signingConfigs.getByName("debug")
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
