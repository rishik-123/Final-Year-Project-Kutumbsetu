import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../constants/app_colors.dart';
import '../models/member_model.dart';
import '../providers/member_providers.dart';
import '../widgets/profile_action_button.dart';
import '../community/community_feed.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  final String memberId;
  final Member? member;

  const MemberProfileScreen({
    super.key,
    required this.memberId,
    this.member,
  });

  @override
  ConsumerState<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  List<dynamic> _posts = [];
  List<dynamic> _reels = [];
  bool _isLoadingContent = true;

  @override
  void initState() {
    super.initState();
    _fetchUserContent();
  }

  Future<void> _fetchUserContent() async {
    if (!mounted) return;
    setState(() => _isLoadingContent = true);
    try {
      final postsRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/posts/user/${widget.memberId}'));
      final reelsRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/reels/user/${widget.memberId}'));
      
      if (postsRes.statusCode == 200 && reelsRes.statusCode == 200) {
        final postsData = jsonDecode(postsRes.body);
        final reelsData = jsonDecode(reelsRes.body);
        if (mounted) {
          setState(() {
            _posts = postsData['posts'] ?? [];
            _reels = reelsData['reels'] ?? [];
            _isLoadingContent = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingContent = false);
      }
    } catch (e) {
      print('Error fetching user content: $e');
      if (mounted) setState(() => _isLoadingContent = false);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _makeCall(BuildContext context, String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(' ', ''));
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        _showSnackBar(context, 'Could not launch dialer for $phoneNumber');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Could not call: $e');
    }
  }

  Future<void> _sendMessage(BuildContext context, Member member) async {
    String cleanPhone = member.mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }
    final String messageText = 'Jay Shree Krishna ${member.fullName}, connecting via KutumbSetu!';
    final Uri waUri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(messageText)}');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: member.mobileNumber,
      queryParameters: {'body': messageText},
    );

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (!context.mounted) return;
        _showSnackBar(context, 'Could not open WhatsApp or SMS for ${member.fullName}');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Could not initiate message: $e');
    }
  }

  Future<void> _shareProfile(BuildContext context, Member member) async {
    final String shareText = '''
=== KutumbSetu Member Profile ===
Name: ${member.fullName}
Profession: ${member.profession}
Location: ${member.fullLocation}
Blood Group: ${member.bloodGroup}
Contact: ${member.mobileNumber}
''';
    try {
      await Share.share(shareText);
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Sharing failed: $e');
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        _showSnackBar(context, 'Could not launch email client for $email');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Could not email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = ref.watch(favoriteMemberIdsProvider);

    // Resolve member model from extra parameter or raw list provider
    final Member? m = widget.member ??
        ref.watch(rawMemberListProvider).asData?.value.firstWhere(
              (element) => element.id == widget.memberId,
              orElse: () => const Member(
                id: '',
                fullName: 'Unknown Member',
                initials: 'UM',
                gender: 'Male',
                mobileNumber: '',
                email: '',
                village: '',
                city: '',
                district: '',
                state: 'Gujarat',
                profession: '',
                company: '',
                education: '',
                bloodGroup: '',
                age: 0,
                maritalStatus: '',
                businessCategory: '',
                skills: [],
                languages: [],
                avatarUrl: '',
                joinedDate: '',
                isVerified: false,
                isActive: true,
              ),
            );

    if (m == null || m.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Profile')),
        body: const Center(child: Text('Member profile not found')),
      );
    }

    final isFavorite = favorites.contains(m.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar with Hero Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.favoriteRed : Colors.white,
                ),
                onPressed: () {
                  ref
                      .read(favoriteMemberIdsProvider.notifier)
                      .toggleFavorite(m.id);
                  _showSnackBar(
                    context,
                    isFavorite
                        ? '${m.fullName} removed from favorites'
                        : '${m.fullName} added to favorites',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareProfile(context, m),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.headerGradientDark
                      : AppColors.headerGradientLight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),

                    // Avatar with Hero transition
                    Hero(
                      tag: 'avatar_${m.id}',
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.avatarGradient,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            m.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Member Full Name & Verified Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            m.fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (m.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Colors.lightBlueAccent,
                            size: 22,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      '${m.profession} • ${m.company}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          m.fullLocation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Profile Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Action Toolbar (Call, WhatsApp, Email, Share)
                  Card(
                    elevation: 0,
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ProfileActionButton(
                            icon: Icons.phone_in_talk,
                            label: 'Call',
                            color: AppColors.accentBlue,
                            backgroundColor: AppColors.accentBlue
                                .withValues(alpha: 0.1),
                            isFilled: true,
                            onTap: () => _makeCall(context, m.mobileNumber),
                          ),
                          ProfileActionButton(
                            icon: Icons.chat_outlined,
                            label: 'WhatsApp',
                            color: AppColors.whatsappGreen,
                            backgroundColor: AppColors.whatsappGreen
                                .withValues(alpha: 0.1),
                            isFilled: true,
                            onTap: () => _sendMessage(context, m),
                          ),
                          ProfileActionButton(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            color: isDark
                                ? AppColors.lightBlue
                                : AppColors.primaryBlue,
                            backgroundColor: isDark
                                ? AppColors.bgDark
                                : AppColors.bgLight,
                            onTap: () => _sendEmail(context, m.email),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 1. Professional & Business Details Card
                  _buildSectionCard(
                    context,
                    title: 'Professional Details',
                    icon: Icons.business_center_outlined,
                    children: [
                      _buildInfoRow(context, 'Profession', m.profession),
                      _buildInfoRow(context, 'Company / Org', m.company),
                      _buildInfoRow(context, 'Business Category', m.businessCategory),
                      _buildInfoRow(context, 'Education / Degree', m.education),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Location & Address Card
                  _buildSectionCard(
                    context,
                    title: 'Location & Address',
                    icon: Icons.map_outlined,
                    children: [
                      _buildInfoRow(context, 'Native Village', m.village),
                      _buildInfoRow(context, 'Current City', m.city),
                      _buildInfoRow(context, 'District', m.district),
                      _buildInfoRow(context, 'State', m.state),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Personal & Contact Info Card
                  _buildSectionCard(
                    context,
                    title: 'Personal Information',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _buildInfoRow(context, 'Mobile Number', m.mobileNumber),
                      _buildInfoRow(context, 'Email Address', m.email),
                      _buildInfoRow(context, 'Blood Group', m.bloodGroup,
                          isHighlight: true),
                      _buildInfoRow(context, 'Age & Gender', '${m.age} years • ${m.gender}'),
                      _buildInfoRow(context, 'Marital Status', m.maritalStatus),
                      _buildInfoRow(context, 'Joined Date', m.joinedDate),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. Skills & Specializations
                  if (m.skills.isNotEmpty) ...[
                    _buildSectionCard(
                      context,
                      title: 'Skills & Specializations',
                      icon: Icons.star_outline_rounded,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: m.skills
                              .map(
                                (skill) => Chip(
                                  label: Text(skill),
                                  backgroundColor: AppColors.accentBlue
                                      .withValues(alpha: 0.1),
                                  side: BorderSide.none,
                                  labelStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 5. Languages Spoken
                  if (m.languages.isNotEmpty) ...[
                    _buildSectionCard(
                      context,
                      title: 'Languages Spoken',
                      icon: Icons.translate_rounded,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: m.languages
                              .map(
                                (lang) => Chip(
                                  label: Text(lang),
                                  backgroundColor: isDark
                                      ? AppColors.bgDark
                                      : AppColors.bgLight,
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 6. User's Posts and Reels Section
                  _buildSectionCard(
                    context,
                    title: 'Uploaded Content',
                    icon: Icons.photo_library_rounded,
                    children: [
                      if (_isLoadingContent)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_posts.isEmpty && _reels.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'No posts or reels uploaded yet.',
                              style: TextStyle(
                                color: isDark ? Colors.grey : Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        DefaultTabController(
                          length: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TabBar(
                                labelColor: isDark ? Colors.orangeAccent : Colors.orange.shade800,
                                unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
                                indicatorColor: Colors.orange,
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                                tabs: [
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.grid_on_rounded, size: 18),
                                        const SizedBox(width: 6),
                                        Text('Posts (${_posts.length})'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.play_circle_outline_rounded, size: 18),
                                        const SizedBox(width: 6),
                                        Text('Reels (${_reels.length})'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 420,
                                child: TabBarView(
                                  children: [
                                    // Posts tab list
                                    _posts.isEmpty
                                        ? const Center(child: Text('No posts yet.'))
                                        : ListView.builder(
                                            padding: const EdgeInsets.only(bottom: 24),
                                            itemCount: _posts.length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: PostCard(
                                                  post: _posts[index],
                                                  onRefresh: _fetchUserContent,
                                                ),
                                              );
                                            },
                                          ),
                                    // Reels tab list
                                    _reels.isEmpty
                                        ? const Center(child: Text('No reels yet.'))
                                        : ListView.builder(
                                            padding: const EdgeInsets.only(bottom: 24),
                                            itemCount: _reels.length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: SizedBox(
                                                  height: 380,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: InstagramStyleReel(
                                                      reel: _reels[index],
                                                      onRefresh: _fetchUserContent,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.accentBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight
                    ? AppColors.favoriteRed
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
