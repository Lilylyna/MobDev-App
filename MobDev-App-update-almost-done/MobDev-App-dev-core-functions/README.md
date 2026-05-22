# MobDev Audio Player - Secured Audio Player (v1.0.0)

A Flutter mobile application designed to provide a secured and personalized audio listening experience. The application integrates rigorous biometric authentication and comprehensive tracking of the user's listening habits.

## 🚀 Features

### 🔐 Security & Authentication

- **Biometric Gate**: Application access is protected by fingerprint/FaceID from the very first launch.
- **Audio Feedback**: Success sound played upon successful authentication.
- **Firebase Auth**: Full system for account creation, login, and password reset via email.
- **Sensitive Action Protection**: Deleting favorites systematically requires biometric validation.

### 🎧 Audio Player

- **Background Playback**: Continuous music control even when the application is minimized.
- **Dynamic Playlist**: Tracks organized by categories (Surahs) fetched via an external API.
- **Favorites Management**: Ability to save favorite tracks to the Cloud via Firestore.

### 📊 Statistics & Goals

- **Complete Dashboard**: Personalized welcome message and listening time summary.
- **Activity Histogram**: Graphical visualization (minutes/day) of activity for the current month.
- **Monthly Goals**: Configuration of a listening hour goal with an interactive progress bar.
- **Top Tracks**: Automated list of locally most-played tracks.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Backend**: [Firebase](https://firebase.google.com) (Authentication, Cloud Firestore)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Audio Engine**: `audio_service`, `just_audio`
- **Biometrics**: `local_auth`
- **Visualization**: `fl_chart`
- **Local Storage**: `shared_preferences`

## 📦 Installation

### 1. Clone the project

```bash
git clone <repository-url>
cd secured_audio_player
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration (Mandatory)

For the application to work, you must link your own Firebase project:

1.  Create a project on the [Firebase Console](https://console.firebase.google.com).
2.  Add an Android app and download the `google-services.json` file. Place it in `android/app/`.
3.  Add an iOS app and download the `GoogleService-Info.plist` file. Place it in `ios/Runner/`.
4.  Enable **Authentication** (Email/Password) and **Firestore Database**.

### 4. Native Permissions

Ensure the following permissions are present:

**Android (`AndroidManifest.xml`)**:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS (`Info.plist`)**:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Authentication required to access your audio files.</string>
```

## 📋 Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  local_auth: ^2.3.0
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  cloud_firestore: ^6.3.0
  just_audio: ^0.10.5
  audio_service: ^0.18.18
  audioplayers: ^6.6.0
  fl_chart: ^1.2.0
  shared_preferences: ^2.5.5
  http: ^1.6.0
  flutter_riverpod: ^3.3.1
  intl: ^0.20.2
  permission_handler: ^12.0.1
```

## 📝 Project Info

- **Version**: 1.0.0+1
- **Dart/Flutter**: Compatible with Dart 3.11.0+
- **Status**: Development/Testing Phase
- **Package Name**: secured_audio_player

## 📝 Author

Developed as part of the **Mobile Development (ING 3 SEC)** module - USTHB.
