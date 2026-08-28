import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/extensions/store_category_extensions.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_confirm_dialog.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/screens/customers_tab.dart';
import 'package:utanglista_mobileapp/features/products/presentation/screens/products_tab.dart';
import 'package:utanglista_mobileapp/features/stores/domain/entities/store_entity.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/bloc/store_cubit.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/bloc/store_state.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/screens/transactions_tab.dart';

/*
  ------------------------------------------------------------------
  The store's home: one route, four tabs.
  ------------------------------------------------------------------

  Tabs rather than four routes, so switching between a store's
  customers and its products does not push history the user then has to
  back out of one screen at a time.

  The tab list is meant to grow — Reports, Ledger export and whatever
  else "and more..." turns out to be all land here, and none of them
  touch the three-destination bottom bar.

  All four tabs are real as of Phase 4.
*/
class StoreDetailScreen extends StatelessWidget {
  final int storeId;

  const StoreDetailScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => locator<StoreDetailCubit>()..loadStore(storeId),
        ),
        BlocProvider(create: (_) => locator<StoreFormCubit>()),
      ],
      child: _StoreDetailView(storeId: storeId),
    );
  }
}

class _StoreDetailView extends StatelessWidget {
  final int storeId;

  const _StoreDetailView({required this.storeId});

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<StoreDetailCubit>();

    await context.push(AppRoutes.editStore(storeId));

    if (context.mounted) await cubit.loadStore(storeId);
  }

  /*
    Deleting a store cascades to its customers, products, transactions
    and payments (§30). The dialog spells that out rather than asking a
    generic "are you sure?", because the consequence is invisible from
    this screen.
  */
  Future<void> _confirmDelete(BuildContext context, StoreEntity store) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete ${store.name}?',
      message:
          'Its customers, products, transactions and payment history will '
          'be permanently removed. This cannot be undone.',
      confirmLabel: 'Delete store',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) return;

    await context.read<StoreFormCubit>().deleteStore(store.id);
  }

  void _onFormState(BuildContext context, StoreFormState state) {
    switch (state) {
      case StoreFormDeleted():
        AppSnackBar.success(context, 'Store deleted.');
        context.pop();

      case StoreFormFailure(:final error):
        AppSnackBar.failure(context, error);

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StoreFormCubit, StoreFormState>(
      listener: _onFormState,
      child: BlocBuilder<StoreDetailCubit, StoreDetailState>(
        builder: (context, state) {
          if (state.status == StoreDetailStateStatus.failure &&
              state.error != null) {
            return Scaffold(
              backgroundColor: AppPalette.background,
              appBar: AppBar(
                backgroundColor: AppPalette.primaryDark,
                foregroundColor: AppPalette.surface,
                title: const Text('Store'),
              ),
              body: AppErrorView(
                failure: state.error!,
                onRetry: () =>
                    context.read<StoreDetailCubit>().loadStore(storeId),
              ),
            );
          }

          final store = state.store;

          if (store == null) {
            return Scaffold(
              backgroundColor: AppPalette.background,
              appBar: AppBar(
                backgroundColor: AppPalette.primaryDark,
                foregroundColor: AppPalette.surface,
                title: const Text('Store'),
              ),
              body: const AppLoadingView(message: 'Loading store...'),
            );
          }

          return DefaultTabController(
            length: 4,
            child: Scaffold(
              backgroundColor: AppPalette.background,
              appBar: AppBar(
                backgroundColor: AppPalette.primaryDark,
                foregroundColor: AppPalette.surface,
                title: Text(
                  store.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Edit store',
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete store',
                    onPressed: () => _confirmDelete(context, store),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
                bottom: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppPalette.surface,
                  labelColor: AppPalette.surface,
                  unselectedLabelColor: AppPalette.primarySoft,
                  tabs: [
                    Tab(text: 'Customers'),
                    Tab(text: 'Products'),
                    Tab(text: 'Transactions'),
                    Tab(text: 'Settings'),
                  ],
                ),
              ),
              body: Column(
                children: [
                  _StoreSummaryHeader(state: state, store: store),

                  Expanded(
                    child: TabBarView(
                      children: [
                        CustomersTab(storeId: storeId),

                        ProductsTab(storeId: storeId),
                        TransactionsTab(storeId: storeId),
                        const _SettingsTab(),
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
}

// ============================================================
// HEADER
// ============================================================
class _StoreSummaryHeader extends StatelessWidget {
  final StoreDetailState state;
  final StoreEntity store;

  const _StoreSummaryHeader({required this.state, required this.store});

  @override
  Widget build(BuildContext context) {
    final category = store.category;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total utang',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.balance.outstanding.format(),
                  style: AppTextStyles.title1.copyWith(
                    color: state.balance.hasDebt
                        ? AppPalette.primaryDark
                        : AppPalette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (category != null) ...[
                      Icon(category.icon, size: 13, color: category.color),
                      const SizedBox(width: 4),
                      Text(
                        category.label,
                        style: AppTextStyles.caption1.copyWith(
                          color: category.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      'Since ${AppDateFormat.medium(store.createdAt)}',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (store.chargesInterest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppPalette.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.percent_rounded,
                    size: 15,
                    color: AppPalette.warning,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.monthlyInterestRate.formatPercent(),
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.warning,
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

// ============================================================
// SETTINGS TAB
// ============================================================
/*
  Read-only for now: editing goes through the store form, which already
  owns the interest rules and their validation. A second editable copy
  here would be a second place for §19 to be enforced.
*/
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreDetailCubit, StoreDetailState>(
      builder: (context, state) {
        final store = state.store;
        if (store == null) return const SizedBox.shrink();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SettingsRow(
              icon: Icons.storefront_outlined,
              label: 'Category',
              value: store.category?.label ?? 'Not set',
            ),
            _SettingsRow(
              icon: Icons.notes_rounded,
              label: 'Description',
              value: store.description.isEmpty ? 'Not set' : store.description,
            ),
            _SettingsRow(
              icon: Icons.percent_rounded,
              label: 'Monthly interest',
              value: store.monthlyInterestEnabled
                  ? store.monthlyInterestRate.formatPercent()
                  : 'Off',
            ),
            _SettingsRow(
              icon: Icons.calendar_today_rounded,
              label: 'Created',
              value: AppDateFormat.full(store.createdAt),
            ),

            const SizedBox(height: 20),

            /*
              Interest actions live here rather than on a tab of their
              own: charging it is a monthly chore tied to the store's
              settings, not a place the seller browses.

              Only shown when interest is actually configured (§19 —
              it is optional, and enabled-at-0% charges nothing).
            */
            if (store.chargesInterest) ...[
              FilledButton.icon(
                onPressed: () => context.push(
                  AppRoutes.applyInterest(store.id),
                  extra: ApplyInterestRequest(rate: store.monthlyInterestRate),
                ),
                icon: const Icon(Icons.percent_rounded, size: 20),
                label: Text(
                  'Charge ${store.monthlyInterestRate.formatPercent()} '
                  'monthly interest',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.warning,
                  foregroundColor: AppPalette.surface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.interestHistory(store.id)),
                icon: const Icon(Icons.history_rounded, size: 20),
                label: const Text('Interest history'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.textSecondary,
                  side: const BorderSide(color: AppPalette.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],

            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.editStore(store.id)),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Edit store details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.primaryDark,
                side: const BorderSide(color: AppPalette.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppPalette.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.textPrimary,
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
