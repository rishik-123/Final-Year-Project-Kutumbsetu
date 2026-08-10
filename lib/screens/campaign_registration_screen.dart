import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../constants/app_colors.dart';
import '../models/campaign_model.dart';
import '../providers/auth_provider.dart';
import '../providers/campaign_providers.dart';
import '../widgets/dynamic_form_field.dart';

class CampaignRegistrationScreen extends ConsumerStatefulWidget {
  final String campaignId;
  final Campaign? campaign;

  const CampaignRegistrationScreen({
    super.key,
    required this.campaignId,
    this.campaign,
  });

  @override
  ConsumerState<CampaignRegistrationScreen> createState() => _CampaignRegistrationScreenState();
}

class _CampaignRegistrationScreenState extends ConsumerState<CampaignRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _dynamicData = {};

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final user = auth.user;

    final campaignAsync = ref.watch(campaignDetailProvider(widget.campaignId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Register for Campaign', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: campaignAsync.when(
        data: (loadedCampaign) {
          final campaign = loadedCampaign ?? widget.campaign;
          if (campaign == null) {
            return const Center(child: Text('Campaign details unavailable.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campaign Info Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded, size: 36, color: AppColors.primaryBlue),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                campaign.title,
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Category: ${campaign.category}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Prefilled Member Profile Information (SCRUM-75)
                  Text('Member Profile Details (Prefilled)', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  _buildDisabledField(
                    label: 'Full Name',
                    value: user?.fullName ?? 'KutumbSetu Member',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDisabledField(
                          label: 'Phone Number',
                          value: user?.phoneNumber ?? '+919999999999',
                          icon: Icons.phone_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDisabledField(
                          label: 'City',
                          value: user?.city ?? 'Anand',
                          icon: Icons.location_city_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDisabledField(
                          label: 'Gender',
                          value: user?.gender ?? 'Male',
                          icon: Icons.transgender_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDisabledField(
                          label: 'Date of Birth',
                          value: user?.dateOfBirth ?? '1995-05-15',
                          icon: Icons.cake_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Section 2: Dynamic Form Fields (SCRUM-76)
                  if (campaign.dynamicFields.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.dynamic_form_rounded, color: AppColors.accentBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Campaign Specific Questions',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...campaign.dynamicFields.map(
                      (field) => DynamicFormFieldWidget(
                        field: field,
                        initialValue: _dynamicData[field.fieldName],
                        onChanged: (val) {
                          _dynamicData[field.fieldName] = val;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit Registration Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _submitRegistration(context, campaign),
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.how_to_reg_rounded),
                      label: Text(_isSubmitting ? 'Submitting Registration...' : 'Confirm & Register'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(body: Center(child: Text('Error loading campaign: $err'))),
      ),
    );
  }

  Widget _buildDisabledField({required String label, required String value, required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accentBlue),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitRegistration(BuildContext context, Campaign campaign) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id ?? '6a7962b212a58c4a0e118cab';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/campaigns/${widget.campaignId}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'submittedData': _dynamicData,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final reg = data['registration'];
        ref.invalidate(myRegistrationsProvider);
        ref.invalidate(campaignDetailProvider(widget.campaignId));

        if (mounted) {
          context.pushReplacement(
            '/campaigns/${widget.campaignId}/success',
            extra: {
              'registrationNumber': reg['registrationNumber'],
              'campaignTitle': campaign.title,
              'registrationStatus': reg['registrationStatus'],
              'registeredAt': reg['registeredAt'],
            },
          );
        }
      } else {
        final errMsg = data['message'] ?? 'Registration failed.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
