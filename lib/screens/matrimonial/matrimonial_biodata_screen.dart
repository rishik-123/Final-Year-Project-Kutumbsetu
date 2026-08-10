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

  // Lifestyle
  String _diet = 'Vegetarian';
  String _smoking = 'No';
  String _drinking = 'No';
  final List<String> _languages = [];
  final List<String> _hobbies = [];

  // Preferences
  int _prefAgeMin = 18;
  int _prefAgeMax = 60;
  int _prefHeightMin = 120;
  int _prefHeightMax = 220;
  String _prefEducation = '';
  String _prefOccupation = '';
  String _prefCity = '';
  String _prefVillage = '';

  // Visibility
  bool _showPhone = true;
  bool _showAddress = true;
  bool _showEmail = false;

  String _profilePhoto = '';
  String _introVideo = '';

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
      
      // Normalize Gender to ['Male', 'Female']
      final genderVal = user.gender.trim().toLowerCase();
      if (genderVal == 'female') {
        _gender = 'Female';
      } else {
        _gender = 'Male';
      }

      _dob = user.dateOfBirth.isNotEmpty ? DateTime.parse(user.dateOfBirth) : DateTime(2000, 1, 1);

      // Normalize Blood Group to ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
      final allowedBGs = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      final bgVal = user.bloodGroup.trim().toUpperCase();
      if (allowedBGs.contains(bgVal)) {
        _bloodGroup = bgVal;
      } else {
        _bloodGroup = 'B+';
      }

      // Normalize Marital Status to ['Never Married', 'Divorced', 'Widowed']
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      // Simulate photo upload by setting path
      setState(() {
        _profilePhoto = img.path;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final vid = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 30));
    if (vid != null) {
      // Simulate video intro path
      setState(() {
        _introVideo = vid.path;
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

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
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
    if (_introVideo.isNotEmpty && !_introVideo.startsWith('/uploads') && !_introVideo.startsWith('http') && !_introVideo.startsWith('https') && !_introVideo.contains('mixkit.co')) {
      try {
        final bytes = await File(_introVideo).readAsBytes();
        introductionVideoBase64 = base64Encode(bytes);
      } catch (e) {
        print('Error encoding intro video: $e');
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
        'languages': _languages.isEmpty ? ['Gujarati', 'Hindi', 'English'] : _languages,
        'hobbies': _hobbies.isEmpty ? ['Reading', 'Traveling'] : _hobbies,
        'diet': _diet,
        'smoking': _smoking,
        'drinking': _drinking,
        'phone': user.phoneNumber, // Include real phone for request validation
      },
      'partnerPreferences': {
        'ageMin': _prefAgeMin,
        'ageMax': _prefAgeMax,
        'heightMin': _prefHeightMin,
        'heightMax': _prefHeightMax,
        'education': _prefEducation,
        'occupation': _prefOccupation,
        'city': _prefCity,
        'village': _prefVillage,
      },
      'visibilitySettings': {
        'showPhone': _showPhone,
        'showAddress': _showAddress,
        'showEmail': _showEmail,
      },
      'profilePhoto': _profilePhoto.isNotEmpty ? _profilePhoto : 'avatar_generic',
      'introductionVideo': _introVideo.isNotEmpty ? _introVideo : 'https://assets.mixkit.co/videos/preview/mixkit-dramatic-waterfall-in-forest-42289-large.mp4',
    };

    if (profilePhotoBase64 != null) {
      payload['profilePhotoBase64'] = profilePhotoBase64;
    }
    if (introductionVideoBase64 != null) {
      payload['introductionVideoBase64'] = introductionVideoBase64;
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
            Tab(text: 'Visibility'),
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
            _buildVisibilityTab(primaryOrange, primaryBlue),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                _tabController.index == 3 ? 'Publish Biodata' : 'Next',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
        children: [
          // Avatar upload row
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: orange.withValues(alpha: 0.1),
              backgroundImage: _getProfileImageProvider(),
              child: _profilePhoto.isEmpty || _profilePhoto.startsWith('avatar')
                  ? Icon(Icons.add_a_photo_outlined, size: 36, color: orange)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text('Upload Profile Photo', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
          
          // Video upload button
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.video_call_rounded),
            label: Text(
              _introVideo.isEmpty || _introVideo.startsWith('http') || _introVideo.contains('mixkit.co')
                  ? 'Select Introduction Video'
                  : 'Video Selected (Tap to Change)',
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_introVideo.isNotEmpty && !_introVideo.startsWith('http') && !_introVideo.contains('mixkit.co')) ...[
            const SizedBox(height: 4),
            Text(
              "Selected local path: ${_introVideo.split('/').last.split('\\').last}",
              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 18),

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
            items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setState(() => _gender = v ?? 'Male'),
          ),
          const SizedBox(height: 14),

          // Height & Weight
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _heightCm.toString(),
                  decoration: const InputDecoration(labelText: 'Height (cm) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => _heightCm = int.tryParse(v ?? '') ?? 165,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  initialValue: _weightKg.toString(),
                  decoration: const InputDecoration(labelText: 'Weight (kg) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => _weightKg = int.tryParse(v ?? '') ?? 60,
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
            onChanged: (v) => setState(() => _bloodGroup = v ?? 'B+'),
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _maritalStatus,
            decoration: const InputDecoration(labelText: 'Marital Status'),
            items: ['Never Married', 'Divorced', 'Widowed']
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _maritalStatus = v ?? 'Never Married'),
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
            decoration: const InputDecoration(labelText: 'Highest Education *', hintText: 'e.g. B.E. Computer Engineering'),
            validator: (v) => v!.isEmpty ? 'Education is required' : null,
            onSaved: (v) => _education = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _occupation,
            decoration: const InputDecoration(labelText: 'Occupation *', hintText: 'e.g. Software Architect'),
            validator: (v) => v!.isEmpty ? 'Occupation is required' : null,
            onSaved: (v) => _occupation = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _company,
            decoration: const InputDecoration(labelText: 'Company / Employer Name', hintText: 'e.g. Samaj Tech Solutions'),
            onSaved: (v) => _company = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _annualIncome.toString(),
            decoration: const InputDecoration(labelText: 'Annual Income (INR)', hintText: 'e.g. 600000'),
            keyboardType: TextInputType.number,
            onSaved: (v) => _annualIncome = double.tryParse(v ?? '') ?? 0,
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _village,
            decoration: const InputDecoration(labelText: 'Native Village *', hintText: 'e.g. Karamsad'),
            validator: (v) => v!.isEmpty ? 'Native village is required' : null,
            onSaved: (v) => _village = v ?? '',
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _city,
            decoration: const InputDecoration(labelText: 'Current City *', hintText: 'e.g. Vadodara'),
            validator: (v) => v!.isEmpty ? 'Current city is required' : null,
            onSaved: (v) => _city = v ?? '',
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



  Widget _buildVisibilityTab(Color orange, Color blue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy & Visibility Settings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: blue),
          ),
          const SizedBox(height: 6),
          Text(
            'Control who within the community can see your direct contact details. If disabled, they will remain private.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text('Show Mobile Number publicly'),
            subtitle: const Text('If off, phone is hidden publicly'),
            value: _showPhone,
            activeColor: orange,
            onChanged: (val) => setState(() => _showPhone = val),
          ),
          SwitchListTile(
            title: const Text('Show Full Address publicly'),
            value: _showAddress,
            activeColor: orange,
            onChanged: (val) => setState(() => _showAddress = val),
          ),
          SwitchListTile(
            title: const Text('Show Email Address publicly'),
            value: _showEmail,
            activeColor: orange,
            onChanged: (val) => setState(() => _showEmail = val),
          ),
        ],
      ),
    );
  }
}
