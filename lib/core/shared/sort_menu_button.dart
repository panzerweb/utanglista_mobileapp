import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  COMPONENT: the sort control every list screen shares.

  Generic over [T] for the same reason GlobalGenericDropdown is: the
  sort enums in core/constants/sort_options.dart have no common base
  class, so [itemLabel] tells this widget how to render one.

  A POPUP MENU RATHER THAN CHIPS, deliberately. Sorting is picked
  rarely and then left alone, unlike the category filter on the Stores
  tab, which is toggled constantly and earns its permanent row. A row
  of sort chips would cost vertical space on every screen, every day,
  to serve a decision made once.

  The current option is shown as text beside the icon when there is
  room, and the menu marks it with a check — a sort control that does
  not say what it is currently doing makes the user open it to find
  out.

  Usage:
    SortMenuButton<ProductSort>(
      selected: state.sort,
      items: ProductSort.values,
      itemLabel: (sort) => sort.label,
      onSelected: cubit.setSort,
    );
*/
class SortMenuButton<T> extends StatelessWidget {
  final T selected;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onSelected;

  /// Hides the label text, leaving the icon alone. For bars where the
  /// search field needs every pixel.
  final bool compact;

  const SortMenuButton({
    super.key,
    required this.selected,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      tooltip: 'Sort',
      color: AppPalette.surface,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item,
            child: Row(
              children: [
                Icon(
                  item == selected
                      ? Icons.check_rounded
                      : Icons.remove_rounded,
                  size: 18,
                  // The unselected rows carry a dash at the same size,
                  // so the labels stay on one vertical line instead of
                  // jumping when the check moves.
                  color: item == selected
                      ? AppPalette.primary
                      : Colors.transparent,
                ),

                const SizedBox(width: 10),

                Text(
                  itemLabel(item),
                  style: AppTextStyles.body1.copyWith(
                    color: item == selected
                        ? AppPalette.primaryDark
                        : AppPalette.textPrimary,
                    fontWeight: item == selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          border: Border.all(color: AppPalette.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_vert_rounded,
              size: 20,
              color: AppPalette.primaryDark,
            ),

            if (!compact) ...[
              const SizedBox(width: 6),
              // Constrained so a long option name cannot push the
              // search field off a narrow screen.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  itemLabel(selected),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
