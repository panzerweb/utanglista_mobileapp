import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/sort_menu_button.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/app_search_field.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/widgets/transaction_card.dart';

/*
  Transaction history — a store's, or one customer's.

  The same widget serves the store's Transactions tab and a customer's
  Utang tab; [customerId] is what tells them apart. Two near-identical
  lists would drift apart the first time either was changed.

  Grouped by day, newest first, with a per-day subtotal. A seller
  reading back a week wants "what went out on Tuesday", not a flat
  scroll.
*/
class TransactionsTab extends StatelessWidget {
  final int storeId;

  /// null == the whole store.
  final int? customerId;

  /// Hidden on a customer's tab, where the FAB belongs to their screen.
  final bool showAddButton;

  const TransactionsTab({
    super.key,
    required this.storeId,
    this.customerId,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<TransactionListCubit>(
        param1: storeId,
        param2: customerId,
      )..loadTransactions(),
      child: _TransactionsView(
        storeId: storeId,
        customerId: customerId,
        showAddButton: showAddButton,
      ),
    );
  }
}

class _TransactionsView extends StatefulWidget {
  final int storeId;
  final int? customerId;
  final bool showAddButton;

  const _TransactionsView({
    required this.storeId,
    required this.customerId,
    required this.showAddButton,
  });

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  Future<void> _newTransaction() async {
    final cubit = context.read<TransactionListCubit>();

    await context.push(
      AppRoutes.newTransaction(widget.storeId),
      extra: widget.customerId == null
          ? null
          : TransactionBuilderRequest(customerId: widget.customerId),
    );

    if (mounted) await cubit.loadTransactions();
  }

  Future<void> _openTransaction(int transactionId) async {
    await context.push(
      AppRoutes.transactionDetail(widget.storeId, transactionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      floatingActionButton: widget.showAddButton
          ? FloatingActionButton.extended(
              heroTag: 'add-transaction',
              onPressed: _newTransaction,
              backgroundColor: AppPalette.primaryDark,
              foregroundColor: AppPalette.surface,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New utang'),
            )
          : null,
      body: BlocBuilder<TransactionListCubit, TransactionListState>(
        builder: (context, state) {
          final cubit = context.read<TransactionListCubit>();

          return Column(
            children: [
              _SearchAndSortBar(
                state: state,
                cubit: cubit,
                // On a customer's Utang tab every row is that one
                // person, so searching their name would match
                // everything. Only the note is worth typing there.
                searchesCustomerName: widget.customerId == null,
              ),
              Expanded(child: _buildBody(context, state, cubit)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TransactionListState state,
    TransactionListCubit cubit,
  ) {
    // Only blank on the first load — a search keeps the previous rows
    // underneath rather than flashing the list away on every keystroke.
    if (state.status == TransactionListStateStatus.loading &&
        state.transactions.isEmpty &&
        state.search.isEmpty) {
      return const AppLoadingView(message: 'Loading transactions...');
    }

    if (state.status == TransactionListStateStatus.failure &&
        state.error != null) {
      return AppErrorView(
        failure: state.error!,
        onRetry: cubit.loadTransactions,
      );
    }

    if (state.isFilteredEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No utang found',
        message: 'Nothing matches "${state.search}".',
        actionLabel: 'Clear search',
        onAction: cubit.clearSearch,
      );
    }

    if (state.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'No utang recorded yet',
        message: widget.customerId == null
            ? 'When someone takes something on credit, record it here.'
            : 'This customer has not taken anything on credit yet.',
        actionLabel: widget.showAddButton ? 'Record an utang' : null,
        onAction: widget.showAddButton ? _newTransaction : null,
      );
    }

    return RefreshIndicator(
      color: AppPalette.primary,
      onRefresh: cubit.loadTransactions,
      child: _GroupedList(
        state: state,
        showCustomerName: widget.customerId == null,
        onOpen: _openTransaction,
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  final TransactionListState state;
  final bool showCustomerName;
  final ValueChanged<int> onOpen;

  const _GroupedList({
    required this.state,
    required this.showCustomerName,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    /*
      Sorted by amount, the rows no longer run in date order, so day
      headings would be meaningless — the same date would reappear
      further down the list. The rows render flat instead.
    */
    if (!state.isGroupedByDay) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: state.transactions.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _TotalSummary(state: state);

          final transaction = state.transactions[index - 1];

          return TransactionCard(
            transaction: transaction,
            showCustomerName: showCustomerName,
            onTap: () => onOpen(transaction.id),
          );
        },
      );
    }

    final groups = state.grouped;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      // +1 for the summary header.
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _TotalSummary(state: state);

        final group = groups[index - 1];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
              child: Row(
                children: [
                  Text(
                    AppDateFormat.relative(group.day),
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    group.total.format(),
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            for (final transaction in group.transactions)
              TransactionCard(
                transaction: transaction,
                showCustomerName: showCustomerName,
                onTap: () => onOpen(transaction.id),
              ),
          ],
        );
      },
    );
  }
}

/*
  Total UTANG RECORDED, deliberately not "balance".

  §15 and §18: what a customer owes is the account-level figure —
  transactions plus interest minus payments — and it lives on
  CustomerBalance. Labelling this sum "balance" would be the exact
  mistake §16 warns about, so the wording keeps them apart.
*/
class _TotalSummary extends StatelessWidget {
  final TransactionListState state;

  const _TotalSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final count = state.transactions.length;

    return Container(
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
                  'Total utang recorded',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.totalRecorded.format(),
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppPalette.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Before payments',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count == 1 ? 'Transaction' : 'Transactions',
                style: AppTextStyles.caption1.copyWith(
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count',
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

// ============================================================
// SEARCH + SORT
// ============================================================
class _SearchAndSortBar extends StatelessWidget {
  final TransactionListState state;
  final TransactionListCubit cubit;

  /// False on a customer's own Utang tab, where every row is already
  /// that person.
  final bool searchesCustomerName;

  const _SearchAndSortBar({
    required this.state,
    required this.cubit,
    required this.searchesCustomerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: AppPalette.background,
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              value: state.search,
              hintText: searchesCustomerName ? 'Customer or note' : 'Note',
              onChanged: cubit.search,
              onClear: cubit.clearSearch,
            ),
          ),

          const SizedBox(width: 8),

          SortMenuButton<TransactionSort>(
            compact: true,
            selected: state.sort,
            items: TransactionSort.values,
            itemLabel: (sort) => sort.label,
            onSelected: cubit.setSort,
          ),
        ],
      ),
    );
  }
}
