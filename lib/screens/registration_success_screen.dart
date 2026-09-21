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
    const saffronColor = Color(0xFFE67E22);
    const darkNavy = Color(0xFF1B4F72);

    final regNum = registrationData['registrationNumber'] as String? ?? 'REG-2026-00001';
    final campaignTitle = registrationData['campaignTitle'] as String? ?? 'Campaign';
    final campaignDate = registrationData['campaignDate'] as String? ?? '';
    final campaignLocation = registrationData['campaignLocation'] as String? ?? '';
    final participationType = registrationData['participationType'] as String? ?? 'Participant';
    final numberOfParticipants = registrationData['numberOfParticipants']?.toString() ?? '1';
    final emergencyContactName = registrationData['emergencyContactName'] as String? ?? '';
    final emergencyContactNumber = registrationData['emergencyContactNumber'] as String? ?? '';
    final regStatus = registrationData['registrationStatus'] as String? ?? 'Registered';

    DateTime regDate = DateTime.now();
    if (registrationData['registeredAt'] != null) {
      regDate = DateTime.tryParse(registrationData['registeredAt'].toString()) ?? DateTime.now();
    }
    final formattedDate = DateFormat('MMMM d, yyyy — hh:mm a').format(regDate);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Success Checkmark Header
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 68,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Registration Successful!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : darkNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your registration for $campaignTitle has been submitted successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),

                // Digital Confirmation Ticket Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'REGISTRATION ID',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: saffronColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Prominent Registration ID Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: saffronColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: saffronColor, width: 1.5),
                        ),
                        child: Text(
                          regNum,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: saffronColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Divider(),
                      const SizedBox(height: 12),

                      _buildTicketRow('Campaign Name', campaignTitle, isDark),
                      if (campaignDate.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildTicketRow('Campaign Date', campaignDate, isDark),
                      ],
                      if (campaignLocation.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildTicketRow('Location', campaignLocation, isDark),
                      ],
                      const SizedBox(height: 10),
                      _buildTicketRow('Participation Type', participationType, isDark),
                      const SizedBox(height: 10),
                      _buildTicketRow('No. of Participants', numberOfParticipants, isDark),
                      if (emergencyContactName.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildTicketRow('Emergency Contact', '$emergencyContactName ($emergencyContactNumber)', isDark),
                      ],
                      const SizedBox(height: 10),
                      _buildTicketRow('Registration Date', formattedDate, isDark),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Registration Status', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                          CampaignStatusBadge(status: regStatus, isCompact: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Primary [ DONE ] Button
                ElevatedButton(
                  onPressed: () => context.go('/campaigns'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: Text(
                    'DONE',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary [ VIEW MY REGISTRATIONS ] Button
                OutlinedButton.icon(
                  onPressed: () => context.push('/my-registrations'),
                  icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                  label: const Text('View My Registrations'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    foregroundColor: saffronColor,
                    side: const BorderSide(color: saffronColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
