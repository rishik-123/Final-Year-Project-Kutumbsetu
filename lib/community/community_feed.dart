import 'package:flutter/material.dart';

// --- DESIGN TOKENS (Matching your HTML UI) ---
const Color kSaffron = Color(0xFFF57C00);
const Color kSaffronTint = Color(0xFFFFE3C2);
const Color kPeacock = Color(0xFF0288D1);
const Color kForest = Color(0xFF2E7D32);
const Color kBgColor = Color(0xFFFAFAFA);
const Color kCardColor = Color(0xFFFFFFFF);
const Color kTextColor = Color(0xFF212121);
const Color kTextSoft = Color(0xFF6B6B6B);
const Color kDivider = Color(0xFFECE7DE);

class CommunityFeedScreen extends StatelessWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        elevation: 1,
        title: const Text(
          "Community Feed",
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: kTextColor),
            onPressed: () {}, // Handle new post creation
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          // 1. STANDARD PHOTO POST (Instagram Style)
          PostCard(
            avatarText: "VJ",
            avatarColor: kPeacock,
            authorName: "Dr. Vishal Joshi",
            timeLocation: "10 mins ago • Nadiad",
            badgeText: "Community",
            content: "Great turnout at the youth sports meet today! Proud of our community talent.",
            likesCount: 124,
            commentsCount: 12,
            mediaWidget: _PlaceholderMedia(icon: Icons.sports_cricket, color: kPeacock),
          ),
          
          // 2. REEL / VIDEO POST (Instagram Reels Style)
          InstagramStyleReel(
            avatarText: "NC",
            avatarColor: kSaffron,
            authorName: "Nikita Chauhan",
            caption: "Glimpses from the Navratri Garba practice! 💃✨ #DarjiSamaj #Garba",
            audioTrack: "Original Audio - Nikita Chauhan",
            likesCount: "1.2K",
            commentsCount: "45",
            sharesCount: "120",
          ),

          // 3. CELEBRATION POST (Newborn / Marriage)
          PostCard(
            avatarText: "PC",
            avatarColor: Color(0xFFC2185B),
            authorName: "Priyaben Chauhan",
            timeLocation: "5 hours ago • Vadodara",
            badgeText: "Good News",
            badgeColor: Color(0xFFFCE4EC),
            badgeTextColor: Color(0xFFC2185B),
            eventHighlightTitle: "Blessed with a Baby Boy! 🍼🐣",
            content: "By the grace of Kuldevi, we are thrilled to announce the arrival of our baby boy, Arjun. Seeking blessings from all elders.",
            likesCount: 512,
            commentsCount: 108,
          ),

          // 4. JOB ADVERTISEMENT (Classified)
          AdCard(
            badgeText: "📢 HIRING",
            icon: Icons.work,
            title: "Role: Accountant (Tally Expert)",
            company: "Shree Tech Solutions",
            description: "We are looking for a reliable accountant for our Surat textile office. Preference will be given to Samaj members. Salary based on experience.",
            buttonText: "Apply Now",
            themeColor: Color(0xFF1565C0),
          ),

          // 5. PROPERTY ADVERTISEMENT (Classified)
          AdCard(
            badgeText: "📢 PROPERTY FOR SALE",
            icon: Icons.home_work,
            title: "3 BHK Flat in Premium Society, Anand",
            company: "Rajeshbhai Properties",
            description: "Fully furnished 3 BHK flat available for sale in Vidyanagar Road, Anand. 1500 sq ft, reserved parking. Exclusive negotiation for Darji Samaj families.",
            buttonText: "Contact Owner",
            themeColor: Color(0xFF33691E),
            bgColor: Color(0xFFF1F8E9),
          ),

          // 6. OBITUARY / DEATH NOTICE
          PostCard(
            avatarText: "DC",
            avatarColor: Colors.grey,
            authorName: "Dineshbhai Chauhan",
            timeLocation: "Just now • Karamsad",
            badgeText: "Besnu / Shradhanjali",
            badgeColor: Color(0xFFEEEEEE),
            badgeTextColor: Color(0xFF424242),
            isObituary: true,
            content: "Late Shri Chhotalal Chauhan\n(1928 - 2026)\n\nWith deep sorrow, we inform you of the sad demise of our beloved grandfather. The Besnu (prayer meeting) will be held on...",
            likesCount: 840,
            commentsCount: 230,
          ),
        ],
      ),
    );
  }
}

// --- STANDARD POST CARD (Instagram Style Likes/Comments/Reposts) ---
class PostCard extends StatelessWidget {
  final String avatarText;
  final Color avatarColor;
  final String authorName;
  final String timeLocation;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String content;
  final Widget? mediaWidget;
  final String? eventHighlightTitle;
  final bool isObituary;
  final int likesCount;
  final int commentsCount;

  const PostCard({
    super.key,
    required this.avatarText,
    required this.avatarColor,
    required this.authorName,
    required this.timeLocation,
    required this.badgeText,
    this.badgeColor = kSaffronTint,
    this.badgeTextColor = kSaffron,
    required this.content,
    this.mediaWidget,
    this.eventHighlightTitle,
    this.isObituary = false,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 12, right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
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
              CircleAvatar(
                backgroundColor: avatarColor,
                radius: 19,
                child: Text(
                  avatarText,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(timeLocation, style: const TextStyle(color: kTextSoft, fontSize: 10)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeTextColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),

          // Event Highlight Box (Newborn/Marriage)
          if (eventHighlightTitle != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)]),
                border: Border.all(color: const Color(0xFFFFE082)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                eventHighlightTitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFF8F00)),
              ),
            ),

          // Content
          Text(
            content, 
            textAlign: isObituary ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 12.5, height: 1.48, color: kTextColor)
          ),

          // Media (Photo)
          if (mediaWidget != null) ...[
            const SizedBox(height: 10),
            mediaWidget!,
          ],

          // Instagram-style Action Bar
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 26, color: kTextColor),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 24, color: kTextColor),
              const SizedBox(width: 16),
              const Icon(Icons.send_outlined, size: 24, color: kTextColor), // Share
              const Spacer(),
              const Icon(Icons.repeat, size: 24, color: kTextSoft), // Repost
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Likes & Comments Text
          Text(
            "$likesCount likes",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextColor),
          ),
          const SizedBox(height: 4),
          if (commentsCount > 0)
            Text(
              "View all $commentsCount comments",
              style: const TextStyle(fontSize: 12, color: kTextSoft),
            ),
          const SizedBox(height: 4),
          
          // Add comment placeholder
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: kDivider,
                radius: 12,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Add a comment...", style: TextStyle(fontSize: 12, color: kTextSoft.withOpacity(0.7))),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// --- INSTAGRAM-STYLE REEL WIDGET ---
class InstagramStyleReel extends StatelessWidget {
  final String avatarText;
  final Color avatarColor;
  final String authorName;
  final String caption;
  final String audioTrack;
  final String likesCount;
  final String commentsCount;
  final String sharesCount;

  const InstagramStyleReel({
    super.key,
    required this.avatarText,
    required this.avatarColor,
    required this.authorName,
    required this.caption,
    required this.audioTrack,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed height for feed scrolling. If you want true full screen, 
    // this would be used inside a PageView.builder with height: MediaQuery.of(context).size.height
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 600, 
      decoration: const BoxDecoration(
        color: Colors.black,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2C2C), Color(0xFF111111)],
        ),
      ),
      child: Stack(
        children: [
          // Play Button Indicator (Center)
          const Center(
            child: Icon(Icons.play_arrow, color: Colors.white54, size: 80),
          ),
          
          // Bottom Left: User Info & Caption
          Positioned(
            bottom: 20,
            left: 12,
            right: 80, // Leave space for right column
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: avatarColor,
                      radius: 16,
                      child: Text(avatarText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("Follow", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  caption,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(audioTrack, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Right: Action Column (Like, Comment, Share, Repost, Audio)
          Positioned(
            bottom: 20,
            right: 12,
            child: Column(
              children: [
                _ReelAction(icon: Icons.favorite_border, label: likesCount),
                const SizedBox(height: 20),
                _ReelAction(icon: Icons.chat_bubble_outline, label: commentsCount),
                const SizedBox(height: 20),
                _ReelAction(icon: Icons.send_outlined, label: sharesCount),
                const SizedBox(height: 20),
                const _ReelAction(icon: Icons.repeat, label: "Repost"),
                const SizedBox(height: 24),
                // Audio Track Image/Box
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.multitrack_audio, color: Colors.white, size: 18),
                )
              ],
            ),
          ),
          
          // Badge at top
          Positioned(
            top: 16,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text("Reel", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- REEL ACTION HELPER ---
class _ReelAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReelAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// --- REUSABLE ADVERTISEMENT CARD ---
class AdCard extends StatelessWidget {
  final String badgeText;
  final IconData icon;
  final String title;
  final String company;
  final String description;
  final String buttonText;
  final Color themeColor;
  final Color bgColor;

  const AdCard({
    super.key,
    required this.badgeText,
    required this.icon,
    required this.title,
    required this.company,
    required this.description,
    required this.buttonText,
    required this.themeColor,
    this.bgColor = const Color(0xFFE3F2FD),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 12, right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(icon, color: themeColor, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: themeColor, fontSize: 15, fontWeight: FontWeight.w800)),
          Text(company, style: TextStyle(color: themeColor.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: themeColor.withOpacity(0.9), fontSize: 12, height: 1.45)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {},
              child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

// --- PHOTO PLACEHOLDER HELPER ---
class _PlaceholderMedia extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _PlaceholderMedia({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 50, color: color),
    );
  }
}