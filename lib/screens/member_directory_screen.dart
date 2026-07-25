import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/member_model.dart';
import '../providers/member_providers.dart';
import '../providers/theme_provider.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/filter_modal_sheet.dart';
import '../widgets/member_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/sort_modal_sheet.dart';
import '../widgets/sticky_alphabet_index.dart';

class MemberDirectoryScreen extends ConsumerStatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  ConsumerState<MemberDirectoryScreen> createState() =>
      _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState
    extends ConsumerState<MemberDirectoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _letterKeys = {};
  String _activeLetter = 'A';

  @override
  void initState() {
    super.initState();
    for (final letter in AppConstants.alphabetIndex) {
      _letterKeys[letter] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter) {
    setState(() {
      _activeLetter = letter;
    });

    final key = _letterKeys[letter];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _openFilterModal([String category = 'Village']) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModalSheet(initialCategory: category),
    );
  }

  void _openSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const SortModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredAsync = ref.watch(filteredMembersProvider);
    final groupedAsync = ref.watch(groupedMembersProvider);
    final rawCount = ref.watch(rawMemberListProvider).asData?.value.length ?? 0;
    final sortOption = ref.watch(sortOptionProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Premium Blue Gradient Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 20,
                left: 20,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.headerGradientDark
                    : AppColors.headerGradientLight,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                            onPressed: () => context.pop(),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(right: 8),
                            tooltip: 'Back to Home',
                          ),
                          // Subtitle tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.groups_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Gujarati Patidar Samaj',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Light/Dark Theme Toggle
                      IconButton(
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.white,
                        ),
                        tooltip: 'Toggle Theme',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Main App Title & Member Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            AppConstants.appSubTitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      // Member Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$rawCount Members',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Debounced Search Bar
            SearchBarWidget(
              onOpenFilter: () => _openFilterModal(),
              onOpenSort: _openSortModal,
            ),

            // 3. Filter Chips Bar
            FilterChipsBar(
              onSelectCategoryFilter: (category) => _openFilterModal(category),
            ),

            // 4. Main Directory List View with Sticky A-Z Index
            Expanded(
              child: filteredAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accentBlue),
                ),
                error: (err, stack) => Center(
                  child: Text('Error loading directory: $err'),
                ),
                data: (members) {
                  if (members.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // If standard A-Z sort, show alphabetical headers and sticky index
                  final bool isAZSort = sortOption == SortOption.nameAZ;

                  return Stack(
                    children: [
                      // List of Members
                      groupedAsync.when(
                        data: (groupedMap) {
                          if (!isAZSort) {
                            // Standard flat list when sorted by Profession, City, Date, etc.
                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(
                                  bottom: 24, left: 4, right: 32),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final member = members[index];
                                return MemberCard(
                                  member: member,
                                  onTap: () => context.push(
                                    '/member/${member.id}',
                                    extra: member,
                                  ),
                                );
                              },
                            );
                          }

                          // Grouped A-Z List with Headers
                          final letters = groupedMap.keys.toList()..sort();

                          return ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                                bottom: 24, left: 4, right: 32),
                            children: letters.map((letter) {
                              final letterMembers = groupedMap[letter] ?? [];

                              return Column(
                                key: _letterKeys[letter],
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Section Header Letter Badge
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16, top: 12, bottom: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentBlue,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            letter,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Divider(
                                            color: isDark
                                                ? AppColors.borderDark
                                                : AppColors.borderLight,
                                          ),
                                        ),
                                        Text(
                                          '${letterMembers.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                    ),
                                  ),

                                  // Members under this letter
                                  ...letterMembers.map(
                                    (member) => MemberCard(
                                      member: member,
                                      onTap: () => context.push(
                                        '/member/${member.id}',
                                        extra: member,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, __) => const SizedBox(),
                      ),

                      // Right-side Sticky A-Z Alphabet Index Bar
                      if (isAZSort)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: StickyAlphabetIndex(
                              availableLetters: groupedAsync.asData?.value.keys.toList() ?? [],
                              activeLetter: _activeLetter,
                              onLetterTap: _scrollToLetter,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Members Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No member profiles match your current search query or applied filter options.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(activeFiltersProvider.notifier).clearAll();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset All Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentBlue,
                side: const BorderSide(color: AppColors.accentBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
