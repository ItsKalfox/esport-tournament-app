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
- Buy gaming equipment — PC components, consoles, accessories
- Stripe payment integration (card payments)
- Order tracking with animated status timeline
- Wishlist to save favourite products
- Saved delivery addresses for faster checkout
- Cart with quantity controls and free delivery threshold

## User System
- Email & password authentication
- Google Sign-In
- Player profiles
- Team management
- Role-based access (user / admin)

---

# Tech Stack

### Frontend
- Flutter (Mobile App)
- React (Web Admin Panel)

### Backend
- Firebase Firestore (database)
- Firebase Auth (authentication)
- Firebase Storage (images)
- Firebase Cloud Functions (Stripe payments)
- Stripe (payment gateway)

---

# Project Structure

```
esport-tournament-app/
 ├── lib/
 │    ├── main.dart
 │    ├── firebase_options.dart
 │    ├── pages/
 │    │    ├── main_shell.dart
 │    │    ├── auth/
 │    │    ├── signup/
 │    │    └── store/
 │    ├── models/
 │    ├── services/
 │    ├── providers/
 │    └── widgets/
 └── functions/               ← Firebase Cloud Functions (Stripe)
      ├── index.js
      └── package.json
```

> **Admin Panel** is maintained in a separate repository:  
> 🔗 [https://github.com/SMDTS/esport-tournament-admin](https://github.com/SMDTS/esport-tournament-admin)

---

# Requirements

Before running the project, install the following:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Node.js (v20 or higher)
- FlutterFire CLI
- Firebase CLI

---

# Versions Used

### Flutter
```
Flutter 3.41.0
Dart 3.11.0
```

### Flutter Dependancies
```
firebase_core: ^4.5.0
cloud_firestore: ^6.1.3
firebase_auth: ^6.2.0
firebase_storage: ^13.1.0
cupertino_icons: ^1.0.8
firebase_core: ^4.5.0
cloud_firestore: ^6.1.3
firebase_auth: ^6.2.0
provider: ^6.1.1
flutter_stripe: ^10.1.1
http: ^1.2.1
cloud_functions: ^6.0.7
google_sign_in: ^6.2.1
firebase_storage: ^13.1.0
image_picker: ^1.2.1
image_cropper: ^12.1.1
font_awesome_flutter: ^10.7.0
youtube_player_flutter: ^9.1.3
google_fonts: ^6.1.0
flutter_inappwebview: ^6.0.0
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

Firebase has already been configured. The config file is already in the repo:

```
lib/firebase_options.dart
```

If you need to reconfigure (e.g. new Firebase project), run:

```bash
flutterfire configure
```

---

# Installation & Running the Project

## 1. Clone the repository

```bash
git clone https://github.com/ItsKalfox/esport-tournament-app.git
cd esport-tournament-app
```

---

## 2. Install Flutter dependencies

```bash
flutter pub get
```

---

## 3. Add your SHA-1 fingerprint to Firebase (required for Google Sign-In)

Every team member must add their own machine's SHA-1 fingerprint to Firebase for Google Sign-In to work.

**Step 1 — Get your SHA-1:**

Windows:
```bash
keytool -list -v -keystore "C:\Users\YOUR_USERNAME\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Mac:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the `SHA1:` line in the output.

**Step 2 — Add to Firebase:**
- Go to [Firebase Console](https://console.firebase.google.com) → `esport-tournament-app-3266f`
- Project Settings (gear icon) → Your Apps → Android app
- Click **Add fingerprint** → paste your SHA-1 → Save
- Download the updated `google-services.json` and replace `android/app/google-services.json`

> ⚠️ Without this step, Google Sign-In will fail with "Google sign-in failed" error.  
> Email/password login works without SHA-1.

---

## 4. Run the Flutter app

Connect a device or start an emulator, then run:

```bash
flutter run
```

---

## 5. Run the Admin Panel (optional)

The admin panel is in a separate repository:  
🔗 [https://github.com/SMDTS/esport-tournament-admin](https://github.com/SMDTS/esport-tournament-admin)

```bash
git clone https://github.com/SMDTS/esport-tournament-admin.git
cd esport-tournament-admin
npm install
npm start
```

Opens at `http://localhost:3000` — log in with your Firebase admin account.

> To set up an admin account, see the Admin Panel Setup section below.

---

# Admin Panel Setup

To access the admin panel, set up an admin account:

**1. Register normally in the app** — this creates a user in Firebase Auth and a document in Firestore `users/{uid}` with `role: "user"`.

**2. Upgrade to admin in Firestore:**
- Go to [Firebase Console](https://console.firebase.google.com) → Firestore → `users` collection
- Find the document for your user (by UID or email)
- Change the `role` field from `"user"` to `"admin"`

---

# Stripe Payments

Stripe payments are handled by **Firebase Cloud Functions** — no local server needed.

The Cloud Function is already deployed. It handles creating payment intents securely on the server side.

### Test Cards

The app uses Stripe in **test mode**. No real money is charged.

> For all test cards use:
> - **Expiry date:** Any future date e.g. `12/29`
> - **CVC:** Any 3 digits e.g. `123`
> - **ZIP / Postal code:** Any 5 digits e.g. `10001`
> - **Name:** Any name

### Basic Cards

| Card Number | Brand | Scenario |
|---|---|---|
| `4242 4242 4242 4242` | Visa | Payment succeeds ✅ |
| `4000 0566 5566 5556` | Visa (debit) | Payment succeeds ✅ |
| `5555 5555 5555 4444` | Mastercard | Payment succeeds ✅ |
| `2223 0031 2200 3222` | Mastercard (2-series) | Payment succeeds ✅ |
| `5200 8282 8282 8210` | Mastercard (debit) | Payment succeeds ✅ |
| `3782 822463 10005` | American Express | Payment succeeds ✅ |
| `6011 1111 1111 1117` | Discover | Payment succeeds ✅ |

### Failure Scenarios

| Card Number | Scenario |
|---|---|
| `4000 0000 0000 0002` | Card declined ❌ |
| `4000 0000 0000 9995` | Insufficient funds ❌ |
| `4000 0000 0000 0069` | Expired card ❌ |
| `4000 0000 0000 0127` | Incorrect CVC ❌ |
| `4000 0000 0000 0119` | Processing error ❌ |
| `4242 4242 4242 4241` | Incorrect card number ❌ |

### 3D Secure (Authentication Required)

| Card Number | Scenario |
|---|---|
| `4000 0025 0000 3155` | Always requires authentication |
| `4000 0027 6000 3184` | Authentication required for some payments |
| `4000 0082 6000 3178` | 3D Secure 2, requires authentication |

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

# Notes for Team Members

- **No local server needed** — images are on Firebase Storage, payments go through Firebase Cloud Functions
- **Google Sign-In requires SHA-1** — each team member must add their debug SHA-1 to Firebase (see step 3 above)
- **Admin panel** is in a separate repo — [https://github.com/SMDTS/esport-tournament-admin](https://github.com/SMDTS/esport-tournament-admin)
- **User data** is saved to Firestore `users/{uid}` on registration with `role: "user"` — upgrade to `"admin"` manually for admin panel access
- The `.env` file in `server/` is kept for reference only — the app no longer uses the Express server