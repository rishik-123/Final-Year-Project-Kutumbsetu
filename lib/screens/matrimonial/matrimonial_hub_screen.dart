import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matrimonial_providers.dart';
import '../../models/matrimonial_profile_model.dart';

class MatrimonialHubScreen extends ConsumerStatefulWidget {
  const MatrimonialHubScreen({super.key});

  @override
  ConsumerState<MatrimonialHubScreen> createState() => _MatrimonialHubScreenState();
}

class _MatrimonialHubScreenState extends ConsumerState<MatrimonialHubScreen> {
  int calculateCompletionPercentage(MatrimonialProfileModel? profile) {
    if (profile == null) return 0;
    int score = 0;
    // Personal fields
    if (profile.name.isNotEmpty) score += 20;
    // Education & Career
    if (profile.education.isNotEmpty || profile.occupation.isNotEmpty) score += 20;
    // Family information
    if (profile.family.isNotEmpty && profile.family['fatherName'] != '') score += 20;
    // Lifestyle details
    if (profile.lifestyle.isNotEmpty && profile.lifestyle['diet'] != null) score += 20;
    // Partner Preferences
    if (profile.partnerPreferences.isNotEmpty && profile.partnerPreferences['ageMin'] != null) score += 20;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final myProfileAsync = ref.watch(myMatrimonialProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // Elegant Header
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'KutumbSetu Matrimony',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryOrange, primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Contents
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Completion Banner
                  myProfileAsync.when(
                    data: (profile) {
                      final percentage = calculateCompletionPercentage(profile);
                      return Card(
                        elevation: 4,
                        shadowColor: primaryOrange.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                  : [Colors.white, const Color(0xFFFDF2E9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            children: [
                              // Circular Progress Indicator
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 65,
                                    height: 65,
                                    child: CircularProgressIndicator(
                                      value: percentage / 100,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                                    ),
                                  ),
                                  Text(
                                    '$percentage%',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile == null
                                          ? 'Create Matrimonial Profile'
                                          : 'Profile Status: ${profile.status}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isDark ? Colors.white : primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile == null
                                          ? 'Create your biodata to match with community profiles.'
                                          : percentage < 100
                                              ? 'Complete all tabs to boost matching visibility.'
                                              : 'Your matrimonial biodata is fully published.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => context.push('/matrimonial/biodata'),
                                      child: Text(
                                        profile == null ? 'Get Started →' : 'Edit Biodata →',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: primaryOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Container(),
                  ),
                  const SizedBox(height: 24),

                  // Premium Benefits Promo Banner Card
                  Card(
                    elevation: 4,
                    shadowColor: const Color(0xFFF1C40F).withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD700), // Gold
                            Color(0xFFE67E22), // Saffron Orange
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          context.push('/matrimonial/premium-benefits');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Benefits of Premium',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Unlock unlimited profile views, priority matching, visitor tracking & more!',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Hub Feature Grid
                  Text(
                    'Explore Matrimony',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildExploreGrid(context, primaryOrange, primaryBlue),
                  const SizedBox(height: 28),

                  // 3. Recommended Matches (Opposite gender of logged-in user)
                  Text(
                    'Recommended Matches ✨',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecommendationsReel(user, primaryOrange, primaryBlue, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreGrid(BuildContext context, Color orange, Color blue) {
    final List<Map<String, dynamic>> items = [
      {'label': 'Browse Profiles', 'icon': Icons.people_outline_rounded, 'color': blue, 'path': '/matrimonial/profiles'},
      {'label': 'My Biodata', 'icon': Icons.description_outlined, 'color': orange, 'path': '/matrimonial/biodata'},
      {'label': 'Shortlists', 'icon': Icons.star_border_rounded, 'color': Colors.amber.shade700, 'path': '/matrimonial/profiles?shortlisted=true'},
      {'label': 'Marriage Events', 'icon': Icons.celebration_outlined, 'color': Colors.teal, 'path': '/matrimonial/events'},
      {'label': 'Success Stories', 'icon': Icons.auto_stories_outlined, 'color': Colors.pink, 'path': '/matrimonial/stories'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => context.push(item['path']),
          borderRadius: BorderRadius.circular(16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    item['color'].withValues(alpha: 0.1),
                    item['color'].withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: item['color'].withValues(alpha: 0.2), width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: item['color'].withValues(alpha: 0.15),
                    radius: 20,
                    child: Icon(item['icon'], color: item['color'], size: 22),
                  ),
                  Text(
                    item['label'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationsReel(dynamic user, Color orange, Color blue, bool isDark) {
    final oppositeGender = (user?.gender == 'Male') ? 'Female' : 'Male';
    final service = ref.read(matrimonialServiceProvider);

    return FutureBuilder<List<MatrimonialProfileModel>>(
      future: service.fetchProfiles(
        gender: oppositeGender,
        requesterId: user?.id,
        limit: 8,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final profiles = snapshot.data ?? [];
        if (profiles.isEmpty) {
          return Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade200.withValues(alpha: 0.5),
            ),
            child: Text(
              'No recommendations found. Try completing your preferences.',
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        return SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final p = profiles[index];
              return Container(
                width: 175,
                margin: const EdgeInsets.only(right: 14),
                child: InkWell(
                  onTap: () => context.push('/matrimonial/profile/${p.userId}'),
                  borderRadius: BorderRadius.circular(18),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Top Image + Match %
                        Stack(
                          children: [
                            Container(
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                color: orange.withValues(alpha: 0.1),
                              ),
                              child: (p.profilePhotoUrl.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                      child: Image.network(
                                        p.profilePhotoUrl,
                                        width: double.infinity,
                                        height: 130,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Center(
                                          child: Icon(Icons.person_rounded, size: 55, color: orange.withValues(alpha: 0.6)),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(Icons.person_rounded, size: 55, color: orange.withValues(alpha: 0.6)),
                                    ),
                            ),
                            // Match Banner
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${p.match}% Match',
                                  style: GoogleFonts.sourceCodePro(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Card text
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.age} Yrs • ${p.heightCm} cm',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.education.isNotEmpty ? p.education : 'Graduate',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: orange,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                p.city.isNotEmpty ? p.city : 'Gujarat',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
