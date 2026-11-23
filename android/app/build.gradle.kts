import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tazaquiz.quiz"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.tazaquiz.quiz"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 49
        versionName = "1.4.3"
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true  // ✅ YE SAHI SYNTAX HAI
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Play Console: "Your app may crash on 16 KB devices — some libraries were compiled using
// an older Android NDK". The one built with an old NDK was libdatastore_shared_counter.so
// from androidx.datastore 1.1.7 (pulled in by shared_preferences). Force the newer stable one.
configurations.all {
    resolutionStrategy.eachDependency {
        if (requested.group == "androidx.datastore") {
            useVersion("1.3.0")
            because("1.1.7 (NDK r25c) and 1.2.1 (NDK r20) native libs trigger the old-NDK warning; 1.3.0 is built with NDK r27")
        }
    }
}

dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
       implementation("com.google.firebase:firebase-messaging:23.4.1")
}

flutter {
    source = "../.."
}