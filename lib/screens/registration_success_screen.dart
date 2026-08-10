import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../widgets/campaign_status_badge.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> registrationData;

  const RegistrationSuccessScreen({
    super.key,
    required this.registrationData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final regNum = registrationData['registrationNumber'] as String? ?? 'KS-REG-XXXXXX';
    final campaignTitle = registrationData['campaignTitle'] as String? ?? 'Campaign';
    final regStatus = registrationData['registrationStatus'] as String? ?? 'Registered';

    DateTime regDate = DateTime.now();
    if (registrationData['registeredAt'] != null) {
      regDate = DateTime.tryParse(registrationData['registeredAt'].toString()) ?? DateTime.now();
    }
    final formattedDate = DateFormat('MMMM d, yyyy — hh:mm a').format(regDate);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Check Icon Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Registration Confirmed!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your registration has been saved successfully in KutumbSetu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 28),

                // Digital Confirmation Ticket Card (SCRUM-80)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'REGISTRATION TICKET',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Unique Registration ID Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentBlue, width: 1.5),
                        ),
                        child: Text(
                          regNum,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Divider(),
                      const SizedBox(height: 14),

                      _buildTicketRow('Campaign Name', campaignTitle, isDark),
                      const SizedBox(height: 12),
                      _buildTicketRow('Registration Date', formattedDate, isDark),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Status', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                          CampaignStatusBadge(status: regStatus, isCompact: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/my-registrations'),
                    icon: const Icon(Icons.assignment_turned_in_rounded),
                    label: const Text('View My Registrations'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/campaigns'),
                    icon: const Icon(Icons.campaign_rounded),
                    label: const Text('Back to All Campaigns'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
