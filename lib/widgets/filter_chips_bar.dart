import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../providers/member_providers.dart';

class FilterChipsBar extends ConsumerWidget {
  final Function(String category) onSelectCategoryFilter;

  const FilterChipsBar({
    super.key,
    required this.onSelectCategoryFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterState = ref.watch(activeFiltersProvider);
    final filterNotifier = ref.read(activeFiltersProvider.notifier);

    final chipCategories = [
      {'key': 'All', 'label': 'All Members'},
      {'key': 'Village', 'label': 'Village (${filterState.selectedVillages.length})'},
      {'key': 'City', 'label': 'City (${filterState.selectedCities.length})'},
      {'key': 'Profession', 'label': 'Profession (${filterState.selectedProfessions.length})'},
      {'key': 'Verified', 'label': 'Verified Only'},
      {'key': 'Active', 'label': 'Active Only'},
      {'key': 'Business', 'label': 'Business Category (${filterState.selectedBusinessCategories.length})'},
      {'key': 'Blood Group', 'label': 'Blood Group (${filterState.selectedBloodGroups.length})'},
      {'key': 'Male', 'label': 'Male'},
      {'key': 'Female', 'label': 'Female'},
      {'key': 'Education', 'label': 'Education (${filterState.selectedEducations.length})'},
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chipCategories.length,
        itemBuilder: (context, index) {
          final item = chipCategories[index];
          final key = item['key']!;
          final label = item['label']!;

          bool isSelected = false;
          if (key == 'All') {
            isSelected = filterState.isEmpty;
          } else if (key == 'Village') {
            isSelected = filterState.selectedVillages.isNotEmpty;
          } else if (key == 'City') {
            isSelected = filterState.selectedCities.isNotEmpty;
          } else if (key == 'Profession') {
            isSelected = filterState.selectedProfessions.isNotEmpty;
          } else if (key == 'Verified') {
            isSelected = filterState.isVerifiedOnly == true;
          } else if (key == 'Active') {
            isSelected = filterState.isActiveOnly == true;
          } else if (key == 'Business') {
            isSelected = filterState.selectedBusinessCategories.isNotEmpty;
          } else if (key == 'Blood Group') {
            isSelected = filterState.selectedBloodGroups.isNotEmpty;
          } else if (key == 'Male') {
            isSelected = filterState.selectedGenders.contains('Male');
          } else if (key == 'Female') {
            isSelected = filterState.selectedGenders.contains('Female');
          } else if (key == 'Education') {
            isSelected = filterState.selectedEducations.isNotEmpty;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (key == 'All') {
                  filterNotifier.clearAll();
                } else if (key == 'Verified') {
                  filterNotifier.toggleVerifiedOnly();
                } else if (key == 'Active') {
                  filterNotifier.toggleActiveOnly();
                } else if (key == 'Male') {
                  filterNotifier.toggleGender('Male');
                } else if (key == 'Female') {
                  filterNotifier.toggleGender('Female');
                } else {
                  onSelectCategoryFilter(key);
                }
              },
              showCheckmark: isSelected && key != 'All',
              checkmarkColor: Colors.white,
              selectedColor: AppColors.accentBlue,
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              elevation: isSelected ? 2 : 0,
              pressElevation: 1,
              side: BorderSide(
                color: isSelected
                    ? AppColors.accentBlue
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: 1,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
