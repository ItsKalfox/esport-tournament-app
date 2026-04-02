import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/Shared widgets.dart';
import '../../services/auth_service.dart';
import '../signup/sign _up.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    setState(() {
      _emailError = Validators.email(_emailCtrl.text);
    });

    if (_emailError != null) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.sendPasswordResetEmail(_emailCtrl.text);

      if (!mounted) return;
      setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = AuthService.getErrorMessage(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthHeader(
            title: 'Forgot\nPassword',
            subtitle: 'Enter your email address',
            onBack: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: _emailSent ? _buildSuccessState() : _buildFormState(),
          ),
        ],
      ),
    );
  }

  // ── Success state after email sent ───────────────────────────
  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  color: AppColors.success, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Check your inbox',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a password reset link to\n${_emailCtrl.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Back to Login',
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _emailSent = false;
                _emailCtrl.clear();
              });
            },
            child: const Text(
              'Try a different email',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Form state ────────────────────────────────────────────────
  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          label: 'Email Address',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          controller: _emailCtrl,
          errorText: _emailError,
          onChanged: (v) {
            setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Send Reset Link',
          isLoading: _isLoading,
          onTap: _handleSendReset,
        ),
        const SizedBox(height: 20),
        const OrDivider(),
        const SizedBox(height: 20),
        GoogleButton(
          onTap: () {},
        ),
        const SizedBox(height: 20),
        FooterLink(
          text: 'Have an account? ',
          linkText: 'Sign up',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SignupPage()),
          ),
        ),
      ],
    );
  }
}