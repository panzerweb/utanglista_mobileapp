import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_state.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/widgets/picker_sheet_scaffold.dart';

/*
  Picks who the utang is for.

  Only ACTIVE customers are listed. §29 says a deactivated customer
  cannot receive new transactions, so offering them here would mean
  building a whole cart before being told it cannot be recorded.

  A bottom sheet rather than a route: picking a customer is a step
  inside building a transaction, not a place the user navigates to.
  showModalBottomSheet is Flutter's API for that, and go_router does not
  replace it — the same exception as dialogs.
*/
abstract final class CustomerPickerSheet {
  static Future<CustomerEntity?> show(
    BuildContext context, {
    required int storeId,
  }) {
    return showModalBottomSheet<CustomerEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => locator<CustomerListCubit>(param1: storeId)
          // includeInactive stays false — see the class note.
          ..loadCustomers(),
        child: const _CustomerPickerView(),
      ),
    );
  }
}

class _CustomerPickerView extends StatelessWidget {
  const _CustomerPickerView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerListCubit, CustomerListState>(
      builder: (context, state) {
        final cubit = context.read<CustomerListCubit>();

        return PickerSheetScaffold(
          title: 'Choose customer',
          searchHint: 'Search name or number',
          searchText: state.search,
          onSearchChanged: cubit.search,
          onSearchCleared: cubit.clearSearch,
          builder: (scrollController) =>
              _buildBody(context, state, cubit, scrollController),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CustomerListState state,
    CustomerListCubit cubit,
    ScrollController scrollController,
  ) {
    if (state.status == CustomerListStateStatus.loading &&
        state.customers.isEmpty) {
      return const AppLoadingView(message: 'Loading customers...');
    }

    if (state.status == CustomerListStateStatus.failure &&
        state.error != null) {
      return AppErrorView(failure: state.error!, onRetry: cubit.loadCustomers);
    }

    if (state.customers.isEmpty) {
      return EmptyStateView(
        icon: Icons.people_outline_rounded,
        title: state.search.isEmpty
            ? 'No active customers'
            : 'No customers found',
        message: state.search.isEmpty
            ? 'Add a customer in the Customers tab before recording utang.'
            : 'Nothing matches "${state.search}".',
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: state.customers.length,
      itemBuilder: (context, index) {
        final customer = state.customers[index];
        final balance = state.balanceFor(customer.id);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: AppPalette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppPalette.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => Navigator.of(context).pop(customer),
            leading: CircleAvatar(
              backgroundColor: AppPalette.primarySoft,
              child: Text(
                customer.initials,
                style: AppTextStyles.caption1.copyWith(
                  color: AppPalette.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              customer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Existing utang, so the seller sees what this person
            // already owes before adding more.
            subtitle: Text(
              balance.hasDebt
                  ? 'Owes ${balance.outstanding.format()}'
                  : 'No utang',
              style: AppTextStyles.caption1.copyWith(
                color: balance.hasDebt
                    ? AppPalette.primaryDark
                    : AppPalette.textMuted,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.textMuted,
            ),
          ),
        );
      },
    );
  }
}
