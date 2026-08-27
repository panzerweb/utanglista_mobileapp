import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/extensions/store_category_extensions.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/stores/domain/entities/store_entity.dart';

/*
  One store in the list.

  The outstanding total is the reason this app exists, so it gets the
  most visual weight on the card — a store owner scanning the list is
  looking for how much they are owed, not for a store's description.

  The figure is real, not a placeholder: CustomerBalanceRepository can
  already total a store. It simply reads ₱0.00 until Phase 4 starts
  writing transactions.
*/
class StoreCard extends StatelessWidget {
  final StoreEntity store;
  final CustomerBalance balance;
  final VoidCallback onTap;

  const StoreCard({
    super.key,
    required this.store,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = store.category;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category?.softColor ?? AppPalette.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category?.icon ?? Icons.store_outlined,
                      color: category?.color ?? AppPalette.textSecondary,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subtitle1.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (category != null)
                              _Badge(
                                label: category.label,
                                color: category.color,
                                background: category.softColor,
                              ),

                            // Only shown when interest actually applies —
                            // enabled at 0% charges nothing, so badging it
                            // would promise a feature that does nothing.
                            if (store.chargesInterest)
                              _Badge(
                                label:
                                    '${store.monthlyInterestRate.formatPercent()} monthly',
                                color: AppPalette.warning,
                                background: AppPalette.warning.withValues(
                                  alpha: 0.12,
                                ),
                                icon: Icons.percent_rounded,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppPalette.textMuted,
                  ),
                ],
              ),

              if (store.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  store.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1, color: AppPalette.border),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total utang',
                        style: AppTextStyles.caption1.copyWith(
                          color: AppPalette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        balance.outstanding.format(),
                        style: AppTextStyles.subtitle1.copyWith(
                          // A settled store is not a warning — grey it
                          // so the ones with money outstanding stand out.
                          color: balance.hasDebt
                              ? AppPalette.primaryDark
                              : AppPalette.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    AppDateFormat.medium(store.createdAt),
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
