import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/campaign_model.dart';
import '../providers/auth_provider.dart';
import '../providers/campaign_providers.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/campaign_card.dart';

class CampaignListingScreen extends ConsumerStatefulWidget {
  const CampaignListingScreen({super.key});

  @override
  ConsumerState<CampaignListingScreen> createState() => _CampaignListingScreenState();
}

class _CampaignListingScreenState extends ConsumerState<CampaignListingScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final categoriesAsync = ref.watch(campaignCategoriesProvider);
    final campaignsAsync = ref.watch(campaignsListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedStatusTab = ref.watch(selectedStatusTabProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Header with Title & Search Bar
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.headerGradientDark : AppColors.headerGradientLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KutumbSetu Campaigns',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Community Drives, Welfare & Events',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (auth.isAdmin)
                        ElevatedButton.icon(
                          onPressed: () => context.push('/campaigns/create'),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('Create'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(campaignSearchQueryProvider.notifier).state = val;
                      },
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search campaigns by title, keyword...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.white70 : AppColors.primaryBlue,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(campaignSearchQueryProvider.notifier).state = '';
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Status Segmented Tabs (SCRUM-71)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Active', 'Upcoming', 'Completed'].map((tab) {
                    final isSelected = selectedStatusTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(tab),
                        selected: isSelected,
                        selectedColor: AppColors.accentBlue,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade800),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(selectedStatusTabProvider.notifier).state = tab;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 3. Category Filter Chips Bar (SCRUM-68)
            categoriesAsync.when(
              data: (categories) {
                final categoryNames = ['All', ...categories.map((c) => c.name)];
                return Container(
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categoryNames.length,
                    itemBuilder: (context, index) {
                      final catName = categoryNames[index];
                      final isSelected = selectedCategory == catName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          avatar: catName == 'All'
                              ? const Icon(Icons.grid_view_rounded, size: 16)
                              : Icon(_getCategoryIcon(catName), size: 16),
                          label: Text(catName),
                          backgroundColor: isSelected
                              ? AppColors.primaryBlue.withValues(alpha: 0.15)
                              : (isDark ? AppColors.cardDark : AppColors.cardLight),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryBlue : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: isSelected ? 1.5 : 1,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.white70 : Colors.grey.shade800),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          onPressed: () {
                            ref.read(selectedCategoryProvider.notifier).state = catName;
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox(height: 48),
              error: (_, __) => const SizedBox(height: 48),
            ),

            // 4. Campaign Cards List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(campaignsListProvider);
                  ref.invalidate(campaignCategoriesProvider);
                },
                child: campaignsAsync.when(
                  data: (campaigns) {
                    if (campaigns.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: campaigns.length,
                      itemBuilder: (context, index) {
                        final campaign = campaigns[index];
                        return CampaignCard(
                          campaign: campaign,
                          onTap: () => context.push('/campaigns/${campaign.id}', extra: campaign),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load campaigns',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(campaignsListProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/campaigns/create'),
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Campaign'),
            )
          : null,
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/campaigns'),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.campaign_outlined,
              size: 72,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Campaigns Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no campaigns matching your selected category or status filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(selectedCategoryProvider.notifier).state = 'All';
                ref.read(selectedStatusTabProvider.notifier).state = 'All';
                ref.read(campaignSearchQueryProvider.notifier).state = '';
                _searchController.clear();
              },
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Reset All Filters'),
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
        return Icons.event_rounded;
      case 'social cause':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
