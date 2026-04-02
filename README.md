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
- Stripe payment integration (card payments)
- Order tracking with status timeline

## User System
- User authentication
- Player profiles
- Team management

---

# Tech Stack

### Frontend
- Flutter (Mobile App)
- React (Web Admin Panel)

### Backend
- Firebase (Firestore, Auth)
- Express.js (Payments & Image Uploads)
- Stripe (Payment Gateway)

### Services Used
- Firebase Authentication
- Cloud Firestore
- Express.js local server (replaces Firebase Storage)
- Stripe API

---

# Project Structure

```
esport-tournament-app/
 ├── lib/
 │    ├── main.dart
 │    ├── firebase_options.dart
 │    ├── pages/
 │    │    ├── main_shell.dart
 │    │    └── store/
 │    ├── models/
 │    ├── services/
 │    ├── providers/
 │    └── widgets/
 ├── server/                  ← Express backend
 │    ├── server.js
 │    ├── package.json
 │    ├── .env                ← create this (see below)
 │    ├── .env.example
 │    └── uploads/            ← images stored here
 └── admin-panel/             ← React web admin panel
      ├── src/
      └── package.json
```

---

# Requirements

Before running the project, install the following:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Node.js (v18 or higher)
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

## 3. Set up and run the Express server

The Express server handles **Stripe payments** and **image uploads/serving**.  
Every team member who runs the app needs to run this server locally.

### Step 1 — Install server dependencies

```bash
cd server
npm install
```

### Step 2 — Create your `.env` file

Copy the example file:

```bash
cp .env.example .env
```

Open `.env` and fill in your values:

```
STRIPE_SECRET_KEY=sk_test_YOUR_STRIPE_SECRET_KEY
BASE_URL=http://YOUR_PC_IP:3000
PORT=3000
```

> **How to find your PC's IP address:**
> - **Windows:** Open Command Prompt → run `ipconfig` → look for **IPv4 Address** under your WiFi adapter (e.g. `192.168.1.5`)
> - **Mac:** Open Terminal → run `ifconfig` → look for `inet` under `en0`

> ⚠️ `BASE_URL` must use your actual PC IP, not `localhost`.  
> This is because images uploaded from the admin panel are accessed by the Flutter app on a real device, which cannot reach `localhost`.

### Step 3 — Start the server

```bash
npm run dev
```

You should see:

```
🚀 Esports Store Server running at http://localhost:3000
📁 Images served from: http://localhost:3000/images/
💳 Stripe: ✅ configured
```

> Keep this terminal running while using the app or admin panel.

---

## 4. Update your IP in the Flutter app

Open `lib/models/product.dart` and update the IP in the `_fixUrl` method:

```dart
static String _fixUrl(String url) {
  return url.replaceAll('localhost', '192.168.X.X'); // ← your PC's IP
}
```

Open `lib/services/stripe_service.dart` and update `_serverUrl`:

```dart
static const String _serverUrl = 'http://192.168.X.X:3000'; // ← your PC's IP
```

> ⚠️ Make sure your phone and PC are on the **same WiFi network**.

---

## 5. Run the Flutter app

Connect a device or start an emulator, then run:

```bash
flutter run
```

---

## 6. Run the Admin Panel (optional)

The web admin panel is used to manage products, categories, banners and orders.

```bash
cd admin-panel
npm install
npm start
```

Opens at `http://localhost:3000` — log in with your Firebase admin account.

> To set up an admin account, see the Admin Panel Setup section below.

---

# Admin Panel Setup

To access the admin panel you need to:

**1. Create a user in Firebase Auth:**
- Go to [Firebase Console](https://console.firebase.google.com) → `esport-tournament-app-3266f`
- Authentication → Users → Add User
- Enter email and password → copy the generated **UID**

**2. Create an admin document in Firestore:**
- Firestore → Create collection `users`
- Document ID = the **UID** from step 1
- Add field: `role` → `string` → `admin`

---

# Stripe Test Cards

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

- Always run the Express server (`npm run dev` in `server/`) before testing the store or admin panel
- Update your PC's IP in `product.dart` and `stripe_service.dart` whenever your IP changes
- The `server/uploads/` folder stores all product and banner images locally — do not delete it
- The `.env` file has been committed to the repository **for development purposes only** — the Stripe keys inside are test keys and no real money is involved. Before going live, `.env` must be removed from Git tracking to protect production secrets:

```bash
echo "server/.env" >> .gitignore
git rm --cached server/.env
git commit -m "remove .env from tracking before production"
```