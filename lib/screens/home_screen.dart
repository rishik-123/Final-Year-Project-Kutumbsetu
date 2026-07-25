import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'family_tree_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final PageController _newsPageController = PageController();
  int _activeNewsIndex = 0;

  // Masking phone number helper
  String _maskPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.length >= 10) {
      if (clean.startsWith('+91')) {
        final mainPart = clean.substring(3);
        return '+91 ${mainPart.substring(0, 2)}*** ***${mainPart.substring(8)}';
      } else {
        return '${clean.substring(0, 2)}*** ***${clean.substring(8)}';
      }
    }
    return phone;
  }

  // Phonetic Gujarati translation dictionary helper
  String _transliterateToGujarati(String name) {
    final clean = name.toLowerCase().trim();
    if (clean == 'rajeshbhai chauhan') return 'રાજેશભાઈ ચૌહાણ';
    if (clean == 'rajeshbhai') return 'રાજેશભાઈ';
    if (clean == 'chauhan') return 'ચૌહાણ';
    if (clean == 'dineshbhai chauhan') return 'દિનેશભાઈ ચૌહાણ';
    if (clean == 'dineshbhai') return 'દિનેશભાઈ';
    if (clean == 'krupal chauhan') return 'કૃપાલ ચૌહાણ';
    if (clean == 'krupal') return 'કૃપาล';
    
    // Split and try word by word translation or phonetic approximation
    final words = clean.split(' ');
    final converted = words.map((w) {
      if (w == 'rajeshbhai') return 'રાજેશભાઈ';
      if (w == 'dineshbhai') return 'દિનેશભાઈ';
      if (w == 'krupal') return 'કૃપાલ';
      if (w == 'chauhan') return 'ચૌહાણ';
      if (w == 'patel') return 'પટેલ';
      if (w == 'shah') return 'શાહ';
      if (w == 'rishi') return 'રિષિ';
      
      // Basic syllabic mapping
      String s = w;
      s = s.replaceAll('bhai', 'ભાઈ');
      s = s.replaceAll('ben', 'બેน');
      s = s.replaceAll('kumar', 'કુમાર');
      s = s.replaceAll('lal', 'લાલ');
      s = s.replaceAll('dev', 'દેવ');
      s = s.replaceAll('mira', 'મીરા');
      s = s.replaceAll('raje', 'રાજે');
      s = s.replaceAll('sh', 'શ');
      s = s.replaceAll('chau', 'ચૌ');
      s = s.replaceAll('ha', 'હા');
      s = s.replaceAll('n', 'ણ');
      return s;
    }).join(' ');

    return converted;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider) ?? const UserModel(
      id: 'USR001',
      fullName: 'Rajeshbhai',
      surname: 'Chauhan',
      fatherName: 'Manilal',
      phoneNumber: '+919825010042',
      gender: 'Male',
      dateOfBirth: '1985-05-12',
      nativePlace: 'Karamsad',
      address: 'Vasant Vihar, Vadodara',
      city: 'Vadodara',
      state: 'Gujarat',
      maritalStatus: 'Married',
      occupation: 'Software Architect',
      education: 'B.E. Computer Engineering',
      bloodGroup: 'B+',
      profilePhoto: 'avatar_male_1',
      familyId: 'TEST-FAMILY-001',
      familyName: 'Chauhan',
      relationshipToHead: 'Self',
      motherName: 'Savitaben',
      spouseName: 'Priyaben',
      familyHeadPhone: '+919825010042',
    );

    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final bgGradient = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF5D2800),
              const Color(0xFF121212),
            ]
          : [
              const Color(0xFFFFF3E0),
              const Color(0xFFFAFAFA),
            ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeFeedTab(user, isDark),
                  const FamilyTreeScreen(),
                  _buildPlaceholderTab('Community Interaction', Icons.diversity_3_outlined, isDark),
                  _buildPlaceholderTab('Events & Announcements', Icons.calendar_month_outlined, isDark),
                  _buildProfileTab(user, isDark),
                ],
              ),
            ),
            _buildBottomNavBar(isDark),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: HOME FEED TAB ---
  Widget _buildHomeFeedTab(UserModel user, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Saffron Header
          _buildHeader(user, isDark),
          const SizedBox(height: 16),

          // 2. Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Quick actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActionsGrid(isDark),
          const SizedBox(height: 20),

          // 3. Birthdays Today
          _buildBirthdaysToday(isDark),
          const SizedBox(height: 20),

          // 4. Recent Samaj News
          _buildRecentSamajNews(isDark),
          const SizedBox(height: 20),

          // 5. Upcoming Events
          _buildUpcomingEvents(isDark),
          const SizedBox(height: 20),

          // 6. Featured Families
          _buildFeaturedFamilies(isDark),
          const SizedBox(height: 20),

          // 7. Community at a Glance
          _buildCommunityAtGlance(isDark),
          const SizedBox(height: 20),

          // 8. Community Posts & Feed
          _buildCommunityPostsFeed(isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- TAB 5: PROFILE TAB (IMAGE 4) ---
  Widget _buildProfileTab(UserModel user, bool isDark) {
    final String displayName = user.surname.isNotEmpty
        ? '${user.fullName} ${user.surname}'
        : user.fullName;
    final String gujaratiName = _transliterateToGujarati(displayName);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floating Avatar Profile Banner
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E8449), Color(0xFF27AE60)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: (user.profilePhoto.startsWith('data:image') || user.profilePhoto.length > 100)
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(user.profilePhoto.split(',').last)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: (user.profilePhoto.startsWith('data:image') || user.profilePhoto.length > 100)
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: (user.profilePhoto.startsWith('data:image') || user.profilePhoto.length > 100)
                      ? null
                      : Center(
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() + (user.surname.isNotEmpty ? user.surname[0].toUpperCase() : '') : 'RC',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),

          // Name & Verification Badge
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF0088CC),
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  gujaratiName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Badge Pills (Surname Parivar, City, Occupation)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadgePill('${user.surname.isNotEmpty ? user.surname : 'Chauhan'} Parivar', const Color(0xFFE8F8F5), const Color(0xFF1E8449)),
              const SizedBox(width: 8),
              _buildBadgePill(user.city.isNotEmpty ? user.city : 'Vadodara', const Color(0xFFEBF5FB), const Color(0xFF2980B9)),
              const SizedBox(width: 8),
              _buildBadgePill(user.occupation.isNotEmpty ? user.occupation : 'Software Architect', const Color(0xFFFEF9E7), const Color(0xFFD35400)),
            ],
          ),
          const SizedBox(height: 24),

          // Digital Community ID Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B5345), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KUTUMB SETU',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'GDS-2026-0417',
                          style: GoogleFonts.sourceCodePro(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Digital Community ID - ${user.surname.isNotEmpty ? user.surname : 'Chauhan'} Parivar',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Color(0xFF1E3A8A),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About / Family / Contributions Segments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'About',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Family',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Contributions',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, width: 1.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileInfoRow('Occupation', user.occupation.isNotEmpty ? user.occupation : 'Software Architect', isDark),
                    _buildProfileInfoRow('Education', user.education.isNotEmpty ? user.education : 'B.E. Computer Engineering', isDark),
                    _buildProfileInfoRow('Village', user.nativePlace.isNotEmpty ? user.nativePlace : 'Karamsad', isDark),
                    _buildProfileInfoRow('City', '${user.city.isNotEmpty ? user.city : 'Vadodara'}, ${user.state.isNotEmpty ? user.state : 'Gujarat'}', isDark),
                    _buildProfileInfoRow('Blood Group', user.bloodGroup.isNotEmpty ? user.bloodGroup : 'B+', isDark, isHighlight: true),
                    _buildProfileInfoRow('Contact', _maskPhone(user.phoneNumber), isDark, showLastDivider: false),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Clear Riverpod active user session
                ref.read(currentUserProvider.notifier).state = null;
                // Navigate to root route (Login page)
                context.go('/');
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: Text(
                'Logout Session',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // --- HOME SUB-WIDGETS ---

  // Saffron Header (Image 1)
  Widget _buildHeader(UserModel user, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE67E22), Color(0xFFD35400)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Jay Shree Krishna ',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          '🙏',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.fullName.isNotEmpty
                          ? '${user.fullName} ${user.surname}'
                          : 'Rajeshbhai Chauhan',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.language_rounded, color: Colors.cyanAccent, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.notifications_rounded, color: Colors.orangeAccent, size: 20),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 4;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.deepPurpleAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF2E86C1), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search families, villages, members...',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Actions Grid (Image 1)
  Widget _buildQuickActionsGrid(bool isDark) {
    final List<Map<String, dynamic>> items = [
      {'label': 'Family Tree', 'icon': Icons.account_tree_rounded, 'color': const Color(0xFFE8F8F5), 'iconColor': const Color(0xFF16A34A)},
      {'label': 'Directory', 'icon': Icons.folder_shared_rounded, 'color': const Color(0xFFEBF5FB), 'iconColor': const Color(0xFF2563EB), 'action': 'directory'},
      {'label': 'Matrimony', 'icon': Icons.favorite_rounded, 'color': const Color(0xFFFCE4D6), 'iconColor': const Color(0xFFEA4C89)},
      {'label': 'Events', 'icon': Icons.calendar_month_rounded, 'color': const Color(0xFFFEF9E7), 'iconColor': const Color(0xFFD35400)},
      {'label': 'Donations', 'icon': Icons.monetization_on_rounded, 'color': const Color(0xFFFCF3CF), 'iconColor': const Color(0xFFD4AC0D)},
      {'label': 'News', 'icon': Icons.newspaper_rounded, 'color': const Color(0xFFEAECEE), 'iconColor': const Color(0xFF7F8C8D)},
      {'label': 'Business', 'icon': Icons.storefront_rounded, 'color': const Color(0xFFF5EEF8), 'iconColor': const Color(0xFF8E44AD)},
      {'label': 'More', 'icon': Icons.more_horiz_rounded, 'color': Colors.transparent, 'iconColor': Colors.grey, 'dashed': true},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final isDashed = item['dashed'] == true;

          return InkWell(
            onTap: () {
              if (item['action'] == 'directory') {
                context.push('/directory');
              } else if (item['label'] == 'Family Tree') {
                setState(() {
                  _currentIndex = 1;
                });
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: item['color'],
                    shape: BoxShape.circle,
                    border: isDashed
                        ? Border.all(color: Colors.grey.shade400, width: 1.5, style: BorderStyle.solid) // Simple solid border for dashed style fallback
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      item['icon'],
                      color: item['iconColor'],
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    item['label'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Birthdays Today (Image 1)
  Widget _buildBirthdaysToday(bool isDark) {
    final List<Map<String, dynamic>> birthdays = [
      {'name': 'Hansaben K.', 'initials': 'HK', 'turns': 'Turns 58', 'color': Colors.orange},
      {'name': 'Dev Parekh', 'initials': 'DP', 'turns': 'Turns 12', 'color': Colors.blue},
      {'name': 'Mira Joshi', 'initials': 'MJ', 'turns': 'Turns 34', 'color': Colors.green},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Birthdays today 🎂',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD35400),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: birthdays.length,
            itemBuilder: (context, index) {
              final b = birthdays[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  width: 105,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: b['color'],
                        child: Text(
                          b['initials'],
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        b['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        b['turns'],
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.grey,
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
    );
  }

  // Recent Samaj News (Image 2)
  Widget _buildRecentSamajNews(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Samaj News 📰',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD35400),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Left thick border decoration
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD35400),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4D6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.push_pin_rounded, color: Color(0xFFD35400), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trust election notice',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Annual Trust elections will be held on 29th Aug at Community Bhavan, Rajkot.',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              width: index == 0 ? 12 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: index == 0 ? const Color(0xFFD35400) : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Upcoming Events (Image 2)
  Widget _buildUpcomingEvents(bool isDark) {
    final List<Map<String, String>> events = [
      {'day': '18', 'month': 'JUL', 'title': 'Samuh Lagna Sammelan', 'loc': 'Community Hall, Ahmedabad'},
      {'day': '02', 'month': 'AUG', 'title': 'Blood Donation Camp', 'loc': 'Darji Samaj Bhavan, Surat'},
      {'day': '15', 'month': 'AUG', 'title': 'Youth Sports Meet', 'loc': 'Rajkot Ground No. 3'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming events',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD35400),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final ev = events[index];
                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ev['day']!,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF16A34A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            ev['month']!,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF16A34A),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev['title']!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ev['loc']!,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Featured Families (Image 2)
  Widget _buildFeaturedFamilies(bool isDark) {
    final List<Map<String, dynamic>> families = [
      {'name': 'Chauhan Parivar', 'desc': 'Vadodara - 6 gen.', 'members': '240 members', 'color': const Color(0xFF2980B9)},
      {'name': 'Parekh Parivar', 'desc': 'Surat - 5 gen.', 'members': '185 members', 'color': const Color(0xFF1E8449)},
      {'name': 'Joshi Parivar', 'desc': 'Rajkot - 4 gen.', 'members': '312 members', 'color': const Color(0xFFB7950B)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured families',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'Explore',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD35400),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: families.length,
            itemBuilder: (context, index) {
              final f = families[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colored banner
                      Container(
                        height: 70,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: f['color'],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                f['members'],
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              f['desc'],
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Community at a Glance (Image 3)
  Widget _buildCommunityAtGlance(bool isDark) {
    final List<Map<String, String>> stats = [
      {'val': '1,240', 'lbl': 'Families'},
      {'val': '18.6K', 'lbl': 'Members'},
      {'val': '86', 'lbl': 'Villages'},
      {'val': '9', 'lbl': 'Generations'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Community at a glance',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: stats.map((st) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          st['val']!,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFD35400),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          st['lbl']!,
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Community Posts & Feed (Image 3)
  Widget _buildCommunityPostsFeed(bool isDark) {
    final List<Map<String, dynamic>> posts = [
      {
        'init': 'RC',
        'name': 'Rajeshbhai Chauhan',
        'time': '2 hours ago • Vadodara',
        'badge': 'Announcement',
        'txt': 'Jay Shree Krishna to all samaj members! Welcome to our new digital platform KutumbSetu. Connect with family lineage, business directory, and upcoming events seamlessly.',
        'likes': '42',
        'comments': '8'
      },
      {
        'init': 'DC',
        'name': 'Dineshbhai Chauhan',
        'time': '5 hours ago • Karamsad',
        'badge': 'Social Work',
        'txt': 'Our Samaj Blood Donation Camp date has been confirmed for 2nd August at Surat. Requesting all youth members to register and donate blood for this noble cause. 🙏',
        'likes': '68',
        'comments': '14'
      },
      {
        'init': 'KC',
        'name': 'Krupal Chauhan',
        'time': 'Yesterday • Anand',
        'badge': 'Achievement',
        'txt': 'Feeling proud to announce that my sister Nikita Chauhan has cleared Chartered Accountancy (CA) exams with distinction! Thanks to elder\'s blessings. 🎓✨',
        'likes': '115',
        'comments': '32'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Community Posts & Feed',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '20 Posts',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD35400),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final p = posts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post User Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFD35400),
                          child: Text(
                            p['init'],
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                p['time'],
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE4D6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p['badge'],
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFD35400),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Post Text
                    Text(
                      p['txt'],
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Actions row
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: Colors.pink, size: 16),
                        const SizedBox(width: 4),
                        Text(p['likes'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 20),
                        const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(p['comments'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                        const Spacer(),
                        const Icon(Icons.share_outlined, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text('Share', style: GoogleFonts.inter(fontSize: 11, color: Colors.blue)),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }

  // --- PLACEHOLDERS ---
  Widget _buildPlaceholderTab(String title, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This tab content will be populated in subsequent modules.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- PROFILE TAB SUB-WIDGETS ---
  Widget _buildBadgePill(String label, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: textCol,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String val, bool isDark, {bool isHighlight = false, bool showLastDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    val,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                      color: isHighlight
                          ? const Color(0xFFEF4444)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLastDivider) const Divider(height: 1),
      ],
    );
  }

  // --- BOTTOM NAV BAR (IMAGE 1 / 4) ---
  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavBarItem(0, Icons.home_rounded, 'Home', isDark),
            _buildNavBarItem(1, Icons.park_rounded, 'Tree', isDark),
            _buildNavBarCenterButton(),
            _buildNavBarItem(3, Icons.calendar_month_rounded, 'Events', isDark),
            _buildNavBarItem(4, Icons.person_rounded, 'Profile', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final Color selectedCol = const Color(0xFFD35400);
    final Color unselectedCol = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedCol : unselectedCol,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedCol : unselectedCol,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarCenterButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFD35400),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.people_alt_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
