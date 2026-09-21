import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppBottomNavBar extends ConsumerWidget {
  final String currentRoute;

  const AppBottomNavBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int selectedIndex = 0;
    if (currentRoute.startsWith('/campaigns')) {
      selectedIndex = 1;
    } else if (currentRoute.startsWith('/my-registrations')) {
      selectedIndex = 2;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Directory Tab
              _buildNavItem(
                context,
                icon: Icons.people_alt_rounded,
                label: 'Directory',
                isSelected: selectedIndex == 0,
                onTap: () {
                  if (currentRoute != '/') context.go('/');
                },
              ),

              // 2. Campaigns Tab
              _buildNavItem(
                context,
                icon: Icons.campaign_rounded,
                label: 'Campaigns',
                isSelected: selectedIndex == 1,
                onTap: () {
                  if (currentRoute != '/campaigns') context.go('/campaigns');
                },
              ),

              // 3. My Registrations Tab
              _buildNavItem(
                context,
                icon: Icons.assignment_turned_in_rounded,
                label: 'My Campaigns',
                isSelected: selectedIndex == 2,
                onTap: () {
                  if (currentRoute != '/my-registrations') context.go('/my-registrations');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.accentBlue;
    final inactiveColor = Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
