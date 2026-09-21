import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../api_config.dart';
import '../constants/app_colors.dart';
import '../models/campaign_model.dart';
import '../providers/auth_provider.dart';
import '../providers/campaign_providers.dart';

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

  // Campaign-specific form fields
  String _participationType = 'Participant'; // 'Participant', 'Volunteer'
  int _numberOfParticipants = 1;
  final TextEditingController _specialRequirementsController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();
  String _heardFrom = 'KutumbSetu'; // 'KutumbSetu', 'Family/Friend', 'Community', 'Social Media', 'Other'

  final List<String> _heardFromOptions = const [
    'KutumbSetu',
    'Family/Friend',
    'Community',
    'Social Media',
    'Other',
  ];

  bool _isConfirmed = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _specialRequirementsController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    super.dispose();
  }

  // Calculate age string helper
  String _calculateAgeDisplay(String dateOfBirth) {
    if (dateOfBirth.trim().isEmpty) return 'Not Provided';
    final parsed = DateTime.tryParse(dateOfBirth);
    if (parsed != null) {
      final now = DateTime.now();
      int age = now.year - parsed.year;
      if (now.month < parsed.month || (now.month == parsed.month && now.day < parsed.day)) {
        age--;
      }
      return age >= 0 ? '$age Years ($dateOfBirth)' : dateOfBirth;
    }
    return dateOfBirth;
  }

  Future<void> _submitRegistration(Campaign campaign) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_isConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check the confirmation box before submitting.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session expired. Please log in to register.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/campaigns/${widget.campaignId}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.id,
          'campaignTitle': campaign.title,
          'campaignCategory': campaign.category,
          'campaignLocation': campaign.location,
          'campaignDescription': campaign.description,
          'participationType': _participationType,
          'numberOfParticipants': _numberOfParticipants,
          'specialRequirements': _specialRequirementsController.text.trim(),
          'emergencyContactName': _emergencyContactNameController.text.trim(),
          'emergencyContactNumber': _emergencyContactNumberController.text.trim(),
          'heardFrom': _heardFrom,
          'submittedData': {
            'participationType': _participationType,
            'numberOfParticipants': _numberOfParticipants,
            'specialRequirements': _specialRequirementsController.text.trim(),
            'emergencyContactName': _emergencyContactNameController.text.trim(),
            'emergencyContactNumber': _emergencyContactNumberController.text.trim(),
            'heardFrom': _heardFrom,
          },
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && data['success'] == true) {
        final reg = data['registration'];
        ref.invalidate(myRegistrationsProvider);
        ref.invalidate(campaignDetailProvider(widget.campaignId));
        ref.invalidate(campaignsListProvider);

        context.pushReplacement(
          '/campaigns/${widget.campaignId}/success',
          extra: {
            'registrationNumber': reg['registrationNumber'] ?? 'REG-2026-00001',
            'campaignTitle': campaign.title,
            'campaignDate': '${DateFormat('dd MMM yyyy').format(campaign.startDate)} - ${DateFormat('dd MMM yyyy').format(campaign.endDate)}',
            'campaignLocation': campaign.location.isNotEmpty ? campaign.location : 'Community Hall',
            'participationType': _participationType,
            'numberOfParticipants': _numberOfParticipants,
            'emergencyContactName': _emergencyContactNameController.text.trim(),
            'emergencyContactNumber': _emergencyContactNumberController.text.trim(),
            'registrationStatus': reg['registrationStatus'] ?? 'Registered',
            'registeredAt': reg['registeredAt'] ?? DateTime.now().toIso8601String(),
          },
        );
      } else {
        final errMsg = data['message'] ?? 'Registration failed. Please try again.';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Registration Notice', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(errMsg, style: GoogleFonts.inter(fontSize: 14)),
            actions: [
              if (data['registration'] != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (mounted) {
                      context.push('/my-registrations');
                    }
                  },
                  child: const Text('View My Registrations'),
                ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, {Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const saffron = Color(0xFFE67E22);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: saffron.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: saffron),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    Widget? prefix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          if (prefix != null) ...[
            prefix,
            const SizedBox(width: 10),
          ] else ...[
            Icon(icon, size: 18, color: const Color(0xFF1B4F72)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const saffronColor = Color(0xFFE67E22);
    const darkNavy = Color(0xFF1B4F72);

    final auth = ref.watch(authProvider);
    final user = auth.user;

    final campaignAsync = ref.watch(campaignDetailProvider(widget.campaignId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Register for Campaign',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: campaignAsync.when(
        data: (loadedCampaign) {
          final campaign = loadedCampaign ?? widget.campaign;
          if (campaign == null) {
            return const Center(child: Text('Campaign details not available.'));
          }

          final dateFormat = DateFormat('dd MMM yyyy');
          final formattedCampaignDate =
              '${dateFormat.format(campaign.startDate)} - ${dateFormat.format(campaign.endDate)}';
          final campaignLocation =
              campaign.location.isNotEmpty ? campaign.location : 'Community Hall / Center';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. AUTO-FILLED CAMPAIGN INFORMATION BANNER CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                            : [const Color(0xFFEBF5FB), const Color(0xFFD4E6F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: darkNavy.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: saffronColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    campaign.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : darkNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Category: ${campaign.category}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: saffronColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // Campaign Date & Location
                        Row(
                          children: [
                            const Icon(Icons.event_available_rounded, size: 16, color: saffronColor),
                            const SizedBox(width: 6),
                            Text(
                              'Date: ',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Expanded(
                              child: Text(
                                formattedCampaignDate,
                                style: GoogleFonts.inter(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: saffronColor),
                            const SizedBox(width: 6),
                            Text(
                              'Location: ',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Expanded(
                              child: Text(
                                campaignLocation,
                                style: GoogleFonts.inter(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. PERSONAL DETAILS (AUTOFILLED & READ-ONLY FROM USER PROFILE)
                  _buildSectionHeader(
                    'PERSONAL DETAILS',
                    Icons.person_rounded,
                    trailing: TextButton.icon(
                      onPressed: () {
                        context.push('/profile-completion');
                      },
                      icon: const Icon(Icons.edit_outlined, size: 15, color: saffronColor),
                      label: Text(
                        'Edit Profile',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: saffronColor,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),

                  // User Avatar + Full Name Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: saffronColor.withValues(alpha: 0.15),
                          backgroundImage: (user != null && user.profilePhoto.isNotEmpty)
                              ? NetworkImage(user.profilePhoto)
                              : null,
                          child: (user == null || user.profilePhoto.isEmpty)
                              ? const Icon(Icons.person, color: saffronColor, size: 24)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName.isNotEmpty == true ? user!.fullName : 'Registered Member',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Role: ${(user?.role ?? "user").toUpperCase()}',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                      ],
                    ),
                  ),

                  // Mobile Number & Email Address
                  Row(
                    children: [
                      Expanded(
                        child: _buildReadOnlyField(
                          label: 'Mobile Number',
                          value: user?.phoneNumber ?? 'N/A',
                          icon: Icons.phone_iphone_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildReadOnlyField(
                          label: 'Email Address',
                          value: user?.email.isNotEmpty == true ? user!.email : 'N/A',
                          icon: Icons.email_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Age / DOB & Gender
                  Row(
                    children: [
                      Expanded(
                        child: _buildReadOnlyField(
                          label: 'Age / DOB',
                          value: _calculateAgeDisplay(user?.dateOfBirth ?? ''),
                          icon: Icons.cake_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildReadOnlyField(
                          label: 'Gender',
                          value: user?.gender.isNotEmpty == true ? user!.gender : 'Male',
                          icon: Icons.wc_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Address, City & Pincode / State
                  _buildReadOnlyField(
                    label: 'Address / Locality',
                    value: user?.address.isNotEmpty == true
                        ? user!.address
                        : (user?.nativePlace.isNotEmpty == true ? user!.nativePlace : 'Community Registered Address'),
                    icon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildReadOnlyField(
                          label: 'City',
                          value: user?.city.isNotEmpty == true ? user!.city : 'Gujarat',
                          icon: Icons.location_city_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildReadOnlyField(
                          label: 'State / Region',
                          value: user?.state.isNotEmpty == true ? user!.state : 'Gujarat',
                          icon: Icons.map_outlined,
                        ),
                      ),
                    ],
                  ),

                  // 3. CAMPAIGN PARTICIPATION DETAILS (EDITABLE USER INPUTS)
                  _buildSectionHeader('PARTICIPATION DETAILS', Icons.how_to_reg_rounded),

                  // Participation Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Participation Type *',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Participant',
                              label: Text('Participant'),
                              icon: Icon(Icons.person_rounded),
                            ),
                            ButtonSegment(
                              value: 'Volunteer',
                              label: Text('Volunteer'),
                              icon: Icon(Icons.volunteer_activism_rounded),
                            ),
                          ],
                          selected: {_participationType},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _participationType = newSelection.first;
                            });
                          },
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Number of Participants Counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Number of Participants *',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Family members or group count',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _numberOfParticipants > 1
                                  ? () => setState(() => _numberOfParticipants--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              color: saffronColor,
                              iconSize: 28,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: saffronColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_numberOfParticipants',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: saffronColor,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _numberOfParticipants < 20
                                  ? () => setState(() => _numberOfParticipants++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              color: saffronColor,
                              iconSize: 28,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Special Requirements / Requests (Optional)
                  TextFormField(
                    controller: _specialRequirementsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Special Requirements / Requests (Optional)',
                      hintText: 'E.g., Dietary preferences, seating assistance, transport...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.notes_rounded),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  // 4. EMERGENCY CONTACT (REQUIRED)
                  _buildSectionHeader('EMERGENCY CONTACT', Icons.contact_emergency_rounded),

                  // Emergency Contact Name
                  TextFormField(
                    controller: _emergencyContactNameController,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact Name *',
                      hintText: 'Full Name of Family Member / Relative',
                      prefixIcon: const Icon(Icons.person_pin_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Emergency contact name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Emergency Contact Number
                  TextFormField(
                    controller: _emergencyContactNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact Number *',
                      prefixText: '+91 ',
                      prefixIcon: const Icon(Icons.phone_in_talk_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Emergency contact phone number is required';
                      }
                      final clean = value.replaceAll(RegExp(r'\D'), '');
                      if (clean.length < 10) {
                        return 'Enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. DISCOVERY / HOW DID YOU HEAR ABOUT THIS CAMPAIGN
                  _buildSectionHeader('HOW DID YOU HEAR ABOUT US?', Icons.campaign_outlined),

                  DropdownButtonFormField<String>(
                    initialValue: _heardFrom,
                    decoration: InputDecoration(
                      labelText: 'How did you hear about this campaign? *',
                      prefixIcon: const Icon(Icons.hearing_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _heardFromOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(opt, style: GoogleFonts.inter(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _heardFrom = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // 6. CONFIRMATION CHECKBOX
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isConfirmed
                          ? Colors.green.withValues(alpha: 0.08)
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isConfirmed ? Colors.green : Colors.grey.shade300,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _isConfirmed,
                      onChanged: (val) {
                        setState(() {
                          _isConfirmed = val ?? false;
                        });
                      },
                      activeColor: saffronColor,
                      title: Text(
                        'I confirm that the information provided is correct.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 7. SUBMIT BUTTON (REGISTER YOURSELF)
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submitRegistration(campaign),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkNavy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.how_to_reg_rounded, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'REGISTER YOURSELF',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE67E22)),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text('Failed to load campaign information: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(campaignDetailProvider(widget.campaignId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
