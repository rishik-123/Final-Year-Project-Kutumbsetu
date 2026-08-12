import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

// --- DESIGN TOKENS ---
const Color kSaffron = Color(0xFFF57C00);
const Color kSaffronTint = Color(0xFFFFE3C2);
const Color kPeacock = Color(0xFF0288D1);
const Color kForest = Color(0xFF2E7D32);
const Color kBgColor = Color(0xFFFAFAFA);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextColor = Color(0xFF212121);
const Color kTextSoft = Color(0xFF6B6B6B);
const Color kDivider = Color(0xFFECE7DE);

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _posts = [];
  List<dynamic> _reels = [];
  bool _isLoadingPosts = false;
  bool _isLoadingReels = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPosts();
    _fetchReels();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/posts'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _posts = data['posts'];
          });
        }
      }
    } catch (e) {
      print('Error fetching posts: $e');
    } finally {
      setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _fetchReels() async {
    setState(() => _isLoadingReels = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/community/reels'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _reels = data['reels'];
          });
        }
      }
    } catch (e) {
      print('Error fetching reels: $e');
    } finally {
      setState(() => _isLoadingReels = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : kBgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : kCardColor,
        elevation: 1,
        title: Text(
          "Community Hub",
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : kTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kSaffron,
          unselectedLabelColor: isDark ? Colors.grey : kTextSoft,
          indicatorColor: kSaffron,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Posts & News"),
            Tab(text: "Reels"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Posts Tab
          RefreshIndicator(
            onRefresh: _fetchPosts,
            color: kSaffron,
            child: _isLoadingPosts && _posts.isEmpty
                ? const Center(child: CircularProgressIndicator(color: kSaffron))
                : _posts.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                const Icon(Icons.newspaper_rounded, size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  "No community posts yet",
                                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return PostCard(
                            post: post,
                            onRefresh: _fetchPosts,
                          );
                        },
                      ),
          ),

          // 2. Reels Tab
          RefreshIndicator(
            onRefresh: _fetchReels,
            color: kSaffron,
            child: _isLoadingReels && _reels.isEmpty
                ? const Center(child: CircularProgressIndicator(color: kSaffron))
                : _reels.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                const Icon(Icons.video_library_rounded, size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  "No reels yet",
                                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: _reels.length,
                        itemBuilder: (context, index) {
                          final reel = _reels[index];
                          return InstagramStyleReel(
                            reel: reel,
                            onRefresh: _fetchReels,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// --- STANDARD POST CARD (Instagram Style Likes/Comments/Shares) ---
class PostCard extends ConsumerStatefulWidget {
  final dynamic post;
  final VoidCallback onRefresh;

  const PostCard({
    super.key,
    required this.post,
    required this.onRefresh,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isLiking = false;

  Future<void> _toggleLike() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _isLiking = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/community/posts/${widget.post['_id']}/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': user.id}),
      );
      if (response.statusCode == 200) {
        widget.onRefresh();
      }
    } catch (e) {
      print('Error liking post: $e');
    } finally {
      setState(() => _isLiking = false);
    }
  }

  Future<void> _incrementShareCount() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/community/posts/${widget.post['_id']}/share'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        widget.onRefresh();
      }
    } catch (e) {
      print('Error incrementing share count: $e');
    }
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CommentsBottomSheet(
          itemId: widget.post['_id'],
          isPost: true,
          comments: widget.post['comments'] ?? [],
          onCommentAdded: widget.onRefresh,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = widget.post;

    final init = p['avatarText'] ?? 'U';
    final author = p['authorName'] ?? 'User';
    final content = p['content'] ?? '';
    final likesList = p['likes'] is List ? p['likes'] as List : [];
    final likesCount = likesList.length;
    final commentsList = p['comments'] is List ? p['comments'] as List : [];
    final commentsCount = commentsList.length;

    final avatarHex = p['avatarColor'] ?? '#F57C00';
    final Color avatarColor = Color(int.parse(avatarHex.replaceFirst('#', '0xFF')));

    final mediaUrl = p['mediaUrl'] != null && p['mediaUrl'].toString().isNotEmpty
        ? '${ApiConfig.baseUrl.replaceAll('/api', '')}${p['mediaUrl']}'
        : null;

    final user = ref.watch(currentUserProvider);
    final isLiked = user != null && likesList.contains(user.id);

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
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 12, right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : kDivider),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(33, 26, 15, 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final userId = p['userId']?.toString() ?? '';
                  if (userId.isNotEmpty) {
                    context.push('/member/$userId');
                  }
                },
                child: CircleAvatar(
                  backgroundColor: avatarColor,
                  radius: 19,
                  child: Text(
                    init,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final userId = p['userId']?.toString() ?? '';
                    if (userId.isNotEmpty) {
                      context.push('/member/$userId');
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : kTextColor,
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.grey : kTextSoft,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF5D2800) : kSaffronTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Samaj Post",
                  style: GoogleFonts.poppins(
                    color: kSaffron,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),

          // Content
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.48,
              color: isDark ? Colors.grey.shade200 : kTextColor,
            ),
          ),

          // Media (Photo)
          if (mediaUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ],

          // Action Bar
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _isLiking ? null : _toggleLike,
                child: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 26,
                  color: isLiked ? Colors.pink : (isDark ? Colors.white : kTextColor),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _showCommentsSheet,
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 24,
                  color: isDark ? Colors.white : kTextColor,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  final shareLink = "${ApiConfig.baseUrl.replaceAll('/api', '')}/share/post/${widget.post['_id']}";
                  final shareText = "$content\n\nView post: $shareLink";
                  if (mediaUrl != null) {
                    try {
                      final response = await http.get(Uri.parse(mediaUrl));
                      if (response.statusCode == 200) {
                        final tempDir = Directory.systemTemp;
                        final file = File('${tempDir.path}/shared_image.png');
                        await file.writeAsBytes(response.bodyBytes);
                        await Share.shareXFiles([XFile(file.path)], text: shareText);
                        _incrementShareCount();
                      } else {
                        await Share.share(shareText);
                        _incrementShareCount();
                      }
                    } catch (e) {
                      print("Error sharing image: $e");
                      await Share.share(shareText);
                      _incrementShareCount();
                    }
                  } else {
                    await Share.share(shareText);
                    _incrementShareCount();
                  }
                },
                child: Icon(
                  Icons.send_outlined,
                  size: 24,
                  color: isDark ? Colors.white : kTextColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Likes & Comments Text
          Text(
            "$likesCount likes • ${p['sharesCount'] ?? 0} shares",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : kTextColor,
            ),
          ),
          const SizedBox(height: 4),
          if (commentsCount > 0)
            GestureDetector(
              onTap: _showCommentsSheet,
              child: Text(
                "View all $commentsCount comments",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: kTextSoft,
                ),
              ),
            ),
          const SizedBox(height: 4),

          // Add comment placeholder shortcut
          GestureDetector(
            onTap: _showCommentsSheet,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? Colors.grey.shade800 : kDivider,
                  radius: 12,
                  child: const Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Add a comment...",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: kTextSoft.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- INSTAGRAM-STYLE REEL WIDGET ---
class InstagramStyleReel extends ConsumerStatefulWidget {
  final dynamic reel;
  final VoidCallback onRefresh;

  const InstagramStyleReel({
    super.key,
    required this.reel,
    required this.onRefresh,
  });

  @override
  ConsumerState<InstagramStyleReel> createState() => _InstagramStyleReelState();
}

class _InstagramStyleReelState extends ConsumerState<InstagramStyleReel> {
  bool _isLiking = false;

  Future<void> _toggleLike() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _isLiking = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/community/reels/${widget.reel['_id']}/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': user.id}),
      );
      if (response.statusCode == 200) {
        widget.onRefresh();
      }
    } catch (e) {
      print('Error liking reel: $e');
    } finally {
      setState(() => _isLiking = false);
    }
  }

  Future<void> _incrementReelShareCount() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/community/reels/${widget.reel['_id']}/share'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        widget.onRefresh();
      }
    } catch (e) {
      print('Error incrementing reel share count: $e');
    }
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CommentsBottomSheet(
          itemId: widget.reel['_id'],
          isPost: false,
          comments: widget.reel['comments'] ?? [],
          onCommentAdded: widget.onRefresh,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reel;

    final init = r['avatarText'] ?? 'U';
    final author = r['authorName'] ?? 'User';
    final caption = r['caption'] ?? '';
    final likesList = r['likes'] is List ? r['likes'] as List : [];
    final likesCount = likesList.length;
    final commentsList = r['comments'] is List ? r['comments'] as List : [];
    final commentsCount = commentsList.length;
    final sharesCount = r['sharesCount']?.toString() ?? '0';

    final avatarHex = r['avatarColor'] ?? '#0288D1';
    final Color avatarColor = Color(int.parse(avatarHex.replaceFirst('#', '0xFF')));

    final videoUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}${r['videoUrl']}';

    final user = ref.watch(currentUserProvider);
    final isLiked = user != null && likesList.contains(user.id);

    return Container(
      color: Colors.black,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          ReelVideoPlayer(videoUrl: videoUrl),

          // Saffron overlay gradient for text readability
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Bottom Left: User Info & Caption
          Positioned(
            bottom: 24,
            left: 12,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    final userId = r['userId']?.toString() ?? '';
                    if (userId.isNotEmpty) {
                      context.push('/member/$userId');
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: avatarColor,
                        radius: 16,
                        child: Text(
                          init,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        author,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  caption,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      r['audioTrack'] ?? "Original Audio",
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Right: Action Column
          Positioned(
            bottom: 24,
            right: 12,
            child: Column(
              children: [
                // Like Button
                _ReelAction(
                  icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isLiked ? Colors.pink : Colors.white,
                  label: likesCount.toString(),
                  onTap: _isLiking ? null : _toggleLike,
                ),
                const SizedBox(height: 20),
                
                // Comments Button
                _ReelAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: Colors.white,
                  label: commentsCount.toString(),
                  onTap: _showCommentsSheet,
                ),
                const SizedBox(height: 20),
                
                // Share Button
                _ReelAction(
                  icon: Icons.send_rounded,
                  iconColor: Colors.white,
                  label: sharesCount,
                  onTap: () async {
                    final shareLink = "${ApiConfig.baseUrl.replaceAll('/api', '')}/share/reel/${widget.reel['_id']}";
                    await Share.share("$caption\n\nView reel: $shareLink");
                    _incrementReelShareCount();
                  },
                ),
              ],
            ),
          ),

          // Badge at top left
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Reel",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- REEL ACTION WIDGET ---
class _ReelAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _ReelAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// --- REUSABLE REEL VIDEO PLAYER ---
class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const ReelVideoPlayer({super.key, required this.videoUrl});

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
        }
      }).catchError((err) {
        print("Reel video player init error: $err");
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 48),
              SizedBox(height: 8),
              Text("Failed to play video", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: kSaffron));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          if (!_controller.value.isPlaying)
            const CircleAvatar(
              backgroundColor: Colors.black45,
              radius: 30,
              child: Icon(Icons.play_arrow_rounded, size: 44, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

// --- COMMENTS BOTTOM SHEET WIDGET ---
class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String itemId;
  final bool isPost;
  final List<dynamic> comments;
  final VoidCallback onCommentAdded;

  const CommentsBottomSheet({
    super.key,
    required this.itemId,
    required this.isPost,
    required this.comments,
    required this.onCommentAdded,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _localComments = [];
  bool _isSubmitting = false;
  dynamic _replyingToComment; // holds the comment map we are replying to

  @override
  void initState() {
    super.initState();
    _localComments = List.from(widget.comments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleCommentLike(String commentId) async {
    final user = ref.read(currentUserProvider);
    if (user == null || commentId.isEmpty) return;
    
    final routeType = widget.isPost ? 'posts' : 'reels';
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/community/$routeType/${widget.itemId}/comment/$commentId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': user.id}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _localComments = data['comments'];
          });
          widget.onCommentAdded();
        }
      }
    } catch (e) {
      print('Error toggling comment like: $e');
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);
    final routeType = widget.isPost ? 'posts' : 'reels';
    try {
      final isReplying = _replyingToComment != null;
      final url = isReplying
          ? '${ApiConfig.baseUrl}/community/$routeType/${widget.itemId}/comment/${_replyingToComment['_id']}/reply'
          : '${ApiConfig.baseUrl}/community/$routeType/${widget.itemId}/comment';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.id,
          'content': text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _localComments = data['comments'];
            _commentController.clear();
            _replyingToComment = null;
          });
          widget.onCommentAdded();
        }
      }
    } catch (e) {
      print('Error adding comment/reply: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Comments",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : kTextColor,
              ),
            ),
            const Divider(),

            // List of comments
            Expanded(
              child: _localComments.isEmpty
                  ? Center(
                      child: Text(
                        "No comments yet. Start the conversation!",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _localComments.length,
                      itemBuilder: (context, index) {
                        final c = _localComments[index];
                        final commentId = c['_id'] ?? '';
                        final author = c['authorName'] ?? 'User';
                        final text = c['content'] ?? '';
                        final commentUserId = c['userId'] ?? '';
                        final init = author.isNotEmpty ? author[0].toUpperCase() : 'U';

                        final user = ref.read(currentUserProvider);
                        final likesList = c['likes'] is List ? c['likes'] as List : [];
                        final isLiked = user != null && likesList.contains(user.id);
                        final likesCount = likesList.length;
                        final repliesList = c['replies'] is List ? c['replies'] as List : [];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (commentUserId.isNotEmpty) {
                                        Navigator.pop(context);
                                        context.push('/member/$commentUserId');
                                      }
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: kSaffron,
                                      radius: 14,
                                      child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (commentUserId.isNotEmpty) {
                                              Navigator.pop(context);
                                              context.push('/member/$commentUserId');
                                            }
                                          },
                                          child: Text(
                                            author,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark ? Colors.white : kTextColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          text,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey.shade300 : kTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _replyingToComment = c;
                                                });
                                              },
                                              child: Text(
                                                'Reply',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.grey : Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _toggleCommentLike(commentId),
                                        child: Icon(
                                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          size: 16,
                                          color: isLiked ? Colors.pink : (isDark ? Colors.grey : Colors.grey.shade600),
                                        ),
                                      ),
                                      if (likesCount > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '$likesCount',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.grey : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              if (repliesList.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 36.0, top: 8.0),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: repliesList.length,
                                    itemBuilder: (context, rIndex) {
                                      final r = repliesList[rIndex];
                                      final replyAuthor = r['authorName'] ?? 'User';
                                      final replyText = r['content'] ?? '';
                                      final replyUserId = r['userId'] ?? '';
                                      final replyInit = replyAuthor.isNotEmpty ? replyAuthor[0].toUpperCase() : 'U';
                                      
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                if (replyUserId.isNotEmpty) {
                                                  Navigator.pop(context);
                                                  context.push('/member/$replyUserId');
                                                }
                                              },
                                              child: CircleAvatar(
                                                backgroundColor: kPeacock.withOpacity(0.8),
                                                radius: 10,
                                                child: Text(
                                                  replyInit,
                                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (replyUserId.isNotEmpty) {
                                                        Navigator.pop(context);
                                                        context.push('/member/$replyUserId');
                                                      }
                                                    },
                                                    child: Text(
                                                      replyAuthor,
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                        color: isDark ? Colors.white : kTextColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    replyText,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: isDark ? Colors.grey.shade300 : kTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            if (_replyingToComment != null)
              Container(
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Replying to ${_replyingToComment['authorName']}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kSaffron,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        setState(() {
                          _replyingToComment = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Input panel
            Container(
              padding: const EdgeInsets.all(12),
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: kSaffron, strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _submitComment,
                          child: Text(
                            "Post",
                            style: GoogleFonts.poppins(
                              color: kSaffron,
                              fontWeight: FontWeight.bold,
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
  }
}