import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/Shared widgets.dart';
import '../../services/auth_service.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _firstError;
  String? _emailError;
  String? _passError;
  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showPasswordRules = false;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _firstCtrl.text.trim().isNotEmpty &&
        Validators.email(_emailCtrl.text) == null &&
        Validators.password(_passCtrl.text) == null &&
        _termsAccepted;
  }

  Future<void> _handleSignup() async {
    setState(() {
      _firstError = _firstCtrl.text.trim().isEmpty ? 'First name is required' : null;
      _emailError = Validators.email(_emailCtrl.text);
      _passError = Validators.password(_passCtrl.text);
    });

    if (!_isFormValid()) {
      if (!_termsAccepted) {
        _showSnackbar(
            'Please agree to the Terms of Service.', AppColors.warning);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.registerWithEmail(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
      );

      if (!mounted) return;
      _showSnackbar('Account created! Welcome 🎮', AppColors.success);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = AuthService.getErrorMessage(e.code);
      if (e.code == 'email-already-in-use') {
        setState(() => _emailError = msg);
      } else {
        _showSnackbar(msg, AppColors.error);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Something went wrong. Please try again.', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final credential = await AuthService.signInWithGoogle();
      if (credential == null) return;
      if (!mounted) return;
      _showSnackbar(
          'Welcome, ${credential.user?.displayName ?? 'User'}! 🎮',
          AppColors.success);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnackbar(AuthService.getErrorMessage(e.code), AppColors.error);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Google sign-in failed.', AppColors.error);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthHeader(
            title: 'Create\nAccount',
            subtitle: 'Please sign up to continue',
            onBack: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First & Last name
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        label: 'First Name',
                        hint: 'John',
                        controller: _firstCtrl,
                        errorText: _firstError,
                        onChanged: (v) => setState(
                            () => _firstError = v.trim().isEmpty
                                ? 'Required'
                                : null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        label: 'Last Name',
                        hint: 'Doe',
                        controller: _lastCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Email Address',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailCtrl,
                  errorText: _emailError,
                  onChanged: (v) =>
                      setState(() => _emailError = Validators.email(v)),
                ),
                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Mobile Number',
                  hint: '+1 (555) 000-0000',
                  keyboardType: TextInputType.phone,
                  controller: _phoneCtrl,
                ),
                const SizedBox(height: 16),

                // Password with live rules
                AuthTextField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  isPassword: true,
                  controller: _passCtrl,
                  errorText: _passError,
                  onChanged: (v) {
                    setState(() {
                      _showPasswordRules = v.isNotEmpty;
                      _passError = null;
                    });
                  },
                ),

                // Live password rules
                if (_showPasswordRules)
                  PasswordRulesWidget(password: _passCtrl.text),

                const SizedBox(height: 16),

                // Terms checkbox
                GestureDetector(
                  onTap: () =>
                      setState(() => _termsAccepted = !_termsAccepted),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: _termsAccepted
                              ? AppColors.orange
                              : AppColors.inputBg,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _termsAccepted
                                ? AppColors.orange
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: _termsAccepted
                            ? const Icon(Icons.check_rounded,
                                size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                PrimaryButton(
                    label: 'Create Account',
                    isLoading: _isLoading,
                    onTap: _handleSignup),
                const SizedBox(height: 20),

                const OrDivider(),
                const SizedBox(height: 20),

                GoogleButton(
                  isLoading: _isGoogleLoading,
                  onTap: _handleGoogleSignIn,
                ),
                const SizedBox(height: 20),

                FooterLink(
                  text: 'Already have an account? ',
                  linkText: 'Sign in',
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}