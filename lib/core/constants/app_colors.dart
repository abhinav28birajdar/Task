import 'package:flutter/material.dart';

class AppColors {
  // Brand - Modern Vibrant Purple (#b72bff)
  static const primary = Color(0xFFb72bff); // Main brand color
  static const primaryDark = Color(0xFF9c24db); // Primary hover
  static const primaryPressed = Color(0xFF7d1bb3); // Primary pressed
  static const primaryLight = Color(0xFFd98cff); // Primary light variant
  static const primarySoftBG = Color(0x1ab72bff); // rgba(183, 43, 255, 0.1)
  static const secondary = Color(0xFFd98cff); // Secondary/Light variant
  static const accent = Color(0xFFb72bff); // Same as primary
  
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFFF5252);
  static const info = Color(0xFF2196F3);

  // Priority
  static const priorityHigh = Color(0xFFb72bff); // High priority - brand color
  static const priorityMedium = Color(0xFFF2C94C);
  static const priorityLow = Color(0xFF6FCF97);
  static const priorityUrgent = Color(0xFFb72bff);

  // Light Mode Specifications
  static const lightPrimary = Color(0xFFb72bff); // Brand color
  static const lightSecondary = Color(0xFFd98cff); // Light variant
  static const lightBackground = Color(0xFFF8F7FF); // Slight purple tint
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF1a1a1a);
  static const lightTextSecondary = Color(0xFF6b6b78);
  static const lightBorder = Color(0xFFE5E7EB);

  // Dark Mode Specifications (#0a0a0f background)
  static const darkPrimary = Color(0xFFb72bff); // Keep brand color consistent
  static const darkSecondary = Color(0xFFd98cff); // Light variant
  static const darkBackground = Color(0xFF0a0a0f); // Main dark bg
  static const darkSurface = Color(0xFF12121a); // Card/surface bg
  static const darkElevatedSurface = Color(0xFF1a1a24); // Elevated surface
  static const darkCard = Color(0xFF12121a);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFa1a1aa);
  static const darkBorder = Color(0xFF2a2a35); // Soft border
  static const darkActiveBorder = Color(0xFFb72bff); // Active border
  
  // Specific Semantic Colors
  static const emerald = Color(0xFF10B981);
  static const rose = Color(0xFFF43F5E);
  static const amber = Color(0xFFF59E0B);
  static const indigo = Color(0xFF6366F1);
  
  // Glassmorphism
  static Color darkGlass = const Color(0xFF12121a).withOpacity(0.7);
  static Color lightGlass = Colors.white.withOpacity(0.7);
  
  // Button States
  static const buttonDisabled = Color(0xFF3a3a45);
  
  // Input States
  static Color inputGlow = const Color(0xFFb72bff).withOpacity(0.6); // 0 0 10px rgba(183, 43, 255, 0.6)
}
