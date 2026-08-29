import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_entity.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/bloc/transaction_state.dart';

/*
  ------------------------------------------------------------------
  A committed transaction, in full. Read-only, on purpose.
  ------------------------------------------------------------------

  §31: once committed, quantity, unit price, subtotal, total and
  customer may not be casually edited — and §14 says a payment never
  changes any of them either. This screen therefore has no edit action.

  It SAYS so rather than just omitting the button, because a missing
  action reads as an oversight while an explained one reads as a rule.
  When corrections arrive they will be explicit reversal entries
  (§31), not edits to this record.
*/
class TransactionDetailScreen extends StatelessWidget {
  final int storeId;
  final int transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.storeId,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          locator<TransactionDetailCubit>()..loadTransaction(transactionId),
      child: _TransactionDetailView(transactionId: transactionId),
    );
  }
}

class _TransactionDetailView extends StatelessWidget {
  final int transactionId;

  const _TransactionDetailView({required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.primaryDark,
        foregroundColor: AppPalette.surface,
        title: Text(
          'Utang details',
          style: AppTextStyles.body1.copyWith(
            color: AppPalette.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<TransactionDetailCubit, TransactionDetailState>(
        builder: (context, state) {
          if (state.status == TransactionDetailStateStatus.failure &&
              state.error != null) {
            return AppErrorView(
              failure: state.error!,
              onRetry: () => context
                  .read<TransactionDetailCubit>()
                  .loadTransaction(transactionId),
            );
          }

          final transaction = state.transaction;

          if (transaction == null) {
            return const AppLoadingView(message: 'Loading...');
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Header(transaction: transaction),

              const SizedBox(height: 20),

              _ItemsCard(transaction: transaction),

              if (transaction.hasNote) ...[
                const SizedBox(height: 20),
                _NoteCard(note: transaction.note),
              ],

              const SizedBox(height: 20),

              const _ImmutabilityNotice(),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TransactionEntity transaction;

  const _Header({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total utang',
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.primarySoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            transaction.totalAmount.format(),
            style: AppTextStyles.heading1.copyWith(
              color: AppPalette.surface,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 15,
                color: AppPalette.primarySoft,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  transaction.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppPalette.primarySoft,
              ),
              const SizedBox(width: 6),
              Text(
                AppDateFormat.withTime(transaction.createdAt),
                style: AppTextStyles.caption1.copyWith(
                  color: AppPalette.primarySoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/*
  Every line, with the price it was SOLD at (§7).

  The footer restates the total from the same rows the lines came
  from — §8 requires the persisted total to equal the sum of subtotals,
  and this is where a seller could actually notice if it did not.
*/
class _ItemsCard extends StatelessWidget {
  final TransactionEntity transaction;

  const _ItemsCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  'ITEMS',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  transaction.itemSummary,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppPalette.border),

          for (final item in transaction.items)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body1.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // '5 kg × ₱100.00' — the §7 worked example.
                        Text(
                          item.lineLabel,
                          style: AppTextStyles.caption1.copyWith(
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    item.subTotal.format(),
                    style: AppTextStyles.body1.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1, color: AppPalette.border),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  transaction.totalAmount.format(),
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppPalette.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sticky_note_2_outlined,
                size: 15,
                color: AppPalette.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'NOTE',
                style: AppTextStyles.caption1.copyWith(
                  color: AppPalette.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: AppTextStyles.body1.copyWith(
              color: AppPalette.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// See the class note on TransactionDetailScreen — the rule is stated,
/// not silently enforced by a missing button.
class _ImmutabilityNotice extends StatelessWidget {
  const _ImmutabilityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppPalette.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recorded utang cannot be edited. Payments reduce what the '
              'customer owes without changing this record.',
              style: AppTextStyles.caption1.copyWith(
                color: AppPalette.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
