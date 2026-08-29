import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/extensions/store_category_extensions.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  The category filter above the store list.

  "All" is a real, selectable chip rather than a state you reach by
  deselecting — passing null for it is what the copyWith sentinel in
  store_state exists to make possible.
*/
class CategoryFilterBar extends StatelessWidget {
  /// null == All.
  final StoreCategory? selected;
  final ValueChanged<StoreCategory?> onSelected;

  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'All',
            icon: Icons.apps_rounded,
            color: AppPalette.primaryDark,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),

          for (final category in StoreCategory.values)
            _FilterChip(
              label: category.label,
              icon: category.icon,
              color: category.color,
              isSelected: selected == category,
              onTap: () => onSelected(category),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? color : AppPalette.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // Matches the bottom navigation bar's feedback, so filtering
            // feels like the same kind of action as switching tabs.
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : AppPalette.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? AppPalette.surface : color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.caption1.copyWith(
                    color: isSelected
                        ? AppPalette.surface
                        : AppPalette.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
