import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../api_config.dart';
import '../constants/app_colors.dart';
import '../models/campaign_model.dart';
import 'campaign_status_badge.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;
  final VoidCallback? onShare;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedStart = dateFormat.format(campaign.startDate);
    final formattedEnd = dateFormat.format(campaign.endDate);

    String bannerImageUrl = campaign.bannerUrl;
    if (bannerImageUrl.startsWith('/')) {
      bannerImageUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}$bannerImageUrl';
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.accentBlue.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Banner Image Header with Overlay Badges
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: bannerImageUrl.isNotEmpty
                          ? Image.network(
                              bannerImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildDefaultBanner(campaign.category),
                            )
                          : _buildDefaultBanner(campaign.category),
                    ),
                    // Gradient overlay for text readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Category Badge (Top Left)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(campaign.category),
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              campaign.category,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Status Badge (Top Right)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: CampaignStatusBadge(
                        status: campaign.effectiveStatus,
                        isCompact: true,
                      ),
                    ),
                  ],
                ),

                // 2. Card Content Body
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        campaign.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Date Range
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: AppColors.accentBlue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$formattedStart — $formattedEnd',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Financial Progress Bar (if target amount > 0)
                      if (campaign.targetAmount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Raised: ${currencyFormat.format(campaign.amountRaised)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.verifiedBadge,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Target: ${currencyFormat.format(campaign.targetAmount)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: campaign.progressPercentage,
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              campaign.progressPercentage >= 1.0 ? Colors.green : AppColors.accentBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // 4. Action Buttons Row (Share & View Details)
                      Row(
                        children: [
                          // Share Button
                          OutlinedButton.icon(
                            onPressed: () {
                              if (onShare != null) {
                                onShare!();
                              } else {
                                Share.share(
                                  'Check out "${campaign.title}" on KutumbSetu! Category: ${campaign.category}.\nJoin and support community causes.',
                                );
                              }
                            },
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('Share'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.lightBlue : AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              side: BorderSide(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const Spacer(),

                          // View Details CTA
                          ElevatedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: const Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBanner(String category) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 48,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'blood donation':
        return Icons.water_drop_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'medical help':
        return Icons.local_hospital_rounded;
      case 'community welfare':
        return Icons.groups_rounded;
      case 'disaster relief':
        return Icons.warning_amber_rounded;
      case 'religious/community events':
      case 'religious events':
        return Icons.event_rounded;
      case 'social cause':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }
}
