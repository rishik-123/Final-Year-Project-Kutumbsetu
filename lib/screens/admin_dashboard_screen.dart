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
        content: Text(msg),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 4,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFF1B4F72), const Color(0xFF0D233A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE67E22).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFFE67E22), width: 1.5),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFE67E22), size: 20),
            ),
            const SizedBox(width: 10),
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE67E22),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'MASTER',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Logged in as ${currentUser?.fullName ?? "Administrator"}',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.visibility_rounded, color: Colors.cyanAccent, size: 14),
              label: const Text('User App', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFFE67E22),
          indicatorWeight: 3,
          labelColor: const Color(0xFFE67E22),
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          tabs: [
            Tab(
              icon: const Icon(Icons.how_to_reg_rounded, size: 18),
              text: 'Approvals (${_pendingUsers.length})',
            ),
            Tab(
              icon: const Icon(Icons.mark_email_unread_rounded, size: 18),
              text: 'User Requests (${_postRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.post_add_rounded, size: 18),
              text: 'Upload Post / Reel',
            ),
            Tab(
              icon: const Icon(Icons.favorite_rounded, size: 18),
              text: 'Matrimonial Match Tracker',
            ),
            Tab(
              icon: const Icon(Icons.security_rounded, size: 18),
              text: 'Profile Moderation',
            ),
            Tab(
              icon: const Icon(Icons.pie_chart_rounded, size: 18),
              text: 'Featured Family Analytics',
            ),
            Tab(
              icon: const Icon(Icons.event_available_rounded, size: 18),
              text: 'Broadcast Events',
            ),
          ],
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_rounded, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text(
              'No Pending Approvals',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All community registration requests have been reviewed.',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPendingUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F72), foregroundColor: Colors.white),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
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

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE67E22).withValues(alpha: 0.2),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'M', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE67E22))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('$email ${phone.isNotEmpty ? "• $phone" : ""}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Village / Native: $village', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectUser(userId),
                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                          label: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveUser(userId),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve Access'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
          child: Row(
            children: [
              const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Pending'),
                selected: _postRequestFilter == 'pending',
                onSelected: (val) {
                  if (val) {
                    setState(() => _postRequestFilter = 'pending');
                    _fetchPostRequests();
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Approved'),
                selected: _postRequestFilter == 'approved',
                onSelected: (val) {
                  if (val) {
                    setState(() => _postRequestFilter = 'approved');
                    _fetchPostRequests();
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Rejected'),
                selected: _postRequestFilter == 'rejected',
                onSelected: (val) {
                  if (val) {
                    setState(() => _postRequestFilter = 'rejected');
                    _fetchPostRequests();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingPostRequests
              ? const Center(child: CircularProgressIndicator())
              : _postRequests.isEmpty
                  ? Center(
                      child: Text(
                        'No $_postRequestFilter requests found.',
                        style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
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

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
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
                                            color: const Color(0xFFE67E22),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            purpose,
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: status == 'approved'
                                              ? Colors.green.withValues(alpha: 0.2)
                                              : status == 'rejected'
                                                  ? Colors.red.withValues(alpha: 0.2)
                                                  : Colors.orange.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: status == 'approved'
                                                ? Colors.green
                                                : status == 'rejected'
                                                    ? Colors.red
                                                    : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Submitted by: $userName', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                                  const Divider(),
                                  if (bride.isNotEmpty || groom.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('💍 Marriage: $groom weds $bride', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE67E22))),
                                          if (weddingDate.isNotEmpty) Text('Date: $weddingDate', style: const TextStyle(fontSize: 12)),
                                          if (venue.isNotEmpty) Text('Venue: $venue', style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (birthdayPerson.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('🎂 Birthday: $birthdayPerson ${ageTurning.isNotEmpty ? "• Turns $ageTurning" : ""}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                                    ),
                                  ],
                                  Text(description, style: GoogleFonts.inter(fontSize: 14)),
                                  if (mediaUrl.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
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
                                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
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
                                              backgroundColor: const Color(0xFF2E7D32),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
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
    final titleController = TextEditingController();
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
              Text(
                'Direct Broadcast Post / Reel',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Publish official posts and video reels visible directly on all members\' feeds.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.image, size: 16), SizedBox(width: 4), Text('Photo Post')],
                    ),
                    selected: contentType == 'post',
                    onSelected: (val) => setMediaState(() => contentType = 'post'),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.video_collection, size: 16), SizedBox(width: 4), Text('Video Reel')],
                    ),
                    selected: contentType == 'reel',
                    onSelected: (val) => setMediaState(() => contentType = 'reel'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: contentType == 'post' ? 'Post Content / Announcement' : 'Reel Caption',
                  hintText: 'Enter description, details, or wishes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          pickedFile != null ? Icons.check_circle : (contentType == 'post' ? Icons.add_photo_alternate_rounded : Icons.video_call_rounded),
                          color: pickedFile != null ? Colors.green : const Color(0xFFE67E22),
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pickedFile != null ? 'Media selected: ${pickedFile!.name}' : 'Tap to attach ${contentType == "post" ? "Photo" : "Video"}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: pickedFile != null ? Colors.green : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
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
                  label: const Text('Publish Broadcast to All Users', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1B4F72).withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF1B4F72), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Matrimonial Match Activity Monitor (Read-Only). Showing interest requests sent between community members.',
                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF1B4F72)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _matrimonialRequests.isEmpty
              ? Center(
                  child: Text('No matrimonial requests tracked yet.', style: GoogleFonts.poppins(color: Colors.grey)),
                )
              : RefreshIndicator(
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

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                                child: Text(sender.isNotEmpty ? sender[0] : 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sender, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    if (senderCity.isNotEmpty) Text(senderCity, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, color: Color(0xFFE67E22), size: 20),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: Colors.pink.withValues(alpha: 0.2),
                                child: Text(receiver.isNotEmpty ? receiver[0] : 'R', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(receiver, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    if (receiverCity.isNotEmpty) Text(receiverCity, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'Accepted'
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : status == 'Rejected'
                                          ? Colors.red.withValues(alpha: 0.2)
                                          : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'Accepted' ? Colors.green : status == 'Rejected' ? Colors.red : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
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

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isFlagged ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF1B4F72).withValues(alpha: 0.2),
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty ? Text(name.isNotEmpty ? name[0] : 'M') : null,
              ),
              title: Row(
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (isFlagged) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                      child: const Text('FLAGGED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(phone.isNotEmpty ? phone : 'No phone linked', style: const TextStyle(fontSize: 12)),
              trailing: PopupMenuButton<String>(
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
                    const PopupMenuItem(value: 'flag', child: Row(children: [Icon(Icons.flag_outlined, color: Colors.redAccent, size: 18), SizedBox(width: 8), Text('Flag Profile')]))
                  else
                    const PopupMenuItem(value: 'unflag', child: Row(children: [Icon(Icons.check, color: Colors.green, size: 18), SizedBox(width: 8), Text('Remove Flag')])),
                  const PopupMenuItem(value: 'reset_photo', child: Row(children: [Icon(Icons.no_photography_outlined, color: Colors.orange, size: 18), SizedBox(width: 8), Text('Reset Inappropriate Photo')])),
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
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF1B4F72),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: Colors.amber, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Community Lineage Analytics', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Total Community Members: $_totalMembersCount', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('Data dynamically feeds into User Side "Featured Families".', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Family Surname Distribution (Live Ranking)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._surnameAnalytics.map((item) {
            final name = item['name'] ?? '';
            final count = item['count'] ?? 0;
            final percentage = double.tryParse(item['percentage']?.toString() ?? '0') ?? 0.0;
            final colors = [const Color(0xFFE67E22), const Color(0xFF1B4F72), const Color(0xFF2E7D32), const Color(0xFF8E44AD), const Color(0xFFD35400), Colors.teal];
            final color = colors[name.hashCode % colors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$name Parivar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('$count members ($percentage%)', style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Publish Upcoming Event', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Broadcast mass marriages (Samuh Lagna), sports, camps, and trust notices to all users.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 16),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Event Title (e.g. Samuh Lagna Sammelan 2026)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: ['Samuh Lagna', 'Blood Donation', 'Youth Sports Meet', 'Trust Election', 'Festival', 'General']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => category = val ?? 'General',
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date & Time (e.g. 15th Nov 2026, 09:00 AM)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location / Venue (e.g. Community Hall, Ahmedabad)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description & Registration Details', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
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
                      label: const Text('Publish Event to Community'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F72), foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Active Published Events (${_events.length})', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._events.map((ev) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE67E22), child: Icon(Icons.event, color: Colors.white)),
                  title: Text(ev['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${ev["date"]} • ${ev["location"]}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(ev['category'] ?? 'Event', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
