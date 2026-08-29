import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_confirm_dialog.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_state.dart';
import 'package:utanglista_mobileapp/features/ledger/presentation/screens/ledger_tab.dart';
import 'package:utanglista_mobileapp/features/payments/presentation/screens/payments_tab.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/screens/transactions_tab.dart';

/*
  ------------------------------------------------------------------
  One customer: what they owe, and how it got that way.
  ------------------------------------------------------------------

  Three tabs, matching the three kinds of financial event in §17:
  the merged Ledger, the Utang that added to it, and the Payments that
  reduced it. All three are real as of Phase 5.
*/
class CustomerDetailScreen extends StatelessWidget {
  final int storeId;
  final int customerId;

  const CustomerDetailScreen({
    super.key,
    required this.storeId,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              locator<CustomerDetailCubit>()..loadCustomer(customerId),
        ),
        BlocProvider(create: (_) => locator<CustomerFormCubit>()),
      ],
      child: _CustomerDetailView(storeId: storeId, customerId: customerId),
    );
  }
}

class _CustomerDetailView extends StatelessWidget {
  final int storeId;
  final int customerId;

  const _CustomerDetailView({required this.storeId, required this.customerId});

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<CustomerDetailCubit>();

    await context.push(AppRoutes.editCustomer(storeId, customerId));

    if (context.mounted) await cubit.loadCustomer(customerId);
  }

  /*
    Opens the builder with this customer already chosen. Reloads on
    return so the balance header reflects the new utang immediately —
    the whole point of recording it from here.
  */
  Future<void> _recordUtang(BuildContext context) async {
    final cubit = context.read<CustomerDetailCubit>();

    await context.push(
      AppRoutes.newTransaction(storeId),
      extra: TransactionBuilderRequest(customerId: customerId),
    );

    if (context.mounted) await cubit.loadCustomer(customerId);
  }

  /// §23's screen. Reloads on return so the header, the ledger and the
  /// payment cap all agree immediately afterwards.
  Future<void> _recordPayment(
    BuildContext context,
    CustomerEntity customer,
  ) async {
    final cubit = context.read<CustomerDetailCubit>();

    await context.push(
      AppRoutes.newPayment(storeId, customerId),
      extra: RecordPaymentRequest(customerName: customer.name),
    );

    if (context.mounted) await cubit.loadCustomer(customerId);
  }

  /*
    §29: deactivating is reversible and keeps every record. The dialog
    says what actually changes — that they cannot take on new utang —
    rather than implying anything is being removed.
  */
  Future<void> _toggleActive(
    BuildContext context,
    CustomerEntity customer,
  ) async {
    final formCubit = context.read<CustomerFormCubit>();

    if (customer.isActive) {
      final confirmed = await AppConfirmDialog.show(
        context,
        title: 'Deactivate ${customer.name}?',
        message:
            'They will not be able to take new utang, but their balance '
            'and full history are kept. You can reactivate them anytime.',
        confirmLabel: 'Deactivate',
      );

      if (!confirmed) return;
    }

    await formCubit.setActive(customer.id, isActive: !customer.isActive);
  }

  /*
    Deletion is only ever offered to a customer with no financial
    record at all (§29, §30) — someone added by mistake, before any
    utang was recorded. The repository refuses the rest, and the
    foreign keys refuse it after that.
  */
  Future<void> _delete(BuildContext context, CustomerEntity customer) async {
    final formCubit = context.read<CustomerFormCubit>();

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete ${customer.name}?',
      message:
          'This customer has no transactions or payments, so nothing '
          'financial will be lost. This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    await formCubit.deleteCustomer(customer.id);
  }

  void _onFormState(BuildContext context, CustomerFormState state) {
    switch (state) {
      case CustomerActiveStateChanged(:final isActive):
        AppSnackBar.success(
          context,
          isActive ? 'Customer reactivated.' : 'Customer deactivated.',
        );
        context.read<CustomerDetailCubit>().loadCustomer(customerId);

      case CustomerFormDeleted():
        AppSnackBar.success(context, 'Customer deleted.');
        context.pop();

      case CustomerFormFailure(:final error):
        AppSnackBar.failure(context, error);

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerFormCubit, CustomerFormState>(
      listener: _onFormState,
      child: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
        builder: (context, state) {
          if (state.status == CustomerDetailStateStatus.failure &&
              state.error != null) {
            return Scaffold(
              backgroundColor: AppPalette.background,
              appBar: _appBar(context, title: 'Customer'),
              body: AppErrorView(
                failure: state.error!,
                onRetry: () => context
                    .read<CustomerDetailCubit>()
                    .loadCustomer(customerId),
              ),
            );
          }

          final customer = state.customer;

          if (customer == null) {
            return Scaffold(
              backgroundColor: AppPalette.background,
              appBar: _appBar(context, title: 'Customer'),
              body: const AppLoadingView(message: 'Loading customer...'),
            );
          }

          return DefaultTabController(
            length: 3,
            child: Scaffold(
              backgroundColor: AppPalette.background,
              floatingActionButton: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  /*
                    Paying is offered only when there is something to
                    pay (§23) — and it stays available for a
                    DEACTIVATED customer, because settling an old debt
                    is exactly what a deactivated account still needs
                    to be able to do.
                  */
                  if (state.balance.hasDebt)
                    FloatingActionButton.extended(
                      heroTag: 'record-payment',
                      onPressed: () => _recordPayment(context, customer),
                      backgroundColor: AppPalette.success,
                      foregroundColor: AppPalette.surface,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Record payment'),
                    ),

                  const SizedBox(height: 10),

                  // §29: a deactivated customer cannot take new utang,
                  // so the action is absent rather than disabled.
                  if (customer.isActive)
                    FloatingActionButton.extended(
                      heroTag: 'record-utang',
                      onPressed: () => _recordUtang(context),
                      backgroundColor: AppPalette.primaryDark,
                      foregroundColor: AppPalette.surface,
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('New utang'),
                    ),
                ],
              ),
              appBar: AppBar(
                backgroundColor: AppPalette.primaryDark,
                foregroundColor: AppPalette.surface,
                title: Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Edit customer',
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  _OverflowMenu(
                    customer: customer,
                    canDelete: state.canDelete,
                    onToggleActive: () => _toggleActive(context, customer),
                    onDelete: () => _delete(context, customer),
                  ),
                ],
                bottom: const TabBar(
                  indicatorColor: AppPalette.surface,
                  labelColor: AppPalette.surface,
                  unselectedLabelColor: AppPalette.primarySoft,
                  tabs: [
                    Tab(text: 'Ledger'),
                    Tab(text: 'Utang'),
                    Tab(text: 'Payments'),
                  ],
                ),
              ),
              body: Column(
                children: [
                  _BalanceHeader(customer: customer, balance: state.balance),

                  Expanded(
                    child: TabBarView(
                      children: [
                        LedgerTab(
                          storeId: storeId,
                          customerId: customerId,
                        ),
                        TransactionsTab(
                          storeId: storeId,
                          customerId: customerId,
                          // The screen's own FAB records the utang.
                          showAddButton: false,
                        ),
                        PaymentsTab(
                          storeId: storeId,
                          customerId: customerId,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, {required String title}) {
    return AppBar(
      backgroundColor: AppPalette.primaryDark,
      foregroundColor: AppPalette.surface,
      title: Text(title),
    );
  }
}

// ============================================================
// OVERFLOW MENU
// ============================================================
/*
  Delete is HIDDEN rather than disabled when the customer has history.

  A greyed-out Delete invites the user to hunt for a way to enable it,
  when the real answer is that the record has to be kept (§30) and
  Deactivate is the action they want. Not offering it says that more
  clearly than offering it broken.
*/
class _OverflowMenu extends StatelessWidget {
  final CustomerEntity customer;
  final bool canDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _OverflowMenu({
    required this.customer,
    required this.canDelete,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      color: AppPalette.surface,
      onSelected: (value) {
        switch (value) {
          case 'toggle':
            onToggleActive();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                customer.isActive
                    ? Icons.person_off_outlined
                    : Icons.person_add_alt_rounded,
                size: 20,
                color: AppPalette.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(customer.isActive ? 'Deactivate' : 'Reactivate'),
            ],
          ),
        ),

        if (canDelete)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppPalette.danger,
                ),
                SizedBox(width: 12),
                Text('Delete', style: TextStyle(color: AppPalette.danger)),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// BALANCE HEADER
// ============================================================
/*
  The §15 breakdown, not just the total: utang and interest added,
  payments subtracted. Showing the parts is what makes the total
  auditable by the person who has to trust it.
*/
class _BalanceHeader extends StatelessWidget {
  final CustomerEntity customer;
  final CustomerBalance balance;

  const _BalanceHeader({required this.customer, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding balance',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balance.outstanding.format(),
                      style: AppTextStyles.heading1.copyWith(
                        color: balance.hasDebt
                            ? AppPalette.primaryDark
                            : AppPalette.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              if (!customer.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.textMuted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Inactive',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // The §15 formula, spelled out: utang + interest − payments.
          Row(
            children: [
              _BreakdownCell(
                label: 'Utang',
                value: balance.totalUtang.format(),
                sign: '+',
              ),
              _BreakdownCell(
                label: 'Interest',
                value: balance.totalInterest.format(),
                sign: '+',
              ),
              _BreakdownCell(
                label: 'Paid',
                value: balance.totalPaid.format(),
                sign: '−',
              ),
            ],
          ),

          if (customer.hasContactNumber) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: AppPalette.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  customer.contactNumber!,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppPalette.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Since ${AppDateFormat.medium(customer.createdAt)}',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownCell extends StatelessWidget {
  final String label;
  final String value;
  final String sign;

  const _BreakdownCell({
    required this.label,
    required this.value,
    required this.sign,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$sign$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
