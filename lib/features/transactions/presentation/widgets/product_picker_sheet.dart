import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/constants/product_units.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/scanner/barcode_scanner_screen.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/money_text_field.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/products/data/model/product_payload_model.dart';
import 'package:utanglista_mobileapp/features/products/domain/entities/product_entity.dart';
import 'package:utanglista_mobileapp/features/products/domain/repositories/product_repository.dart';
import 'package:utanglista_mobileapp/features/products/presentation/bloc/product_cubit.dart';
import 'package:utanglista_mobileapp/features/products/presentation/bloc/product_state.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/widgets/picker_sheet_scaffold.dart';

/*
  ------------------------------------------------------------------
  Picks what the customer is taking.
  ------------------------------------------------------------------

  Three ways in, because these sellers work in three different ways:

    SEARCH     type a name — works for everyone
    SCAN       the sari-sari case, where goods carry barcodes
    QUICK ADD  the street-vendor case, where they do not

  Only SELLABLE products are listed: active (§28) and priced above zero
  (§24 requires a transaction total greater than zero, so a ₱0 item
  could never form a valid transaction on its own).

  Returns the chosen product; the caller snapshots its price into a
  draft line.
*/
abstract final class ProductPickerSheet {
  static Future<ProductEntity?> show(
    BuildContext context, {
    required int storeId,
  }) {
    return showModalBottomSheet<ProductEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => locator<ProductListCubit>(param1: storeId)
              ..loadProducts(),
          ),
          BlocProvider(
            create: (_) => locator<BarcodeLookupCubit>(param1: storeId),
          ),
        ],
        child: _ProductPickerView(storeId: storeId),
      ),
    );
  }
}

class _ProductPickerView extends StatefulWidget {
  final int storeId;

  const _ProductPickerView({required this.storeId});

  @override
  State<_ProductPickerView> createState() => _ProductPickerViewState();
}

class _ProductPickerViewState extends State<_ProductPickerView> {
  /*
    ------------------------------------------------------------------
    SCAN, inside the builder.
    ------------------------------------------------------------------

    A hit adds the product straight to the cart — that is the whole
    point of scanning while serving someone.

    A miss does NOT offer to create a product here. Mid-transaction is
    the wrong moment to ask a seller to fill in a product form, so it
    says what was scanned and points at Quick add, which needs only a
    name and a price.
  */
  Future<void> _scan() async {
    final lookupCubit = context.read<BarcodeLookupCubit>();

    final barcode = await BarcodeScannerScreen.open(
      context,
      title: 'Scan item',
      subtitle: 'Scan a barcode to add it to this utang',
    );

    if (barcode == null || !mounted) return;

    await lookupCubit.lookup(barcode);
    if (!mounted) return;

    switch (lookupCubit.state) {
      case BarcodeLookupFound(:final product):
        if (!product.isSellable) {
          AppSnackBar.warning(
            context,
            product.isActive
                ? '${product.name} has no price set.'
                : '${product.name} is deactivated.',
          );
          return;
        }

        Navigator.of(context).pop(product);

      case BarcodeLookupNotFound(:final barcode):
        AppSnackBar.info(
          context,
          'No product for $barcode. Use Quick add to record it.',
        );

      case BarcodeLookupFailure(:final error):
        AppSnackBar.failure(context, error);

      default:
        break;
    }
  }

  /*
    ------------------------------------------------------------------
    QUICK ADD.
    ------------------------------------------------------------------

    transaction_items.product_id is a required foreign key, so every
    line must point at a real product row — there is no such thing as
    a free-text line. §35 puts products at the top of the source-of-
    truth hierarchy, and that is deliberate: it is what lets a seller
    later ask "how much fishball have I sold on credit?"

    So Quick add genuinely CREATES the product (active, no barcode),
    then returns it. It just asks for the two fields that cannot be
    guessed instead of the full form.
  */
  Future<void> _quickAdd() async {
    final product = await showDialog<ProductEntity>(
      context: context,
      builder: (_) => _QuickAddDialog(storeId: widget.storeId),
    );

    if (product == null || !mounted) return;

    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductListCubit, ProductListState>(
      builder: (context, state) {
        final cubit = context.read<ProductListCubit>();

        return PickerSheetScaffold(
          title: 'Add item',
          searchHint: 'Search name or barcode',
          searchText: state.search,
          onSearchChanged: cubit.search,
          onSearchCleared: cubit.clearSearch,
          trailingAction: _ScanButton(onTap: _scan),
          builder: (scrollController) =>
              _buildBody(context, state, cubit, scrollController),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductListState state,
    ProductListCubit cubit,
    ScrollController scrollController,
  ) {
    if (state.status == ProductListStateStatus.loading &&
        state.products.isEmpty) {
      return const AppLoadingView(message: 'Loading products...');
    }

    if (state.status == ProductListStateStatus.failure && state.error != null) {
      return AppErrorView(failure: state.error!, onRetry: cubit.loadProducts);
    }

    // §28 + §24: only what can actually go into a transaction.
    final sellable = state.products
        .where((product) => product.isSellable)
        .toList();

    if (sellable.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: state.search.isEmpty
                  ? 'Nothing to sell yet'
                  : 'No products found',
              message: state.search.isEmpty
                  ? 'Add products in the Products tab, or use Quick add '
                        'for something you sell without a catalogue.'
                  : 'Nothing matches "${state.search}".',
            ),
          ),
          _QuickAddBar(onTap: _quickAdd),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            itemCount: sellable.length,
            itemBuilder: (context, index) {
              final product = sellable[index];

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
                  onTap: () => Navigator.of(context).pop(product),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPalette.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      product.hasBarcode
                          ? Icons.qr_code_2_rounded
                          : Icons.inventory_2_outlined,
                      size: 18,
                      color: AppPalette.primaryDark,
                    ),
                  ),
                  title: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body1.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    product.priceWithUnit,
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppPalette.primary,
                  ),
                ),
              );
            },
          ),
        ),

        _QuickAddBar(onTap: _quickAdd),
      ],
    );
  }
}

// ============================================================
// QUICK ADD
// ============================================================
class _QuickAddBar extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickAddBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.flash_on_rounded, size: 20),
        label: const Text('Quick add something not listed'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.primaryDark,
          side: const BorderSide(color: AppPalette.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/*
  Name, price, unit — the minimum a product needs to exist. Everything
  else on the product form has a sensible default or is optional, and
  asking for it while a customer waits at the stall is the wrong trade.
*/
class _QuickAddDialog extends StatefulWidget {
  final int storeId;

  const _QuickAddDialog({required this.storeId});

  @override
  State<_QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<_QuickAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController(
    text: ProductUnits.defaultUnit,
  );

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final repository = locator<ProductRepository>();

    try {
      final id = await repository.createProduct(
        ProductPayloadModel(
          storeId: widget.storeId,
          name: _nameController.text.trim(),
          price: MoneyTextField.read(_priceController) ?? Money.zero,
          unit: _unitController.text.trim(),
        ),
      );

      final product = await repository.fetchProductById(id);
      if (!mounted) return;

      Navigator.of(context).pop(product);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      AppSnackBar.info(context, 'Could not add that product.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Quick add',
        style: AppTextStyles.subtitle1.copyWith(
          color: AppPalette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.length < 2) return 'Enter a name';
                if (name.length > 60) return 'Name is too long';
                return null;
              },
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.textPrimary,
              ),
              decoration: _decoration('Name', 'Fishball'),
            ),

            const SizedBox(height: 14),

            MoneyTextField(
              controller: _priceController,
              label: 'Price',
              helperText: 'Saved to your products so you can reuse it',
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _unitController,
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) ? 'Enter a unit' : null,
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.textPrimary,
              ),
              decoration: _decoration('Unit', 'pc'),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppPalette.textSecondary,
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.primaryDark,
            foregroundColor: AppPalette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppPalette.surface,
                  ),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppPalette.accentSoft,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 18,
      ),
      labelStyle: AppTextStyles.body1.copyWith(
        color: AppPalette.textSecondary,
      ),
      hintStyle: AppTextStyles.body1.copyWith(color: AppPalette.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.accentSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.danger, width: 2),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Scan a barcode to add it',
      child: Material(
        color: AppPalette.primary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 20,
              color: AppPalette.surface,
            ),
          ),
        ),
      ),
    );
  }
}
