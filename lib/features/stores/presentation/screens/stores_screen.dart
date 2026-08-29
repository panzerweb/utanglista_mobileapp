import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/services/data_reset_notifier.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/main_app_bar.dart';
import 'package:utanglista_mobileapp/core/shared/sort_menu_button.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/app_search_field.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/bloc/store_cubit.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/bloc/store_state.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/widgets/category_filter_bar.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/widgets/store_card.dart';

/*
  Every store the user has created.

  The cubit is provided here rather than higher up so it is disposed
  with the screen — see the registerFactory note in service_locator.

  The list reloads whenever the user comes back from a form or a detail
  screen, because both can change what belongs on it. `context.push`
  returns a Future that completes on pop, which is what makes that a
  single await rather than a refresh flag threaded through the router.
*/
class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<StoreListCubit>()..loadAllStores(),
      // Same reason as the dashboard: this tab survives in the shell's
      // IndexedStack, so a restore reaches it through the notifier
      // rather than through navigation.
      child: DataResetListener(
        onReset: (context) => context.read<StoreListCubit>().loadAllStores(),
        child: const _StoresView(),
      ),
    );
  }
}

class _StoresView extends StatelessWidget {
  const _StoresView();

  Future<void> _openStore(BuildContext context, int storeId) async {
    final cubit = context.read<StoreListCubit>();

    await context.push(AppRoutes.storeDetail(storeId));

    // The store may have been renamed or deleted while it was open.
    if (context.mounted) await cubit.loadAllStores();
  }

  Future<void> _createStore(BuildContext context) async {
    final cubit = context.read<StoreListCubit>();

    await context.push(AppRoutes.newStore);

    if (context.mounted) await cubit.loadAllStores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: const MainAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createStore(context),
        backgroundColor: AppPalette.primaryDark,
        foregroundColor: AppPalette.surface,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New store'),
      ),
      body: BlocBuilder<StoreListCubit, StoreListState>(
        builder: (context, state) {
          final cubit = context.read<StoreListCubit>();

          return Column(
            children: [
              _SearchAndSortBar(state: state, cubit: cubit),

              /*
                Search and category are separate controls on purpose.
                Category is a coarse, sticky choice the seller leaves
                set; search is typed and thrown away. Folding one into
                the other would mean clearing a search to change
                category, or losing the category by typing.
              */
              CategoryFilterBar(
                selected: state.category,
                onSelected: cubit.setFilter,
              ),

              const SizedBox(height: 4),

              Expanded(child: _buildBody(context, state, cubit)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StoreListState state,
    StoreListCubit cubit,
  ) {
    // Only blank the list on the FIRST load. A filter change, a search
    // or a refresh keeps the previous rows on screen underneath, which
    // reads as the list updating rather than the screen restarting.
    if (state.status == StoreListStateStatus.loading &&
        state.stores.isEmpty &&
        state.search.isEmpty) {
      return const AppLoadingView(message: 'Loading stores...');
    }

    if (state.status == StoreListStateStatus.failure && state.error != null) {
      return AppErrorView(
        failure: state.error!,
        onRetry: () => cubit.loadAllStores(),
      );
    }

    /*
      Two ways to end up with an empty filtered list, and they need
      different offers. Telling someone to "show all stores" when what
      they actually did was mistype a name sends them to the wrong
      control.
    */
    if (state.isFilteredEmpty) {
      if (state.search.isNotEmpty) {
        return EmptyStateView(
          icon: Icons.search_off_rounded,
          title: 'No stores found',
          message: state.category == null
              ? 'Nothing matches "${state.search}".'
              : 'Nothing matches "${state.search}" under '
                    '${state.category!.label.toLowerCase()}.',
          actionLabel: 'Clear search',
          onAction: cubit.clearSearch,
        );
      }

      return EmptyStateView(
        icon: Icons.filter_alt_off_outlined,
        title: 'No ${state.category?.label.toLowerCase()} stores',
        message:
            'Nothing here yet under this category. '
            'Try another one, or show all stores.',
        actionLabel: 'Show all stores',
        onAction: () => cubit.setFilter(null),
      );
    }

    if (state.isEmpty) {
      return EmptyStateView(
        icon: Icons.storefront_outlined,
        title: 'No stores yet',
        message:
            'Add your first store to start tracking utang — '
            'a sari-sari store, a street cart, or anything you sell from.',
        actionLabel: 'Add your first store',
        onAction: () => _createStore(context),
      );
    }

    return RefreshIndicator(
      color: AppPalette.primary,
      onRefresh: () => cubit.loadAllStores(),
      child: ListView.builder(
        // Always scrollable, so pull-to-refresh works even when the
        // list is short enough to fit.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: state.stores.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _TotalSummary(state: state);

          final store = state.stores[index - 1];

          return StoreCard(
            store: store,
            balance: state.balanceFor(store.id),
            onTap: () => _openStore(context, store.id),
          );
        },
      ),
    );
  }
}

/*
  What every listed store adds up to.

  Respects the active filter — showing an all-stores total above a
  filtered list would read as a mistake in the arithmetic.
*/
class _TotalSummary extends StatelessWidget {
  final StoreListState state;

  const _TotalSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final storeCount = state.stores.length;
    final label = state.category == null
        ? 'Across $storeCount ${storeCount == 1 ? 'store' : 'stores'}'
        : 'Across $storeCount ${state.category!.label.toLowerCase()} '
              '${storeCount == 1 ? 'store' : 'stores'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppPalette.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
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
                  state.totalOutstanding.format(),
                  style: AppTextStyles.title1.copyWith(
                    color: AppPalette.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.primarySoft,
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
    );
  }
}

// ============================================================
// SEARCH + SORT
// ============================================================
/*
  Sits above the category chips rather than beside them: three
  controls on one row would leave the search field too narrow to read
  a store name in, and the chips already own a full row.
*/
class _SearchAndSortBar extends StatelessWidget {
  final StoreListState state;
  final StoreListCubit cubit;

  const _SearchAndSortBar({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              value: state.search,
              hintText: 'Search stores',
              onChanged: cubit.search,
              onClear: cubit.clearSearch,
            ),
          ),

          const SizedBox(width: 8),

          SortMenuButton<StoreSort>(
            selected: state.sort,
            items: StoreSort.values,
            itemLabel: (sort) => sort.label,
            onSelected: cubit.setSort,
          ),
        ],
      ),
    );
  }
}
