import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/sort_menu_button.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/app_search_field.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/interest/domain/entities/interest_record_entity.dart';
import 'package:utanglista_mobileapp/features/interest/presentation/bloc/interest_cubit.dart';

/*
  Every interest charge this store has made, grouped by the month it
  covers.

  Read-only: §21 records are permanent financial events, and §30 keeps
  them. Each row shows the base and the rate it was charged at, because
  a charge nobody can check the arithmetic on is a charge a customer
  cannot be shown.
*/
class InterestHistoryScreen extends StatelessWidget {
  final int storeId;
  final int? customerId;

  const InterestHistoryScreen({
    super.key,
    required this.storeId,
    this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          locator<InterestHistoryCubit>(param1: storeId, param2: customerId)
            ..loadRecords(),
      child: _InterestHistoryView(showCustomerName: customerId == null),
    );
  }
}

class _InterestHistoryView extends StatelessWidget {
  final bool showCustomerName;

  const _InterestHistoryView({required this.showCustomerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.primaryDark,
        foregroundColor: AppPalette.surface,
        title: Text(
          'Interest history',
          style: AppTextStyles.body1.copyWith(
            color: AppPalette.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<InterestHistoryCubit, InterestHistoryState>(
        builder: (context, state) {
          final cubit = context.read<InterestHistoryCubit>();

          /*
            The search bar is hidden on a single customer's history:
            every row is that person, so the only thing to match on is
            their own name. The sort still earns its place there.
          */
          return Column(
            children: [
              _SearchAndSortBar(
                state: state,
                cubit: cubit,
                showSearch: showCustomerName,
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
    InterestHistoryState state,
    InterestHistoryCubit cubit,
  ) {
    if (state.status == InterestHistoryStatus.loading &&
        state.records.isEmpty &&
        state.search.isEmpty) {
      return const AppLoadingView(message: 'Loading interest...');
    }

    if (state.status == InterestHistoryStatus.failure && state.error != null) {
      return AppErrorView(failure: state.error!, onRetry: cubit.loadRecords);
    }

    if (state.isFilteredEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No charges found',
        message: 'Nothing matches "${state.search}".',
        actionLabel: 'Clear search',
        onAction: cubit.clearSearch,
      );
    }

    if (state.isEmpty) {
      return const EmptyStateView(
        icon: Icons.percent_rounded,
        title: 'No interest charged yet',
        message:
            'Monthly interest charges will be listed here, grouped '
            'by the month they cover.',
      );
    }

    /*
            Sorted by amount, the rows cross months freely, so month
            headings would repeat and jump. The list renders flat.
          */
    if (!state.isGroupedByPeriod) {
      return RefreshIndicator(
        color: AppPalette.primary,
        onRefresh: cubit.loadRecords,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: state.records.length,
          itemBuilder: (context, index) => _RecordCard(
            record: state.records[index],
            showCustomerName: showCustomerName,
            // Flat, so each row has to say which month it covers
            // — the heading that used to say so is gone.
            showPeriod: true,
          ),
        ),
      );
    }

    final periods = state.byPeriod;
    final periodKeys = periods.keys.toList();

    return RefreshIndicator(
      color: AppPalette.primary,
      onRefresh: cubit.loadRecords,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: periodKeys.length,
        itemBuilder: (context, index) {
          final periodKey = periodKeys[index];
          final records = periods[periodKey]!;
          final total = records.map((record) => record.interestAmount).sum();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                child: Row(
                  children: [
                    Text(
                      AppDateFormat.periodLabel(periodKey),
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      total.format(),
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              for (final record in records)
                _RecordCard(record: record, showCustomerName: showCustomerName),

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// SEARCH + SORT
// ============================================================
class _SearchAndSortBar extends StatelessWidget {
  final InterestHistoryState state;
  final InterestHistoryCubit cubit;

  /// False on one customer's history, where searching their own name
  /// would match every row.
  final bool showSearch;

  const _SearchAndSortBar({
    required this.state,
    required this.cubit,
    required this.showSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: AppPalette.background,
      child: Row(
        children: [
          if (showSearch) ...[
            Expanded(
              child: AppSearchField(
                value: state.search,
                hintText: 'Customer',
                onChanged: cubit.search,
                onClear: cubit.clearSearch,
              ),
            ),
            const SizedBox(width: 8),
          ] else
            const Spacer(),

          SortMenuButton<InterestSort>(
            compact: showSearch,
            selected: state.sort,
            items: InterestSort.values,
            itemLabel: (sort) => sort.label,
            onSelected: cubit.setSort,
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final InterestRecordEntity record;
  final bool showCustomerName;

  /// True when the list is flat, so no month heading sits above this
  /// row to say which period the charge covers.
  final bool showPeriod;

  const _RecordCard({
    required this.record,
    required this.showCustomerName,
    this.showPeriod = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppPalette.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.percent_rounded,
              size: 17,
              color: AppPalette.warning,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showCustomerName
                      ? record.customerName
                      : AppDateFormat.medium(record.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                // The arithmetic, spelled out: rate × base = charge,
                // plus the month it covers when nothing else says so.
                Text(
                  showPeriod
                      ? '${record.rate.formatPercent()} of '
                            '${record.baseAmount.format()} · '
                            '${AppDateFormat.periodLabel(record.periodKey)}'
                      : '${record.rate.formatPercent()} of '
                            '${record.baseAmount.format()}',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '+${record.interestAmount.format()}',
            style: AppTextStyles.body1.copyWith(
              color: AppPalette.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
