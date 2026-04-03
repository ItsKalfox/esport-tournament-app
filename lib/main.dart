import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'services/stripe_service.dart';
import 'pages/main_shell.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '.../../pages/signup/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  StripeService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Esport Tournament',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8400),
          surface: Color(0xFF181818),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────
// Listens to Firebase auth state:
//   - User already logged in  → goes straight to MainShell
//   - User not logged in      → shows LoginPage
//   - Loading                 → shows splash screen
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking auth state — show splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        // User is logged in — go to MainShell
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }

        // User is not logged in — show Login
        return const LoginPage();
      },
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Replace with your app logo if you have one
            Icon(Icons.sports_esports, color: Color(0xFFFF8400), size: 64),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFFFF8400), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
