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
  RangeValues _ageRange = const RangeValues(18, 60);
  RangeValues _heightRange = const RangeValues(120, 220);
  RangeValues _incomeRange = const RangeValues(0, 50); // in lakhs
  String _selectedMaritalStatus = 'Any';
  String _filterCity = '';
  String _filterVillage = '';
  String _filterEducation = '';
  String _filterOccupation = '';

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
    );

    setState(() {
      _profiles = res;
      _isLoading = false;
    });
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
                              _ageRange = const RangeValues(18, 60);
                              _heightRange = const RangeValues(120, 220);
                              _incomeRange = const RangeValues(0, 50);
                              _selectedMaritalStatus = 'Any';
                              _filterCity = '';
                              _filterVillage = '';
                              _filterEducation = '';
                              _filterOccupation = '';
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
                              onTap: () => context.push('/matrimonial/profile/${p.userId}'),
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
                                                '${p.age} Yrs • ${p.heightCm} cm • ${p.maritalStatus}',
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
                                          icon: Icon(Icons.phone_enabled_outlined, color: primaryBlue, size: 20),
                                          onPressed: () => _triggerCall(p.mobileNumber, p.name),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.sms_outlined, color: primaryBlue, size: 20),
                                          onPressed: () => _triggerSMS(p.mobileNumber, p.name),
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
