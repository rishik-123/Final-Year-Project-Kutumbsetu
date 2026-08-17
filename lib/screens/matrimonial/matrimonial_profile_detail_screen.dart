import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matrimonial_providers.dart';
import '../../models/matrimonial_profile_model.dart';

class MatrimonialProfileDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const MatrimonialProfileDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<MatrimonialProfileDetailScreen> createState() => _MatrimonialProfileDetailScreenState();
}

class _MatrimonialProfileDetailScreenState extends ConsumerState<MatrimonialProfileDetailScreen> {
  bool _isShortlisted = false;
  late Future<MatrimonialProfileModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final requester = ref.read(currentUserProvider);
    _profileFuture = ref.read(matrimonialServiceProvider).fetchProfile(
      widget.userId,
      requesterId: requester?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final requester = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);
    final service = ref.read(matrimonialServiceProvider);

    return FutureBuilder<MatrimonialProfileModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFE67E22))),
          );
        }
        final p = snapshot.data;
        if (p == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: primaryOrange,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: Text('Profile not found.')),
          );
        }

        final isOwnProfile = requester != null && requester.id == p.userId;
        final isUnlocked = isOwnProfile || p.connectionStatus == 'Accepted';

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
          body: CustomScrollView(
            slivers: [
              // Large Picture Banner
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: primaryOrange,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      p.profilePhotoUrl.isNotEmpty && isUnlocked
                          ? Image.network(
                              p.profilePhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: primaryOrange.withValues(alpha: 0.1),
                                child: Icon(Icons.person, size: 100, color: primaryOrange),
                              ),
                            )
                          : Container(
                              color: primaryOrange.withValues(alpha: 0.1),
                              child: Icon(
                                isUnlocked ? Icons.person : Icons.lock_rounded,
                                size: 100,
                                color: primaryOrange,
                              ),
                            ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0x99000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: Colors.blue, size: 20),
                              ],
                            ),
                            if (isUnlocked) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${p.age} Yrs • ${p.heightCm} cm • ${p.maritalStatus}',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        Positioned(
                          top: 40,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${p.match}% Match',
                              style: GoogleFonts.sourceCodePro(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Profile Content details
              SliverList(
                delegate: SliverChildListDelegate([
                  if (!isUnlocked) ...[
                    // Details locked warning & Connection request actions
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 72,
                                color: primaryOrange,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Profile Details Private',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDark ? Colors.white : primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                p.connectionStatus == 'None'
                                    ? 'Send a connection request to unlock their biodata, career details, expectations, photos, and contact information.'
                                    : p.connectionStatus == 'Pending'
                                        ? 'Connection request has been sent! Waiting for candidate response.'
                                        : 'Connection request declined.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (p.connectionStatus == 'None')
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                                  label: Text(
                                    'Send Connection Request',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (requester != null) {
                                      final success = await service.sendRequest(requester.id, widget.userId);
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Connection request sent successfully!')),
                                        );
                                        setState(() {
                                          _loadProfile();
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to send connection request.')),
                                        );
                                      }
                                    }
                                  },
                                )
                              else if (p.connectionStatus == 'Pending')
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.hourglass_empty_rounded, color: Colors.grey),
                                  label: const Text('Request Pending Approval'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: null,
                                )
                              else
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.block_rounded, color: Colors.redAccent),
                                  label: const Text('Request Declined'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: null,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Unlocked Full Profile Details
                    // Shortlist / Save Profile Button Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: _isShortlisted ? (isDark ? const Color(0xFF334155) : Colors.amber.shade50) : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        child: InkWell(
                          onTap: () async {
                            if (requester != null) {
                              final success = await service.toggleShortlist(requester.id, widget.userId);
                              if (success) {
                                setState(() {
                                  _isShortlisted = !_isShortlisted;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_isShortlisted ? 'Profile added to shortlists!' : 'Profile removed from shortlists!'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isShortlisted ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber.shade800,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isShortlisted ? 'Profile Shortlisted' : 'Save to Shortlist',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _isShortlisted ? Colors.amber.shade900 : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Biography / Description
                    if (p.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About Candidate',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryOrange,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  p.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    height: 1.5,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Partner Expectations
                    if (p.partnerExpectations.isNotEmpty || p.partnerExpectationsHobbies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expectations from Partner',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryBlue,
                                  ),
                                ),
                                if (p.partnerExpectations.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    p.partnerExpectations,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      height: 1.5,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                                if (p.partnerExpectationsHobbies.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Preferred Hobbies:',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: p.partnerExpectationsHobbies.map((hob) {
                                      return Chip(
                                        label: Text(hob, style: const TextStyle(fontSize: 11)),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        backgroundColor: primaryOrange.withValues(alpha: 0.1),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Social Links Section
                    if (p.socialLinks['showSocialLinks'] == true &&
                        ((p.socialLinks['instagramUrl']?.toString().isNotEmpty ?? false) ||
                         (p.socialLinks['facebookUrl']?.toString().isNotEmpty ?? false)))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Social Handles',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (p.socialLinks['instagramUrl']?.toString().isNotEmpty ?? false)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final url = Uri.parse(p.socialLinks['instagramUrl'].toString());
                                            if (await canLaunchUrl(url)) await launchUrl(url);
                                          },
                                          icon: const Icon(Icons.link, size: 16),
                                          label: const Text('Instagram'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pink.shade700,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    if (p.socialLinks['instagramUrl']?.toString().isNotEmpty ?? false &&
                                        p.socialLinks['facebookUrl']?.toString().isNotEmpty ?? false)
                                      const SizedBox(width: 12),
                                    if (p.socialLinks['facebookUrl']?.toString().isNotEmpty ?? false)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final url = Uri.parse(p.socialLinks['facebookUrl'].toString());
                                            if (await canLaunchUrl(url)) await launchUrl(url);
                                          },
                                          icon: const Icon(Icons.link, size: 16),
                                          label: const Text('Facebook'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue.shade800,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Additional Photos Grid
                    if (p.additionalPhotos.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                              child: Text(
                                'Additional Photos',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: p.additionalPhotos.length,
                                itemBuilder: (context, index) {
                                  final imgUrl = p.additionalPhotos[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        imgUrl,
                                        width: 140,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          width: 140,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Introduction Video Player Card
                    if (p.introductionVideoUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.video_camera_back_rounded, color: primaryOrange, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Family Introduction Video (30-Sec)',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : primaryBlue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Card(
                              elevation: 2,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: MatrimonialVideoPlayer(videoUrl: p.introductionVideoUrl),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Info sections
                    _buildDetailsSection(
                      title: 'Personal Information',
                      icon: Icons.person_outline_rounded,
                      color: primaryBlue,
                      isDark: isDark,
                      children: [
                        _buildInfoRow('Native Village', p.village),
                        _buildInfoRow('Current City', p.city),
                        _buildInfoRow('Current Working Country', p.workingCountry.isNotEmpty ? p.workingCountry : 'India'),
                        _buildInfoRow('Gender', p.gender),
                        _buildInfoRow('Weight', '${p.weightKg} Kg'),
                        _buildInfoRow('Blood Group', p.bloodGroup),
                        _buildInfoRow('Birthdate', '${p.dateOfBirth.day}/${p.dateOfBirth.month}/${p.dateOfBirth.year}'),
                      ],
                    ),

                    _buildDetailsSection(
                      title: 'Education & Career',
                      icon: Icons.school_outlined,
                      color: primaryOrange,
                      isDark: isDark,
                      children: [
                        _buildInfoRow('Highest Qualification', p.education),
                        _buildInfoRow('Profession', p.occupation),
                        _buildInfoRow('Working At', p.company),
                        _buildInfoRow('Annual Income', '₹ ${(p.annualIncome / 100000).toStringAsFixed(1)} Lakhs / yr'),
                      ],
                    ),

                    _buildDetailsSection(
                      title: 'Family Details',
                      icon: Icons.family_restroom_outlined,
                      color: Colors.teal,
                      isDark: isDark,
                      children: [
                        _buildInfoRow('Father\'s Name', p.family['fatherName'] ?? ''),
                        _buildInfoRow('Mother\'s Name', p.family['motherName'] ?? ''),
                        _buildInfoRow('Paternal Grandfather', p.family['grandfather'] ?? ''),
                        _buildInfoRow('Paternal Grandmother', p.family['grandmother'] ?? ''),
                        _buildInfoRow('Maternal Grandfather (Nana)', p.family['nana'] ?? ''),
                        _buildInfoRow('Maternal Grandmother (Nani)', p.family['nani'] ?? ''),
                        _buildInfoRow('Family Occupation', p.family['familyOccupation'] ?? ''),
                      ],
                    ),

                    const SizedBox(height: 80),
                  ]
                ]),
              ),
            ],
          ),
          bottomSheet: isUnlocked
              ? Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                        label: const Text('Call Candidate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _triggerCall(p.mobileNumber, p.name),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.sms_outlined, color: Colors.white, size: 18),
                        label: const Text('Send SMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _triggerSMS(p.mobileNumber, p.name),
                      ),
                      IconButton(
                        icon: Icon(
                          _isShortlisted ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber.shade700,
                          size: 28,
                        ),
                        onPressed: () async {
                          if (requester != null) {
                            final success = await service.toggleShortlist(requester.id, widget.userId);
                            if (success) {
                              setState(() {
                                _isShortlisted = !_isShortlisted;
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDetailsSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : color),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not Specified',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
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
}

class MatrimonialVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const MatrimonialVideoPlayer({super.key, required this.videoUrl});

  @override
  State<MatrimonialVideoPlayer> createState() => _MatrimonialVideoPlayerState();
}

class _MatrimonialVideoPlayerState extends State<MatrimonialVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: VideoPlayer(_controller),
        ),
        if (!_controller.value.isPlaying)
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.play();
              });
            },
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
            ),
          ),
        if (_controller.value.position == _controller.value.duration)
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.seekTo(Duration.zero);
                _controller.play();
              });
            },
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: const Icon(Icons.replay_rounded, color: Colors.white, size: 32),
            ),
          ),
      ],
    );
  }
}
