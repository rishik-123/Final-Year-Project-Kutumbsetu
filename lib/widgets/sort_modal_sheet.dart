import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../providers/member_providers.dart';

class SortModalSheet extends ConsumerWidget {
  const SortModalSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSort = ref.watch(sortOptionProvider);

    final sortOptions = [
      {'option': SortOption.nameAZ, 'icon': Icons.sort_by_alpha, 'desc': 'Sort names from A to Z'},
      {'option': SortOption.nameZA, 'icon': Icons.sort_by_alpha_outlined, 'desc': 'Sort names from Z to A'},
      {'option': SortOption.profession, 'icon': Icons.work_outline, 'desc': 'Group by profession alphabetically'},
      {'option': SortOption.city, 'icon': Icons.location_city_outlined, 'desc': 'Group by city name'},
      {'option': SortOption.village, 'icon': Icons.home_work_outlined, 'desc': 'Group by native village'},
      {'option': SortOption.newestJoined, 'icon': Icons.calendar_month_outlined, 'desc': 'Most recently registered members first'},
      {'option': SortOption.oldestJoined, 'icon': Icons.history_outlined, 'desc': 'First registered community members'},
      {'option': SortOption.verifiedFirst, 'icon': Icons.verified_outlined, 'desc': 'Show verified profiles at the top'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.swap_vert_rounded, color: AppColors.accentBlue),
                const SizedBox(width: 8),
                Text(
                  'Sort Members By',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sortOptions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
              itemBuilder: (context, index) {
                final item = sortOptions[index];
                final option = item['option'] as SortOption;
                final icon = item['icon'] as IconData;
                final desc = item['desc'] as String;
                final isSelected = currentSort == option;

                return ListTile(
                  leading: Icon(
                    icon,
                    color: isSelected
                        ? AppColors.accentBlue
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                      color: isSelected
                          ? AppColors.accentBlue
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                  subtitle: Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.accentBlue)
                      : null,
                  onTap: () {
                    ref.read(sortOptionProvider.notifier).setSortOption(option);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
