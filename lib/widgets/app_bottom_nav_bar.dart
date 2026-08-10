import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';

class AppBottomNavBar extends ConsumerWidget {
  final String currentRoute;

  const AppBottomNavBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final isAdmin = auth.isAdmin;

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

              // 4. Admin Toggle / Role Badge
              InkWell(
                onTap: () {
                  ref.read(authProvider.notifier).toggleAdminRole();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !isAdmin
                            ? 'Switched to Admin Role. You can now create campaigns & manage registrations.'
                            : 'Switched to Normal User Role.',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? AppColors.primaryBlue.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                          color: isAdmin ? AppColors.accentBlue : Colors.grey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAdmin ? 'Admin ON' : 'User',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isAdmin ? FontWeight.bold : FontWeight.w500,
                          color: isAdmin ? AppColors.accentBlue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
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
