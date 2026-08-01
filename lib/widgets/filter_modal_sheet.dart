import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/member_model.dart';
import '../providers/member_providers.dart';

class FilterModalSheet extends ConsumerStatefulWidget {
  final String initialCategory;

  const FilterModalSheet({
    super.key,
    this.initialCategory = 'Village',
  });

  @override
  ConsumerState<FilterModalSheet> createState() => _FilterModalSheetState();
}

class _FilterModalSheetState extends ConsumerState<FilterModalSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = [
    'Village',
    'City',
    'Profession',
    'Business',
    'Blood Group',
    'Education',
    'Status',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = _categories.indexOf(widget.initialCategory);
    if (initialIndex == -1) initialIndex = 0;
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterState = ref.watch(activeFiltersProvider);
    final filterNotifier = ref.read(activeFiltersProvider.notifier);
    final rawMembersAsync = ref.watch(rawMemberListProvider);

    final members = rawMembersAsync.asData?.value ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header: Title + Clear All
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: AppColors.accentBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Filter Directory',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                  ],
                ),
                if (!filterState.isEmpty)
                  TextButton.icon(
                    onPressed: () {
                      filterNotifier.clearAll();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset All'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.favoriteRed,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Category Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.accentBlue,
            labelColor: AppColors.accentBlue,
            unselectedLabelColor: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: _categories.map((cat) {
              int count = 0;
              if (cat == 'Village') count = filterState.selectedVillages.length;
              if (cat == 'City') count = filterState.selectedCities.length;
              if (cat == 'Profession') count = filterState.selectedProfessions.length;
              if (cat == 'Business') count = filterState.selectedBusinessCategories.length;
              if (cat == 'Blood Group') count = filterState.selectedBloodGroups.length;
              if (cat == 'Education') count = filterState.selectedEducations.length;
              if (cat == 'Status') {
                if (filterState.isVerifiedOnly == true) count++;
                if (filterState.isActiveOnly == true) count++;
                count += filterState.selectedGenders.length;
              }

              return Tab(
                child: Row(
                  children: [
                    Text(cat),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          const Divider(height: 1),

          // Tab View Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Village Tab
                _buildMultiSelectCategoryList(
                  items: AppConstants.villages,
                  selectedItems: filterState.selectedVillages,
                  getItemCount: (v) =>
                      members.where((m) => m.village == v).length,
                  onToggle: (v) => filterNotifier.toggleVillage(v),
                  isDark: isDark,
                ),

                // 2. City Tab
                _buildMultiSelectCategoryList(
                  items: AppConstants.cities,
                  selectedItems: filterState.selectedCities,
                  getItemCount: (c) =>
                      members.where((m) => m.city == c).length,
                  onToggle: (c) => filterNotifier.toggleCity(c),
                  isDark: isDark,
                ),

                // 3. Profession Tab
                _buildMultiSelectCategoryList(
                  items: (members.map((m) => m.profession).toSet().toList()..add('Tailor')).toSet().toList()..removeWhere((p) => p.isEmpty)..sort(),
                  selectedItems: filterState.selectedProfessions,
                  getItemCount: (p) =>
                      members.where((m) => m.profession == p).length,
                  onToggle: (p) => filterNotifier.toggleProfession(p),
                  isDark: isDark,
                ),

                // 4. Business Category Tab
                _buildMultiSelectCategoryList(
                  items: AppConstants.businessCategories,
                  selectedItems: filterState.selectedBusinessCategories,
                  getItemCount: (bc) => members
                      .where((m) => m.businessCategory == bc)
                      .length,
                  onToggle: (bc) => filterNotifier.toggleBusinessCategory(bc),
                  isDark: isDark,
                ),

                // 5. Blood Group Tab
                _buildMultiSelectCategoryList(
                  items: AppConstants.bloodGroups,
                  selectedItems: filterState.selectedBloodGroups,
                  getItemCount: (bg) =>
                      members.where((m) => m.bloodGroup == bg).length,
                  onToggle: (bg) => filterNotifier.toggleBloodGroup(bg),
                  isDark: isDark,
                ),

                // 6. Education Tab
                _buildMultiSelectCategoryList(
                  items: members.map((m) => m.education).toSet().toList()..sort(),
                  selectedItems: filterState.selectedEducations,
                  getItemCount: (ed) =>
                      members.where((m) => m.education == ed).length,
                  onToggle: (ed) => filterNotifier.toggleEducation(ed),
                  isDark: isDark,
                ),

                // 7. Status & Gender Tab
                _buildStatusAndGenderList(
                  filterState: filterState,
                  filterNotifier: filterNotifier,
                  members: members,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Apply Filters (${ref.watch(filteredMembersProvider).asData?.value.length ?? 0} Members)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectCategoryList({
    required List<String> items,
    required Set<String> selectedItems,
    required int Function(String item) getItemCount,
    required Function(String item) onToggle,
    required bool isDark,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedItems.contains(item);
        final count = getItemCount(item);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (_) => onToggle(item),
          activeColor: AppColors.accentBlue,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          title: Text(
            item,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          secondary: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusAndGenderList({
    required MemberFilterState filterState,
    required MemberFilterNotifier filterNotifier,
    required List<Member> members,
    required bool isDark,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, top: 10, bottom: 4),
          child: Text(
            'Verification & Activity',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.accentBlue,
            ),
          ),
        ),
        SwitchListTile(
          value: filterState.isVerifiedOnly == true,
          onChanged: (_) => filterNotifier.toggleVerifiedOnly(),
          activeTrackColor: AppColors.accentBlue,
          title: const Text(
            'Verified Profiles Only',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Show members with verified status badge'),
          secondary: const Icon(Icons.verified, color: AppColors.verifiedBadge),
        ),
        const Divider(),
        SwitchListTile(
          value: filterState.isActiveOnly == true,
          onChanged: (_) => filterNotifier.toggleActiveOnly(),
          activeTrackColor: AppColors.activeBadge,
          title: const Text(
            'Active Members Only',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Show currently active registered members'),
          secondary: const Icon(Icons.circle, color: AppColors.activeBadge, size: 16),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.only(left: 8, top: 10, bottom: 4),
          child: Text(
            'Gender Filter',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.accentBlue,
            ),
          ),
        ),
        CheckboxListTile(
          value: filterState.selectedGenders.contains('Male'),
          onChanged: (_) => filterNotifier.toggleGender('Male'),
          activeColor: AppColors.accentBlue,
          title: const Text('Male', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          secondary: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${members.where((m) => m.gender == 'Male').length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        CheckboxListTile(
          value: filterState.selectedGenders.contains('Female'),
          onChanged: (_) => filterNotifier.toggleGender('Female'),
          activeColor: AppColors.accentBlue,
          title: const Text('Female', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          secondary: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${members.where((m) => m.gender == 'Female').length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
