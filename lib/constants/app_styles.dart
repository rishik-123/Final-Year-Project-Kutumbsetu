import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ];
  }

  static BoxDecoration glassDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? AppColors.cardDark.withValues(alpha: 0.85)
          : AppColors.cardLight.withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1,
      ),
    );
  }
}
