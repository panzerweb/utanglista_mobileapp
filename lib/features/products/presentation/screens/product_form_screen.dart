import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/constants/product_units.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_confirm_dialog.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/scanner/barcode_scanner_screen.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/global_text_field.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/money_text_field.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/products/data/model/product_payload_model.dart';
import 'package:utanglista_mobileapp/features/products/domain/entities/product_entity.dart';
import 'package:utanglista_mobileapp/features/products/presentation/bloc/product_cubit.dart';
import 'package:utanglista_mobileapp/features/products/presentation/bloc/product_state.dart';

/*
  ------------------------------------------------------------------
  Create and edit a product — and the product's detail screen too.
  ------------------------------------------------------------------

  DEVIATION from design_plan §2, which listed a separate
  /products/:productId detail route.

  A product has no sub-content: no ledger, no history of its own worth
  a page. A read-only detail screen would show exactly the fields this
  form already shows, one tap further from editing them. So the form IS
  the detail screen, with deactivate and delete in its overflow menu.

  Customers kept their detail screen because it hosts the ledger tabs.
*/
class ProductFormScreen extends StatelessWidget {
  final int storeId;

  /// null == create.
  final int? productId;

  /// Pre-fills the barcode when the user got here from a scan that
  /// found nothing.
  final String? initialBarcode;

  const ProductFormScreen({
    super.key,
    required this.storeId,
    this.productId,
    this.initialBarcode,
  });

  bool get _isEditing => productId != null;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => locator<ProductFormCubit>()),
        BlocProvider(
          create: (_) {
            final cubit = locator<ProductDetailCubit>();
            if (_isEditing) cubit.loadProduct(productId!);
            return cubit;
          },
        ),
      ],
      child: _isEditing
          ? _EditProductLoader(storeId: storeId, productId: productId!)
          : _ProductFormView(storeId: storeId, initialBarcode: initialBarcode),
    );
  }
}

class _EditProductLoader extends StatelessWidget {
  final int storeId;
  final int productId;

  const _EditProductLoader({required this.storeId, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        if (state.status == ProductDetailStateStatus.failure &&
            state.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: AppErrorView(
              failure: state.error!,
              onRetry: () =>
                  context.read<ProductDetailCubit>().loadProduct(productId),
            ),
          );
        }

        if (state.product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: const AppLoadingView(message: 'Loading product...'),
          );
        }

        return _ProductFormView(
          storeId: storeId,
          existing: state.product,
          canDelete: state.canDelete,
        );
      },
    );
  }
}

class _ProductFormView extends StatefulWidget {
  final int storeId;
  final ProductEntity? existing;
  final String? initialBarcode;
  final bool canDelete;

  const _ProductFormView({
    required this.storeId,
    this.existing,
    this.initialBarcode,
    this.canDelete = true,
  });

  @override
  State<_ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<_ProductFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _barcodeController = TextEditingController(
      text: existing?.barcode ?? widget.initialBarcode ?? '',
    );
    _priceController = TextEditingController(
      text: existing?.price.toEditableString() ?? '',
    );
    _unitController = TextEditingController(
      text: existing?.unit ?? ProductUnits.defaultUnit,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  // ========================================================
  // ** VALIDATION **
  // Mirrors the cubit's rules so the user is told before submitting.
  // ========================================================

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.length < 2) return 'Name must be at least 2 characters';
    if (name.length > 60) return 'Name must be 60 characters or fewer';

    return null;
  }

  String? _validateUnit(String? value) {
    final unit = value?.trim() ?? '';

    if (unit.isEmpty) return 'Enter a unit, e.g. pc, kg or serving';
    if (unit.length > 20) return 'Unit must be 20 characters or fewer';

    return null;
  }

  /// Blank is valid — street-vendor goods have no barcode.
  String? _validateBarcode(String? value) {
    final barcode = value?.trim() ?? '';

    if (barcode.length > 40) return 'Barcode must be 40 characters or fewer';

    return null;
  }

  // ========================================================
  // ** SCAN TO FILL **
  // ========================================================

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerScreen.open(
      context,
      title: 'Scan product barcode',
      subtitle: 'The barcode will be added to this product',
    );

    if (barcode == null || !mounted) return;

    setState(() => _barcodeController.text = barcode);
  }

  // ========================================================
  // ** SUBMIT **
  // ========================================================

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final price = MoneyTextField.read(_priceController) ?? Money.zero;
    final cubit = context.read<ProductFormCubit>();

    if (_isEditing) {
      cubit.editProduct(
        UpdateProductPayloadModel(
          productId: widget.existing!.id,
          name: _nameController.text.trim(),
          // '' is a deliberate clear, not "leave alone".
          description: _descriptionController.text.trim(),
          barcode: _barcodeController.text.trim(),
          price: price,
          unit: _unitController.text.trim(),
        ),
      );
      return;
    }

    cubit.insertProduct(
      ProductPayloadModel(
        storeId: widget.storeId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        barcode: _barcodeController.text.trim(),
        price: price,
        unit: _unitController.text.trim(),
      ),
    );
  }

  Future<void> _toggleActive() async {
    final product = widget.existing!;
    final cubit = context.read<ProductFormCubit>();

    if (product.isActive) {
      final confirmed = await AppConfirmDialog.show(
        context,
        title: 'Deactivate ${product.name}?',
        message:
            'It will stop appearing when you build new transactions. '
            'Past transactions keep it exactly as it was sold. '
            'You can reactivate it anytime.',
        confirmLabel: 'Deactivate',
      );

      if (!confirmed) return;
    }

    await cubit.setActive(product.id, isActive: !product.isActive);
  }

  Future<void> _delete() async {
    final product = widget.existing!;
    final cubit = context.read<ProductFormCubit>();

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete ${product.name}?',
      message:
          'This product has never been sold, so no transaction history '
          'will be lost. This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    await cubit.deleteProduct(product.id);
  }

  /*
    DUPLICATE_BARCODE carries the offending product's id in `details`,
    so the failure can offer to open it rather than leaving the seller
    to search for a product they cannot see.
  */
  void _onFormState(BuildContext context, ProductFormState state) {
    switch (state) {
      case ProductFormSuccess():
        AppSnackBar.success(context, 'Product added.');
        context.pop();

      case ProductFormUpdated():
        AppSnackBar.success(context, 'Changes saved.');
        context.pop();

      case ProductActiveStateChanged(:final isActive):
        AppSnackBar.success(
          context,
          isActive ? 'Product reactivated.' : 'Product deactivated.',
        );
        context.pop();

      case ProductFormDeleted():
        AppSnackBar.success(context, 'Product deleted.');
        context.pop();

      case ProductFormFailure(:final error):
        AppSnackBar.failure(context, error);

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductFormCubit, ProductFormState>(
      listener: _onFormState,
      builder: (context, state) {
        final isBusy =
            state is ProductFormSubmitting ||
            state is ProductFormUpdating ||
            state is ProductFormDeleting;

        return Scaffold(
          backgroundColor: AppPalette.background,
          appBar: AppBar(
            backgroundColor: AppPalette.primaryDark,
            foregroundColor: AppPalette.surface,
            title: Text(
              _isEditing ? 'Edit product' : 'New product',
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (_isEditing)
                _OverflowMenu(
                  product: widget.existing!,
                  canDelete: widget.canDelete,
                  onToggleActive: _toggleActive,
                  onDelete: _delete,
                ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  if (_isEditing && !widget.existing!.isActive)
                    const _InactiveBanner(),

                  GlobalTextField(
                    label: 'Product name',
                    fieldController: _nameController,
                    validator: _validateName,
                  ),

                  const SizedBox(height: 16),

                  MoneyTextField(
                    controller: _priceController,
                    label: 'Selling price',
                    helperText: 'The price now — past sales keep their own.',
                  ),

                  const SizedBox(height: 16),

                  _UnitField(
                    controller: _unitController,
                    validator: _validateUnit,
                    onSuggestionTapped: (unit) =>
                        setState(() => _unitController.text = unit),
                  ),

                  const SizedBox(height: 16),

                  _BarcodeField(
                    controller: _barcodeController,
                    validator: _validateBarcode,
                    onScan: _scanBarcode,
                    onClear: () => setState(() => _barcodeController.clear()),
                  ),

                  const SizedBox(height: 16),

                  GlobalTextField(
                    label: 'Description (optional)',
                    fieldController: _descriptionController,
                    minLines: 2,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : _submit,
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppPalette.surface,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        isBusy
                            ? 'Saving...'
                            : (_isEditing ? 'Save changes' : 'Add product'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.primaryDark,
                        foregroundColor: AppPalette.surface,
                        disabledBackgroundColor: AppPalette.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// BARCODE FIELD
// ============================================================
/*
  Scanning is an assist, never a requirement. The field is typeable on
  its own, the scan button sits beside it, and a barcode can be cleared
  back to nothing — because plenty of what these sellers sell has none.
*/
class _BarcodeField extends StatelessWidget {
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final VoidCallback onScan;
  final VoidCallback onClear;

  const _BarcodeField({
    required this.controller,
    required this.validator,
    required this.onScan,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            validator: validator,
            // Numeric-leaning but not digits-only: Code 128 labels
            // carry letters, and sellers invent their own codes.
            keyboardType: TextInputType.visiblePassword,
            style: AppTextStyles.body1.copyWith(
              color: AppPalette.textPrimary,
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              labelText: 'Barcode (optional)',
              hintText: '4801234567890',
              helperText: 'Leave empty for unbarcoded goods',
              filled: true,
              fillColor: AppPalette.accentSoft,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();

                  return IconButton(
                    tooltip: 'Remove barcode',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppPalette.textMuted,
                    onPressed: onClear,
                  );
                },
              ),
              labelStyle: AppTextStyles.body1.copyWith(
                color: AppPalette.textSecondary,
              ),
              hintStyle: AppTextStyles.body1.copyWith(
                color: AppPalette.textMuted,
              ),
              helperStyle: AppTextStyles.caption1.copyWith(
                color: AppPalette.textMuted,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppPalette.accentSoft,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppPalette.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppPalette.danger,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppPalette.danger,
                  width: 2,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            height: 56,
            width: 56,
            child: FilledButton(
              onPressed: onScan,
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.primary,
                foregroundColor: AppPalette.surface,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// UNIT FIELD
// ============================================================
/*
  Free text with quick-pick chips, not a dropdown.

  A closed list would stop a seller describing "1/4 kilo" or "3 sticks",
  and being unable to name what you sell is worse than typing it. The
  chips cover the common cases so most people never type at all.
*/
class _UnitField extends StatelessWidget {
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onSuggestionTapped;

  const _UnitField({
    required this.controller,
    required this.validator,
    required this.onSuggestionTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          validator: validator,
          style: AppTextStyles.body1.copyWith(color: AppPalette.textPrimary),
          decoration: InputDecoration(
            labelText: 'Unit',
            hintText: 'pc',
            filled: true,
            fillColor: AppPalette.accentSoft,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            labelStyle: AppTextStyles.body1.copyWith(
              color: AppPalette.textSecondary,
            ),
            hintStyle: AppTextStyles.body1.copyWith(
              color: AppPalette.textMuted,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppPalette.accentSoft,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppPalette.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppPalette.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppPalette.danger, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 32,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final unit in ProductUnits.suggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _UnitChip(
                        label: unit,
                        isSelected: value.text.trim() == unit,
                        onTap: () => onSuggestionTapped(unit),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppPalette.primaryDark : AppPalette.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppPalette.primaryDark : AppPalette.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: isSelected
                  ? AppPalette.surface
                  : AppPalette.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OVERFLOW MENU
// ============================================================
/*
  Delete is HIDDEN, not disabled, for a product that has been sold —
  same reasoning as the customer menu. The record has to keep the price
  it was sold at (§27, §28), and Deactivate is the action they want.
*/
class _OverflowMenu extends StatelessWidget {
  final ProductEntity product;
  final bool canDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _OverflowMenu({
    required this.product,
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
                product.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_rounded,
                size: 20,
                color: AppPalette.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(product.isActive ? 'Deactivate' : 'Reactivate'),
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

class _InactiveBanner extends StatelessWidget {
  const _InactiveBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            size: 18,
            color: AppPalette.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This product is deactivated. It will not appear when '
              'building new transactions.',
              style: AppTextStyles.caption1.copyWith(
                color: AppPalette.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
