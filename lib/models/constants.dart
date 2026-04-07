import 'package:flutter/material.dart';

class FigmaColors {
  static const Color background = Color(0xFF000000); // Pure Black
  static const Color containerBg = Color(0x21FFA600); // ~13% opacity orange over dark background
  static const Color containerBorder = Color(0xFFFF8400); // Bright Orange glowing border
  
  static const Color titleText = Color(0xFFFFFFFF);
  static const Color subtitleText = Color(0xFFFFFFFF);
  
  static const Color nextBtnBg = Color(0xFFD9D9D9); // Light Silver
  static const Color nextBtnText = Color(0xFF000000);
  
  static const Color skipBtnBg = Color(0xFF4A4747); // Dark Grey
  static const Color skipBtnText = Color(0xFFFFFFFF);
  
  static const Color activeIndicator = Color(0xFFFF8400);
  static const Color inactiveIndicator = Color(0x80FFFFFF); // Semi-transparent white
  static const Color dividerLine = Color(0x4DFFFFFF); // Subtle divider
}

class FigmaTypography {
  static const TextStyle title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28.0, 
    fontWeight: FontWeight.w800, // Extra Bold
    color: FigmaColors.titleText,
    height: 1.2,
    letterSpacing: 1.0,
  );
  
  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    color: FigmaColors.subtitleText,
    height: 1.5,
  );
  
  static const TextStyle nextButton = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: FigmaColors.nextBtnText,
  );
  
  static const TextStyle skipButton = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: FigmaColors.skipBtnText,
  );
}
