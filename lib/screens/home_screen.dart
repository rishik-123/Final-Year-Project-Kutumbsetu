import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'family_tree_screen.dart';
import 'matrimonial/matrimonial_hub_screen.dart';
import 'profile_completion_screen.dart';
import '../community/community_feed.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final PageController _newsPageController = PageController();
  int _activeNewsIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  bool _showLanguageToggle = false;
  bool _isGujarati = false;

  final Map<String, String> _translations = {
    'Jay Shree Krishna': 'જય શ્રી કૃષ્ણ',
    'Search families, villages, members...': 'પરિવારો, ગામો, સભ્યો શોધો...',
    'Quick actions': 'ઝડપી કાર્યો',
    'Family Tree': 'કુટુંબ વૃક્ષ',
    'Directory': 'ડિરેક્ટરી',
    'Matrimony': 'લગ્નવિષયક',
    'Events': 'કાર્યક્રમો',
    'Donations': 'દાન',
    'News': 'સમાચાર',
    'Community Hub': 'સમાજ હબ',
    'Business': 'વ્યવસાય',
    'More': 'વધુ',
    'Birthdays today 🎂': 'આજના જન્મદિવસ 🎂',
    'See all': 'બધા જુઓ',
    'Recent Samaj News 📰': 'તાજેતરના સમાજ સમાચાર 📰',
    'Upcoming events': 'આગામી કાર્યક્રમો',
    'Featured families': 'વિશિષ્ટ પરિવારો',
    'Community at a glance': 'સમાજ એક નજરમાં',
    'Community Posts & Feed': 'સમાજ પોસ્ટ્સ અને ફીડ',
    'Explore': 'શોધો',
    'Families': 'પરિવારો',
    'Members': 'સભ્યો',
    'Villages': 'ગામો',
    'Generations': 'પેઢીઓ',
    'Posts': 'પોસ્ટ્સ',
    'Share': 'શેર કરો',
    'Trust election notice': 'ટ્રસ્ટ ચૂંટણી નોટિસ',
    'Annual Trust elections will be held on 29th Aug at Community Bhavan, Rajkot.': 'વાર્ષિક ટ્રસ્ટની ચૂંટણી ૨૯ ઓગસ્ટે કોમ્યુનિટી ભવન, રાજકોટ ખાતે યોજાશે.',
    'Samuh Lagna Sammelan': 'સમૂહ લગ્ન સંમેલન',
    'Blood Donation Camp': 'રક્તદાન કેમ્પ',
    'Youth Sports Meet': 'યુવા રમતગમત મહોત્સવ',
    'Community Hall, Ahmedabad': 'કોમ્યુનિટી હોલ, અમદાવાદ',
    'Darji Samaj Bhavan, Surat': 'દરજી સમાજ ભવન, સુરત',
    'Rajkot Ground No. 3': 'રાજકોટ ગ્રાઉન્ડ નં. ૩',
    'Chauhan Parivar': 'ચૌહાણ પરિવાર',
    'Parekh Parivar': 'પારેખ પરિવાર',
    'Joshi Parivar': 'જોશી પરિવાર',
    'Vadodara - 6 gen.': 'વડોદરા - ૬ પેઢી',
    'Surat - 5 gen.': 'સુરત - ૫ પેઢી',
    'Rajkot - 4 gen.': 'રાજકોટ - ૪ પેઢી',
    '240 members': '૨૪૦ સભ્યો',
    '185 members': '૧૮૫ સભ્યો',
    '312 members': '૩૧૨ સભ્યો',
    'Announcement': 'જાહેરાત',
    'Social Work': 'સામાજિક કાર્ય',
    'Achievement': 'સિદ્ધિ',
    'Jay Shree Krishna to all samaj members! Welcome to our new digital platform KutumbSetu. Connect with family lineage, business directory, and upcoming events seamlessly.': 'તમામ સમાજ સભ્યોને જય શ્રી કૃષ્ણ! અમારા નવા ડિજિટલ પ્લેટફોર્મ કુટુંબસેતુમાં આપનું સ્વાગત છે. પારિવારિક વંશાવળી, વ્યવસાય ડિરેક્ટરી અને આગામી કાર્યક્રમો સાથે એકીકૃત રીતે જોડાઓ.',
    'Our Samaj Blood Donation Camp date has been confirmed for 2nd August at Surat. Requesting all youth members to register and donate blood for this noble cause. 🙏': 'અમારા સમાજ રક્તદાન કેમ્પની તારીખ ૨ ઓગસ્ટ સુરત ખાતે નક્કી કરવામાં આવી છે. આ ઉમદા કાર્ય માટે તમામ યુવા સભ્યોને રજીસ્ટર કરવા અને રક્તદાન કરવા વિનંતી છે. 🙏',
    'Feeling proud to announce that my sister Nikita Chauhan has cleared Chartered Accountancy (CA) exams with distinction! Thanks to elder\'s blessings. 🎓✨': 'મારી બહેન નિકિતા ચૌહાણે ચાર્ટર્ડ એકાઉન્ટન્સી (CA) ની પરીક્ષા ગૌરવપૂર્વક પાસ કરી છે તે જાહેર કરતા ગર્વ થાય છે! વડીલોના આશીર્વાદ બદલ આભાર. 🎓✨',
    'Hansaben K.': 'હંસાબેન કે.',
    'Dev Parekh': 'દેવ પારેખ',
    'Mira Joshi': 'મીરા જોશી',
    'Turns 58': '૫૮ વર્ષ પૂર્ણ',
    'Turns 12': '૧૨ વર્ષ પૂર્ણ',
    'Turns 34': '૩૪ વર્ષ પૂર્ણ',
    '2 hours ago • Vadodara': '૨ કલાક પહેલા • વડોદરા',
    '5 hours ago • Karamsad': '૫ કલાક પહેલા • કરમસદ',
    'Yesterday • Anand': 'ગઈકાલે • આણંદ',
    'Home': 'હોમ',
    'Tree': 'વૃક્ષ',
    'Profile': 'પ્રોફાઇલ',
    'Build Profile': 'પ્રોફાઇલ બનાવો',
    'Matrimonial': 'લગ્નવિષયક',
    'Community Posts & News': 'સમાજ સમાચાર અને પોસ્ટ્સ',
    'Logout Session': 'સત્ર બહાર નીકળો',
    'About': 'વિશે',
    'Family': 'પરિવાર',
    'Contributions': 'योगदान',
    'Occupation': 'વ્યવસાય',
    'Education': 'શિક્ષણ',
    'Village': 'ગામ',
    'City': 'શહેર',
    'Blood Group': 'બ્લડ ગ્રુપ',
    'Contact': 'સંપર્ક',
    'Rishik Jariwala': 'રિષિક જરીવાલા',
    'Rajeshbhai Chauhan': 'રાજેશભાઈ ચૌહાણ',
    'Jay Shree Krishna ': 'જય શ્રી કૃષ્ણ ',
  };

  String _translate(String text) {
    if (!_isGujarati) return text;
    if (_translations.containsKey(text)) {
      return _translations[text]!;
    }
    final trimmed = text.trim();
    if (_translations.containsKey(trimmed)) {
      return _translations[trimmed]!;
    }
    return _transliterateToGujarati(text);
  }

  // Stateful list of notifications
  final List<Map<String, String>> _notifications = [
    {
      'id': '1',
      'title': 'New Event Registered',
      'body': 'Samuh Lagna Sammelan registration is now open.',
      'time': 'Just now',
      'icon': 'event'
    },
    {
      'id': '2',
      'title': 'Birthday Today',
      'body': 'Hansaben K. is turning 58 today. Wish her!',
      'time': '2 hours ago',
      'icon': 'cake'
    },
  ];

  bool _hasUnreadNotifications = true;

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

  void _showNotificationsBottomSheet(BuildContext context) {
    setState(() {
      _hasUnreadNotifications = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _translate('Notifications'),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (_notifications.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _notifications.clear();
                              });
                              setModalState(() {});
                            },
                            child: Text(
                              _translate('Clear All'),
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_rounded,
                                  size: 64,
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _translate('No new notifications'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final newNotif = {
                                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                      'title': 'New Announcement',
                                      'body': 'Trust election notice: Voting is mandatory for all heads of family.',
                                      'time': 'Just now',
                                      'icon': 'campaign'
                                    };
                                    setState(() {
                                      _notifications.add(newNotif);
                                    });
                                    setModalState(() {});
                                  },
                                  icon: const Icon(Icons.add_alert_rounded, size: 16),
                                  label: const Text('Add Live Test Notification'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD35400),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                )
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _notifications.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              IconData iconData = Icons.notifications_active;
                              if (item['icon'] == 'event') {
                                iconData = Icons.event_available;
                              } else if (item['icon'] == 'cake') {
                                iconData = Icons.cake_rounded;
                              } else if (item['icon'] == 'campaign') {
                                iconData = Icons.campaign_rounded;
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFFCE4D6),
                                  child: Icon(iconData, color: const Color(0xFFD35400), size: 20),
                                ),
                                title: Text(
                                  _translate(item['title']!),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      _translate(item['body']!),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _translate(item['time']!),
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _notifications.removeAt(index);
                                    });
                                    setModalState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQRCodeDialog(UserModel user, bool isDark) {
    final String displayName = user.surname.isNotEmpty
        ? '${user.fullName} ${user.surname}'
        : user.fullName;
    
    final String qrData = '''
=== KUTUMB SETU PROFILE ===
ID: GDS-2026-0417
Name: $displayName
Occupation: ${user.occupation}
Education: ${user.education}
Village: ${user.nativePlace}
City: ${user.city}, ${user.state}
Blood Group: ${user.bloodGroup}
Contact: ${user.phoneNumber}
''';

    final String qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(qrData)}';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _translate('Digital Community ID'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'GDS-2026-0417',
              style: GoogleFonts.sourceCodePro(
                fontSize: 14,
                color: const Color(0xFFD35400),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Image.network(
                qrUrl,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFD35400)),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Offline QR Cache', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _translate(displayName),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              _translate(user.occupation),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              _translate('Scan this code to view the complete profile details in real-time.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD35400),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _translate('Close'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider) ?? const UserModel(
      id: 'USR001',
      fullName: 'Rajeshbhai',
      email: 'rajesh@example.com',
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
      grandfather: 'Manilalbhai',
      grandmother: 'Maniben',
      nana: 'Nanabhai',
      nani: 'Naniben',
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
                  const MatrimonialHubScreen(),
                  const CommunityFeedScreen(),
                  const ProfileCompletionScreen(),
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
              _translate('Quick actions'),
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
                          _translate('Jay Shree Krishna '),
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
                      _translate(user.fullName.isNotEmpty
                          ? '${user.fullName} ${user.surname}'
                          : 'Rajeshbhai Chauhan'),
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
                  if (!_showLanguageToggle)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showLanguageToggle = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.language_rounded, color: Colors.cyanAccent, size: 20),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isGujarati = !_isGujarati;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 68,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _isGujarati ? const Color(0xFF1B4F72) : Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white70, width: 1.5),
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              left: _isGujarati ? 36.0 : 2.0,
                              right: _isGujarati ? 2.0 : 36.0,
                              top: 2.0,
                              bottom: 2.0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Center(
                                  child: Text(
                                    _isGujarati ? 'GJ' : 'EN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _isGujarati ? const Color(0xFF1B4F72) : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Opacity(
                                    opacity: _isGujarati ? 0.3 : 1.0,
                                    child: const Text('EN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  Opacity(
                                    opacity: _isGujarati ? 1.0 : 0.3,
                                    child: const Text('GJ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showNotificationsBottomSheet(context),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: const Icon(Icons.notifications_rounded, color: Colors.orangeAccent, size: 20),
                        ),
                        if (_hasUnreadNotifications && _notifications.isNotEmpty)
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
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: Colors.amberAccent,
                        size: 20,
                      ),
                    ),
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
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search families, villages, members...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.grey : Colors.grey.shade500,
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
              );
            }
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
              } else if (item['label'] == 'Matrimony') {
                context.push('/matrimonial');
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
                    _translate(item['label']),
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
                _translate('Birthdays today 🎂'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                _translate('See all'),
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
                        _translate(b['name']),
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
                        _translate(b['turns']),
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
                _translate('Recent Samaj News 📰'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                _translate('See all'),
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
                        _translate('Trust election notice'),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _translate('Annual Trust elections will be held on 29th Aug at Community Bhavan, Rajkot.'),
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
                _translate('Upcoming events'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                _translate('See all'),
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
                            _translate(ev['month']!),
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
                            _translate(ev['title']!),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _translate(ev['loc']!),
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
                _translate('Featured families'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                _translate('Explore'),
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
                                _translate(f['members']),
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
                              _translate(f['name']),
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _translate(f['desc']),
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
            _translate('Community at a glance'),
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
                          _translate(st['val']!),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFD35400),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _translate(st['lbl']!),
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

  Future<List<dynamic>> _fetchHomePosts() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/posts'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['posts'] as List<dynamic>;
        }
      }
    } catch (e) {
      print('Error fetching home posts: $e');
    }
    return [];
  }

  // Community Posts & Feed (Image 3)
  Widget _buildCommunityPostsFeed(bool isDark) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchHomePosts(),
      builder: (context, snapshot) {
        // Fallback static posts if database is empty or loading
        final List<Map<String, dynamic>> staticPosts = [
          {
            'init': 'RC',
            'name': 'Rajeshbhai Chauhan',
            'time': '2 hours ago • Vadodara',
            'badge': 'Announcement',
            'txt': 'Jay Shree Krishna to all samaj members! Welcome to our new digital platform KutumbSetu. Connect with family lineage, business directory, and upcoming events seamlessly.',
            'likes': 42,
            'comments': 8,
            'media': null
          },
          {
            'init': 'DC',
            'name': 'Dineshbhai Chauhan',
            'time': '5 hours ago • Karamsad',
            'badge': 'Social Work',
            'txt': 'Our Samaj Blood Donation Camp date has been confirmed for 2nd August at Surat. Requesting all youth members to register and donate blood for this noble cause. 🙏',
            'likes': 68,
            'comments': 14,
            'media': null
          }
        ];

        final List<dynamic> posts = snapshot.hasData && snapshot.data!.isNotEmpty
            ? snapshot.data!
            : staticPosts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _translate('Community Posts & Feed'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    _translate('${posts.length} Posts'),
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
                
                // Extract properties with fallbacks
                final init = p['avatarText'] ?? p['init'] ?? 'U';
                final author = p['authorName'] ?? p['name'] ?? 'User';
                final content = p['content'] ?? p['txt'] ?? '';
                final likesCount = p['likes'] is List ? (p['likes'] as List).length : int.tryParse(p['likes']?.toString() ?? '0') ?? 0;
                final commentsCount = p['comments'] is List ? (p['comments'] as List).length : int.tryParse(p['comments']?.toString() ?? '0') ?? 0;
                
                String time = 'Just now';
                if (p['createdAt'] != null) {
                  try {
                    final dt = DateTime.parse(p['createdAt'].toString());
                    final diff = DateTime.now().difference(dt);
                    if (diff.inMinutes < 60) {
                      time = '${diff.inMinutes} mins ago';
                    } else if (diff.inHours < 24) {
                      time = '${diff.inHours} hours ago';
                    } else {
                      time = '${diff.inDays} days ago';
                    }
                  } catch (_) {}
                } else if (p['time'] != null) {
                  time = p['time'];
                }

                final avatarHex = p['avatarColor'] ?? '#D35400';
                final Color avatarColor = Color(int.parse(avatarHex.replaceFirst('#', '0xFF')));

                final mediaUrl = p['mediaUrl'] != null && p['mediaUrl'].toString().isNotEmpty
                    ? '${ApiConfig.baseUrl.replaceAll('/api', '')}${p['mediaUrl']}'
                    : null;

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
                              backgroundColor: avatarColor,
                              child: Text(
                                init,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _translate(author),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _translate(time),
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
                                p['badge'] ?? 'Samaj',
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
                          content,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                        
                        // Media display if present
                        if (mediaUrl != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              mediaUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Actions row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (p['_id'] != null) {
                                  final user = ref.read(currentUserProvider);
                                  if (user != null) {
                                    await http.post(
                                      Uri.parse('${ApiConfig.baseUrl}/community/posts/${p['_id']}/like'),
                                      headers: {'Content-Type': 'application/json'},
                                      body: jsonEncode({'userId': user.id}),
                                    );
                                    setState(() {});
                                  }
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    p['likes'] is List && ref.watch(currentUserProvider) != null && (p['likes'] as List).contains(ref.watch(currentUserProvider)!.id)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: Colors.pink,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(likesCount.toString(), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 16),
                            const SizedBox(width: 4),
                            Text(commentsCount.toString(), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                if (mediaUrl != null) {
                                  try {
                                    final response = await http.get(Uri.parse(mediaUrl));
                                    if (response.statusCode == 200) {
                                      final tempDir = Directory.systemTemp;
                                      final file = File('${tempDir.path}/shared_image.png');
                                      await file.writeAsBytes(response.bodyBytes);
                                      await Share.shareXFiles([XFile(file.path)], text: "$content\n\nShared via KutumbSetu Community");
                                    } else {
                                      await Share.share("$content\n\nShared via KutumbSetu Community");
                                    }
                                  } catch (e) {
                                    print("Error sharing image: $e");
                                    await Share.share("$content\n\nShared via KutumbSetu Community");
                                  }
                                } else {
                                  await Share.share("$content\n\nShared via KutumbSetu Community");
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.share_outlined, color: Colors.blue, size: 16),
                                  const SizedBox(width: 4),
                                  Text(_translate('Share'), style: GoogleFonts.inter(fontSize: 11, color: Colors.blue)),
                                ],
                              ),
                            ),
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
      },
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
            _translate(title),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _translate('This tab content will be populated in subsequent modules.'),
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
            _buildNavBarCenterButton(isDark),
            _buildNavBarItem(3, Icons.people_alt_rounded, 'Community Hub', isDark),
            _buildNavBarItem(4, Icons.assignment_ind_rounded, 'Build Profile', isDark),
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
              _translate(label),
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

  Widget _buildNavBarCenterButton(bool isDark) {
    final isSelected = _currentIndex == 2;
    final Color selectedCol = const Color(0xFFD35400);
    final Color unselectedCol = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? selectedCol : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.favorite_rounded,
                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _translate('Matrimonial'),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? selectedCol : unselectedCol,
            ),
          ),
        ],
      ),
    );
  }
}
