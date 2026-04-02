import 'package:flutter/material.dart';

class AppColors {
  static const orange = Color(0xFFFF8400);
  static const orangeDark = Color(0xFFE07200);
  static const orangeGlow = Color(0x40FF8400);
  static const bg = Color(0xFF0F0F0F);
  static const card = Color(0xFF181818);
  static const card2 = Color(0xFF202020);
  static const border = Color(0xFF2A2A2A);
  static const text = Color(0xFFF0F0F0);
  static const muted = Color(0xFF888888);
  static const inputBg = Color(0xFF141414);
  static const success = Color(0xFF4ADE80);
  static const error = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);
  static const info = Color(0xFF60A5FA);
}

// ─── Validators ──────────────────────────────────────────────────
class Validators {
  /// Returns null if valid, error string if invalid
  static String? email(String value) {
    if (value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  /// Returns list of unmet password rules
  static List<_PasswordRule> passwordRules(String value) {
    return [
      _PasswordRule('At least 8 characters', value.length >= 8),
      _PasswordRule('One uppercase letter (A-Z)',
          RegExp(r'[A-Z]').hasMatch(value)),
      _PasswordRule(
          'One lowercase letter (a-z)', RegExp(r'[a-z]').hasMatch(value)),
      _PasswordRule('One number (0-9)', RegExp(r'[0-9]').hasMatch(value)),
      _PasswordRule('One special character (!@#\$...)',
          RegExp(r'[!@#\$&*~%^()_\-+=<>?/]').hasMatch(value)),
    ];
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Password is required';
    final rules = passwordRules(value);
    final failed = rules.where((r) => !r.passed).toList();
    if (failed.isNotEmpty) return failed.first.label;
    return null;
  }

  static int passwordStrength(String value) {
    if (value.isEmpty) return 0;
    return passwordRules(value).where((r) => r.passed).length;
  }
}

class _PasswordRule {
  final String label;
  final bool passed;
  const _PasswordRule(this.label, this.passed);
}

// ─── Grid Background ─────────────────────────────────────────────
class GridBackground extends StatelessWidget {
  final Widget child;
  const GridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(), child: child);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08FF8400)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Auth Card Wrapper ───────────────────────────────────────────
class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GridBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x99000000),
                        blurRadius: 60,
                        offset: Offset(0, 30),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Auth Header ─────────────────────────────────────────────────
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.orange,
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Back',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Auth Text Field ─────────────────────────────────────────────
class AuthTextField extends StatefulWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? errorText;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.onChanged,
    this.errorText,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: const TextStyle(color: AppColors.text, fontSize: 14),
          cursorColor: AppColors.orange,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                const TextStyle(color: Color(0xFF444444), fontSize: 14),
            filled: true,
            fillColor: AppColors.inputBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorText: widget.errorText,
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontSize: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.errorText != null
                    ? AppColors.error
                    : AppColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.errorText != null
                    ? AppColors.error
                    : AppColors.orange,
                width: 1.5,
              ),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// ─── Password Rules Widget ───────────────────────────────────────
class PasswordRulesWidget extends StatelessWidget {
  final String password;
  const PasswordRulesWidget({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final rules = Validators.passwordRules(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final score = Validators.passwordStrength(password);
            Color barColor;
            if (i < score) {
              if (score <= 1) barColor = AppColors.error;
              else if (score <= 2) barColor = AppColors.warning;
              else if (score <= 3) barColor = AppColors.info;
              else barColor = AppColors.success;
            } else {
              barColor = AppColors.border;
            }
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        // Rules list
        ...rules.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Icon(
                    r.passed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 13,
                    color: r.passed ? AppColors.success : AppColors.muted,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    r.label,
                    style: TextStyle(
                      color: r.passed ? AppColors.success : AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ─── Primary Button ──────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          disabledBackgroundColor: AppColors.orange.withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2),
              ),
      ),
    );
  }
}

// ─── Google Button ───────────────────────────────────────────────
class GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const GoogleButton({super.key, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card2,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.orange,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GooglePainter()),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), -0.5, 3.14, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), -1.6, 1.8, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), 1.9, 1.1, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), 3.0, 0.9, true, paint);
    paint.color = AppColors.card2;
    canvas.drawCircle(c, r * 0.55, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Or Divider ──────────────────────────────────────────────────
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}

// ─── Footer Link ─────────────────────────────────────────────────
class FooterLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const FooterLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            text: text,
            style:
                const TextStyle(color: AppColors.muted, fontSize: 13),
            children: [
              TextSpan(
                text: linkText,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}