import 'package:flutter/material.dart';

class ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool isFilled;

  const ProfileActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isFilled ? color : backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: isFilled ? null : Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isFilled ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isFilled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
