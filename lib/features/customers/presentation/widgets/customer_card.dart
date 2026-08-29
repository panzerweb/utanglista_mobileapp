import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';

/*
  One customer in the list.

  What the seller is scanning for is "who owes me, and how much", so
  the balance gets the weight and everything else stays quiet. A
  customer who owes nothing is rendered in muted grey rather than
  green — settled is not an achievement to celebrate on every row, it
  just needs to not compete with the ones that need attention.
*/
class CustomerCard extends StatelessWidget {
  final CustomerEntity customer;
  final CustomerBalance balance;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInactive = !customer.isActive;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppPalette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          // Deactivated customers stay visible and readable, just
          // clearly set back from the active ones (§29).
          opacity: isInactive ? 0.6 : 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _Avatar(initials: customer.initials, isInactive: isInactive),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body1.copyWith(
                                color: AppPalette.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          if (isInactive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.textMuted.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Inactive',
                                style: AppTextStyles.caption1.copyWith(
                                  color: AppPalette.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 3),

                      Text(
                        customer.hasContactNumber
                            ? customer.contactNumber!
                            : 'No contact number',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption1.copyWith(
                          color: AppPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balance.outstanding.format(),
                      style: AppTextStyles.body1.copyWith(
                        color: balance.hasDebt
                            ? AppPalette.primaryDark
                            : AppPalette.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      balance.hasDebt ? 'Utang' : 'Settled',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final bool isInactive;

  const _Avatar({required this.initials, required this.isInactive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isInactive
            ? AppPalette.surfaceSubtle
            : AppPalette.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppTextStyles.body1.copyWith(
          color: isInactive ? AppPalette.textMuted : AppPalette.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
