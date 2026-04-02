import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'models/constants.dart';

void main() {
  runApp(const OnboardingApp());
}

class OnboardingApp extends StatelessWidget {
  const OnboardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onboarding App Design Implementation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: FigmaColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: FigmaColors.containerBorder),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
