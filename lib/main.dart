import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'services/stripe_service.dart';
import 'pages/main_shell.dart';
import 'pages/signup/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  StripeService.init();
  runApp(const MyApp());
}

class OnboardingApp extends StatelessWidget {
  const OnboardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MaterialApp(
        title: 'Esport Tournament',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFF0F0F0F),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF8400),
            surface: Color(0xFF181818),
          ),
          useMaterial3: true,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────
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

        // User is logged in — load wishlist and go to MainShell
        if (snapshot.hasData && snapshot.data != null) {
          context.read<WishlistProvider>().loadWishlist();
          return const MainShell();
        }

        // User is not logged in — show Login
        return const LoginPage();
      },
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
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
            Icon(Icons.sports_esports, color: Color(0xFFFF8400), size: 64),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFFFF8400), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
