plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Google Services doit être ici
    id("com.google.gms.google-services")
    // Le plugin Flutter doit être appliqué en dernier
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Ton nouvel espace de nom pour SecuAudio
    namespace = "com.secuaudio.app.secured_audio_player"
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
        // Ton Application ID qui doit matcher avec la console Firebase
        applicationId = "com.secuaudio.app.secured_audio_player"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Les dépendances d'implémentation vont ici, PAS dans le bloc android
dependencies {
    // Exemple : implementation("com.google.firebase:firebase-analytics")
}