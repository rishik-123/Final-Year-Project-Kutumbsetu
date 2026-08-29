import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/member_model.dart';
import '../providers/member_providers.dart';

class MemberCard extends ConsumerWidget {
  final Member member;
  final VoidCallback onTap;

  const MemberCard({
    super.key,
    required this.member,
    required this.onTap,
  });

  void _showActionSnackBar(BuildContext context, String message) {
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
        _showActionSnackBar(context, 'Could not launch dialer for $phoneNumber');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showActionSnackBar(context, 'Could not call: $e');
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
        _showActionSnackBar(context, 'Could not open WhatsApp or SMS for ${member.fullName}');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showActionSnackBar(context, 'Could not initiate message: $e');
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
      _showActionSnackBar(context, 'Sharing failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = ref.watch(favoriteMemberIdsProvider);
    final isFavorite = favorites.contains(member.id);
    final connectionState = ref.watch(directoryConnectionProvider);
    final isConnected = connectionState.connectedMemberIds.contains(member.id);
    final isPending = connectionState.pendingRequestMemberIds.contains(member.id);

    void showFollowRequestDialog() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: const Color(0xFFE67E22), size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Follow ${member.fullName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To protect member privacy, please send a follow request to ${member.fullName} to unlock their full phone number, address, village, profession, and start a chat.',
                style: const TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: const Color(0xFFE67E22), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Once accepted, full member details and direct contact will be unlocked.',
                        style: TextStyle(fontSize: 11.5, color: const Color(0xFFE67E22), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(directoryConnectionProvider.notifier).sendFollowRequest(member.id);
                _showActionSnackBar(context, 'Follow request sent to ${member.fullName}!');
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Follow Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.cardShadow(context),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isConnected ? onTap : showFollowRequestDialog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name, Age & Gender
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'avatar_${member.id}',
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: (member.avatarUrl.startsWith('data:image') || member.avatarUrl.length > 100)
                              ? DecorationImage(
                                  image: MemoryImage(base64Decode(member.avatarUrl.split(',').last)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: (member.avatarUrl.startsWith('data:image') || member.avatarUrl.length > 100)
                              ? null
                              : AppColors.avatarGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentBlue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: (member.avatarUrl.startsWith('data:image') || member.avatarUrl.length > 100)
                            ? null
                            : Center(
                                child: Text(
                                  member.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Member Basic Info: Name, Age, Gender
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  member.fullName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (member.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: AppColors.verifiedBadge,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                member.gender.trim().toLowerCase() == 'female'
                                    ? Icons.female_rounded
                                    : Icons.male_rounded,
                                size: 14,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Age: ${member.age} • Gender: ${member.gender}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          if (isConnected) ...[
                            const SizedBox(height: 2),
                            Text(
                              member.profession,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.lightBlue : AppColors.accentBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Favorite Button
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? AppColors.favoriteRed
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        size: 22,
                      ),
                      onPressed: () {
                        ref
                            .read(favoriteMemberIdsProvider.notifier)
                            .toggleFavorite(member.id);
                        _showActionSnackBar(
                          context,
                          isFavorite
                              ? '${member.fullName} removed from favorites'
                              : '${member.fullName} added to favorites',
                        );
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),

                // Bottom Action: Request to Follow (if locked) OR Unlocked details & Contact buttons
                if (!isConnected)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            isPending ? 'Follow Requested (Pending)' : 'Details & Contact Protected',
                            style: TextStyle(fontSize: 11, color: isPending ? Colors.orange : Colors.grey.shade600),
                          ),
                        ],
                      ),
                      if (isPending)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Requested', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: showFollowRequestDialog,
                          icon: const Icon(Icons.person_add_rounded, size: 14),
                          label: const Text('Request to Follow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE67E22),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accentBlue),
                          const SizedBox(width: 4),
                          Text(member.village, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          if (member.bloodGroup.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('• ${member.bloodGroup}', style: const TextStyle(fontSize: 12, color: AppColors.favoriteRed, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          _ActionIconBtn(
                            icon: Icons.phone_rounded,
                            color: Colors.green,
                            tooltip: 'Call',
                            onTap: () => _makeCall(context, member.mobileNumber),
                          ),
                          const SizedBox(width: 8),
                          _ActionIconBtn(
                            icon: Icons.chat_rounded,
                            color: AppColors.accentBlue,
                            tooltip: 'Message',
                            onTap: () => _sendMessage(context, member),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}
