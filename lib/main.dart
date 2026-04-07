import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE07B2A),
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        // ── Uncomment as teammates finish their screens ─────────────────
        // '/tournaments': (context) => const TournamentsScreen(),
        // '/store':       (context) => const StoreScreen(),
        // '/community':   (context) => const CommunityScreen(),
        // '/chat':        (context) => const ChatScreen(),
        // '/watch':       (context) => const WatchLiveScreen(),
        // '/calendar':    (context) => const CalendarScreen(),
        // '/profile':     (context) => const ProfileScreen(),
      },
    );
  }
}