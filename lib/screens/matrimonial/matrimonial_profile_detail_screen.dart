import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
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

  @override
  Widget build(BuildContext context) {
    final requester = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);

    final service = ref.read(matrimonialServiceProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      body: FutureBuilder<MatrimonialProfileModel?>(
        future: service.fetchProfile(widget.userId, requesterId: requester?.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data;
          if (p == null) {
            return Scaffold(
              appBar: AppBar(backgroundColor: primaryOrange, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
              body: const Center(child: Text('Profile not found.')),
            );
          }

          return CustomScrollView(
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
                      p.profilePhotoUrl.isNotEmpty
                          ? Image.network(
                              p.profilePhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(color: primaryOrange.withValues(alpha: 0.1), child: Icon(Icons.person, size: 100, color: primaryOrange)),
                            )
                          : Container(color: primaryOrange.withValues(alpha: 0.1), child: Icon(Icons.person, size: 100, color: primaryOrange)),
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
                            const SizedBox(height: 4),
                            Text(
                              '${p.age} Yrs • ${p.heightCm} cm • ${p.maritalStatus}',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
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
                ]),
              ),
            ],
          );
        },
      ),
      bottomSheet: Consumer(
        builder: (context, ref, child) {
          final user = ref.watch(currentUserProvider);
          if (user == null) return const SizedBox();
          return Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -3))],
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
                  onPressed: () async {
                    final p = await service.fetchProfile(widget.userId, requesterId: user.id);
                    if (p != null) {
                      _triggerCall(p.mobileNumber, p.name);
                    }
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sms_outlined, color: Colors.white, size: 18),
                  label: const Text('Send SMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final p = await service.fetchProfile(widget.userId, requesterId: user.id);
                    if (p != null) {
                      _triggerSMS(p.mobileNumber, p.name);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isShortlisted ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                  onPressed: () async {
                    final success = await service.toggleShortlist(user.id, widget.userId);
                    if (success) {
                      setState(() {
                        _isShortlisted = !_isShortlisted;
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
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

// ----------------------------------------------------
// NESTED NATIVE VIDEO PLAYER WIDGET
// ----------------------------------------------------
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
        // Play / Pause Indicator overlay
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
        // Replay overlay
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
