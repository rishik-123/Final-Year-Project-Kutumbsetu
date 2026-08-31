import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFields();
    });
  }

  void _showCreatePostBottomSheet(BuildContext context) {
    final picker = ImagePicker();
    XFile? pickedImage;
    final contentController = TextEditingController();
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Community Post',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFD35400)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "What's on your mind? Share announcements, achievements...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (pickedImage != null)
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<List<int>>(
                            future: pickedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data as dynamic,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              }
                              return const Center(child: CircularProgressIndicator());
                            },
                          ),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (img != null) {
                            setSheetState(() {
                              pickedImage = img;
                            });
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: const Text('Pick Image from Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: uploading
                          ? null
                          : () async {
                              final text = contentController.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter some text content.')),
                                );
                                return;
                              }
                              setSheetState(() => uploading = true);
                              try {
                                final user = ref.read(currentUserProvider);
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('User profile not loaded. Please log in again.')),
                                  );
                                  return;
                                }

                                String? base64Image;
                                if (pickedImage != null) {
                                  final bytes = await pickedImage!.readAsBytes();
                                  base64Image = base64Encode(bytes);
                                }

                                final response = await http.post(
                                  Uri.parse('${ApiConfig.baseUrl}/community/posts'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'userId': user.id,
                                    'content': text,
                                    'mediaBase64': base64Image,
                                  }),
                                );

                                if (response.statusCode == 201) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Post published successfully!')),
                                  );
                                } else {
                                  String errMsg = 'Failed to publish post.';
                                  try {
                                    final body = jsonDecode(response.body);
                                    if (body != null && body['message'] != null) {
                                      errMsg = body['message'].toString();
                                    }
                                  } catch (_) {}
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errMsg)),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error uploading post: $e')),
                                );
                              } finally {
                                setSheetState(() => uploading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD35400),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: uploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Publish Post', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateReelBottomSheet(BuildContext context) {
    final picker = ImagePicker();
    XFile? pickedVideo;
    final captionController = TextEditingController();
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Community Reel',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0288D1)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: captionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Add a caption for your reel...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (pickedVideo != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0288D1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.video_library_rounded, color: Color(0xFF0288D1), size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Video Selected',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0288D1)),
                                  ),
                                  Text(
                                    pickedVideo!.name,
                                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final vid = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 30));
                          if (vid != null) {
                            setSheetState(() {
                              pickedVideo = vid;
                            });
                          }
                        },
                        icon: const Icon(Icons.video_call_rounded),
                        label: const Text('Pick Reel Video from Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: uploading
                          ? null
                          : () async {
                              final caption = captionController.text.trim();
                              if (caption.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a caption.')),
                                );
                                return;
                              }
                              if (pickedVideo == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a video.')),
                                );
                                return;
                              }
                              setSheetState(() => uploading = true);
                              try {
                                final user = ref.read(currentUserProvider);
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('User profile not loaded. Please log in again.')),
                                  );
                                  return;
                                }

                                final bytes = await pickedVideo!.readAsBytes();
                                final base64Video = base64Encode(bytes);

                                final response = await http.post(
                                  Uri.parse('${ApiConfig.baseUrl}/community/reels'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'userId': user.id,
                                    'caption': caption,
                                    'videoBase64': base64Video,
                                  }),
                                );

                                if (response.statusCode == 201) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reel published successfully!')),
                                  );
                                } else {
                                  String errMsg = 'Failed to upload reel.';
                                  try {
                                    final body = jsonDecode(response.body);
                                    if (body != null && body['message'] != null) {
                                      errMsg = body['message'].toString();
                                    }
                                  } catch (_) {}
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errMsg)),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error uploading reel: $e')),
                                );
                              } finally {
                                setSheetState(() => uploading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: uploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Upload Reel', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _prefillFields() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      setState(() {
        _phoneController.text = user.phoneNumber;
        _dobController.text = user.dateOfBirth;
        _gender = ['Male', 'Female', 'Other'].contains(user.gender) ? user.gender : 'Male';
        _profilePhoto = user.profilePhoto.isNotEmpty ? user.profilePhoto : 'avatar_male_1';
        
        final bg = user.bloodGroup.trim().toUpperCase();
        _bloodGroup = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(bg) ? bg : 'B+';
        _willingToDonateBlood = user.willingToDonateBlood;
        
        _villageController.text = user.nativePlace;
        _cityController.text = user.city;
        _stateController.text = user.state;
        _addressController.text = user.address;
        _qualificationController.text = user.education;
        _professionController.text = user.occupation;
        _memberId = user.memberId;
        _maidenNameController.text = user.maidenName;
        _fatherId = user.fatherId;
        _fatherNameController.text = user.fatherName;
        _motherId = user.motherId;
        _motherNameController.text = user.motherName;
        _spouseId = user.spouseId;
        _spouseNameController.text = user.spouseName;
        _paternalGrandfatherId = user.paternalGrandfatherId;
        _grandfatherController.text = user.grandfather;
        _paternalGrandmotherId = user.paternalGrandmotherId;
        _grandmotherController.text = user.grandmother;
        _maternalGrandfatherId = user.maternalGrandfatherId;
        _nanaController.text = user.nana;
        _maternalGrandmotherId = user.maternalGrandmotherId;
        _naniController.text = user.nani;
        _relationshipToHead = ['Self', 'Father', 'Mother', 'Wife', 'Son', 'Daughter', 'Brother', 'Sister', 'Grandfather', 'Grandmother', 'Other']
            .contains(user.relationshipToHead) ? user.relationshipToHead : 'Self';
        _familyHeadPhoneController.text = user.familyHeadPhone;
        _familyIdController.text = user.familyId;
      });
    }
  }

  // Personal
  String _memberId = '';
  String _gender = 'Male';
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  String _profilePhoto = 'avatar_male_1';
  String _bloodGroup = 'B+';
  bool _willingToDonateBlood = false;

  // Address
  final _villageController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _addressController = TextEditingController();

  // Edu & Occ
  final _qualificationController = TextEditingController();
  final _collegeController = TextEditingController();
  final _professionController = TextEditingController();

  // Family & ID Links
  final _maidenNameController = TextEditingController();
  String _fatherId = '';
  final _fatherNameController = TextEditingController();
  String _motherId = '';
  final _motherNameController = TextEditingController();
  String _paternalGrandfatherId = '';
  final _grandfatherController = TextEditingController();
  String _paternalGrandmotherId = '';
  final _grandmotherController = TextEditingController();
  String _maternalGrandfatherId = '';
  final _nanaController = TextEditingController();
  String _maternalGrandmotherId = '';
  final _naniController = TextEditingController();
  String _spouseId = '';
  final _spouseNameController = TextEditingController();

  // Additional
  final _bioController = TextEditingController();
  final _familyIdController = TextEditingController();
  String _relationshipToHead = 'Self';
  final _familyHeadPhoneController = TextEditingController();
  bool _isDeceased = false;

  @override
  void dispose() {
    _dobController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _qualificationController.dispose();
    _collegeController.dispose();
    _professionController.dispose();
    _maidenNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _grandfatherController.dispose();
    _grandmotherController.dispose();
    _nanaController.dispose();
    _naniController.dispose();
    _bioController.dispose();
    _familyIdController.dispose();
    _familyHeadPhoneController.dispose();
    _spouseNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD35400),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session expired. Please log in again.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? profilePhotoBase64;
    if (_profilePhoto.isNotEmpty && !_profilePhoto.startsWith('/uploads') && !_profilePhoto.startsWith('http') && !_profilePhoto.startsWith('avatar')) {
      try {
        final bytes = await File(_profilePhoto).readAsBytes();
        profilePhotoBase64 = base64Encode(bytes);
      } catch (e) {
        print('Error encoding profile photo: $e');
      }
    }

    final payload = {
      'userId': user.id,
      'memberId': _memberId,
      'maidenName': _maidenNameController.text.trim(),
      'gender': _gender,
      'dateOfBirth': _dobController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'profilePhoto': _profilePhoto,
      'profilePhotoBase64': profilePhotoBase64,
      'bloodGroup': _bloodGroup,
      'willingToDonateBlood': _willingToDonateBlood,
      'village': _villageController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'address': _addressController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'college': _collegeController.text.trim(),
      'profession': _professionController.text.trim(),
      'fatherId': _fatherId,
      'fatherName': _fatherNameController.text.trim(),
      'motherId': _motherId,
      'motherName': _motherNameController.text.trim(),
      'paternalGrandfatherId': _paternalGrandfatherId,
      'grandfather': _grandfatherController.text.trim(),
      'paternalGrandmotherId': _paternalGrandmotherId,
      'grandmother': _grandmotherController.text.trim(),
      'maternalGrandfatherId': _maternalGrandfatherId,
      'nana': _nanaController.text.trim(),
      'maternalGrandmotherId': _maternalGrandmotherId,
      'nani': _naniController.text.trim(),
      'spouseId': _spouseId,
      'spouseName': _spouseNameController.text.trim(),
      'bio': _bioController.text.trim(),
      'familyId': _familyIdController.text.trim().toUpperCase(),
      'relationshipToHead': _relationshipToHead,
      'familyHeadPhone': _familyHeadPhoneController.text.trim(),
      'isDeceased': _isDeceased,
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Fetch updated profile
          final updatedUser = await AuthService.fetchUserProfile(user.email);
          if (updatedUser != null) {
            ref.read(currentUserProvider.notifier).state = updatedUser;
          }
          if (mounted) {
            final isCompleted = user.phoneNumber.isNotEmpty && user.city.isNotEmpty;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isCompleted ? 'Profile updated successfully!' : 'Profile completed successfully! Welcome to KutumbSetu.')),
            );
            context.go('/home');
          }
        } else {
          _showError(data['message'] ?? 'Failed to complete profile.');
        }
      } else {
        _showError('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Failed to connect to server: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildSearchableMemberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String currentId,
    required ValueChanged<Map<String, dynamic>?> onSelected,
    String? gender,
  }) {
    return Autocomplete<Map<String, dynamic>>(
      initialValue: TextEditingValue(text: controller.text),
      displayStringForOption: (option) => option['fullName'] as String? ?? '',
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.length < 2) {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        try {
          final uri = Uri.parse('${ApiConfig.baseUrl}/members/search?q=${Uri.encodeComponent(query)}${gender != null ? '&gender=$gender' : ''}');
          final res = await http.get(uri);
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data['success'] == true && data['members'] is List) {
              return (data['members'] as List).cast<Map<String, dynamic>>();
            }
          }
        } catch (_) {}
        return const Iterable<Map<String, dynamic>>.empty();
      },
      onSelected: (selection) {
        controller.text = selection['fullName'] ?? '';
        onSelected(selection);
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        if (controller.text.isNotEmpty && textEditingController.text != controller.text) {
          textEditingController.text = controller.text;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              onChanged: (val) {
                controller.text = val;
                onSelected(null);
              },
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                suffixIcon: currentId.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text(
                            currentId,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: currentId.isNotEmpty
                    ? 'Linked to Member ID: $currentId'
                    : 'Search existing member by name or type new',
                helperStyle: TextStyle(
                  fontSize: 11,
                  color: currentId.isNotEmpty ? const Color(0xFF2E7D32) : Colors.grey,
                  fontWeight: currentId.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final name = option['fullName'] ?? 'Unnamed';
                  final memberId = option['memberId'] ?? '';
                  final maiden = option['maidenName'] ?? '';
                  final city = option['city'] ?? option['village'] ?? '';

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFD35400).withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD35400)),
                      ),
                    ),
                    title: Text(
                      maiden.isNotEmpty ? '$name (Maiden: $maiden)' : name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      'ID: $memberId ${city.isNotEmpty ? "• $city" : ""}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    onTap: () => onSelectedOption(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD35400), size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B4F72),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final primaryOrange = const Color(0xFFD35400);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 0,
        title: Text(
          ref.watch(currentUserProvider)?.phoneNumber.isNotEmpty == true && ref.watch(currentUserProvider)?.city.isNotEmpty == true
              ? 'Edit Profile'
              : 'Complete Your Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD35400)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      ref.watch(currentUserProvider)?.phoneNumber.isNotEmpty == true && ref.watch(currentUserProvider)?.city.isNotEmpty == true
                          ? 'Update your profile details below.'
                          : 'Let\'s build your profile to unlock all community features!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // If user is admin, show post upload shortcut
                    if (ref.watch(currentUserProvider)?.role == 'admin') ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showCreatePostBottomSheet(context),
                            icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                            label: Text('Add Post', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD35400),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                    ],

                    // SECTION 1: Personal Details
                    _buildSectionHeader('Personal Details', Icons.person_outline_rounded),
                    
                    // Profile Photo Picker Row
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (img != null) {
                            setState(() {
                              _profilePhoto = img.path;
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                          backgroundImage: (() {
                            if (_profilePhoto.isEmpty || _profilePhoto.startsWith('avatar_m') || _profilePhoto.startsWith('avatar_f')) {
                              return null;
                            }
                            if (_profilePhoto.startsWith('http')) {
                              return NetworkImage(_profilePhoto);
                            }
                            if (_profilePhoto.startsWith('/uploads')) {
                              return NetworkImage('${ApiConfig.baseUrl.replaceAll('/api', '')}$_profilePhoto');
                            }
                            return FileImage(File(_profilePhoto));
                          })() as ImageProvider<Object>?,
                          child: (_profilePhoto.isEmpty || _profilePhoto.startsWith('avatar_m') || _profilePhoto.startsWith('avatar_f'))
                              ? const Icon(Icons.add_a_photo_outlined, size: 28, color: Colors.orange)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Upload Profile Photo',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_iphone_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender Selection
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.transgender_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Male', 'Female', 'Other']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _gender = val;
                            // automatically match profilePhoto gender prefix
                            _profilePhoto = val == 'Female' ? 'avatar_female_1' : 'avatar_male_1';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth (YYYY-MM-DD)',
                        prefixIcon: const Icon(Icons.calendar_today_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.date_range_rounded),
                          onPressed: _selectDate,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Date of Birth is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Blood Group
                    DropdownButtonFormField<String>(
                      value: _bloodGroup,
                      decoration: InputDecoration(
                        labelText: 'Blood Group',
                        prefixIcon: const Icon(Icons.bloodtype_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _bloodGroup = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Willing to donate blood for campaigns'),
                      subtitle: const Text('Show blood group in directory for blood donation campaigns'),
                      value: _willingToDonateBlood,
                      activeColor: const Color(0xFFD35400),
                      onChanged: (val) {
                        setState(() {
                          _willingToDonateBlood = val ?? false;
                        });
                      },
                    ),

                    // SECTION 2: Address
                    _buildSectionHeader('Residence Address', Icons.home_work_outlined),
                    TextFormField(
                      controller: _villageController,
                      decoration: InputDecoration(
                        labelText: 'Native Village',
                        prefixIcon: const Icon(Icons.villa_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        prefixIcon: const Icon(Icons.map_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Full Address',
                        prefixIcon: const Icon(Icons.home_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    // SECTION 3: Education & Occupation
                    _buildSectionHeader('Education & Occupation', Icons.school_outlined),
                    TextFormField(
                      controller: _qualificationController,
                      decoration: InputDecoration(
                        labelText: 'Qualification (e.g. B.Tech)',
                        prefixIcon: const Icon(Icons.history_edu_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _collegeController,
                      decoration: InputDecoration(
                        labelText: 'College / University',
                        prefixIcon: const Icon(Icons.account_balance_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _professionController,
                      decoration: InputDecoration(
                        labelText: 'Profession (e.g. Tailor, Doctor)',
                        prefixIcon: const Icon(Icons.work_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    // SECTION 4: Family Details with Autocomplete & Member ID Matching
                    _buildSectionHeader('Family Members & Relations', Icons.family_restroom_outlined),
                    _buildSearchableMemberField(
                      controller: _fatherNameController,
                      label: 'Father\'s Name',
                      icon: Icons.person,
                      currentId: _fatherId,
                      gender: 'Male',
                      onSelected: (item) {
                        setState(() {
                          _fatherId = item != null ? (item['memberId'] ?? '') : '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSearchableMemberField(
                      controller: _motherNameController,
                      label: 'Mother\'s Name',
                      icon: Icons.person_2,
                      currentId: _motherId,
                      gender: 'Female',
                      onSelected: (item) {
                        setState(() {
                          _motherId = item != null ? (item['memberId'] ?? '') : '';
                        });
                      },
                    ),
                    if (_gender == 'Female') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maidenNameController,
                        decoration: InputDecoration(
                          labelText: 'Maiden / Birth Surname (Before Marriage)',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          helperText: 'Used to link family tree with your parents and native family',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildSearchableMemberField(
                      controller: _grandfatherController,
                      label: 'Paternal Grandfather\'s Name',
                      icon: Icons.elderly_rounded,
                      currentId: _paternalGrandfatherId,
                      gender: 'Male',
                      onSelected: (item) {
                        setState(() {
                          _paternalGrandfatherId = item != null ? (item['memberId'] ?? '') : '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSearchableMemberField(
                      controller: _grandmotherController,
                      label: 'Paternal Grandmother\'s Name',
                      icon: Icons.elderly_woman_rounded,
                      currentId: _paternalGrandmotherId,
                      gender: 'Female',
                      onSelected: (item) {
                        setState(() {
                          _paternalGrandmotherId = item != null ? (item['memberId'] ?? '') : '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSearchableMemberField(
                      controller: _nanaController,
                      label: 'Nana\'s Name (Maternal Grandfather)',
                      icon: Icons.elderly_rounded,
                      currentId: _maternalGrandfatherId,
                      gender: 'Male',
                      onSelected: (item) {
                        setState(() {
                          _maternalGrandfatherId = item != null ? (item['memberId'] ?? '') : '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSearchableMemberField(
                      controller: _naniController,
                      label: 'Nani\'s Name (Maternal Grandmother)',
                      icon: Icons.elderly_woman_rounded,
                      currentId: _maternalGrandmotherId,
                      gender: 'Female',
                      onSelected: (item) {
                        setState(() {
                          _maternalGrandmotherId = item != null ? (item['memberId'] ?? '') : '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSearchableMemberField(
                      controller: _spouseNameController,
                      label: 'Spouse\'s Name',
                      icon: Icons.favorite_outline_rounded,
                      currentId: _spouseId,
                      gender: _gender == 'Male' ? 'Female' : 'Male',
                      onSelected: (item) {
                        setState(() {
                          _spouseId = item != null ? (item['memberId'] ?? '') : '';
                        });
                      },
                    ),

                    // SECTION 5: Family Node Links
                    _buildSectionHeader('Family Tree Association', Icons.account_tree_outlined),
                    TextFormField(
                      controller: _familyIdController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Family ID',
                        hintText: 'Auto-generated on save',
                        prefixIcon: const Icon(Icons.lan_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        helperText: 'Assigned automatically based on your name when saved.',
                        helperStyle: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _relationshipToHead,
                      decoration: InputDecoration(
                        labelText: 'Relationship to Head of Family',
                        prefixIcon: const Icon(Icons.supervisor_account_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Self', 'Father', 'Mother', 'Wife', 'Son', 'Daughter', 'Brother', 'Sister', 'Grandfather', 'Grandmother', 'Other']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _relationshipToHead = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _familyHeadPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Family Head\'s Phone Number',
                        prefixIcon: const Icon(Icons.contact_phone_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        'Mark Deceased (isDeceased)',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Add deceased indicator ⚫ to family tree node'),
                      value: _isDeceased,
                      activeColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          _isDeceased = val;
                        });
                      },
                    ),

                    // SECTION 6: Biography
                    _buildSectionHeader('Brief Bio', Icons.description_outlined),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Write a few words about yourself...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      child: Text(
                        ref.watch(currentUserProvider)?.phoneNumber.isNotEmpty == true && ref.watch(currentUserProvider)?.city.isNotEmpty == true
                            ? 'Save Changes'
                            : 'Save & Complete Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
