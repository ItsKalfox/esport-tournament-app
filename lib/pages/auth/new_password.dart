
// new_password.dart
import 'package:flutter/material.dart';
import '../../widgets/Shared widgets.dart';
import '../signup/login.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  int _strengthScore = 0;
  bool _match = false;
  bool _confirmTouched = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _checkStrength(String val) {
    int score = 0;
    if (val.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(val)) score++;
    if (RegExp(r'[0-9]').hasMatch(val)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(val)) score++;
    setState(() {
      _strengthScore = score;
      if (_confirmTouched) {
        _match = _newPassCtrl.text == _confirmCtrl.text;
      }
    });
  }

  void _checkMatch(String _) {
    setState(() {
      _confirmTouched = true;
      _match = _newPassCtrl.text == _confirmCtrl.text;
    });
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  String get _strengthLabel {
    switch (_strengthScore) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  void _submit() {
    if (_newPassCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_newPassCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    // Clear stack and go back to login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────
          AuthHeader(
            title: 'New\nPassword',
            subtitle: 'Create a unique password',
            onBack: () => Navigator.pop(context),
          ),

          // ── Body ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthTextField(
                  label: 'New Password',
                  hint: 'At least 8 characters',
                  isPassword: true,
                  controller: _newPassCtrl,
                  onChanged: _checkStrength,
                ),

                // Strength bar
                if (_newPassCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _strengthScore / 4,
                      backgroundColor: AppColors.border,
                      color: _strengthColor,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _strengthLabel,
                      style: TextStyle(
                        color: _strengthColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Confirm Password',
                  hint: '••••••••',
                  isPassword: true,
                  controller: _confirmCtrl,
                  onChanged: _checkMatch,
                ),

                if (_confirmTouched) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _match
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 14,
                        color: _match ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _match
                            ? 'Passwords match'
                            : 'Passwords do not match',
                        style: TextStyle(
                          color:
                              _match ? AppColors.success : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 28),
                PrimaryButton(
                    label: 'Save New Password', onTap: _submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}