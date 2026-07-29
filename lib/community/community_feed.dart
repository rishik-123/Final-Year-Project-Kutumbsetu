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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Community Feed",
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: kTextColor),
            onPressed: () {}, // Add post
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: const [
          // 1. STANDARD PHOTO POST
          PostCard(
            avatarText: "VJ",
            avatarColor: kPeacock,
            authorName: "Dr. Vishal Joshi",
            timeLocation: "10 mins ago • Nadiad",
            badgeText: "Community",
            content: "Great turnout at the youth sports meet today! Proud of our community talent.",
            mediaWidget: _PlaceholderMedia(icon: Icons.sports_cricket, color: kPeacock),
          ),
          
          // 2. REEL / VIDEO POST
          PostCard(
            avatarText: "NC",
            avatarColor: kSaffron,
            authorName: "Nikita Chauhan",
            timeLocation: "2 hours ago • Ahmedabad",
            badgeText: "Reel",
            badgeColor: Color(0xFFFCE4EC),
            badgeTextColor: Color(0xFFC2185B),
            content: "Glimpses from the Navratri Garba practice! 💃✨",
            mediaWidget: _ReelPlaceholder(),
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
          ),
        ],
      ),
    );
  }
}

// --- REUSABLE POST CARD WIDGET ---
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(33, 26, 15, 0.06),
            blurRadius: 14,
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
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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

          // Event Highlight Box (If applicable)
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

          // Body Text
          Text(
            content,
            textAlign: isObituary ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 12.5, height: 1.48, color: kTextColor),
          ),

          // Media (Photo/Reel)
          if (mediaWidget != null) ...[
            const SizedBox(height: 10),
            mediaWidget!,
          ],

          // Footer Actions
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Divider(color: kDivider, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _ActionBtn(icon: Icons.favorite_border, text: "Like"),
                const SizedBox(width: 18),
                _ActionBtn(icon: Icons.chat_bubble_outline, text: "Comment"),
                const SizedBox(width: 18),
                _ActionBtn(icon: Icons.send, text: "Share"),
              ],
            ),
          )
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 14),
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

// --- HELPERS ---
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ActionBtn({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kTextSoft),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11.5, color: kTextSoft, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PlaceholderMedia extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _PlaceholderMedia({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 40, color: color),
    );
  }
}

class _ReelPlaceholder extends StatelessWidget {
  const _ReelPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1a1a1a), Color(0xFF333333)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: kSaffron, size: 30),
            ),
            const Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                "▶ 1.2K views   ⏱ 0:45",
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}