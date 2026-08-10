import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';
import '../constants/app_colors.dart';
import '../models/campaign_model.dart';
import '../providers/auth_provider.dart';
import '../providers/campaign_providers.dart';
import '../widgets/campaign_status_badge.dart';

class CampaignDetailScreen extends ConsumerStatefulWidget {
  final String campaignId;
  final Campaign? initialCampaign;

  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
    this.initialCampaign,
  });

  @override
  ConsumerState<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends ConsumerState<CampaignDetailScreen> {
  bool _isUpdatingStatus = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/campaigns/${widget.campaignId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        ref.invalidate(campaignDetailProvider(widget.campaignId));
        ref.invalidate(campaignsListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Campaign status updated to $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final campaignAsync = ref.watch(campaignDetailProvider(widget.campaignId));

    return Scaffold(
      body: campaignAsync.when(
        data: (campaignData) {
          final campaign = campaignData ?? widget.initialCampaign;
          if (campaign == null) {
            return const Center(child: Text('Campaign details not found.'));
          }

          final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
          final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

          String bannerImageUrl = campaign.bannerUrl;
          if (bannerImageUrl.startsWith('/')) {
            bannerImageUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}$bannerImageUrl';
          }

          final isActive = campaign.calculatedStatus == 'Active';

          return CustomScrollView(
            slivers: [
              // 1. Sliver App Bar with Banner
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: isDark ? AppColors.bgDark : AppColors.primaryBlue,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      onPressed: () {
                        Share.share(
                          'Join KutumbSetu Campaign: *${campaign.title}*\nCategory: ${campaign.category}\n\n${campaign.description}\n\nDownload KutumbSetu App to participate!',
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      bannerImageUrl.isNotEmpty
                          ? Image.network(
                              bannerImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackBanner(campaign.category),
                            )
                          : _buildFallbackBanner(campaign.category),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                campaign.category,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            CampaignStatusBadge(status: campaign.effectiveStatus),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Body Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        campaign.title,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Admin Status Change Selector (If Authorized Admin)
                      if (auth.isAdmin) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings, color: AppColors.accentBlue, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Admin Control — Status Management',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.accentBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: ['Draft', 'Upcoming', 'Active', 'Completed', 'Cancelled'].map((st) {
                                  final isCurrent = campaign.status == st;
                                  return ChoiceChip(
                                    label: Text(st),
                                    selected: isCurrent,
                                    selectedColor: AppColors.accentBlue,
                                    onSelected: (selected) {
                                      if (selected && !isCurrent) _updateStatus(st);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Dates & Duration Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              context,
                              icon: Icons.calendar_month_rounded,
                              label: 'Start Date',
                              value: dateFormat.format(campaign.startDate),
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              context,
                              icon: Icons.event_available_rounded,
                              label: 'End Date',
                              value: dateFormat.format(campaign.endDate),
                            ),
                            if (campaign.totalRegistrations > 0) ...[
                              const Divider(height: 20),
                              _buildInfoRow(
                                context,
                                icon: Icons.people_outline_rounded,
                                label: 'Registered Participants',
                                value: '${campaign.totalRegistrations} Users Registered',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Target & Raised Financial Progress
                      if (campaign.targetAmount > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Financial Progress',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${(campaign.progressPercentage * 100).toStringAsFixed(0)}% Achieved',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.verifiedBadge,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: campaign.progressPercentage,
                                  minHeight: 10,
                                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    campaign.progressPercentage >= 1.0 ? Colors.green : AppColors.accentBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Raised: ${currencyFormat.format(campaign.amountRaised)}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.verifiedBadge,
                                    ),
                                  ),
                                  Text(
                                    'Target: ${currencyFormat.format(campaign.targetAmount)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Objective
                      if (campaign.objective.isNotEmpty) ...[
                        Text(
                          'Campaign Objective',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          campaign.objective,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Description
                      Text(
                        'About Campaign',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        campaign.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dynamic Fields Info Badge
                      if (campaign.dynamicFields.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.dynamic_form_rounded, color: AppColors.accentBlue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dynamic Registration Fields Enabled',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'This campaign requires details: ${campaign.dynamicFields.map((f) => f.label).join(', ')}.',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Contact Info
                      if (campaign.contactInfo.phone.isNotEmpty || campaign.contactInfo.email.isNotEmpty) ...[
                        Text(
                          'Organizer Contact Details',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (campaign.contactInfo.organizerName.isNotEmpty)
                                _buildInfoRow(
                                  context,
                                  icon: Icons.person_outline_rounded,
                                  label: 'Organizer',
                                  value: campaign.contactInfo.organizerName,
                                ),
                              if (campaign.contactInfo.phone.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildInfoRow(
                                  context,
                                  icon: Icons.phone_outlined,
                                  label: 'Phone',
                                  value: campaign.contactInfo.phone,
                                ),
                              ],
                              if (campaign.contactInfo.email.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildInfoRow(
                                  context,
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: campaign.contactInfo.email,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Bottom CTAs Row
                      Row(
                        children: [
                          if (auth.isAdmin)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.push('/campaigns/${campaign.id}/registrations');
                                },
                                icon: const Icon(Icons.people_alt_rounded),
                                label: const Text('View Registered Users'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: AppColors.primaryBlue),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          if (auth.isAdmin) const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isActive
                                  ? () => context.push('/campaigns/${campaign.id}/register', extra: campaign)
                                  : null,
                              icon: const Icon(Icons.app_registration_rounded),
                              label: Text(
                                isActive ? 'Register for Campaign' : 'Registration Closed',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive ? AppColors.accentBlue : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error loading details: $err')),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accentBlue),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackBanner(String category) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_rounded, size: 56, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              category,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
