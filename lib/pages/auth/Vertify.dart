import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/Shared_widgets.dart';
import 'new_password.dart';
import '../signup/sign _up.dart';

class VertifyPage extends StatefulWidget {
  final String email;
  const VertifyPage({super.key, required this.email});

  @override
  State<VertifyPage> createState() => _VertifyPageState();
}

class _VertifyPageState extends State<VertifyPage> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focuses = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focuses) f.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focuses[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focuses[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────
          AuthHeader(
            title: 'Verification',
            subtitle: 'We sent a code to your email',
            onBack: () => Navigator.pop(context),
          ),

          // ── Body ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENTER VERIFICATION CODE',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),

                // ── OTP Boxes ────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (i) => _OtpBox(
                      controller: _controllers[i],
                      focusNode: _focuses[i],
                      onChanged: (v) => _onChanged(i, v),
                      isFilled: _controllers[i].text.isNotEmpty,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Resend row
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Didn't receive it? ",
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code resent!'),
                                  backgroundColor: AppColors.orange,
                                ),
                              );
                            },
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                PrimaryButton(
                  label: 'Verify & Continue',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewPasswordPage()),
                  ),
                ),
                const SizedBox(height: 20),
                const OrDivider(),
                const SizedBox(height: 20),
                const GoogleButton(),
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
            ),
          ),
        ],
      ),
    );
  }
}

// ── OTP Single Box ───────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final bool isFilled;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 62,
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFilled ? AppColors.orange : AppColors.border,
          width: 1.5,
        ),
        boxShadow: isFilled
            ? [const BoxShadow(color: Color(0x33FF8400), blurRadius: 8)]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          color: isFilled ? AppColors.orange : AppColors.text,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        cursorColor: AppColors.orange,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
