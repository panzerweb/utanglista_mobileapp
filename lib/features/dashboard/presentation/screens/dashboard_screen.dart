import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/extensions/store_category_extensions.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/services/data_reset_notifier.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/main_app_bar.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utanglista_mobileapp/features/dashboard/presentation/bloc/dashboard_cubit.dart';

/*
  ------------------------------------------------------------------
  The at-a-glance screen.
  ------------------------------------------------------------------

  Ordered by what a seller opens the app to find out:

    1. how much am I owed, in total
    2. is there anything I need to do (interest)
    3. who owes the most
    4. what happened recently
    5. which store is which

  Every figure comes from the same §15 path the store and customer
  screens use — the dashboard adds no arithmetic of its own.
*/
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<DashboardCubit>()..loadDashboard(),
      // This tab sits in the shell's IndexedStack and is not rebuilt
      // by navigation, so a restore has to tell it to read again.
      child: DataResetListener(
        onReset: (context) => context.read<DashboardCubit>().loadDashboard(),
        child: const _DashboardView(),
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  // Scroll Controllers
  final ScrollController _owesTheMostScrollController = ScrollController();
  final ScrollController _recentActivityScrollController = ScrollController();
  final ScrollController _storesController = ScrollController();

  @override
  void initState() {
    super.initState();

    _loadDashboard();
  }

  /*
    Reloads whenever the user comes back from anywhere the dashboard
    links to — every one of those screens can change a figure on it.
  */
  Future<void> _open(String route) async {
    final cubit = context.read<DashboardCubit>();

    await context.push(route);

    if (mounted) await cubit.loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final cubit = context.read<DashboardCubit>();

    if (mounted) await cubit.loadDashboard();
  }

  @override
  void dispose() {
    _owesTheMostScrollController.dispose();
    _recentActivityScrollController.dispose();
    _storesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: const MainAppBar(),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final cubit = context.read<DashboardCubit>();

          if (state.isFirstLoad) {
            return const AppLoadingView(message: 'Loading your figures...');
          }

          if (state.status == DashboardStateStatus.failure &&
              state.error != null &&
              !state.summary.hasStores) {
            return AppErrorView(
              failure: state.error!,
              onRetry: cubit.loadDashboard,
            );
          }

          if (state.isEmpty) {
            return EmptyStateView(
              icon: Icons.storefront_outlined,
              title: 'Nothing to show yet',
              message:
                  'Create your first store to start tracking utang. '
                  'Your totals will appear here.',
              actionLabel: 'Try to Refresh',
              onAction: () => _loadDashboard(),
            );
          }

          final summary = state.summary;

          return RefreshIndicator(
            color: AppPalette.primary,
            onRefresh: cubit.loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReceivableCard(summary: summary),

                  if (summary.storesNeedingInterest.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InterestNudge(
                      stores: summary.storesNeedingInterest,
                      onOpen: (store) =>
                          _open(AppRoutes.storeDetail(store.storeId)),
                    ),
                  ],

                  if (summary.topDebtors.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionLabel('Owes the most'),
                    ListView.builder(
                      scrollDirection: Axis.vertical,
                      controller: _owesTheMostScrollController,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summary.topDebtors.length,
                      itemBuilder: (context, index) {
                        final debtor = summary.topDebtors[index];
                        return _DebtorCard(
                          debtor: debtor,
                          onTap: () => _open(
                            AppRoutes.customerDetail(
                              debtor.storeId,
                              debtor.customerId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  if (summary.recentActivity.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionLabel('Recent activity'),
                    ListView.builder(
                      scrollDirection: Axis.vertical,
                      controller: _recentActivityScrollController,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summary.recentActivity.length,
                      itemBuilder: (context, index) {
                        final activity = summary.recentActivity[index];
                        return _ActivityRow(
                          activity: activity,
                          onTap: () => _open(
                            activity.kind == ActivityKind.utang
                                ? AppRoutes.transactionDetail(
                                    activity.storeId,
                                    activity.sourceId,
                                  )
                                : AppRoutes.customerDetail(
                                    activity.storeId,
                                    activity.customerId,
                                  ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                  _SectionLabel('Your stores (${summary.stores.length})'),
                  ListView.builder(
                    scrollDirection: Axis.vertical,
                    controller: _storesController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.stores.length,
                    itemBuilder: (context, index) {
                      final store = summary.stores[index];
                      return _StoreRow(
                        store: store,
                        onTap: () =>
                            _open(AppRoutes.storeDetail(store.storeId)),
                      );
                    },
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
// HEADLINE
// ============================================================
class _ReceivableCard extends StatelessWidget {
  final DashboardSummary summary;

  const _ReceivableCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.primaryDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total receivable',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.primarySoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.totalReceivable.format(),
                      style: AppTextStyles.heading1.copyWith(
                        color: AppPalette.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppPalette.surface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(color: AppPalette.primary.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 14),

          // The §15 breakdown, so the headline is checkable.
          Row(
            children: [
              _Stat(label: 'Utang', value: summary.overall.totalUtang.format()),
              _Stat(
                label: 'Interest',
                value: summary.overall.totalInterest.format(),
              ),
              _Stat(label: 'Paid', value: summary.overall.totalPaid.format()),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            '${summary.totalDebtors} of ${summary.totalCustomers} '
            '${summary.totalCustomers == 1 ? 'customer' : 'customers'} '
            'still owe you',
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.primarySoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.primarySoft,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.surface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INTEREST NUDGE
// ============================================================
/*
  The one thing on this screen that asks the seller to DO something.

  Only appears when a store charges interest and this month has
  something chargeable that has not been charged — computed by running
  the real preview, so tapping through never shows "nothing to charge".
*/
class _InterestNudge extends StatelessWidget {
  final List<StoreSummary> stores;
  final ValueChanged<StoreSummary> onOpen;

  const _InterestNudge({required this.stores, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final month = AppDateFormat.monthYear(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.percent_rounded,
                size: 18,
                color: AppPalette.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$month interest not charged yet',
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            stores.length == 1
                ? '${stores.single.storeName} has interest to charge this '
                      'month.'
                : '${stores.length} stores have interest to charge this '
                      'month.',
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          for (final store in stores)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OutlinedButton.icon(
                onPressed: () => onOpen(store),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('Open ${store.storeName}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.warning,
                  side: BorderSide(
                    color: AppPalette.warning.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// TOP DEBTORS
// ============================================================
class _DebtorCard extends StatelessWidget {
  final TopDebtor debtor;
  final VoidCallback onTap;

  const _DebtorCard({required this.debtor, required this.onTap});

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debtor.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body1.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // The dashboard spans stores, so this is never
                    // redundant the way it is on a store screen.
                    Text(
                      debtor.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                debtor.balance.outstanding.format(),
                style: AppTextStyles.body1.copyWith(
                  color: AppPalette.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RECENT ACTIVITY
// ============================================================
class _ActivityRow extends StatelessWidget {
  final RecentActivity activity;
  final VoidCallback onTap;

  const _ActivityRow({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCredit = activity.isCredit;
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
                child: Icon(
                  isCredit
                      ? Icons.payments_outlined
                      : Icons.shopping_basket_outlined,
                  size: 16,
                  color: accent,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body1.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${activity.storeName} • '
                      '${AppDateFormat.relative(activity.occurredAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // The §15 sign convention, per event.
              Text(
                '${isCredit ? '−' : '+'}${activity.amount.format()}',
                style: AppTextStyles.body1.copyWith(
                  color: accent,
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

// ============================================================
// STORES
// ============================================================
class _StoreRow extends StatelessWidget {
  final StoreSummary store;
  final VoidCallback onTap;

  const _StoreRow({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = store.category;

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
                  color: category?.softColor ?? AppPalette.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category?.icon ?? Icons.store_outlined,
                  size: 18,
                  color: category?.color ?? AppPalette.textSecondary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body1.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      store.customerCount == 0
                          ? 'No customers yet'
                          : '${store.debtorCount} of '
                                '${store.customerCount} owe you',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                store.balance.outstanding.format(),
                style: AppTextStyles.body1.copyWith(
                  // A settled store is not a warning — grey it so the
                  // ones with money outstanding stand out.
                  color: store.balance.hasDebt
                      ? AppPalette.primaryDark
                      : AppPalette.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption1.copyWith(
          color: AppPalette.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
