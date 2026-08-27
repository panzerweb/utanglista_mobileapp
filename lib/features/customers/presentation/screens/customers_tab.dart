import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_state.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/widgets/customer_card.dart';

/*
  The Customers tab inside a store's detail screen.

  Not a route of its own — it lives inside the store's TabBarView, so
  switching between Customers and Products pushes no history. The
  screens it opens (form, detail) ARE routes.
*/
class CustomersTab extends StatelessWidget {
  final int storeId;

  const CustomersTab({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          locator<CustomerListCubit>(param1: storeId)..loadCustomers(),
      child: _CustomersView(storeId: storeId),
    );
  }
}

class _CustomersView extends StatelessWidget {
  final int storeId;

  const _CustomersView({required this.storeId});

  Future<void> _addCustomer(BuildContext context) async {
    final cubit = context.read<CustomerListCubit>();

    await context.push(AppRoutes.newCustomer(storeId));

    if (context.mounted) await cubit.loadCustomers();
  }

  Future<void> _openCustomer(BuildContext context, int customerId) async {
    final cubit = context.read<CustomerListCubit>();

    await context.push(AppRoutes.customerDetail(storeId, customerId));

    // The customer may have been renamed, deactivated or deleted.
    if (context.mounted) await cubit.loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-customer',
        onPressed: () => _addCustomer(context),
        backgroundColor: AppPalette.primaryDark,
        foregroundColor: AppPalette.surface,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add customer'),
      ),
      body: BlocBuilder<CustomerListCubit, CustomerListState>(
        builder: (context, state) {
          final cubit = context.read<CustomerListCubit>();

          return Column(
            children: [
              _SearchAndFilterBar(state: state, cubit: cubit),
              Expanded(child: _buildBody(context, state, cubit)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CustomerListState state,
    CustomerListCubit cubit,
  ) {
    // Only blank on the first load. A search keeps the previous rows
    // underneath, so typing does not flash the whole list away.
    if (state.status == CustomerListStateStatus.loading &&
        state.customers.isEmpty &&
        state.search.isEmpty) {
      return const AppLoadingView(message: 'Loading customers...');
    }

    if (state.status == CustomerListStateStatus.failure &&
        state.error != null) {
      return AppErrorView(
        failure: state.error!,
        onRetry: cubit.loadCustomers,
      );
    }

    if (state.isFilteredEmpty) {
      return EmptyStateView(
        icon: Icons.person_search_outlined,
        title: 'No customers found',
        message: state.search.isNotEmpty
            ? 'Nothing matches "${state.search}" in this store.'
            : 'No customers match the current filter.',
        actionLabel: state.search.isNotEmpty ? 'Clear search' : null,
        onAction: state.search.isNotEmpty ? cubit.clearSearch : null,
      );
    }

    if (state.isEmpty) {
      return EmptyStateView(
        icon: Icons.people_outline_rounded,
        title: 'No customers yet',
        message:
            'Add the people who buy on credit from this store, '
            'and track what each of them owes.',
        actionLabel: 'Add your first customer',
        onAction: () => _addCustomer(context),
      );
    }

    return RefreshIndicator(
      color: AppPalette.primary,
      onRefresh: cubit.loadCustomers,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: state.customers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _CustomerSummary(state: state);

          final customer = state.customers[index - 1];

          return CustomerCard(
            customer: customer,
            balance: state.balanceFor(customer.id),
            onTap: () => _openCustomer(context, customer.id),
          );
        },
      ),
    );
  }
}

// ============================================================
// SEARCH + FILTER
// ============================================================
class _SearchAndFilterBar extends StatefulWidget {
  final CustomerListState state;
  final CustomerListCubit cubit;

  const _SearchAndFilterBar({required this.state, required this.cubit});

  @override
  State<_SearchAndFilterBar> createState() => _SearchAndFilterBarState();
}

class _SearchAndFilterBarState extends State<_SearchAndFilterBar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.search,
  );

  @override
  void didUpdateWidget(_SearchAndFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The cubit can clear the search itself (from the empty state's
    // "Clear search" action); keep the field in step without fighting
    // the user's cursor while they type.
    if (widget.state.search.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppPalette.background,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.cubit.search,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search name or number',
                hintStyle: AppTextStyles.body1.copyWith(
                  color: AppPalette.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppPalette.textMuted,
                  size: 20,
                ),
                suffixIcon: state.search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppPalette.textMuted,
                        onPressed: () {
                          _controller.clear();
                          widget.cubit.clearSearch();
                        },
                      ),
                filled: true,
                fillColor: AppPalette.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppPalette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppPalette.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          /*
            §29: deactivated customers are never deleted, so there has
            to be a way back to them. Off by default — the active list
            is what the seller works from day to day.
          */
          Tooltip(
            message: state.includeInactive
                ? 'Hide inactive customers'
                : 'Show inactive customers',
            child: Material(
              color: state.includeInactive
                  ? AppPalette.primaryDark
                  : AppPalette.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    widget.cubit.setIncludeInactive(!state.includeInactive),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.includeInactive
                          ? AppPalette.primaryDark
                          : AppPalette.border,
                    ),
                  ),
                  child: Icon(
                    state.includeInactive
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: state.includeInactive
                        ? AppPalette.surface
                        : AppPalette.textSecondary,
                  ),
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
// SUMMARY
// ============================================================
class _CustomerSummary extends StatelessWidget {
  final CustomerListState state;

  const _CustomerSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final debtors = state.debtorCount;

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
                  'Total utang',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.totalOutstanding.format(),
                  style: AppTextStyles.subtitle1.copyWith(
                    color: state.totalOutstanding.isPositive
                        ? AppPalette.primaryDark
                        : AppPalette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 34,
            width: 1,
            color: AppPalette.border,
            margin: const EdgeInsets.symmetric(horizontal: 14),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                debtors == 1 ? 'Owes you' : 'Owe you',
                style: AppTextStyles.caption1.copyWith(
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$debtors of ${state.customers.length}',
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
