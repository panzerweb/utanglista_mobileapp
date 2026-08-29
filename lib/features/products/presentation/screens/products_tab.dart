import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/routes/routes.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_confirm_dialog.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/scanner/barcode_scanner_screen.dart';
import 'package:utanglista_mobileapp/core/shared/sort_menu_button.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/app_search_field.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/features/products/presentation/bloc/product_cubit.dart';
import 'package:utanglista_mobileapp/features/products/presentation/bloc/product_state.dart';
import 'package:utanglista_mobileapp/features/products/presentation/widgets/product_card.dart';

/*
  The Products tab inside a store's detail screen.

  Like CustomersTab, not a route of its own — it lives in the store's
  TabBarView. The screens it opens are routes.
*/
class ProductsTab extends StatelessWidget {
  final int storeId;

  const ProductsTab({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              locator<ProductListCubit>(param1: storeId)..loadProducts(),
        ),
        BlocProvider(
          create: (_) => locator<BarcodeLookupCubit>(param1: storeId),
        ),
        BlocProvider(create: (_) => locator<ProductFormCubit>()),
      ],
      child: _ProductsView(storeId: storeId),
    );
  }
}

class _ProductsView extends StatefulWidget {
  final int storeId;

  const _ProductsView({required this.storeId});

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  /// The product a scan just landed on, highlighted so it is findable
  /// in a long list without scrolling for it.
  int? _highlightedProductId;

  Future<void> _addProduct({String? barcode}) async {
    final cubit = context.read<ProductListCubit>();

    await context.push(
      AppRoutes.newProduct(widget.storeId),
      // Pre-fills the barcode field when we got here from a scan that
      // found nothing.
      extra: barcode == null ? null : ProductFormRequest(barcode: barcode),
    );

    if (mounted) await cubit.loadProducts();
  }

  Future<void> _openProduct(int productId) async {
    final cubit = context.read<ProductListCubit>();

    await context.push(AppRoutes.editProduct(widget.storeId, productId));

    if (mounted) await cubit.loadProducts();
  }

  /*
    ------------------------------------------------------------------
    SCAN TO FIND.
    ------------------------------------------------------------------

    Three endings, all of which have to go somewhere useful:

      found + active    open it
      found + inactive  say so, offer to reactivate — NOT "not found",
                        which would push the seller into creating a
                        duplicate the unique index then rejects
      not found         offer to create it, barcode already filled in
  */
  Future<void> _scanToFind() async {
    final listCubit = context.read<ProductListCubit>();
    final lookupCubit = context.read<BarcodeLookupCubit>();
    final formCubit = context.read<ProductFormCubit>();

    final barcode = await BarcodeScannerScreen.open(
      context,
      title: 'Find product',
      subtitle: 'Scan a barcode to look it up in this store',
    );

    if (barcode == null || !mounted) return;

    await lookupCubit.lookup(barcode);
    if (!mounted) return;

    final result = lookupCubit.state;

    switch (result) {
      case BarcodeLookupFound(:final product):
        setState(() => _highlightedProductId = product.id);

        if (!product.isActive) {
          final reactivate = await AppConfirmDialog.show(
            context,
            title: '${product.name} is deactivated',
            message:
                'This barcode belongs to a product you deactivated. '
                'Reactivate it so it can be used in transactions again?',
            confirmLabel: 'Reactivate',
          );

          if (!mounted) return;

          if (reactivate) {
            await formCubit.setActive(product.id, isActive: true);
            if (mounted) await listCubit.loadProducts();
          }
          return;
        }

        await _openProduct(product.id);

      case BarcodeLookupNotFound(:final barcode):
        final create = await AppConfirmDialog.show(
          context,
          title: 'No product with this barcode',
          message:
              'Nothing in this store uses $barcode. '
              'Add it as a new product?',
          confirmLabel: 'Add product',
        );

        if (!mounted || !create) return;

        await _addProduct(barcode: barcode);

      case BarcodeLookupFailure(:final error):
        if (mounted) AppSnackBar.failure(context, error);

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-product',
        onPressed: () => _addProduct(),
        backgroundColor: AppPalette.primaryDark,
        foregroundColor: AppPalette.surface,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
      body: BlocListener<ProductFormCubit, ProductFormState>(
        listener: (context, formState) {
          if (formState is ProductFormFailure) {
            AppSnackBar.failure(context, formState.error);
          }
          if (formState is ProductActiveStateChanged) {
            AppSnackBar.success(context, 'Product reactivated.');
          }
        },
        child: BlocBuilder<ProductListCubit, ProductListState>(
        builder: (context, state) {
          final cubit = context.read<ProductListCubit>();

          return Column(
            children: [
              _SearchBar(
                state: state,
                cubit: cubit,
                onScan: _scanToFind,
              ),
              Expanded(child: _buildBody(context, state, cubit)),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductListState state,
    ProductListCubit cubit,
  ) {
    if (state.status == ProductListStateStatus.loading &&
        state.products.isEmpty &&
        state.search.isEmpty) {
      return const AppLoadingView(message: 'Loading products...');
    }

    if (state.status == ProductListStateStatus.failure && state.error != null) {
      return AppErrorView(failure: state.error!, onRetry: cubit.loadProducts);
    }

    if (state.isFilteredEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: 'No products found',
        message: state.search.isNotEmpty
            ? 'Nothing matches "${state.search}" in this store.'
            : 'No products match the current filter.',
        actionLabel: state.search.isNotEmpty ? 'Clear search' : null,
        onAction: state.search.isNotEmpty ? cubit.clearSearch : null,
      );
    }

    if (state.isEmpty) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        message:
            'Add what you sell, with prices. Barcodes are optional — '
            'street food and repacked goods usually have none.',
        actionLabel: 'Add your first product',
        onAction: () => _addProduct(),
      );
    }

    return RefreshIndicator(
      color: AppPalette.primary,
      onRefresh: cubit.loadProducts,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: state.products.length,
        itemBuilder: (context, index) {
          final product = state.products[index];

          return ProductCard(
            product: product,
            isHighlighted: product.id == _highlightedProductId,
            onTap: () => _openProduct(product.id),
          );
        },
      ),
    );
  }
}

// ============================================================
// SEARCH BAR
// ============================================================
class _SearchBar extends StatelessWidget {
  final ProductListState state;
  final ProductListCubit cubit;
  final VoidCallback onScan;

  const _SearchBar({
    required this.state,
    required this.cubit,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppPalette.background,
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              value: state.search,
              // Short: four controls share this row on a phone, so the
              // field is narrow and a longer hint just clips.
              hintText: 'Name or barcode',
              onChanged: cubit.search,
              onClear: cubit.clearSearch,
            ),
          ),

          const SizedBox(width: 8),

          _SquareButton(
            tooltip: 'Scan a barcode to find a product',
            icon: Icons.qr_code_scanner_rounded,
            isActive: false,
            onTap: onScan,
          ),

          const SizedBox(width: 8),

          // Compact: this is the busiest bar in the app — search,
          // scan, sort and the inactive toggle all share one row, so
          // the sort control gives its label back to the search field.
          SortMenuButton<ProductSort>(
            compact: true,
            selected: state.sort,
            items: ProductSort.values,
            itemLabel: (sort) => sort.label,
            onSelected: cubit.setSort,
          ),

          const SizedBox(width: 8),

          // §28: deactivated products are never deleted, so there has
          // to be a way back to them.
          _SquareButton(
            tooltip: state.includeInactive
                ? 'Hide inactive products'
                : 'Show inactive products',
            icon: state.includeInactive
                ? Icons.visibility_rounded
                : Icons.visibility_off_outlined,
            isActive: state.includeInactive,
            onTap: () =>
                cubit.setIncludeInactive(!state.includeInactive),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SquareButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? AppPalette.primaryDark : AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppPalette.primaryDark : AppPalette.border,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? AppPalette.surface : AppPalette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
