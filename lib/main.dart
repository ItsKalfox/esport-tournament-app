import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'services/stripe_service.dart';
import 'pages/main_shell.dart';

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
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'Esports App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFFF0A500),
            surface: const Color(0xFF161616),
          ),
          useMaterial3: true,
        ),
        home: const MainShell(),
      ),
    );
  }
}
