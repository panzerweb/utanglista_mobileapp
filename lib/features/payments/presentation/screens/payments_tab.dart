import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/payments/domain/entities/payment_entity.dart';
import 'package:utanglista_mobileapp/features/payments/presentation/bloc/payment_cubit.dart';

/*
  Payment history — a store's, or one customer's.

  Read-only: §30 keeps financial records, so there is no edit or
  delete here and their absence is the rule, not an omission.
*/
class PaymentsTab extends StatelessWidget {
  final int storeId;
  final int? customerId;

  const PaymentsTab({super.key, required this.storeId, this.customerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PaymentListCubit>(
        param1: storeId,
        param2: customerId,
      )..loadPayments(),
      child: _PaymentsView(showCustomerName: customerId == null),
    );
  }
}

class _PaymentsView extends StatelessWidget {
  final bool showCustomerName;

  const _PaymentsView({required this.showCustomerName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentListCubit, PaymentListState>(
      builder: (context, state) {
        final cubit = context.read<PaymentListCubit>();

        if (state.status == PaymentListStateStatus.loading &&
            state.payments.isEmpty) {
          return const AppLoadingView(message: 'Loading payments...');
        }

        if (state.status == PaymentListStateStatus.failure &&
            state.error != null) {
          return AppErrorView(
            failure: state.error!,
            onRetry: cubit.loadPayments,
          );
        }

        if (state.isEmpty) {
          return const EmptyStateView(
            icon: Icons.payments_outlined,
            title: 'No payments yet',
            message: 'Money received will be listed here.',
          );
        }

        return RefreshIndicator(
          color: AppPalette.primary,
          onRefresh: cubit.loadPayments,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: state.payments.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _TotalReceived(state: state);

              return _PaymentCard(
                payment: state.payments[index - 1],
                showCustomerName: showCustomerName,
              );
            },
          ),
        );
      },
    );
  }
}

class _TotalReceived extends StatelessWidget {
  final PaymentListState state;

  const _TotalReceived({required this.state});

  @override
  Widget build(BuildContext context) {
    final count = state.payments.length;

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
                  'Total received',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.totalReceived.format(),
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppPalette.success,
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
                count == 1 ? 'Payment' : 'Payments',
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

class _PaymentCard extends StatelessWidget {
  final PaymentEntity payment;
  final bool showCustomerName;

  const _PaymentCard({required this.payment, required this.showCustomerName});

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppPalette.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.payments_outlined,
                size: 18,
                color: AppPalette.success,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showCustomerName
                        ? payment.customerName
                        : AppDateFormat.withTime(payment.createdAt),
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
                        ? AppDateFormat.withTime(payment.createdAt)
                        : (payment.hasNote ? payment.note : 'Payment'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // '−' because a payment REDUCES what is owed (§15).
            Text(
              '−${payment.amount.format()}',
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
