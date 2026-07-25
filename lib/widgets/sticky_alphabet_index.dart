import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class StickyAlphabetIndex extends StatelessWidget {
  final List<String> availableLetters;
  final String activeLetter;
  final ValueChanged<String> onLetterTap;

  const StickyAlphabetIndex({
    super.key,
    required this.availableLetters,
    required this.activeLetter,
    required this.onLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 28,
      margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: AppConstants.alphabetIndex.map((letter) {
            final bool isAvailable = availableLetters.contains(letter);
            final bool isActive = activeLetter == letter;

            return GestureDetector(
              onTap: isAvailable ? () => onLetterTap(letter) : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.accentBlue
                      : (isAvailable ? Colors.transparent : Colors.transparent),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : (isAvailable
                            ? (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.primaryBlue)
                            : (isDark
                                ? Colors.white24
                                : Colors.black26)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
