import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matrimonial_providers.dart';
import '../../api_config.dart';

class MatrimonialBiodataScreen extends ConsumerStatefulWidget {
  const MatrimonialBiodataScreen({super.key});

  @override
  ConsumerState<MatrimonialBiodataScreen> createState() => _MatrimonialBiodataScreenState();
}

class _MatrimonialBiodataScreenState extends ConsumerState<MatrimonialBiodataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Field values
  String _name = '';
  String _gender = 'Male';
  DateTime _dob = DateTime(2000, 1, 1);
  int _heightCm = 165;
  int _weightKg = 60;
  String _bloodGroup = 'B+';
  String _maritalStatus = 'Never Married';
  String _education = '';
  String _occupation = '';
  String _company = '';
  double _annualIncome = 0;
  String _village = '';
  String _city = '';

  // Family Info
  String _fatherName = '';
  String _motherName = '';
  String _grandfather = '';
  String _grandmother = '';
  String _nana = '';
  String _nani = '';
  String _familyOccupation = '';

  // New Fields
  String _workingCountry = 'India';
  String _description = '';
  String _partnerExpectations = '';
  List<String> _partnerExpectationsHobbies = [];
  bool _addSocialLinks = false;
  String _instagramUrl = '';
  String _facebookUrl = '';
  List<String> _additionalPhotos = [];

  // Visibility
  bool _showPhone = true;
  bool _showAddress = true;
  bool _showEmail = false;

  String _profilePhoto = '';
  String _introVideo = '';

  final List<String> _availableHobbies = [
    'Singing',
    'Dancing',
    'Cooking',
    'Traveling',
    'Reading',
    'Sports',
    'Photography',
    'Music',
    'Gardening',
    'Yoga',
    'Painting',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _prefillFromUser();
  }

  void _prefillFromUser() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _name = user.fullName + (user.surname.isNotEmpty ? ' ${user.surname}' : '');
      final genderVal = user.gender.trim().toLowerCase();
      _gender = genderVal == 'female' ? 'Female' : 'Male';
      _dob = user.dateOfBirth.isNotEmpty ? DateTime.parse(user.dateOfBirth) : DateTime(2000, 1, 1);
      final allowedBGs = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      final bgVal = user.bloodGroup.trim().toUpperCase();
      _bloodGroup = allowedBGs.contains(bgVal) ? bgVal : 'B+';

      final msVal = user.maritalStatus.trim().toLowerCase();
      if (msVal == 'single' || msVal == 'never married' || msVal == 'unmarried') {
        _maritalStatus = 'Never Married';
      } else if (msVal == 'divorced') {
        _maritalStatus = 'Divorced';
      } else if (msVal == 'widowed') {
        _maritalStatus = 'Widowed';
      } else {
        _maritalStatus = 'Never Married';
      }

      _education = user.education;
      _occupation = user.occupation;
      _village = user.nativePlace;
      _city = user.city;
      _fatherName = user.fatherName;
      _motherName = user.motherName;
      _profilePhoto = user.profilePhoto;
    }

    final myProfile = ref.read(myMatrimonialProfileProvider).value;
    if (myProfile != null) {
      _gender = myProfile.gender;
      _dob = myProfile.dateOfBirth;
      _heightCm = myProfile.heightCm;
      _weightKg = myProfile.weightKg;
      _bloodGroup = myProfile.bloodGroup;
      _maritalStatus = myProfile.maritalStatus;
      _education = myProfile.education;
      _occupation = myProfile.occupation;
      _company = myProfile.company;
      _annualIncome = myProfile.annualIncome;
      _village = myProfile.village;
      _city = myProfile.city;
      _fatherName = myProfile.family['fatherName'] ?? '';
      _motherName = myProfile.family['motherName'] ?? '';
      _grandfather = myProfile.family['grandfather'] ?? '';
      _grandmother = myProfile.family['grandmother'] ?? '';
      _nana = myProfile.family['nana'] ?? '';
      _nani = myProfile.family['nani'] ?? '';
      _familyOccupation = myProfile.family['familyOccupation'] ?? '';
      _showPhone = myProfile.visibility['showPhone'] ?? true;
      _showAddress = myProfile.visibility['showAddress'] ?? true;
      _showEmail = myProfile.visibility['showEmail'] ?? false;
      _profilePhoto = myProfile.profilePhotoUrl;
      _introVideo = myProfile.introductionVideoUrl;

      // New fields prefill
      _workingCountry = myProfile.workingCountry.isNotEmpty ? myProfile.workingCountry : 'India';
      _description = myProfile.description;
      _partnerExpectations = myProfile.partnerExpectations;
      _partnerExpectationsHobbies = List<String>.from(myProfile.partnerExpectationsHobbies);
      _addSocialLinks = myProfile.socialLinks['showSocialLinks'] ?? false;
      _instagramUrl = myProfile.socialLinks['instagramUrl'] ?? '';
      _facebookUrl = myProfile.socialLinks['facebookUrl'] ?? '';
      _additionalPhotos = List<String>.from(myProfile.additionalPhotos);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() {
        _profilePhoto = img.path;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final vid = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 30));
    if (vid != null) {
      setState(() {
        _introVideo = vid.path;
      });
    }
  }

  Future<void> _pickAdditionalPhoto() async {
    if (_additionalPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload up to 3 additional photos.')),
      );
      return;
    }
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) {
      setState(() {
        _additionalPhotos.add(img.path);
      });
    }
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profilePhoto.isEmpty || _profilePhoto.startsWith('avatar')) {
      return null;
    }
    if (_profilePhoto.startsWith('http')) {
      return NetworkImage(_profilePhoto);
    }
    if (_profilePhoto.startsWith('/uploads')) {
      return NetworkImage('${ApiConfig.baseUrl.replaceAll('/api', '')}$_profilePhoto');
    }
    return FileImage(File(_profilePhoto));
  }

  Future<void> _saveBiodata() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please resolve validation errors first.')),
      );
      return;
    }
    _formKey.currentState!.save();

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22))),
    );

    String? profilePhotoBase64;
    if (_profilePhoto.isNotEmpty && !_profilePhoto.startsWith('/uploads') && !_profilePhoto.startsWith('http') && _profilePhoto != 'avatar_generic') {
      try {
        final bytes = await File(_profilePhoto).readAsBytes();
        profilePhotoBase64 = base64Encode(bytes);
      } catch (e) {
        print('Error encoding profile photo: $e');
      }
    }

    String? introductionVideoBase64;
    if (_introVideo.isNotEmpty && !_introVideo.startsWith('/uploads') && !_introVideo.startsWith('http') && !_introVideo.startsWith('https')) {
      try {
        final bytes = await File(_introVideo).readAsBytes();
        introductionVideoBase64 = base64Encode(bytes);
      } catch (e) {
        print('Error encoding intro video: $e');
      }
    }

    List<String> additionalPhotosBase64 = [];
    for (String path in _additionalPhotos) {
      if (path.isNotEmpty && !path.startsWith('http') && !path.startsWith('/uploads')) {
        try {
          final bytes = await File(path).readAsBytes();
          additionalPhotosBase64.add(base64Encode(bytes));
        } catch (e) {
          print('Error encoding additional photo: $e');
        }
      }
    }

    final payload = {
      'userId': user.id,
      'name': _name,
      'gender': _gender,
      'dob': _dob.toIso8601String(),
      'heightCm': _heightCm,
      'weightKg': _weightKg,
      'bloodGroup': _bloodGroup,
      'maritalStatus': _maritalStatus,
      'education': _education,
      'occupation': _occupation,
      'company': _company,
      'annualIncome': _annualIncome,
      'village': _village,
      'city': _city,
      'familyInformation': {
        'fatherName': _fatherName,
        'motherName': _motherName,
        'grandfather': _grandfather,
        'grandmother': _grandmother,
        'nana': _nana,
        'nani': _nani,
        'familyOccupation': _familyOccupation,
      },
      'lifestyle': {
        'languages': ['Gujarati', 'Hindi', 'English'],
        'hobbies': ['Reading', 'Traveling'],
        'diet': 'Vegetarian',
        'smoking': 'No',
        'drinking': 'No',
        'phone': user.phoneNumber,
      },
      'partnerPreferences': {
        'ageMin': 21,
        'ageMax': 50,
        'heightMin': 120,
        'heightMax': 220,
        'education': '',
        'occupation': '',
        'city': '',
        'village': '',
      },
      'visibilitySettings': {
        'showPhone': _showPhone,
        'showAddress': _showAddress,
        'showEmail': _showEmail,
      },
      'profilePhoto': _profilePhoto.isNotEmpty ? _profilePhoto : 'avatar_generic',
      'introductionVideo': _introVideo.isNotEmpty ? _introVideo : 'https://assets.mixkit.co/videos/preview/mixkit-dramatic-waterfall-in-forest-42289-large.mp4',
      
      // New fields payload
      'workingCountry': _workingCountry,
      'description': _description,
      'partnerExpectations': _partnerExpectations,
      'partnerExpectationsHobbies': _partnerExpectationsHobbies,
      'socialLinks': {
        'showSocialLinks': _addSocialLinks,
        'instagramUrl': _instagramUrl,
        'facebookUrl': _facebookUrl,
      },
      'additionalPhotos': _additionalPhotos.where((p) => p.startsWith('http') || p.startsWith('/uploads')).toList(),
    };

    if (profilePhotoBase64 != null) {
      payload['profilePhotoBase64'] = profilePhotoBase64;
    }
    if (introductionVideoBase64 != null) {
      payload['introductionVideoBase64'] = introductionVideoBase64;
    }
    if (additionalPhotosBase64.isNotEmpty) {
      payload['additionalPhotosBase64'] = additionalPhotosBase64;
    }

    final service = ref.read(matrimonialServiceProvider);
    final success = await service.saveProfile(payload);

    if (context.mounted) {
      Navigator.pop(context); // Dismiss spinner
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matrimonial biodata published successfully!')),
      );
      ref.invalidate(myMatrimonialProfileProvider);
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: primaryOrange,
        title: Text(
          'Manage My Biodata',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'Work / Edu'),
            Tab(text: 'Family'),
            Tab(text: 'Expectations & Social'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPersonalTab(primaryOrange, primaryBlue),
            _buildWorkEduTab(),
            _buildFamilyTab(),
            _buildExpectationsSocialTab(primaryOrange, primaryBlue),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () {
                if (_tabController.index > 0) {
                  _tabController.animateTo(_tabController.index - 1);
                }
              },
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_tabController.index < 3) {
                  _tabController.animateTo(_tabController.index + 1);
                } else {
                  _saveBiodata();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.white),
              child: Text(_tabController.index == 3 ? 'Publish Biodata' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab(Color orange, Color blue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _getProfileImageProvider(),
                  child: _profilePhoto.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: orange,
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: _name,
            decoration: const InputDecoration(labelText: 'Full Name *'),
            validator: (v) => v!.isEmpty ? 'Name is required' : null,
            onSaved: (v) => _name = v ?? '',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: ['Male', 'Female']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (val) => setState(() => _gender = val ?? 'Male'),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date of Birth *'),
            subtitle: Text('${_dob.day}/${_dob.month}/${_dob.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dob,
                firstDate: DateTime(1960),
                lastDate: DateTime.now().subtract(const Duration(days: 6570)),
              );
              if (picked != null) {
                setState(() => _dob = picked);
              }
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _heightCm.toString(),
                  decoration: const InputDecoration(labelText: 'Height (cm) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid height' : null,
                  onSaved: (v) => _heightCm = int.parse(v!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  initialValue: _weightKg.toString(),
                  decoration: const InputDecoration(labelText: 'Weight (kg) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid weight' : null,
                  onSaved: (v) => _weightKg = int.parse(v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _bloodGroup,
            decoration: const InputDecoration(labelText: 'Blood Group'),
            items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                .toList(),
            onChanged: (val) => setState(() => _bloodGroup = val ?? 'B+'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _maritalStatus,
            decoration: const InputDecoration(labelText: 'Marital Status'),
            items: ['Never Married', 'Divorced', 'Widowed']
                .map((ms) => DropdownMenuItem(value: ms, child: Text(ms)))
                .toList(),
            onChanged: (val) => setState(() => _maritalStatus = val ?? 'Never Married'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _village,
            decoration: const InputDecoration(labelText: 'Native Village *'),
            validator: (v) => v!.isEmpty ? 'Native village is required' : null,
            onSaved: (v) => _village = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _city,
            decoration: const InputDecoration(labelText: 'Current City *'),
            validator: (v) => v!.isEmpty ? 'Current city is required' : null,
            onSaved: (v) => _city = v ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkEduTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            initialValue: _education,
            decoration: const InputDecoration(labelText: 'Highest Qualification *', hintText: 'e.g. B.Tech / MBA'),
            validator: (v) => v!.isEmpty ? 'Education is required' : null,
            onSaved: (v) => _education = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _occupation,
            decoration: const InputDecoration(labelText: 'Profession *', hintText: 'e.g. Software Engineer'),
            validator: (v) => v!.isEmpty ? 'Profession is required' : null,
            onSaved: (v) => _occupation = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _company,
            decoration: const InputDecoration(labelText: 'Company Name', hintText: 'e.g. Google'),
            onSaved: (v) => _company = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _annualIncome.toString(),
            decoration: const InputDecoration(labelText: 'Annual Income (INR)', hintText: 'e.g. 800000'),
            keyboardType: TextInputType.number,
            onSaved: (v) => _annualIncome = double.tryParse(v ?? '') ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            initialValue: _fatherName,
            decoration: const InputDecoration(labelText: 'Father\'s Name'),
            onSaved: (v) => _fatherName = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _motherName,
            decoration: const InputDecoration(labelText: 'Mother\'s Name'),
            onSaved: (v) => _motherName = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _grandfather,
            decoration: const InputDecoration(labelText: 'Paternal Grandfather'),
            onSaved: (v) => _grandfather = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _grandmother,
            decoration: const InputDecoration(labelText: 'Paternal Grandmother'),
            onSaved: (v) => _grandmother = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _nana,
            decoration: const InputDecoration(labelText: 'Maternal Grandfather (Nana)'),
            onSaved: (v) => _nana = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _nani,
            decoration: const InputDecoration(labelText: 'Maternal Grandmother (Nani)'),
            onSaved: (v) => _nani = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _familyOccupation,
            decoration: const InputDecoration(labelText: 'Family Occupation / Business'),
            onSaved: (v) => _familyOccupation = v ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildExpectationsSocialTab(Color orange, Color blue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: _workingCountry,
            decoration: const InputDecoration(
              labelText: 'Current Working Country',
              hintText: 'e.g. India, USA, Canada',
            ),
            onSaved: (v) => _workingCountry = v ?? 'India',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'About Me (Description) *',
              hintText: 'Describe your personality, values, hobbies...',
            ),
            validator: (v) => v!.isEmpty ? 'Description is required' : null,
            onSaved: (v) => _description = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _partnerExpectations,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Expectations from Partner *',
              hintText: 'Describe what you expect from your life partner...',
            ),
            validator: (v) => v!.isEmpty ? 'Expectations is required' : null,
            onSaved: (v) => _partnerExpectations = v ?? '',
          ),
          const SizedBox(height: 20),
          Text(
            'Partner Preferred Hobbies / Activities',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: blue),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableHobbies.map((hob) {
              final isSelected = _partnerExpectationsHobbies.contains(hob);
              return ChoiceChip(
                label: Text(hob),
                selected: isSelected,
                selectedColor: orange.withValues(alpha: 0.2),
                checkmarkColor: orange,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _partnerExpectationsHobbies.add(hob);
                    } else {
                      _partnerExpectationsHobbies.remove(hob);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            title: const Text('Add Instagram / Facebook Handles'),
            value: _addSocialLinks,
            onChanged: (val) => setState(() => _addSocialLinks = val ?? false),
          ),
          if (_addSocialLinks) ...[
            TextFormField(
              initialValue: _instagramUrl,
              decoration: const InputDecoration(labelText: 'Instagram Profile URL'),
              onSaved: (v) => _instagramUrl = v ?? '',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _facebookUrl,
              decoration: const InputDecoration(labelText: 'Facebook Profile URL'),
              onSaved: (v) => _facebookUrl = v ?? '',
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Upload Additional Photos (Max 3)',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: blue),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _additionalPhotos.length + (_additionalPhotos.length < 3 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _additionalPhotos.length) {
                  return GestureDetector(
                    onTap: _pickAdditionalPhoto,
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.dashed),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_a_photo_rounded, color: Colors.grey),
                    ),
                  );
                }

                final path = _additionalPhotos[index];
                final isNetwork = path.startsWith('http') || path.startsWith('/uploads');

                return Stack(
                  children: [
                    Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: isNetwork
                              ? NetworkImage(path.startsWith('/uploads') ? '${ApiConfig.baseUrl.replaceAll('/api', '')}$path' : path)
                              : FileImage(File(path)) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _additionalPhotos.removeAt(index);
                          });
                        },
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.close, size: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Privacy Settings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: blue),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Show Mobile Number publicly'),
            value: _showPhone,
            onChanged: (val) => setState(() => _showPhone = val),
          ),
          SwitchListTile(
            title: const Text('Show Full Address publicly'),
            value: _showAddress,
            onChanged: (val) => setState(() => _showAddress = val),
          ),
          SwitchListTile(
            title: const Text('Show Email Address publicly'),
            value: _showEmail,
            onChanged: (val) => setState(() => _showEmail = val),
          ),
        ],
      ),
    );
  }
}
