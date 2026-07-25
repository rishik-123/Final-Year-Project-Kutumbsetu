import 'package:flutter/material.dart';

class AppColors {
  // Brand Blues & Gradients
  static const Color primaryBlue = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color accentBlue = Color(0xFF2563EB); // Vibrant Electric Blue
  static const Color lightBlue = Color(0xFF60A5FA); // Soft Blue accent
  static const Color skyBlue = Color(0xFFEFF6FF); // Background tint

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradientLight = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradientDark = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient avatarGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status & Badges
  static const Color verifiedBadge = Color(0xFF0284C7);
  static const Color activeBadge = Color(0xFF16A34A);
  static const Color inactiveBadge = Color(0xFF9CA3AF);
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color favoriteRed = Color(0xFFEF4444);

  // Neutral Colors Light
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Neutral Colors Dark
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);
}
