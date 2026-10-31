import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../constants/app_colors.dart';
import '../models/campaign_registration_model.dart';
import '../providers/auth_provider.dart';
import '../providers/campaign_providers.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/campaign_status_badge.dart';

/// Screen displaying all community campaigns and events registered by the currently logged-in user.
/// Allows the user to:
/// 1. View all active and past campaign registrations.
/// 2. Inspect full registration details via a bottom sheet modal.
/// 3. Cancel an active registration via PATCH /api/campaign-registrations/:id/cancel.
class MyRegistrationsScreen extends ConsumerWidget {
  const MyRegistrationsScreen({super.key});

  /// Displays a confirmation dialog and triggers cancellation of the specified registration.
  /// Sends PATCH request to /api/campaign-registrations/:id/cancel and invalidates the Riverpod provider.
  Future<void> _cancelRegistration(BuildContext context, WidgetRef ref, CampaignRegistration reg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Cancel Registration', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel your registration for "${reg.campaign?.title ?? 'this campaign'}"?\n\nRegistration ID: ${reg.registrationNumber}',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep Active'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Yes, Cancel Registration'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final auth = ref.read(authProvider);
    final userId = auth.user?.id;

    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/campaign-registrations/${reg.id}/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Invalidate provider to automatically refresh registration list
        ref.invalidate(myRegistrationsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration cancelled successfully.'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to cancel.'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  /// Displays a comprehensive bottom sheet containing all submitted registration data,
  /// including custom dynamic form responses and emergency contacts.
  void _showRegistrationDetailsModal(BuildContext context, CampaignRegistration reg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMMM d, yyyy — hh:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Registration Details',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  CampaignStatusBadge(status: reg.registrationStatus),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _buildDetailItem('Registration ID', reg.registrationNumber),
              _buildDetailItem('Campaign Title', reg.campaign?.title ?? 'Campaign'),
              _buildDetailItem('Category', reg.campaign?.category ?? 'General'),
              _buildDetailItem('Participation Type', reg.participationType),
              _buildDetailItem('Participants Count', reg.numberOfParticipants.toString()),
              if (reg.emergencyContactName.isNotEmpty)
                _buildDetailItem('Emergency Contact', '${reg.emergencyContactName} (${reg.emergencyContactNumber})'),
              if (reg.specialRequirements.isNotEmpty)
                _buildDetailItem('Special Requirements', reg.specialRequirements),
              _buildDetailItem('Registered Date', dateFormat.format(reg.registeredAt)),

              // Display custom form responses if submitted during campaign signup
              if (reg.submittedData.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Additional Responses:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                ...reg.submittedData.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${e.key}:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${e.value}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper row widget for clean key-value formatting inside the details modal.
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch reactive state of the user's registrations from Riverpod
    final registrationsAsync = ref.watch(myRegistrationsProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('My Registered Campaigns', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      // Pull-to-refresh invalidates the provider cache and reloads from server
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myRegistrationsProvider),
        child: registrationsAsync.when(
          data: (registrations) {
            // Empty state when user has not yet registered for any campaign
            if (registrations.isEmpty) {
              return _buildEmptyState(context);
            }
            // List of registered campaigns
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registrations.length,
              itemBuilder: (context, index) {
                final reg = registrations[index];
                final campaign = reg.campaign;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Registration ID Chip & Status Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                reg.registrationNumber,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.accentBlue,
                                ),
                              ),
                            ),
                            const Spacer(),
                            CampaignStatusBadge(status: reg.registrationStatus, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Campaign Title
                        Text(
                          campaign?.title ?? 'Campaign Details',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),

                        // Campaign Category
                        Text(
                          'Category: ${campaign?.category ?? 'General'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Registration Date
                        Row(
                          children: [
                            const Icon(Icons.event_rounded, size: 14, color: AppColors.accentBlue),
                            const SizedBox(width: 6),
                            Text(
                              'Registered on: ${dateFormat.format(reg.registeredAt)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // Bottom Action Buttons (View Details & Cancel Registration)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showRegistrationDetailsModal(context, reg),
                              icon: const Icon(Icons.info_outline_rounded, size: 15),
                              label: const Text('View Details', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            // Only show cancel action if the registration is currently active
                            if (!reg.isCancelled)
                              TextButton.icon(
                                onPressed: () => _cancelRegistration(context, ref, reg),
                                icon: const Icon(Icons.cancel_outlined, size: 15, color: Colors.redAccent),
                                label: const Text('Cancel Registration', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading registrations: $err')),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/my-registrations'),
    );
  }

  /// Empty state placeholder rendered when the user has zero campaign registrations.
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 64, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              'No Registrations Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You have not registered for any KutumbSetu campaigns yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/campaigns'),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Active Campaigns'),
            ),
          ],
        ),
      ),
    );
  }
}
