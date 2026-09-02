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
import '../providers/campaign_providers.dart';
import '../widgets/campaign_status_badge.dart';

class AdminRegistrationsScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const AdminRegistrationsScreen({
    super.key,
    required this.campaignId,
  });

  @override
  ConsumerState<AdminRegistrationsScreen> createState() => _AdminRegistrationsScreenState();
}

class _AdminRegistrationsScreenState extends ConsumerState<AdminRegistrationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateRegistrationStatus(String regId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/campaign-registrations/$regId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'registrationStatus': newStatus}),
      );

      if (response.statusCode == 200) {
        ref.invalidate(campaignRegistrationsAdminProvider(widget.campaignId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration status updated to $newStatus'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showDynamicDetailsModal(CampaignRegistration reg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = reg.user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Registration Form Responses', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  _buildRow('Registration ID', reg.registrationNumber),
                  _buildRow('Member Name', user?.fullName ?? 'Member'),
                  _buildRow('Phone Number', user?.phoneNumber ?? 'N/A'),
                  _buildRow('City', user?.city ?? 'N/A'),
                  _buildRow('Gender', user?.gender ?? 'N/A'),
                  _buildRow('Date of Birth', user?.dateOfBirth ?? 'N/A'),

                  if (reg.submittedData.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('Campaign Custom Responses:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...reg.submittedData.entries.map((e) => _buildRow(e.key, e.value.toString())),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final registrationsAsync = ref.watch(campaignRegistrationsAdminProvider(widget.campaignId));
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Registered Users List (SCRUM-79)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar & Status Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search registered user by name, phone, or ID...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Registered', 'Approved', 'Rejected', 'Attended', 'Cancelled'].map((st) {
                      final isSelected = _statusFilter == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(st),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _statusFilter = st);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 2. Registrations List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(campaignRegistrationsAdminProvider(widget.campaignId)),
              child: registrationsAsync.when(
                data: (rawList) {
                  final query = _searchController.text.trim().toLowerCase();
                  var filtered = rawList.where((reg) {
                    if (_statusFilter != 'All' && reg.registrationStatus != _statusFilter) {
                      return false;
                    }
                    if (query.isNotEmpty) {
                      final name = reg.user?.fullName.toLowerCase() ?? '';
                      final phone = reg.user?.phoneNumber.toLowerCase() ?? '';
                      final regNum = reg.registrationNumber.toLowerCase();
                      return name.contains(query) || phone.contains(query) || regNum.contains(query);
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No registered users matching search query.',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final reg = filtered[index];
                      final user = reg.user;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryBlue,
                                    child: Text(
                                      user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user?.fullName ?? 'Registered Member', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('${user?.phoneNumber ?? ''} • ${user?.city ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CampaignStatusBadge(status: reg.registrationStatus, isCompact: true),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Ref: ${reg.registrationNumber}',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentBlue),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(dateFormat.format(reg.registeredAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Admin Action Controls
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showDynamicDetailsModal(reg),
                                      icon: const Icon(Icons.description_outlined, size: 16),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('View Answers'),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: PopupMenuButton<String>(
                                      onSelected: (newSt) => _updateRegistrationStatus(reg.id, newSt),
                                      itemBuilder: (ctx) => ['Registered', 'Approved', 'Attended', 'Rejected', 'Cancelled']
                                          .map((st) => PopupMenuItem(value: st, child: Text('Mark as $st')))
                                          .toList(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentBlue,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Update Status',
                                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                                          ],
                                        ),
                                      ),
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
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
