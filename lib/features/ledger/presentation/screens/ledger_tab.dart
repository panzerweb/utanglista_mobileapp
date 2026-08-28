import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/ledger/domain/entities/ledger_entry.dart';
import 'package:utanglista_mobileapp/features/ledger/presentation/bloc/ledger_cubit.dart';

/*
  ------------------------------------------------------------------
  The §17 ledger, as the seller reads it.
  ------------------------------------------------------------------

      Aug 23   INTEREST   Monthly (2%)     +₱9.00     ₱559.00
      Aug 23   UTANG      3 items         +₱150.00    ₱550.00
      Aug 22   PAYMENT    Partial         −₱200.00    ₱400.00

  Rendered NEWEST FIRST, though the running balance is computed
  oldest-first — so the top row's balance is what the customer owes
  right now, which is why the seller opened this screen.

  Every row is a projection of an immutable record (§14, §30), so
  there is nothing to edit here. Tapping an utang opens its
  transaction; payments and interest have no deeper detail.

  ------------------------------------------------------------------
  NO SEARCH, NO SORT — and that is deliberate.
  ------------------------------------------------------------------

  Every other list in the app gained both in Phase 8. This one did
  not, because the running balance in the right-hand column is only
  correct in one order.

  A running balance is a fold over the rows BEFORE it. Filter the list
  and every balance below the hidden row is wrong by the amount of
  that row — the screen would show ₱559.00 for a customer who owes
  ₱400.00, with nothing on it to say why. Re-sort the list and the
  column stops meaning anything at all: "balance after this event" has
  no reading when the events are ordered by size.

  A seller who wants to find one utang has the Utang tab; one payment,
  the Payments tab. Both ARE searchable and sortable, because neither
  carries a running total.
*/
class LedgerTab extends StatelessWidget {
  final int storeId;
  final int customerId;

  const LedgerTab({
    super.key,
    required this.storeId,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          locator<LedgerCubit>(param1: customerId)..loadLedger(),
      child: _LedgerView(storeId: storeId),
    );
  }
}

class _LedgerView extends StatelessWidget {
  final int storeId;

  const _LedgerView({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LedgerCubit, LedgerState>(
      builder: (context, state) {
        final cubit = context.read<LedgerCubit>();

        if (state.status == LedgerStateStatus.loading && state.rows.isEmpty) {
          return const AppLoadingView(message: 'Building ledger...');
        }

        if (state.status == LedgerStateStatus.failure && state.error != null) {
          return AppErrorView(failure: state.error!, onRetry: cubit.loadLedger);
        }

        if (state.isEmpty) {
          return const EmptyStateView(
            icon: Icons.receipt_long_outlined,
            title: 'Nothing recorded yet',
            message:
                'Every utang, payment and interest charge will appear here '
                'in order, with the running balance.',
          );
        }

        final rows = state.newestFirst;

        return RefreshIndicator(
          color: AppPalette.primary,
          onRefresh: cubit.loadLedger,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: rows.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _LedgerHeader(state: state);

              final row = rows[index - 1];

              return _LedgerRowTile(
                row: row,
                onTap: row.entry is LedgerUtangEntry
                    ? () => context.push(
                        AppRoutes.transactionDetail(
                          storeId,
                          row.entry.sourceId,
                        ),
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

class _LedgerHeader extends StatelessWidget {
  final LedgerState state;

  const _LedgerHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance now',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.currentBalance.format(),
                  style: AppTextStyles.subtitle1.copyWith(
                    color: state.currentBalance.isPositive
                        ? AppPalette.primaryDark
                        : AppPalette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                state.rows.length == 1 ? 'Entry' : 'Entries',
                style: AppTextStyles.caption1.copyWith(
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${state.rows.length}',
                style: AppTextStyles.subtitle1.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerRowTile extends StatelessWidget {
  final LedgerRow row;
  final VoidCallback? onTap;

  const _LedgerRowTile({required this.row, this.onTap});

  @override
  Widget build(BuildContext context) {
    final entry = row.entry;
    final isCredit = entry.signedAmount.isNegative;

    final (icon, label, description) = switch (entry) {
      LedgerUtangEntry(:final description) => (
        Icons.shopping_basket_outlined,
        'UTANG',
        description,
      ),
      LedgerPaymentEntry(:final description) => (
        Icons.payments_outlined,
        'PAYMENT',
        description,
      ),
      LedgerInterestEntry(:final rateBasisPoints, :final periodKey) => (
        Icons.percent_rounded,
        'INTEREST',
        '${InterestRate.fromBasisPoints(rateBasisPoints).formatPercent()} '
            '— ${AppDateFormat.periodLabel(periodKey)}',
      ),
    };

    // Payments are the only thing that reduces the balance, so they get
    // the one different colour on this screen.
    final accent = isCredit ? AppPalette.success : AppPalette.primaryDark;

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.caption1.copyWith(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppDateFormat.medium(entry.occurredAt),
                            style: AppTextStyles.caption1.copyWith(
                              color: AppPalette.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body1.copyWith(
                        color: AppPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // The sign IS the §15 formula, per event.
                  Text(
                    '${isCredit ? '−' : '+'}${entry.amount.format()}',
                    style: AppTextStyles.body1.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.balanceAfter.format(),
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
    );
  }
}
