import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/member_providers.dart';
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
  final ScrollController _birthdayScrollController = ScrollController();
  int _activeNewsIndex = 0;
  Timer? _approvalPollTimer;

  // Dynamic Home Feed Data
  List<dynamic> _dynamicBirthdays = [];
  List<dynamic> _dynamicEvents = [];
  List<dynamic> _dynamicFeaturedFamilies = [];
  int _communityTotalMembers = 1240;
  bool _checkedMatrimonialAlerts = false;
  bool _checkedDirectoryAlerts = false;
  bool _checkedAcceptedAlerts = false;

  @override
  void initState() {
    super.initState();
    _fetchHomeDynamicData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _birthdayScrollController.hasClients) {
          final maxScroll = _birthdayScrollController.position.maxScrollExtent;
          if (maxScroll > 0) {
            _birthdayScrollController.animateTo(
              maxScroll,
              duration: const Duration(seconds: 10),
              curve: Curves.linear,
            );
          }
        }
      });

      final user = ref.read(currentUserProvider);
      if (user != null) {
        // Load directory connection state from backend
        ref.read(directoryConnectionProvider.notifier).loadUserConnections(user.id.isNotEmpty ? user.id : user.email);

        // Check for incoming matrimonial interest alerts on login
        if (!_checkedMatrimonialAlerts) {
          _checkedMatrimonialAlerts = true;
          _checkIncomingMatrimonialAlerts(user);
        }

        // Check for incoming connect / follow requests on login (Approval Dialog)
        if (!_checkedDirectoryAlerts) {
          _checkedDirectoryAlerts = true;
          _checkIncomingDirectoryRequests(user);
        }

        // Check for accepted requests on login (Celebration Dialog)
        if (!_checkedAcceptedAlerts) {
          _checkedAcceptedAlerts = true;
          _checkAcceptedDirectoryAlerts(user);
        }
      }
    });
  }

  Future<void> _fetchHomeDynamicData() async {
    try {
      // 1. Fetch Dynamic Birthdays
      final bdayRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/birthdays'));
      if (bdayRes.statusCode == 200) {
        final bdayData = jsonDecode(bdayRes.body);
        if (bdayData['success'] == true && mounted) {
          setState(() {
            _dynamicBirthdays = bdayData['birthdays'] ?? [];
          });
        }
      }

      // 2. Fetch Dynamic Events
      final evRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/events'));
      if (evRes.statusCode == 200) {
        final evData = jsonDecode(evRes.body);
        if (evData['success'] == true && mounted) {
          setState(() {
            _dynamicEvents = evData['events'] ?? [];
          });
        }
      }

      // 3. Fetch Surname Analytics & Featured Families
      final snRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/surname-analytics'));
      if (snRes.statusCode == 200) {
        final snData = jsonDecode(snRes.body);
        if (snData['success'] == true && mounted) {
          setState(() {
            _dynamicFeaturedFamilies = snData['featuredFamilies'] ?? [];
            _communityTotalMembers = snData['totalMembers'] ?? 1240;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dynamic home feeds: $e');
    }
  }

  Future<void> _checkIncomingMatrimonialAlerts(UserModel user) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/matrimonial/incoming-alerts/${user.id}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['alerts'] != null) {
          final List alerts = data['alerts'];
          if (alerts.isNotEmpty && mounted) {
            final first = alerts.first;
            _showIncomingInterestDialog(first);
          }
        }
      }
    } catch (_) {}
  }

  void _showIncomingInterestDialog(Map<String, dynamic> alert) {
    final reqId = alert['requestId'] ?? '';
    final senderName = alert['senderName'] ?? 'A member';
    final senderOccupation = alert['senderOccupation'] ?? '';
    final senderCity = alert['senderCity'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Color(0xFFE67E22), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New Match Request!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$senderName has requested to connect with you for Matrimonial purposes.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (senderOccupation.isNotEmpty || senderCity.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$senderOccupation ${senderCity.isNotEmpty ? "• $senderCity" : ""}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE67E22)),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Accepting will unlock full contact details, WhatsApp, and call features for both of you.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/matrimonial/request/respond'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'requestId': reqId, 'status': 'Rejected'}),
                );
              } catch (_) {}
            },
            child: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/matrimonial/request/respond'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'requestId': reqId, 'status': 'Accepted'}),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You are now connected with $senderName! Details unlocked.'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                }
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Accept Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkIncomingDirectoryRequests(UserModel user) async {
    try {
      final targetId = user.email.isNotEmpty ? user.email : user.id;
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/directory/incoming-alerts/$targetId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['alerts'] != null) {
          final List alerts = data['alerts'];
          if (alerts.isNotEmpty && mounted) {
            final first = alerts.first;
            _showIncomingDirectoryRequestDialog(first, user);
          }
        }
      }
    } catch (_) {}
  }

  void _showIncomingDirectoryRequestDialog(Map<String, dynamic> alert, UserModel user) {
    final reqId = alert['requestId'] ?? '';
    final senderName = alert['senderName'] ?? 'A member';
    final senderOccupation = alert['senderOccupation'] ?? '';
    final senderCity = alert['senderCity'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFE67E22), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New Connect Request!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$senderName has requested to connect with you on KutumbSetu.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 10),
            if (senderOccupation.isNotEmpty || senderCity.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$senderOccupation ${senderCity.isNotEmpty ? "• $senderCity" : ""}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE67E22)),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Approving will unlock full contact details, phone number, and allow direct connection with each other.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/directory/respond'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'requestId': reqId, 'status': 'rejected'}),
                );
              } catch (_) {}
            },
            child: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/directory/respond'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'requestId': reqId, 'status': 'accepted'}),
                );
                ref.read(directoryConnectionProvider.notifier).loadUserConnections(user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You approved $senderName\'s request! Details unlocked.'),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Approve & Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAcceptedDirectoryAlerts(UserModel user) async {
    try {
      final targetId = user.email.isNotEmpty ? user.email : user.id;
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/directory/accepted-alerts/$targetId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['alerts'] != null) {
          final List alerts = data['alerts'];
          if (alerts.isNotEmpty && mounted) {
            final first = alerts.first;
            _showAcceptedDirectoryDialog(first, user);
          }
        }
      }
    } catch (_) {}
  }

  void _showAcceptedDirectoryDialog(Map<String, dynamic> alert, UserModel user) {
    final reqId = alert['requestId'] ?? '';
    final receiverName = alert['receiverName'] ?? 'A member';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: Color(0xFF2E7D32), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Request Accepted! 🎉',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$receiverName has approved your connect request!',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
              ),
              child: Text(
                'You can now view $receiverName\'s complete contact number, address, and profile in the Member Directory.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF2E7D32)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/directory/acknowledge-accepted'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'requestId': reqId}),
                );
                ref.read(directoryConnectionProvider.notifier).loadUserConnections(user.id);
              } catch (_) {}
              setState(() {
                _currentIndex = 1; // Jump to Directory tab
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View in Directory'),
          ),
        ],
      ),
    );
  }

  void _startApprovalPollingIfNeeded(UserModel? user) {
    if (user == null || user.role == 'admin' || user.isApproved) {
      _approvalPollTimer?.cancel();
      _approvalPollTimer = null;
      return;
    }
    if (_approvalPollTimer != null) return;

    _approvalPollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) return;
      final identifier = (user.email != null && user.email!.isNotEmpty)
          ? user.email
          : user.phoneNumber;
      if (identifier == null || identifier.isEmpty) return;

      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/users/profile/$identifier'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['user'] != null) {
            final updatedUser = UserModel.fromJson(data['user']);
            if (updatedUser.isApproved) {
              _approvalPollTimer?.cancel();
              _approvalPollTimer = null;
              if (mounted) {
                ref.read(currentUserProvider.notifier).state = updatedUser;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error polling user approval status: $e');
      }
    });
  }

  @override
  void dispose() {
    _approvalPollTimer?.cancel();
    _newsPageController.dispose();
    _birthdayScrollController.dispose();
    super.dispose();
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
    ref.listen<UserModel?>(currentUserProvider, (prev, next) {
      if (next != null) {
        final uid = next.email.isNotEmpty ? next.email : next.id;
        ref.read(directoryConnectionProvider.notifier).loadUserConnections(uid);
        _checkIncomingDirectoryRequests(next);
        _checkAcceptedDirectoryAlerts(next);
      }
    });

    final realUser = ref.watch(currentUserProvider);
    if (realUser != null && !_checkedDirectoryAlerts) {
      _checkedDirectoryAlerts = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIncomingDirectoryRequests(realUser);
        _checkAcceptedDirectoryAlerts(realUser);
      });
    }

    final user = realUser ?? const UserModel(
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
    _startApprovalPollingIfNeeded(user);

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

    // If user is not admin and not approved, block navigation
    if (user.role != 'admin' && !user.isApproved) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: bgGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 80,
                    color: Color(0xFFE67E22),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Request Sent to Admin!',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You will be able to navigate the app once the Admin accepts your request.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(currentUserProvider.notifier).state = null;
                      context.go('/');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Back to Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
            _buildBottomNavBar(isDark, user),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: HOME FEED TAB ---
  Widget _buildHomeFeedTab(UserModel user, bool isDark) {
    final isAdminUser = user.isAdmin || user.role == 'admin';

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
          const SizedBox(height: 16),

          // 3. User "Send Request to Admin" Card
          _buildSendRequestToAdminCard(isDark),
          const SizedBox(height: 20),

          // 4. Birthdays Today
          _buildBirthdaysToday(isDark),
          const SizedBox(height: 20),

          // 5. Recent Samaj News
          _buildRecentSamajNews(isDark),
          const SizedBox(height: 20),

          // 6. Upcoming Events
          _buildUpcomingEvents(isDark),
          const SizedBox(height: 20),

          // 7. Featured Families
          _buildFeaturedFamilies(isDark),
          const SizedBox(height: 20),

          // 8. Community at a Glance
          _buildCommunityAtGlance(isDark),
          const SizedBox(height: 20),

          // 9. Community Posts & Feed
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
                              width: 28.0,
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

  // --- SEND REQUEST TO ADMIN MODAL ---
  void _showSendRequestToAdminModal(BuildContext context) {
    final user = ref.read(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    final descController = TextEditingController();
    final brideController = TextEditingController();
    final groomController = TextEditingController();
    final dateController = TextEditingController();
    final venueController = TextEditingController();
    final bdayPersonController = TextEditingController();
    final ageController = TextEditingController();

    String selectedPurpose = 'General Post';
    String contentType = 'post';
    XFile? attachedMedia;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.send_and_archive_rounded, color: Color(0xFFE67E22), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Send Request to Admin',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Submit your post, video reel, wedding announcement, or birthday wish for Admin approval before public broadcast.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 20),
                  
                  // Purpose dropdown
                  DropdownButtonFormField<String>(
                    value: selectedPurpose,
                    decoration: const InputDecoration(
                      labelText: 'Purpose of Request',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'General Post',
                      'Marriage Announcement',
                      'Birthday Wish',
                      'Samaj News / Event',
                      'Achievement',
                    ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedPurpose = val ?? 'General Post';
                        if (selectedPurpose == 'Marriage Announcement') {
                          contentType = 'post';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Format selection: Post or Reel
                  Row(
                    children: [
                      const Text('Format: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Post (Image/Text)'),
                        selected: contentType == 'post',
                        onSelected: (val) => setModalState(() => contentType = 'post'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Reel (Video)'),
                        selected: contentType == 'reel',
                        onSelected: (val) => setModalState(() => contentType = 'reel'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Your Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // Conditional Marriage Fields
                  if (selectedPurpose == 'Marriage Announcement') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE67E22).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.favorite, color: Color(0xFFE67E22), size: 18),
                              SizedBox(width: 6),
                              Text('Wedding Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE67E22))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(controller: groomController, decoration: const InputDecoration(labelText: 'Groom\'s Name', border: OutlineInputBorder())),
                          const SizedBox(height: 10),
                          TextField(controller: brideController, decoration: const InputDecoration(labelText: 'Bride\'s Name', border: OutlineInputBorder())),
                          const SizedBox(height: 10),
                          TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Wedding Date (e.g. 15 Dec 2026)', border: OutlineInputBorder())),
                          const SizedBox(height: 10),
                          TextField(controller: venueController, decoration: const InputDecoration(labelText: 'Venue / City', border: OutlineInputBorder())),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Conditional Birthday Fields
                  if (selectedPurpose == 'Birthday Wish') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.cake_rounded, color: Colors.purple, size: 18),
                              SizedBox(width: 6),
                              Text('Birthday Celebration Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(controller: bdayPersonController, decoration: const InputDecoration(labelText: 'Birthday Person Name', border: OutlineInputBorder())),
                          const SizedBox(height: 10),
                          TextField(controller: ageController, decoration: const InputDecoration(labelText: 'Age / Milestone (Optional, e.g. 25)', border: OutlineInputBorder())),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description / Message to Admin & Samaj', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // Media attachment
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file = contentType == 'post'
                          ? await picker.pickImage(source: ImageSource.gallery)
                          : await picker.pickVideo(source: ImageSource.gallery);
                      if (file != null) {
                        setModalState(() => attachedMedia = file);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            attachedMedia != null ? Icons.check_circle : (contentType == 'post' ? Icons.add_photo_alternate : Icons.video_call),
                            color: attachedMedia != null ? Colors.green : const Color(0xFFE67E22),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              attachedMedia != null ? 'Attached: ${attachedMedia!.name}' : 'Attach ${contentType == "post" ? "Photo" : "Video"} (Optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: attachedMedia != null ? Colors.green : Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (descController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a description for your request.')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                String mediaBase64 = '';
                                if (attachedMedia != null) {
                                  final bytes = await attachedMedia!.readAsBytes();
                                  mediaBase64 = base64Encode(bytes);
                                }

                                final body = {
                                  'userId': user?.id ?? '6a7962b212a58c4a0e118cab',
                                  'userName': nameController.text.trim(),
                                  'userPhone': phoneController.text.trim(),
                                  'purpose': selectedPurpose,
                                  'contentType': contentType,
                                  'description': descController.text.trim(),
                                  if (mediaBase64.isNotEmpty) 'mediaBase64': mediaBase64,
                                  'brideName': brideController.text.trim(),
                                  'groomName': groomController.text.trim(),
                                  'weddingDate': dateController.text.trim(),
                                  'venue': venueController.text.trim(),
                                  'birthdayPersonName': bdayPersonController.text.trim(),
                                  'ageTurning': ageController.text.trim(),
                                };

                                final res = await http.post(
                                  Uri.parse('${ApiConfig.baseUrl}/admin/post-requests'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode(body),
                                );

                                if (ctx.mounted) Navigator.pop(ctx);

                                if (res.statusCode == 201 || res.statusCode == 200) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Your request has been submitted to Admin! It will appear once approved.'),
                                        backgroundColor: Color(0xFF2E7D32),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to submit request. Please try again.')),
                                    );
                                  }
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Request to Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- PROMINENT "SEND REQUEST TO ADMIN" CARD ---
  Widget _buildSendRequestToAdminCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE67E22), Color(0xFFD35400)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE67E22).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Want to Post or Announce?',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'Submit wedding, birthday wish, post or reel to Admin.',
                    style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showSendRequestToAdminModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD35400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Send Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // Birthdays Today (Dynamic)
  Widget _buildBirthdaysToday(bool isDark) {
    if (_dynamicBirthdays.isEmpty) {
      return const SizedBox.shrink();
    }

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
              GestureDetector(
                onTap: () => _showSendRequestToAdminModal(context),
                child: Text(
                  '+ Wish Someone',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD35400),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.builder(
            controller: _birthdayScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: _dynamicBirthdays.length,
            itemBuilder: (context, index) {
              final b = _dynamicBirthdays[index];
              final name = b['name'] ?? 'Member';
              final turns = b['ageText'] ?? 'Celebration 🎂';
              final photoUrl = b['photoUrl'] ?? '';
              final colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.teal];
              final color = colors[index % colors.length];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: color,
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _translate(name),
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
                        _translate(turns),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  // Recent Samaj News (Dynamic)
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
              GestureDetector(
                onTap: () => _showSendRequestToAdminModal(context),
                child: Text(
                  _translate('See all'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD35400),
                  ),
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
      ],
    );
  }

  // Upcoming Events (Dynamic from Admin)
  Widget _buildUpcomingEvents(bool isDark) {
    final eventsToDisplay = _dynamicEvents.isNotEmpty ? _dynamicEvents : [
      {'date': '15 Nov 2026', 'title': 'Samuh Lagna Sammelan', 'location': 'Community Hall, Ahmedabad'},
      {'date': '02 Aug 2026', 'title': 'Blood Donation Camp', 'location': 'Darji Samaj Bhavan, Surat'},
      {'date': '28 Sep 2026', 'title': 'Youth Sports Meet', 'location': 'Rajkot Ground No. 3'},
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
              GestureDetector(
                onTap: () => context.push('/matrimonial/events'),
                child: Text(
                  _translate('See all'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD35400),
                  ),
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
              itemCount: eventsToDisplay.length.clamp(0, 4),
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final ev = eventsToDisplay[index];
                final dateStr = (ev['date'] ?? 'Upcoming').toString();
                final parts = dateStr.split(' ');
                final day = parts.isNotEmpty ? parts[0] : '15';
                final month = parts.length > 1 ? parts[1].toUpperCase() : 'EVENT';

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
                            day,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF16A34A),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            month,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF16A34A),
                              fontSize: 8.5,
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
                            _translate(ev['title'] ?? ''),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _translate(ev['location'] ?? ''),
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

  // Featured Families (Dynamic from Live Surname Analytics)
  Widget _buildFeaturedFamilies(bool isDark) {
    final familiesToDisplay = _dynamicFeaturedFamilies.isNotEmpty
        ? _dynamicFeaturedFamilies
        : [
            {'parivarName': 'Shah Parivar', 'locationInfo': 'Vadodara - 6 gen.', 'memberCount': '420 members', 'colorHex': '#E67E22'},
            {'parivarName': 'Patel Parivar', 'locationInfo': 'Surat - 5 gen.', 'memberCount': '360 members', 'colorHex': '#1B4F72'},
            {'parivarName': 'Chauhan Parivar', 'locationInfo': 'Rajkot - 4 gen.', 'memberCount': '285 members', 'colorHex': '#2E7D32'},
            {'parivarName': 'Parekh Parivar', 'locationInfo': 'Ahmedabad - 5 gen.', 'memberCount': '210 members', 'colorHex': '#8E44AD'},
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
              GestureDetector(
                onTap: () => context.push('/directory'),
                child: Text(
                  _translate('Explore'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD35400),
                  ),
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
            itemCount: familiesToDisplay.length,
            itemBuilder: (context, index) {
              final f = familiesToDisplay[index];
              final String hexStr = f['colorHex'] ?? '#E67E22';
              final color = Color(int.parse(hexStr.replaceFirst('#', '0xFF')));

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
                      Container(
                        height: 70,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: color,
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
                                _translate(f['memberCount'] ?? '100+ members'),
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
                              _translate(f['parivarName'] ?? 'Parivar'),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _translate(f['locationInfo'] ?? 'Gujarat'),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  // Community at a Glance (Dynamic)
  Widget _buildCommunityAtGlance(bool isDark) {
    final List<Map<String, String>> stats = [
      {'val': '$_communityTotalMembers', 'lbl': 'Families'},
      {'val': '${(_communityTotalMembers * 3.5).toInt()}', 'lbl': 'Members'},
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
                                final shareLink = "${ApiConfig.baseUrl.replaceAll('/api', '')}/share/post/${p['_id']}";
                                final shareText = "$content\n\nView post: $shareLink";
                                if (mediaUrl != null) {
                                  try {
                                    final response = await http.get(Uri.parse(mediaUrl));
                                    if (response.statusCode == 200) {
                                      final tempDir = Directory.systemTemp;
                                      final file = File('${tempDir.path}/shared_image.png');
                                      await file.writeAsBytes(response.bodyBytes);
                                      await Share.shareXFiles([XFile(file.path)], text: shareText);
                                    } else {
                                      await Share.share(shareText);
                                    }
                                  } catch (e) {
                                    print("Error sharing image: $e");
                                    await Share.share(shareText);
                                  }
                                } else {
                                  await Share.share(shareText);
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
  Widget _buildBottomNavBar(bool isDark, UserModel user) {
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
