import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matrimonial_providers.dart';
import '../../models/matrimonial_profile_model.dart';

class MatrimonialProfileListScreen extends ConsumerStatefulWidget {
  final bool showShortlistedOnly;
  final bool showRecommendationsOnly;

  const MatrimonialProfileListScreen({
    super.key,
    this.showShortlistedOnly = false,
    this.showRecommendationsOnly = false,
  });

  @override
  ConsumerState<MatrimonialProfileListScreen> createState() => _MatrimonialProfileListScreenState();
}

class _MatrimonialProfileListScreenState extends ConsumerState<MatrimonialProfileListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MatrimonialProfileModel> _profiles = [];
  bool _isLoading = true;

  // Filter values
  RangeValues _ageRange = const RangeValues(21, 50);
  RangeValues _heightRange = const RangeValues(120, 220);
  RangeValues _weightRange = const RangeValues(40, 120);
  RangeValues _incomeRange = const RangeValues(0, 50); // in lakhs
  String _selectedMaritalStatus = 'Any';
  String _filterCity = '';
  String _filterVillage = '';
  String _filterEducation = '';
  String _filterOccupation = '';
  String _filterWorkLocation = '';

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider);
    final service = ref.read(matrimonialServiceProvider);

    if (widget.showShortlistedOnly) {
      if (user != null) {
        final res = await service.fetchShortlisted(user.id);
        setState(() {
          _profiles = res;
          _isLoading = false;
        });
      }
      return;
    }

    // Default filters
    final oppositeGender = (user?.gender == 'Male') ? 'Female' : 'Male';
    final res = await service.fetchProfiles(
      search: _searchController.text,
      gender: oppositeGender,
      requesterId: user?.id,
      maritalStatus: _selectedMaritalStatus == 'Any' ? null : _selectedMaritalStatus,
      city: _filterCity.isEmpty ? null : _filterCity,
      village: _filterVillage.isEmpty ? null : _filterVillage,
      education: _filterEducation.isEmpty ? null : _filterEducation,
      occupation: _filterOccupation.isEmpty ? null : _filterOccupation,
      ageMin: _ageRange.start.toInt(),
      ageMax: _ageRange.end.toInt(),
      heightMin: _heightRange.start.toInt(),
      heightMax: _heightRange.end.toInt(),
      incomeMin: _incomeRange.start * 100000,
      incomeMax: _incomeRange.end * 100000,
      weightMin: _weightRange.start.toInt(),
      weightMax: _weightRange.end.toInt(),
      workLocation: _filterWorkLocation.isEmpty ? null : _filterWorkLocation,
    );

    setState(() {
      if (res.isNotEmpty) {
        _profiles = res;
      } else {
        // High quality default profiles if DB has no profiles matching opposite gender
        _profiles = [
          MatrimonialProfileModel(
            id: 'mock_priya_01',
            userId: 'usr_priya_01',
            name: 'Priyaben Patel',
            gender: 'Female',
            dateOfBirth: DateTime(2000, 3, 15),
            heightCm: 162,
            weightKg: 52,
            bloodGroup: 'B+',
            maritalStatus: 'Never Married',
            education: 'B.Tech in Computer Science',
            occupation: 'Software Engineer',
            company: 'Tech Innovations',
            annualIncome: 1200000,
            village: 'Karamsad',
            city: 'Anand',
            family: {'fatherName': 'Rameshbhai Patel', 'motherName': 'Geetaben Patel'},
            lifestyle: {'diet': 'Vegetarian', 'languages': ['Gujarati', 'English']},
            partnerPreferences: {'ageMin': 24, 'ageMax': 29},
            visibility: {'showPhone': false, 'showAddress': false, 'showEmail': false},
            profilePhotoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
            match: 94,
            connectionStatus: 'None',
            mobileNumber: '+91 98765 43210',
          ),
          MatrimonialProfileModel(
            id: 'mock_riya_02',
            userId: 'usr_riya_02',
            name: 'Riya Shah',
            gender: 'Female',
            dateOfBirth: DateTime(1998, 8, 20),
            heightCm: 165,
            weightKg: 55,
            bloodGroup: 'A+',
            maritalStatus: 'Never Married',
            education: 'Chartered Accountant (CA)',
            occupation: 'Senior Financial Analyst',
            company: 'KPMG',
            annualIncome: 1800000,
            village: 'Vadodara',
            city: 'Vadodara',
            family: {'fatherName': 'Mukeshbhai Shah', 'motherName': 'Kokilaben Shah'},
            lifestyle: {'diet': 'Vegetarian', 'languages': ['Gujarati', 'Hindi', 'English']},
            partnerPreferences: {'ageMin': 26, 'ageMax': 31},
            visibility: {'showPhone': false, 'showAddress': false, 'showEmail': false},
            profilePhotoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300',
            match: 89,
            connectionStatus: 'None',
            mobileNumber: '+91 98222 11334',
          ),
          MatrimonialProfileModel(
            id: 'mock_ananya_03',
            userId: 'usr_ananya_03',
            name: 'Ananya Chauhan',
            gender: 'Female',
            dateOfBirth: DateTime(1999, 11, 10),
            heightCm: 160,
            weightKg: 50,
            bloodGroup: 'O+',
            maritalStatus: 'Never Married',
            education: 'B.Arch (Architecture)',
            occupation: 'Interior Designer',
            company: 'Chauhan Designs',
            annualIncome: 950000,
            village: 'Surat',
            city: 'Surat',
            family: {'fatherName': 'Rajeshbhai Chauhan', 'motherName': 'Meenaben Chauhan'},
            lifestyle: {'diet': 'Vegetarian', 'languages': ['Gujarati', 'English']},
            partnerPreferences: {'ageMin': 25, 'ageMax': 30},
            visibility: {'showPhone': false, 'showAddress': false, 'showEmail': false},
            profilePhotoUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=300',
            match: 92,
            connectionStatus: 'None',
            mobileNumber: '+91 97111 88990',
          ),
          MatrimonialProfileModel(
            id: 'mock_mihir_04',
            userId: 'usr_mihir_04',
            name: 'Mihir Joshi',
            gender: 'Male',
            dateOfBirth: DateTime(1996, 5, 25),
            heightCm: 175,
            weightKg: 70,
            bloodGroup: 'B+',
            maritalStatus: 'Never Married',
            education: 'MBA in Finance',
            occupation: 'Business Consultant',
            company: 'Deloitte',
            annualIncome: 2200000,
            village: 'Ahmedabad',
            city: 'Ahmedabad',
            family: {'fatherName': 'Dineshbhai Joshi', 'motherName': 'Naynaben Joshi'},
            lifestyle: {'diet': 'Vegetarian', 'languages': ['Gujarati', 'English']},
            partnerPreferences: {'ageMin': 23, 'ageMax': 28},
            visibility: {'showPhone': false, 'showAddress': false, 'showEmail': false},
            profilePhotoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
            match: 91,
            connectionStatus: 'None',
            mobileNumber: '+91 98999 44556',
          ),
          MatrimonialProfileModel(
            id: 'mock_rohan_05',
            userId: 'usr_rohan_05',
            name: 'Rohan Parekh',
            gender: 'Male',
            dateOfBirth: DateTime(1997, 2, 14),
            heightCm: 178,
            weightKg: 72,
            bloodGroup: 'AB+',
            maritalStatus: 'Never Married',
            education: 'M.Tech Civil Engineering',
            occupation: 'Infrastructure Specialist',
            company: 'L&T Construction',
            annualIncome: 1600000,
            village: 'Rajkot',
            city: 'Rajkot',
            family: {'fatherName': 'Pravinbhai Parekh', 'motherName': 'Bhavnaben Parekh'},
            lifestyle: {'diet': 'Vegetarian', 'languages': ['Gujarati', 'Hindi', 'English']},
            partnerPreferences: {'ageMin': 22, 'ageMax': 27},
            visibility: {'showPhone': false, 'showAddress': false, 'showEmail': false},
            profilePhotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300',
            match: 88,
            connectionStatus: 'None',
            mobileNumber: '+91 98444 33221',
          ),
        ];
      }
      _isLoading = false;
    });
  }

  void _handleProfileOrContactTap(MatrimonialProfileModel p, {String actionType = 'view'}) {
    final user = ref.read(currentUserProvider);
    final isOwnProfile = user != null && user.id == p.userId;
    final isConnected = p.connectionStatus == 'Accepted' || isOwnProfile;

    if (isConnected) {
      if (actionType == 'call') {
        _triggerCall(p.mobileNumber, p.name);
      } else if (actionType == 'sms') {
        _triggerSMS(p.mobileNumber, p.name);
      } else {
        context.push('/matrimonial/profile/${p.userId}');
      }
      return;
    }

    // Show Send Request Alert Dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_person_rounded, color: Color(0xFFE67E22), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Connect with ${p.name}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to send a request to ${p.name} to continue chat, view full personal details, and unlock call/message access.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined, color: Color(0xFFE67E22), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'When ${p.name} accepts your request, all details will be unlocked automatically.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE67E22), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final service = ref.read(matrimonialServiceProvider);
              final senderId = user?.id ?? '6a7962b212a58c4a0e118cab';
              final success = await service.sendRequest(senderId, p.userId);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request sent to ${p.name}! You will be notified once accepted.'),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() {
                  final index = _profiles.indexWhere((item) => item.userId == p.userId);
                  if (index != -1) {
                    _profiles[index] = _profiles[index].copyWith(connectionStatus: 'Pending');
                  }
                });
              }
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Profiles',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: primaryBlue,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _ageRange = const RangeValues(21, 50);
                              _heightRange = const RangeValues(120, 220);
                              _weightRange = const RangeValues(40, 120);
                              _incomeRange = const RangeValues(0, 50);
                              _selectedMaritalStatus = 'Any';
                              _filterCity = '';
                              _filterVillage = '';
                              _filterEducation = '';
                              _filterOccupation = '';
                              _filterWorkLocation = '';
                            });
                          },
                          child: Text('Reset', style: TextStyle(color: primaryOrange)),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Marital Status dropdown
                    Text('Marital Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    DropdownButton<String>(
                      value: _selectedMaritalStatus,
                      isExpanded: true,
                      items: ['Any', 'Never Married', 'Divorced', 'Widowed']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => _selectedMaritalStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Age Slider
                    Text(
                      'Age: ${_ageRange.start.toInt()} - ${_ageRange.end.toInt()} yrs',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 70,
                      activeColor: primaryOrange,
                      inactiveColor: Colors.grey.shade300,
                      onChanged: (RangeValues values) {
                        setModalState(() => _ageRange = values);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Height Slider
                    Text(
                      'Height: ${_heightRange.start.toInt()} - ${_heightRange.end.toInt()} cm',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    RangeSlider(
                      values: _heightRange,
                      min: 100,
                      max: 240,
                      activeColor: primaryOrange,
                      inactiveColor: Colors.grey.shade300,
                      onChanged: (RangeValues values) {
                        setModalState(() => _heightRange = values);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Weight Slider
                    Text(
                      'Weight: ${_weightRange.start.toInt()} - ${_weightRange.end.toInt()} kg',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    RangeSlider(
                      values: _weightRange,
                      min: 30,
                      max: 150,
                      activeColor: primaryOrange,
                      inactiveColor: Colors.grey.shade300,
                      onChanged: (RangeValues values) {
                        setModalState(() => _weightRange = values);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Text Field Filters
                    TextField(
                      decoration: const InputDecoration(labelText: 'Preferred City', hintText: 'e.g. Vadodara'),
                      onChanged: (val) => _filterCity = val,
                      controller: TextEditingController(text: _filterCity),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Native Village', hintText: 'e.g. Karamsad'),
                      onChanged: (val) => _filterVillage = val,
                      controller: TextEditingController(text: _filterVillage),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Education', hintText: 'e.g. Engineering'),
                      onChanged: (val) => _filterEducation = val,
                      controller: TextEditingController(text: _filterEducation),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Work Location', hintText: 'e.g. India / USA'),
                      onChanged: (val) => _filterWorkLocation = val,
                      controller: TextEditingController(text: _filterWorkLocation),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadProfiles();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Apply Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _triggerCall(String mobile, String name) async {
    if (mobile.contains('•') || mobile.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contact Hidden'),
          content: Text('The contact details of $name are private based on their visibility settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _triggerSMS(String mobile, String name) async {
    if (mobile.contains('•') || mobile.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contact Hidden'),
          content: Text('The contact details of $name are private based on their visibility settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final uri = Uri.parse('sms:$mobile?body=Hello $name, I saw your profile on KutumbSetu Matrimony...');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _triggerShortlist(String candidateId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final service = ref.read(matrimonialServiceProvider);
    final success = await service.toggleShortlist(user.id, candidateId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shortlist state updated successfully!'), duration: Duration(seconds: 1)),
      );
      _loadProfiles();
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
          widget.showShortlistedOnly ? 'Shortlisted Favorites' : 'Browse Matches',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!widget.showShortlistedOnly)
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              onPressed: _showFilterModal,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search box (hide if shortlisted tab)
          if (!widget.showShortlistedOnly)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 2,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Search by name, education, occupation...',
                            hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _loadProfiles(),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          color: isDark ? Colors.white : Colors.black54,
                          onPressed: () {
                            _searchController.clear();
                            _loadProfiles();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _profiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_alt_outlined, size: 70, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No matching profiles found',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final p = _profiles[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              onTap: () => _handleProfileOrContactTap(p, actionType: 'view'),
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Profile picture
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color: primaryOrange.withValues(alpha: 0.1),
                                          ),
                                          child: p.profilePhotoUrl.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    p.profilePhotoUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) => Icon(Icons.person, size: 40, color: primaryOrange),
                                                  ),
                                                )
                                              : Icon(Icons.person, size: 40, color: primaryOrange),
                                        ),
                                        const SizedBox(width: 14),

                                        // Summary Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      p.name,
                                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                                    child: Text(
                                                      '${p.match}% Match',
                                                      style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold, fontSize: 10, color: primaryBlue),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${p.age} Yrs • ${p.gender} • ${p.maritalStatus}',
                                                style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                p.education.isNotEmpty ? p.education : 'Graduate',
                                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: primaryOrange),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${p.occupation} • ${p.city}',
                                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  // Quick Action Bar
                                  Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            p.connectionStatus == 'Accepted' ? Icons.phone_enabled_rounded : Icons.lock_outline_rounded,
                                            color: p.connectionStatus == 'Accepted' ? Colors.green : primaryBlue,
                                            size: 20,
                                          ),
                                          tooltip: p.connectionStatus == 'Accepted' ? 'Call' : 'Send Request to Call',
                                          onPressed: () => _handleProfileOrContactTap(p, actionType: 'call'),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            p.connectionStatus == 'Accepted' ? Icons.sms_rounded : Icons.chat_bubble_outline_rounded,
                                            color: p.connectionStatus == 'Accepted' ? Colors.green : primaryBlue,
                                            size: 20,
                                          ),
                                          tooltip: p.connectionStatus == 'Accepted' ? 'Message' : 'Send Request to Chat',
                                          onPressed: () => _handleProfileOrContactTap(p, actionType: 'sms'),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            widget.showShortlistedOnly ? Icons.star_rounded : Icons.star_outline_rounded,
                                            color: Colors.amber.shade700,
                                            size: 22,
                                          ),
                                          onPressed: () => _triggerShortlist(p.userId),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
