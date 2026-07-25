import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../providers/member_providers.dart';
import '../utils/debouncer.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  final VoidCallback onOpenFilter;
  final VoidCallback onOpenSort;

  const SearchBarWidget({
    super.key,
    required this.onOpenFilter,
    required this.onOpenSort,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  late final TextEditingController _controller;
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeFilters = ref.watch(activeFiltersProvider);
    final activeFilterCount = activeFilters.activeFilterCount;
    final sortOption = ref.watch(sortOptionProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search Input Container
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (value) {
                  _debouncer.run(() {
                    ref.read(searchQueryProvider.notifier).state = value;
                  });
                  setState(() {});
                },
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Search name, village, profession...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.accentBlue,
                    size: 22,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, size: 18),
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Filter Trigger Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: activeFilterCount > 0
                      ? AppColors.accentBlue
                      : (isDark ? AppColors.cardDark : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: activeFilterCount > 0
                        ? AppColors.accentBlue
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: activeFilterCount > 0
                        ? Colors.white
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.primaryBlue),
                  ),
                  onPressed: widget.onOpenFilter,
                  tooltip: 'Filter Members',
                ),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.favoriteRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '$activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 6),

          // Sort Button
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: sortOption != SortOption.nameAZ
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.swap_vert_rounded,
                size: 22,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.primaryBlue,
              ),
              onPressed: widget.onOpenSort,
              tooltip: 'Sort Directory',
            ),
          ),
        ],
      ),
    );
  }
}
