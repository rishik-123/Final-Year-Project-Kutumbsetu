import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../api_config.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

/// KutumbSetu Admin Panel.
///
/// Same data layer and API calls as the rest of the app — only the visual
/// language changes here, to read as one product with the member-facing
/// screens: saffron / forest / peacock palette, soft 16-20px rounded
/// corners, Poppins headings + Inter body text.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Pending user registrations
  List<dynamic> _pendingUsers = [];
  bool _isLoadingUsers = false;

  // User post/reel/marriage requests
  List<dynamic> _postRequests = [];
  bool _isLoadingPostRequests = false;
  String _postRequestFilter = 'pending'; // 'pending', 'approved', 'rejected'

  // Matrimonial all requests (monitoring)
  List<dynamic> _matrimonialRequests = [];
  bool _isLoadingMatrimonial = false;

  // Profile moderation list
  List<dynamic> _allProfiles = [];
  bool _isLoadingProfiles = false;

  // Surname Analytics
  List<dynamic> _surnameAnalytics = [];
  int _totalMembersCount = 0;
  bool _isLoadingAnalytics = false;

  // Events
  List<dynamic> _events = [];
  bool _isLoadingEvents = false;

  static const List<_AdminTabMeta> _tabMeta = [
    _AdminTabMeta(icon: Icons.how_to_reg_rounded, label: 'Approvals'),
    _AdminTabMeta(icon: Icons.mark_email_unread_rounded, label: 'User Requests'),
    _AdminTabMeta(icon: Icons.post_add_rounded, label: 'Upload Post / Reel'),
    _AdminTabMeta(icon: Icons.favorite_rounded, label: 'Matrimonial Tracker'),
    _AdminTabMeta(icon: Icons.security_rounded, label: 'Profile Moderation'),
    _AdminTabMeta(icon: Icons.pie_chart_rounded, label: 'Family Analytics'),
    _AdminTabMeta(icon: Icons.event_available_rounded, label: 'Broadcast Events'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _refreshCurrentTab();
    });

    _refreshAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshCurrentTab() {
    switch (_selectedTabIndex) {
      case 0:
        _fetchPendingUsers();
        break;
      case 1:
        _fetchPostRequests();
        break;
      case 2:
        _fetchEvents();
        break;
      case 3:
        _fetchMatrimonialRequests();
        break;
      case 4:
        _fetchProfiles();
        break;
      case 5:
        _fetchSurnameAnalytics();
        break;
      case 6:
        _fetchEvents();
        break;
    }
  }

  Future<void> _refreshAllData() async {
    _fetchPendingUsers();
    _fetchPostRequests();
    _fetchMatrimonialRequests();
    _fetchProfiles();
    _fetchSurnameAnalytics();
    _fetchEvents();
  }

  // 1. Fetch Pending Users
  Future<void> _fetchPendingUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/users/pending'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _pendingUsers = data['pendingUsers'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching pending users: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _approveUser(String userId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      if (res.statusCode == 200) {
        _showSuccessSnackBar('Member approved and granted access!');
        _fetchPendingUsers();
        _fetchProfiles();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to approve member.');
    }
  }

  Future<void> _rejectUser(String userId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      if (res.statusCode == 200) {
        _showSuccessSnackBar('Registration request rejected.');
        _fetchPendingUsers();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to reject request.');
    }
  }

  // 2. Fetch Post/Marriage Requests
  Future<void> _fetchPostRequests() async {
    setState(() => _isLoadingPostRequests = true);
    try {
      final url = '${ApiConfig.baseUrl}/admin/post-requests?status=$_postRequestFilter';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _postRequests = data['requests'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching post requests: $e');
    } finally {
      setState(() => _isLoadingPostRequests = false);
    }
  }

  Future<void> _respondToPostRequest(String requestId, String status, {String notes = ''}) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/post-requests/$requestId/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status, 'adminNotes': notes}),
      );
      if (res.statusCode == 200) {
        _showSuccessSnackBar(status == 'approved' ? 'Request approved & published to community!' : 'Request rejected.');
        _fetchPostRequests();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to process request.');
    }
  }

  // 3. Matrimonial Requests Monitoring
  Future<void> _fetchMatrimonialRequests() async {
    setState(() => _isLoadingMatrimonial = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/matrimonial/all-requests'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _matrimonialRequests = data['requests'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching matrimonial requests: $e');
    } finally {
      setState(() => _isLoadingMatrimonial = false);
    }
  }

  // 4. Profiles Moderation
  Future<void> _fetchProfiles() async {
    setState(() => _isLoadingProfiles = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/profiles/all'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _allProfiles = data['profiles'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
    } finally {
      setState(() => _isLoadingProfiles = false);
    }
  }

  Future<void> _moderateProfile(String userId, String action, {String reason = ''}) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/profiles/moderate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'action': action, 'flagReason': reason}),
      );
      if (res.statusCode == 200) {
        _showSuccessSnackBar('Profile moderation action applied.');
        _fetchProfiles();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to apply moderation action.');
    }
  }

  // 5. Surname Analytics
  Future<void> _fetchSurnameAnalytics() async {
    setState(() => _isLoadingAnalytics = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/surname-analytics'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _surnameAnalytics = data['analytics'] ?? [];
            _totalMembersCount = data['totalMembers'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching surname analytics: $e');
    } finally {
      setState(() => _isLoadingAnalytics = false);
    }
  }

  // 6. Events
  Future<void> _fetchEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/events'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _events = data['events'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    } finally {
      setState(() => _isLoadingEvents = false);
    }
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(146),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.forestDeep, const Color(0xFF0E2A10)]
                    : [AppColors.forest, AppColors.forestDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.saffron.withValues(alpha: 0.22),
                            border: Border.all(color: AppColors.saffron, width: 1.5),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.saffron, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'KutumbSetu Admin',
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.saffron,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'MASTER',
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Logged in as ${currentUser?.fullName ?? "Administrator"}',
                                style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.78)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Switch to User App Preview
                        TextButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.visibility_rounded, color: Colors.white, size: 15),
                          label: Text('User App', style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.white.withValues(alpha: 0.14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppColors.saffron,
                    indicatorWeight: 3,
                    labelColor: AppColors.saffron,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.72),
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                    unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
                    tabs: [
                      Tab(icon: const Icon(Icons.how_to_reg_rounded, size: 18), text: 'Approvals (${_pendingUsers.length})'),
                      Tab(icon: const Icon(Icons.mark_email_unread_rounded, size: 18), text: 'User Requests (${_postRequests.length})'),
                      const Tab(icon: Icon(Icons.post_add_rounded, size: 18), text: 'Upload Post / Reel'),
                      const Tab(icon: Icon(Icons.favorite_rounded, size: 18), text: 'Matrimonial Match Tracker'),
                      const Tab(icon: Icon(Icons.security_rounded, size: 18), text: 'Profile Moderation'),
                      const Tab(icon: Icon(Icons.pie_chart_rounded, size: 18), text: 'Featured Family Analytics'),
                      const Tab(icon: Icon(Icons.event_available_rounded, size: 18), text: 'Broadcast Events'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovalsTab(isDark),
          _buildUserRequestsTab(isDark),
          _buildUploadMediaTab(isDark),
          _buildMatrimonialTrackerTab(isDark),
          _buildProfileModerationTab(isDark),
          _buildFamilyAnalyticsTab(isDark),
          _buildBroadcastEventsTab(isDark),
        ],
      ),
    );
  }

  // TAB 1: Member Approvals
  Widget _buildApprovalsTab(bool isDark) {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
    }

    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: AppColors.forestTint, shape: BoxShape.circle),
              child: const Icon(Icons.verified_user_rounded, size: 40, color: AppColors.forest),
            ),
            const SizedBox(height: 18),
            Text('No Pending Approvals', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'All community registration requests have been reviewed.',
              style: GoogleFonts.inter(color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchPendingUsers,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.saffron,
      onRefresh: _fetchPendingUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingUsers.length,
        itemBuilder: (context, index) {
          final u = _pendingUsers[index];
          final String userId = u['_id'] ?? '';
          final String name = u['fullName'] ?? 'Unnamed Member';
          final String email = u['email'] ?? '';
          final String phone = u['phoneNumber'] ?? '';
          final String village = u['nativePlace'] ?? 'Gujarat';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05), blurRadius: 14, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.saffronTint,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.saffronDeep),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15.5)),
                          Text(
                            '$email ${phone.isNotEmpty ? "• $phone" : ""}',
                            style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(999)),
                      child: Text('PENDING', style: GoogleFonts.poppins(color: AppColors.warning, fontSize: 9.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                Divider(height: 26, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight),
                    const SizedBox(width: 5),
                    Text(
                      'Village / Native: $village',
                      style: GoogleFonts.inter(fontSize: 12.5, color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectUser(userId),
                        icon: const Icon(Icons.close, color: AppColors.danger, size: 18),
                        label: Text('Reject', style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveUser(userId),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('Approve Access', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // TAB 2: User Request Review Queue
  Widget _buildUserRequestsTab(bool isDark) {
    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? AppColors.cardDark : AppColors.saffronTint.withValues(alpha: 0.5),
          child: Row(
            children: [
              Text('Filter: ', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Pending',
                selected: _postRequestFilter == 'pending',
                onTap: () {
                  setState(() => _postRequestFilter = 'pending');
                  _fetchPostRequests();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Approved',
                selected: _postRequestFilter == 'approved',
                onTap: () {
                  setState(() => _postRequestFilter = 'approved');
                  _fetchPostRequests();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Rejected',
                selected: _postRequestFilter == 'rejected',
                onTap: () {
                  setState(() => _postRequestFilter = 'rejected');
                  _fetchPostRequests();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingPostRequests
              ? const Center(child: CircularProgressIndicator(color: AppColors.saffron))
              : _postRequests.isEmpty
                  ? Center(
                      child: Text(
                        'No $_postRequestFilter requests found.',
                        style: GoogleFonts.poppins(fontSize: 15, color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.saffron,
                      onRefresh: _fetchPostRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _postRequests.length,
                        itemBuilder: (context, index) {
                          final req = _postRequests[index];
                          final id = req['_id'] ?? '';
                          final userName = req['userName'] ?? 'Member';
                          final purpose = req['purpose'] ?? 'General Post';
                          final contentType = req['contentType'] ?? 'post';
                          final description = req['description'] ?? '';
                          final mediaUrl = req['mediaUrl'] ?? '';
                          final bride = req['brideName'] ?? '';
                          final groom = req['groomName'] ?? '';
                          final weddingDate = req['weddingDate'] ?? '';
                          final venue = req['venue'] ?? '';
                          final birthdayPerson = req['birthdayPersonName'] ?? '';
                          final ageTurning = req['ageTurning'] ?? '';
                          final status = req['status'] ?? 'pending';
                          final statusColor = status == 'approved'
                              ? AppColors.forest
                              : status == 'rejected'
                                  ? AppColors.danger
                                  : AppColors.warning;
                          final statusTint = status == 'approved'
                              ? AppColors.forestTint
                              : status == 'rejected'
                                  ? AppColors.dangerTint
                                  : AppColors.warningTint;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05), blurRadius: 14, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          contentType == 'reel' ? Icons.video_collection_rounded : Icons.article_rounded,
                                          color: AppColors.saffron,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(purpose, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(color: statusTint, borderRadius: BorderRadius.circular(999)),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Submitted by: $userName',
                                    style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight)),
                                Divider(height: 20, color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                                if (bride.isNotEmpty || groom.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(11),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(color: AppColors.saffronTint, borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('💍 Marriage: $groom weds $bride',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.saffronDeep)),
                                        if (weddingDate.isNotEmpty) Text('Date: $weddingDate', style: GoogleFonts.inter(fontSize: 12)),
                                        if (venue.isNotEmpty) Text('Venue: $venue', style: GoogleFonts.inter(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                                if (birthdayPerson.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(11),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(color: AppColors.peacockTint, borderRadius: BorderRadius.circular(12)),
                                    child: Text(
                                      '🎂 Birthday: $birthdayPerson ${ageTurning.isNotEmpty ? "• Turns $ageTurning" : ""}',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.peacockDeep),
                                    ),
                                  ),
                                ],
                                Text(description, style: GoogleFonts.inter(fontSize: 14)),
                                if (mediaUrl.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: mediaUrl.startsWith('http')
                                        ? Image.network(mediaUrl, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox())
                                        : Image.network('${ApiConfig.baseUrl}$mediaUrl', height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox()),
                                  ),
                                ],
                                if (status == 'pending') ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _respondToPostRequest(id, 'rejected'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.danger,
                                            side: const BorderSide(color: AppColors.danger),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _respondToPostRequest(id, 'approved'),
                                          icon: const Icon(Icons.check_circle_outline, size: 18),
                                          label: const Text('Approve & Publish'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.forest,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // TAB 3: Upload Post / Reel Directly
  Widget _buildUploadMediaTab(bool isDark) {
    final descController = TextEditingController();
    String contentType = 'post';
    XFile? pickedFile;

    return StatefulBuilder(
      builder: (context, setMediaState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Direct Broadcast Post / Reel', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Publish official posts and video reels visible directly on all members\' feeds.',
                style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _ChipToggle(
                    icon: Icons.image_rounded,
                    label: 'Photo Post',
                    selected: contentType == 'post',
                    onTap: () => setMediaState(() => contentType = 'post'),
                  ),
                  const SizedBox(width: 10),
                  _ChipToggle(
                    icon: Icons.video_collection_rounded,
                    label: 'Video Reel',
                    selected: contentType == 'reel',
                    onTap: () => setMediaState(() => contentType = 'reel'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: descController,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: contentType == 'post' ? 'Post Content / Announcement' : 'Reel Caption',
                  hintText: 'Enter description, details, or wishes...',
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.saffron, width: 1.4)),
                ),
              ),
              const SizedBox(height: 16),
              // Media Picker
              InkWell(
                onTap: () async {
                  final picker = ImagePicker();
                  final file = contentType == 'post'
                      ? await picker.pickImage(source: ImageSource.gallery)
                      : await picker.pickVideo(source: ImageSource.gallery);
                  if (file != null) {
                    setMediaState(() {
                      pickedFile = file;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 124,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.saffronTint.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: pickedFile != null ? AppColors.forest : AppColors.saffron.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          pickedFile != null ? Icons.check_circle : (contentType == 'post' ? Icons.add_photo_alternate_rounded : Icons.video_call_rounded),
                          color: pickedFile != null ? AppColors.forest : AppColors.saffron,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pickedFile != null ? 'Media selected: ${pickedFile!.name}' : 'Tap to attach ${contentType == "post" ? "Photo" : "Video"}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: pickedFile != null ? AppColors.forest : (isDark ? AppColors.textSoftDark : AppColors.textSoftLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final text = descController.text.trim();
                    if (text.isEmpty) {
                      _showErrorSnackBar('Please enter description or caption.');
                      return;
                    }

                    try {
                      final currentUser = ref.read(currentUserProvider);
                      final url = '${ApiConfig.baseUrl}/community/${contentType == "post" ? "posts" : "reels"}';

                      String mediaBase64 = '';
                      if (pickedFile != null) {
                        final bytes = await pickedFile!.readAsBytes();
                        mediaBase64 = base64Encode(bytes);
                      }

                      final body = contentType == 'post'
                          ? {
                              'authorName': 'Admin Announcement',
                              'content': text,
                              'userId': currentUser?.id ?? '6a7962b212a58c4a0e118cab',
                              if (mediaBase64.isNotEmpty) 'imageBase64': mediaBase64,
                            }
                          : {
                              'authorName': 'Admin Reel',
                              'caption': text,
                              'userId': currentUser?.id ?? '6a7962b212a58c4a0e118cab',
                              if (mediaBase64.isNotEmpty) 'videoBase64': mediaBase64,
                            };

                      final res = await http.post(
                        Uri.parse(url),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(body),
                      );

                      if (res.statusCode == 200 || res.statusCode == 201) {
                        _showSuccessSnackBar('Broadcast ${contentType.toUpperCase()} uploaded successfully!');
                        descController.clear();
                        setMediaState(() => pickedFile = null);
                      } else {
                        _showErrorSnackBar('Failed to broadcast.');
                      }
                    } catch (e) {
                      _showErrorSnackBar('Error broadcasting media: $e');
                    }
                  },
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: Text('Publish Broadcast to All Users', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffron,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 4: Matrimonial Match Monitoring
  Widget _buildMatrimonialTrackerTab(bool isDark) {
    if (_isLoadingMatrimonial) {
      return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: AppColors.peacockTint.withValues(alpha: isDark ? 0.15 : 1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.peacock, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Matrimonial Match Activity Monitor (Read-Only). Showing interest requests sent between community members.',
                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : AppColors.peacockDeep),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _matrimonialRequests.isEmpty
              ? Center(
                  child: Text('No matrimonial requests tracked yet.',
                      style: GoogleFonts.poppins(color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight)),
                )
              : RefreshIndicator(
                  color: AppColors.saffron,
                  onRefresh: _fetchMatrimonialRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _matrimonialRequests.length,
                    itemBuilder: (context, index) {
                      final item = _matrimonialRequests[index];
                      final sender = item['senderName'] ?? 'Member';
                      final senderCity = item['senderCity'] ?? '';
                      final receiver = item['receiverName'] ?? 'Member';
                      final receiverCity = item['receiverCity'] ?? '';
                      final status = item['status'] ?? 'Pending';
                      final statusColor = status == 'Accepted' ? AppColors.forest : status == 'Rejected' ? AppColors.danger : AppColors.warning;
                      final statusTint = status == 'Accepted' ? AppColors.forestTint : status == 'Rejected' ? AppColors.dangerTint : AppColors.warningTint;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.peacockTint,
                              child: Text(sender.isNotEmpty ? sender[0] : 'S', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.peacockDeep)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sender, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                                  if (senderCity.isNotEmpty)
                                    Text(senderCity, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.saffron, size: 20),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: AppColors.saffronTint,
                              child: Text(receiver.isNotEmpty ? receiver[0] : 'R', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.saffronDeep)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(receiver, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                                  if (receiverCity.isNotEmpty)
                                    Text(receiverCity, style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(color: statusTint, borderRadius: BorderRadius.circular(999)),
                              child: Text(status, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w800, color: statusColor)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // TAB 5: Profile Moderation
  Widget _buildProfileModerationTab(bool isDark) {
    if (_isLoadingProfiles) {
      return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
    }

    return RefreshIndicator(
      color: AppColors.saffron,
      onRefresh: _fetchProfiles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allProfiles.length,
        itemBuilder: (context, index) {
          final p = _allProfiles[index];
          final id = p['id'] ?? '';
          final name = p['fullName'] ?? 'Member';
          final phone = p['phone'] ?? '';
          final isFlagged = p['isFlagged'] == true;
          final avatarUrl = p['avatarUrl'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isFlagged ? AppColors.danger.withValues(alpha: 0.4) : (isDark ? AppColors.dividerDark : AppColors.dividerLight)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: isFlagged ? AppColors.dangerTint : AppColors.forestTint,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(name.isNotEmpty ? name[0] : 'M', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: isFlagged ? AppColors.danger : AppColors.forest))
                    : null,
              ),
              title: Row(
                children: [
                  Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  if (isFlagged) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                      child: Text('FLAGGED', style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(phone.isNotEmpty ? phone : 'No phone linked',
                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight)),
              trailing: PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (action) {
                  if (action == 'flag') {
                    _moderateProfile(id, 'flag', reason: 'Flagged by admin for investigation');
                  } else if (action == 'unflag') {
                    _moderateProfile(id, 'unflag');
                  } else if (action == 'reset_photo') {
                    _moderateProfile(id, 'reset_photo');
                  }
                },
                itemBuilder: (context) => [
                  if (!isFlagged)
                    PopupMenuItem(
                      value: 'flag',
                      child: Row(children: [const Icon(Icons.flag_outlined, color: AppColors.danger, size: 18), const SizedBox(width: 8), Text('Flag Profile', style: GoogleFonts.inter())]),
                    )
                  else
                    PopupMenuItem(
                      value: 'unflag',
                      child: Row(children: [const Icon(Icons.check, color: AppColors.forest, size: 18), const SizedBox(width: 8), Text('Remove Flag', style: GoogleFonts.inter())]),
                    ),
                  PopupMenuItem(
                    value: 'reset_photo',
                    child: Row(children: [const Icon(Icons.no_photography_outlined, color: AppColors.warning, size: 18), const SizedBox(width: 8), Text('Reset Inappropriate Photo', style: GoogleFonts.inter())]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // TAB 6: Featured Family & Surname Analytics
  Widget _buildFamilyAnalyticsTab(bool isDark) {
    if (_isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.forest, AppColors.forestDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.analytics_rounded, color: AppColors.saffron, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Community Lineage Analytics', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('Total Community Members: $_totalMembersCount', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Data dynamically feeds into User Side "Featured Families".',
                          style: GoogleFonts.inter(color: AppColors.saffronTint, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Family Surname Distribution (Live Ranking)', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ..._surnameAnalytics.map((item) {
            final name = item['name'] ?? '';
            final count = item['count'] ?? 0;
            final percentage = double.tryParse(item['percentage']?.toString() ?? '0') ?? 0.0;
            const colors = [AppColors.saffron, AppColors.peacock, AppColors.forest, AppColors.gold, Color(0xFF8E44AD), Color(0xFF00897B)];
            final color = colors[name.hashCode % colors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$name Parivar', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('$count members ($percentage%)', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: color, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 9,
                      backgroundColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // TAB 7: Broadcast Events & News
  Widget _buildBroadcastEventsTab(bool isDark) {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final dateController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Samuh Lagna';

    InputDecoration decoration(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.saffron, width: 1.4)),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Publish Upcoming Event', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Broadcast mass marriages (Samuh Lagna), sports, camps, and trust notices to all users.',
                    style: GoogleFonts.inter(color: isDark ? AppColors.textSoftDark : AppColors.textSoftLight, fontSize: 12.5)),
                const SizedBox(height: 18),
                TextField(controller: titleController, style: GoogleFonts.inter(fontSize: 14), decoration: decoration('Event Title (e.g. Samuh Lagna Sammelan 2026)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  style: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.textDark : AppColors.textLight),
                  decoration: decoration('Category'),
                  items: ['Samuh Lagna', 'Blood Donation', 'Youth Sports Meet', 'Trust Election', 'Festival', 'General']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => category = val ?? 'General',
                ),
                const SizedBox(height: 12),
                TextField(controller: dateController, style: GoogleFonts.inter(fontSize: 14), decoration: decoration('Date & Time (e.g. 15th Nov 2026, 09:00 AM)')),
                const SizedBox(height: 12),
                TextField(controller: locationController, style: GoogleFonts.inter(fontSize: 14), decoration: decoration('Location / Venue (e.g. Community Hall, Ahmedabad)')),
                const SizedBox(height: 12),
                TextField(controller: descController, maxLines: 3, style: GoogleFonts.inter(fontSize: 14), decoration: decoration('Description & Registration Details')),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (titleController.text.isEmpty || dateController.text.isEmpty || locationController.text.isEmpty || descController.text.isEmpty) {
                        _showErrorSnackBar('Please fill in all event fields.');
                        return;
                      }

                      try {
                        final res = await http.post(
                          Uri.parse('${ApiConfig.baseUrl}/admin/events'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'title': titleController.text.trim(),
                            'category': category,
                            'date': dateController.text.trim(),
                            'location': locationController.text.trim(),
                            'description': descController.text.trim(),
                            'bannerUrl': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800',
                          }),
                        );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          _showSuccessSnackBar('Event published successfully to all users!');
                          titleController.clear();
                          dateController.clear();
                          locationController.clear();
                          descController.clear();
                          _fetchEvents();
                        }
                      } catch (e) {
                        _showErrorSnackBar('Failed to publish event.');
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: Text('Publish Event to Community', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('Active Published Events (${_events.length})', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ..._events.map((ev) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04), blurRadius: 8)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: const CircleAvatar(backgroundColor: AppColors.saffron, child: Icon(Icons.event, color: Colors.white)),
                  title: Text(ev['title'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  subtitle: Text('${ev["date"]} • ${ev["location"]}', style: GoogleFonts.inter(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.forestTint, borderRadius: BorderRadius.circular(999)),
                    child: Text(ev['category'] ?? 'Event', style: GoogleFonts.poppins(color: AppColors.forest, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _AdminTabMeta {
  final IconData icon;
  final String label;
  const _AdminTabMeta({required this.icon, required this.label});
}

/// Pill-style filter chip used in the User Requests tab, styled to match
/// the rest of the app's chip language instead of the stock ChoiceChip.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.saffron : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.saffron : Theme.of(context).dividerColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

/// Two-way toggle chip (Photo Post / Video Reel) used in the Upload tab.
class _ChipToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipToggle({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.saffronTint : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.saffron : Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.saffronDeep : Theme.of(context).textTheme.bodyMedium?.color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.saffronDeep : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
