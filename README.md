# Esports Tournament Management Platform

A **cross-platform esports tournament management application** built using **Flutter** and **Firebase**.  
This platform allows gamers and organizers to **create tournaments, form teams, track leaderboards, share gaming content, and purchase gaming equipment**.

The system aims to create a **community-driven esports ecosystem** where players can interact, compete, and stay updated with gaming content.

---

# Features

## Tournament Management
- Create and host esports tournaments
- Join tournaments
- Create and manage teams
- View tournament brackets and progress
- Leaderboard with points system
- Track match results

## Community Feed
- Post gaming related content
- Share videos and updates
- View community posts from other gamers

## Gaming Marketplace
- Buy gaming equipment
- PC components
- Consoles
- Gaming accessories

## User System
- User authentication
- Player profiles
- Team management

---

# Tech Stack

### Frontend
- Flutter

### Backend
- Firebase

### Services Used
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

---

# Project Structure

```
lib/
 ├── main.dart
 ├── firebase_options.dart
 ├── pages/
 ├── models/
 ├── services/
 └── widgets/
```

---

# Requirements

Before running the project, install the following:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- FlutterFire CLI

---

# Versions Used

### Flutter
```
Flutter 3.41.0
Dart 3.11.0
```

### Firebase
```
firebase_core: ^4.5.0
cloud_firestore: ^6.1.3
firebase_auth: ^6.2.0
firebase_storage: ^13.1.0
```

### FlutterFire CLI
```
flutterfire_cli: ^1.3.1
```

### Firebase CLI
```
firebase-tools: ^15.9.0
```

---

# Firebase Configuration

This project uses **FlutterFire CLI** for Firebase configuration.

Firebase has already been configured using:

```
flutterfire configure
```

This command generates the file:

```
lib/firebase_options.dart
```

which connects the application to Firebase automatically.

---

# Installation & Running the Project

## 1. Clone the repository

```
git clone https://github.com/ItsKalfox/esport-tournament-app.git
```

Navigate to the project directory:

```
cd esport-tournament-app
```

---

## 2. Install dependencies

```
flutter pub get
```

---

## 3. Configure Firebase (if needed)

Install FlutterFire CLI:

```
dart pub global activate flutterfire_cli
```

Then run:

```
flutterfire configure
```

---

## 4. Run the application

Connect a device or start an emulator, then run:

```
flutter run
```

---

# Supported Platforms

- Android

---

# Development Tools

### Recommended IDEs
- VS Code
- Android Studio

### Useful Extensions
- Flutter
- Dart
- Firebase Explorer

---