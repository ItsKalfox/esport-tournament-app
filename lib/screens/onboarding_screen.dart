import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/onboarding_model.dart';
import '../models/constants.dart';
import '../services/auth_service.dart';
import '../widgets/onboarding_page_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  
  // Naming strictness requirement
  int _userOnboardingIndex = 0;
  bool _isLoading = false;

  final List<OnboardingPageModel> _pages = const [
    OnboardingPageModel(
      imagePath: 'assets/image 16.png',
      title: 'The Ultimate\nPlayground',
      subtitle: "Step into the spotlight where legends are born. Whether you're hosting the next grand-slam tournament or tracking every heart stopping play, the pulse of the e-sports world starts here.",
    ),
    OnboardingPageModel(
      imagePath: 'assets/image 17.png',
      title: 'Stay Ahead\nOf The Game',
      subtitle: 'Receive real-time tactical intelligence from our AI chat bot. Connect with an elite tech community to master the gear behind the glory.',
    ),
    OnboardingPageModel(
      imagePath: 'assets/image 18.png',
      title: 'Equip For\nVictory',
      subtitle: 'Browse our curated marketplace for exclusive gear drops and pro-tier essentials. Elevate your playstyle with the high-performance tech used by the legends.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Enforce dark status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);
    final success = await _authService.completeOnboarding();
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to the playground!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaColors.background,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: FigmaColors.containerBorder))
        : PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _userOnboardingIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPageWidget(
                data: _pages[index],
                currentIndex: index,
                totalPages: _pages.length,
                isLastPage: index == _pages.length - 1,
                onNext: () {
                  if (index == _pages.length - 1) {
                    _handleComplete();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                onSkip: () => _handleComplete(),
              );
            },
          ),
    );
  }
}
