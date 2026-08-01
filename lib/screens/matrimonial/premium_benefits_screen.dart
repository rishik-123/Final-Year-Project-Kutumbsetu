import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';

class PremiumBenefitsScreen extends ConsumerWidget {
  const PremiumBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final primaryOrange = const Color(0xFFE67E22);
    final primaryBlue = const Color(0xFF1B4F72);
    final goldColor = const Color(0xFFD4AC0D);

    final List<Map<String, dynamic>> benefits = [
      {
        'title': 'Unlimited Profile Views',
        'desc': 'Access complete contact information and detailed biodatas of all community members without limits.',
        'icon': Icons.visibility_rounded,
        'color': const Color(0xFF3498DB),
      },
      {
        'title': 'Priority Profile Listing',
        'desc': 'Feature your profile at the top of search results and recommendations to get up to 5x more visibility.',
        'icon': Icons.bolt_rounded,
        'color': primaryOrange,
      },
      {
        'title': 'Profile Visitors Tracker',
        'desc': 'See exactly who visited your matrimonial profile, showing you active interest in real-time.',
        'icon': Icons.remove_red_eye_rounded,
        'color': const Color(0xFF2ECC71),
      },
      {
        'title': 'Golden Verified Badge',
        'desc': 'Add an exclusive gold verification badge to your card to build trust and authenticity in the community.',
        'icon': Icons.verified_rounded,
        'color': goldColor,
      },
      {
        'title': 'Advanced Match Filters',
        'desc': 'Filter matches by specific education, career, location, height, and customized lifestyle choices.',
        'icon': Icons.tune_rounded,
        'color': const Color(0xFF9B59B6),
      },
      {
        'title': 'Direct Contact Connect',
        'desc': 'Directly connect with coordinates and family members via integrated WhatsApp and chat features.',
        'icon': Icons.phone_iphone_rounded,
        'color': const Color(0xFF1ABC9C),
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Saffron & Gold Header Banner
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD35400),
                      primaryOrange,
                      const Color(0xFFFFD700),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: -20,
                      top: -20,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 200,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'KutumbSetu Premium',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Find Your Ideal Life Partner Today',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content body
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Exclusive Advantages',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Discover how KutumbSetu Premium makes your matrimonial search easier and faster.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // Benefits Grid/List of Cards
                ...benefits.map((b) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: b['color'].withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              b['icon'],
                              color: b['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b['title'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b['desc'],
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Premium Betas / Admin Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B3B30) : const Color(0xFFE8F8F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E8449).withValues(alpha: 0.3) : const Color(0xFFA3E4D7),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF16A085),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Note: Matrimonial premium plans are managed directly by community coordinators. Access is complimentary during the current system evaluation phase.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFD1F2EB) : const Color(0xFF117A65),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
