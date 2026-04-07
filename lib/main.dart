import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'services/stripe_service.dart';
import 'pages/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash.dart';
import 'services/auth_service.dart';

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
        home: const _SplashLauncher(),
      ),
    );
  }
}

class _SplashLauncher extends StatefulWidget {
  const _SplashLauncher();

  @override
  State<_SplashLauncher> createState() => _SplashLauncherState();
}

class _SplashLauncherState extends State<_SplashLauncher> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted || _navigated) return;
      _navigated = true;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const _AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ));
    });
  }

  void navigateToAuth() {
    // Always attempt navigation when user explicitly taps GET STARTED.
    // Mark `_navigated` to avoid duplicate auto-navigation from the timer,
    // but do not block manual navigation if the flag was previously set.
    _navigated = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const OnboardingScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 450),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(onGetStarted: navigateToAuth);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const OnboardingApp();
}

class SplashScreenWrapper extends StatelessWidget {
  const SplashScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      key: UniqueKey(),
      onGetStarted: () {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ));
    });
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreenWrapper();
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return FutureBuilder<bool>(
            future: AuthService.isOnboardingCompleted(user.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SplashScreenWrapper();
              }
              final completed = snap.data ?? false;
              if (!completed) {
                return const OnboardingScreen();
              }
              context.read<WishlistProvider>().loadWishlist();
              return const MainShell();
            },
          );
        }

        return const OnboardingScreen();
      },
    );
  }
}
