import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/Shared widgets.dart';
import '../../services/auth_service.dart';
import '../main_shell.dart';
import '../auth/forgot _password.dart';
import '../signup/sign _up.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _emailError;
  String? _passError;
  bool _isLoggingIn = false;
  bool _isGoogleLoading = false;
  bool _emailTouched = false;
  bool _passTouched = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    if (!_emailTouched) return;
    setState(() => _emailError = Validators.email(value));
  }

  void _validatePassword(String value) {
    if (!_passTouched) return;
    setState(() =>
        _passError = value.isEmpty ? 'Password is required' : null);
  }

  bool _isFormValid() =>
      Validators.email(_emailCtrl.text) == null &&
      _passCtrl.text.isNotEmpty;

  // ── Firebase Email Login ──────────────────────────────────────
  Future<void> _handleLogin() async {
    setState(() {
      _emailTouched = true;
      _passTouched = true;
      _emailError = Validators.email(_emailCtrl.text);
      _passError =
          _passCtrl.text.isEmpty ? 'Password is required' : null;
    });

    if (!_isFormValid()) return;

    setState(() => _isLoggingIn = true);

    try {
      await AuthService.loginWithEmail(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );

      if (!mounted) return;
      _showSnackbar('Login successful! Welcome back 👋', AppColors.success);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnackbar(AuthService.getErrorMessage(e.code), AppColors.error);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Something went wrong. Please try again.', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  // ── Firebase Google Sign-In ───────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final credential = await AuthService.signInWithGoogle();

      if (credential == null) {
        // User cancelled the picker
        setState(() => _isGoogleLoading = false);
        return;
      }

      if (!mounted) return;
      final name = credential.user?.displayName ?? credential.user?.email ?? 'User';
      _showSnackbar('Welcome, $name! 🎮', AppColors.success);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnackbar(AuthService.getErrorMessage(e.code), AppColors.error);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Google sign-in failed. Please try again.', AppColors.error);
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
          const AuthHeader(
            title: 'Welcome\nBack',
            subtitle: 'Please sign in to continue',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailCtrl,
                  errorText: _emailError,
                  onChanged: (v) {
                    _emailTouched = true;
                    _validateEmail(v);
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Password',
                  hint: '••••••••',
                  isPassword: true,
                  controller: _passCtrl,
                  errorText: _passError,
                  onChanged: (v) {
                    _passTouched = true;
                    _validatePassword(v);
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage()),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Login',
                  isLoading: _isLoggingIn,
                  onTap: _handleLogin,
                ),
                const SizedBox(height: 20),
                const OrDivider(),
                const SizedBox(height: 20),
                GoogleButton(
                  isLoading: _isGoogleLoading,
                  onTap: _handleGoogleSignIn,
                ),
                const SizedBox(height: 20),
                FooterLink(
                  text: "Don't have an account? ",
                  linkText: 'Sign up',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupPage()),
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