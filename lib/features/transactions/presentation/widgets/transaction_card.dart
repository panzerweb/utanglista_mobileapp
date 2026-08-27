import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_entity.dart';

/*
  One transaction in a history list.

  The amount is shown with a leading '+' because a transaction always
  ADDS to what a customer owes (§15) — payments carry the '−'. Seeing
  the sign makes the ledger readable at a glance without labels.

  The customer name is hidden on a customer's own Utang tab, where
  repeating it on every row would be noise.
*/
class TransactionCard extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onTap;
  final bool showCustomerName;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    this.showCustomerName = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppPalette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppPalette.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  size: 18,
                  color: AppPalette.primaryDark,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showCustomerName
                          ? transaction.customerName
                          : AppDateFormat.withTime(transaction.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body1.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      showCustomerName
                          ? AppDateFormat.withTime(transaction.createdAt)
                          : (transaction.hasNote
                                ? transaction.note
                                : 'Utang recorded'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),

                    if (showCustomerName && transaction.hasNote) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.sticky_note_2_outlined,
                            size: 11,
                            color: AppPalette.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              transaction.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption1.copyWith(
                                color: AppPalette.textMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Text(
                '+${transaction.totalAmount.format()}',
                style: AppTextStyles.body1.copyWith(
                  color: AppPalette.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
