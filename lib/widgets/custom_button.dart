import 'package:flutter/material.dart';
import '../models/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 56.0, 
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? FigmaColors.containerBorder : Colors.transparent,
          foregroundColor: isPrimary ? Colors.white : FigmaColors.containerBorder,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: isPrimary 
                ? BorderSide.none 
                : const BorderSide(color: FigmaColors.containerBorder, width: 2),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: isPrimary 
              ? FigmaTypography.nextButton 
              : FigmaTypography.nextButton.copyWith(color: FigmaColors.containerBorder),
        ),
      ),
    );
  }
}
