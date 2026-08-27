import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
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
      create: (_) => locator<InterestHistoryCubit>(
        param1: storeId,
        param2: customerId,
      )..loadRecords(),
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

          if (state.status == InterestHistoryStatus.loading &&
              state.records.isEmpty) {
            return const AppLoadingView(message: 'Loading interest...');
          }

          if (state.status == InterestHistoryStatus.failure &&
              state.error != null) {
            return AppErrorView(
              failure: state.error!,
              onRetry: cubit.loadRecords,
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
                final total = records
                    .map((record) => record.interestAmount)
                    .sum();

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
                      _RecordCard(
                        record: record,
                        showCustomerName: showCustomerName,
                      ),

                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final InterestRecordEntity record;
  final bool showCustomerName;

  const _RecordCard({required this.record, required this.showCustomerName});

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
                // The arithmetic, spelled out: rate × base = charge.
                Text(
                  '${record.rate.formatPercent()} of '
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
