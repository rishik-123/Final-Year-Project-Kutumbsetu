import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../constants/app_colors.dart';
import '../models/campaign_model.dart';
import '../providers/auth_provider.dart';
import '../providers/campaign_providers.dart';

class CampaignCreateScreen extends ConsumerStatefulWidget {
  const CampaignCreateScreen({super.key});

  @override
  ConsumerState<CampaignCreateScreen> createState() => _CampaignCreateScreenState();
}

class _CampaignCreateScreenState extends ConsumerState<CampaignCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _objectiveController = TextEditingController();
  final TextEditingController _organizerNameController = TextEditingController();
  final TextEditingController _organizerPhoneController = TextEditingController();
  final TextEditingController _organizerEmailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'Blood Donation';
  String _selectedStatus = 'Active';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));

  File? _selectedImageFile;
  String? _uploadedBannerUrl;
  bool _isUploadingBanner = false;
  bool _isSubmitting = false;

  final List<CampaignDynamicField> _dynamicFields = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _objectiveController.dispose();
    _organizerNameController.dispose();
    _organizerPhoneController.dispose();
    _organizerEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadBanner() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final sizeInBytes = await file.length();
    if (sizeInBytes > 5 * 1024 * 1024) {
      if (mounted) {
        _showSnackBar('Image size exceeds 5MB limit. Please choose a smaller image.', isError: true);
      }
      return;
    }

    setState(() {
      _selectedImageFile = file;
      _isUploadingBanner = true;
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/banner');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('banner', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['url'] != null) {
          setState(() {
            _uploadedBannerUrl = data['url'] as String;
          });
          _showSnackBar('Banner uploaded successfully!');
        }
      } else {
        _showSnackBar('Banner upload failed. Status ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Upload failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingBanner = false;
        });
      }
    }
  }

  void _addDynamicFieldDialog() {
    final labelCtrl = TextEditingController();
    String fieldType = 'text';
    bool required = false;
    final optionsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add Custom Registration Field', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(labelText: 'Field Label (e.g. T-Shirt Size)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: fieldType,
                      decoration: const InputDecoration(labelText: 'Field Type'),
                      items: const [
                        DropdownMenuItem(value: 'text', child: Text('Text Field')),
                        DropdownMenuItem(value: 'number', child: Text('Number Input')),
                        DropdownMenuItem(value: 'dropdown', child: Text('Dropdown Select')),
                        DropdownMenuItem(value: 'radio', child: Text('Radio Buttons')),
                        DropdownMenuItem(value: 'checkbox', child: Text('Checkboxes')),
                        DropdownMenuItem(value: 'date', child: Text('Date Picker')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => fieldType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Is Required?'),
                      value: required,
                      onChanged: (val) => setDialogState(() => required = val ?? false),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (fieldType == 'dropdown' || fieldType == 'radio' || fieldType == 'checkbox') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: optionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Options (comma separated)',
                          hintText: 'Small, Medium, Large, XL',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (labelCtrl.text.trim().isEmpty) return;
                    final label = labelCtrl.text.trim();
                    final fieldName = label.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
                    final opts = optionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                    setState(() {
                      _dynamicFields.add(CampaignDynamicField(
                        fieldName: fieldName,
                        label: label,
                        type: fieldType,
                        required: required,
                        options: opts,
                        order: _dynamicFields.length + 1,
                      ));
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Field'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate) || _endDate.isAtSameMomentAs(_startDate)) {
      _showSnackBar('Campaign End Date must be strictly after Start Date.', isError: true);
      return;
    }

    final targetVal = double.tryParse(_targetAmountController.text.trim()) ?? 0;
    if (targetVal < 0) {
      _showSnackBar('Target amount cannot be negative.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = ref.read(authProvider);
      final campaignPayload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'bannerUrl': _uploadedBannerUrl ?? '',
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'status': _selectedStatus,
        'targetAmount': targetVal,
        'objective': _objectiveController.text.trim(),
        'contactInfo': {
          'organizerName': _organizerNameController.text.trim(),
          'phone': _organizerPhoneController.text.trim(),
          'email': _organizerEmailController.text.trim(),
        },
        'additionalNotes': _notesController.text.trim(),
        'createdBy': auth.user?.id,
        'dynamicFields': _dynamicFields.map((f) => f.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/campaigns'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(campaignPayload),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ref.invalidate(campaignsListProvider);
          if (mounted) {
            _showSnackBar('Campaign created successfully!');
            context.pop();
          }
        }
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(data['message'] ?? 'Failed to create campaign.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error submitting campaign: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(campaignCategoriesProvider);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Campaign', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner Image Picker Container
              Text('Campaign Banner Image (SCRUM-70)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAndUploadBanner,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1.5,
                    ),
                  ),
                  child: _isUploadingBanner
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_rounded, size: 44, color: AppColors.accentBlue),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to choose & upload campaign banner',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.accentBlue),
                                ),
                                const SizedBox(height: 4),
                                const Text('Supports JPG, PNG, WEBP (Max 5MB)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Campaign Title
              TextFormField(
                controller: _titleController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Campaign title is required' : null,
                decoration: const InputDecoration(
                  labelText: 'Campaign Title *',
                  hintText: 'e.g. Annual Blood Donation Drive 2026',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Category & Status Row (SCRUM-68, 73)
              Row(
                children: [
                  Expanded(
                    child: categoriesAsync.when(
                      data: (cats) => DropdownButtonFormField<String>(
                        value: cats.any((c) => c.name == _selectedCategory) ? _selectedCategory : cats.first.name,
                        decoration: const InputDecoration(labelText: 'Category *'),
                        items: cats.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status *'),
                      items: ['Draft', 'Upcoming', 'Active', 'Completed', 'Cancelled']
                          .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) => val == null || val.trim().isEmpty ? 'Campaign description is required' : null,
                decoration: const InputDecoration(
                  labelText: 'Campaign Description *',
                  hintText: 'Provide detailed information about the campaign goals...',
                  prefixIcon: Icon(Icons.description_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Start & End Dates Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: TextEditingController(text: dateFormat.format(_startDate)),
                          decoration: const InputDecoration(
                            labelText: 'Start Date *',
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: TextEditingController(text: dateFormat.format(_endDate)),
                          decoration: const InputDecoration(
                            labelText: 'End Date *',
                            prefixIcon: Icon(Icons.event_available_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Target Amount & Objective
              TextFormField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Amount (Optional ₹)',
                  hintText: 'e.g. 50000',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _objectiveController,
                decoration: const InputDecoration(
                  labelText: 'Campaign Objective (Optional)',
                  hintText: 'e.g. Collect 500 units of blood',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // 7. Organizer Contact Information
              Text('Organizer Contact Information', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _organizerNameController,
                decoration: const InputDecoration(
                  labelText: 'Organizer Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _organizerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _organizerEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 8. Additional Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  hintText: 'Special instructions or event guidelines...',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // 9. Dynamic Form Fields Builder Section (SCRUM-76)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dynamic_form_rounded, color: AppColors.accentBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Dynamic Registration Fields (SCRUM-76)',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: AppColors.accentBlue),
                          onPressed: _addDynamicFieldDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_dynamicFields.isEmpty)
                      const Text(
                        'No custom fields added. Standard registration fields (Name, Phone, City, Age, Gender) will be collected.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      Column(
                        children: _dynamicFields.map((f) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade900 : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${f.label} (${f.type})', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                                      if (f.options.isNotEmpty)
                                        Text('Options: ${f.options.join(", ")}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _dynamicFields.remove(f);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_isSubmitting ? 'Creating Campaign...' : 'Publish Campaign'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
