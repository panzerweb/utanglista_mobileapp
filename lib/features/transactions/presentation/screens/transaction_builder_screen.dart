import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_confirm_dialog.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_repository.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_draft.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/bloc/transaction_cubit.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/widgets/customer_picker_sheet.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/widgets/product_picker_sheet.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/widgets/quantity_stepper.dart';

/*
  ------------------------------------------------------------------
  Recording an utang — the app's central screen.
  ------------------------------------------------------------------

  Nothing here touches the database until "Record utang". Everything up
  to that point edits an in-memory TransactionDraft, which owns the
  §24/§38 rules; the write itself is atomic (§10).

  §7 matters most on this screen: each line snapshots the product's
  price WHEN IT WAS ADDED. Repricing the product afterwards — even
  before this cart is submitted — does not move a line that is already
  in it.
*/
class TransactionBuilderScreen extends StatelessWidget {
  final int storeId;

  /// Set when the seller started from a customer's screen, so they do
  /// not have to pick a customer they have already chosen.
  final int? customerId;

  const TransactionBuilderScreen({
    super.key,
    required this.storeId,
    this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<TransactionBuilderCubit>(param1: storeId),
      child: _TransactionBuilderView(
        storeId: storeId,
        initialCustomerId: customerId,
      ),
    );
  }
}

class _TransactionBuilderView extends StatefulWidget {
  final int storeId;
  final int? initialCustomerId;

  const _TransactionBuilderView({
    required this.storeId,
    this.initialCustomerId,
  });

  @override
  State<_TransactionBuilderView> createState() =>
      _TransactionBuilderViewState();
}

class _TransactionBuilderViewState extends State<_TransactionBuilderView> {
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialCustomerId != null) {
      _preselectCustomer(widget.initialCustomerId!);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /*
    Loaded rather than passed in, so the draft holds a real
    CustomerEntity — the draft checks §29 (is this customer active?)
    and cannot do that from an id alone.
  */
  Future<void> _preselectCustomer(int customerId) async {
    final customer = await locator<CustomerRepository>().fetchCustomerById(
      customerId,
    );

    if (customer == null || !mounted) return;

    context.read<TransactionBuilderCubit>().selectCustomer(customer);
  }

  Future<void> _pickCustomer() async {
    final cubit = context.read<TransactionBuilderCubit>();

    final customer = await CustomerPickerSheet.show(
      context,
      storeId: widget.storeId,
    );

    if (customer == null) return;

    cubit.selectCustomer(customer);
  }

  Future<void> _addItem() async {
    final cubit = context.read<TransactionBuilderCubit>();

    final product = await ProductPickerSheet.show(
      context,
      storeId: widget.storeId,
    );

    if (product == null) return;

    // The price snapshot is taken inside addProduct (§7).
    cubit.addProduct(product);
  }

  /// Nothing is written until submit, so backing out mid-cart loses
  /// work the seller cannot recover. Worth one question.
  Future<bool> _confirmDiscard() async {
    final draft = context.read<TransactionBuilderCubit>().state.draft;

    if (draft.isEmpty) return true;

    return AppConfirmDialog.show(
      context,
      title: 'Discard this utang?',
      message:
          'You have ${draft.itemCount} '
          '${draft.itemCount == 1 ? 'item' : 'items'} that have not been '
          'recorded yet.',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
  }

  void _onBuilderState(BuildContext context, TransactionBuilderState state) {
    switch (state.status) {
      case TransactionBuilderStatus.submitted:
        AppSnackBar.success(
          context,
          'Utang recorded — ${state.draft.total.format()}.',
        );
        context.pop(state.createdTransactionId);

      case TransactionBuilderStatus.failure:
        if (state.error != null) AppSnackBar.failure(context, state.error!);

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionBuilderCubit, TransactionBuilderState>(
      listener: _onBuilderState,
      builder: (context, state) {
        final cubit = context.read<TransactionBuilderCubit>();
        final draft = state.draft;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            final shouldPop = await _confirmDiscard();
            if (shouldPop && context.mounted) context.pop();
          },
          child: Scaffold(
            backgroundColor: AppPalette.background,
            appBar: AppBar(
              backgroundColor: AppPalette.primaryDark,
              foregroundColor: AppPalette.surface,
              title: Text(
                'New utang',
                style: AppTextStyles.body1.copyWith(
                  color: AppPalette.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      _CustomerSection(
                        customer: draft.customer,
                        onTap: _pickCustomer,
                      ),

                      const SizedBox(height: 20),

                      _ItemsSection(
                        draft: draft,
                        onAddItem: _addItem,
                        onIncrement: cubit.incrementQuantity,
                        onDecrement: cubit.decrementQuantity,
                        onSetQuantity: cubit.setQuantity,
                        onRemove: cubit.removeProduct,
                      ),

                      const SizedBox(height: 20),

                      _NoteField(
                        controller: _noteController,
                        onChanged: cubit.setNote,
                      ),
                    ],
                  ),
                ),

                _SubmitBar(state: state, onSubmit: cubit.submit),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// CUSTOMER
// ============================================================
class _CustomerSection extends StatelessWidget {
  final CustomerEntity? customer;
  final VoidCallback onTap;

  const _CustomerSection({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Who is taking this?'),

        Material(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: customer == null
                      ? AppPalette.primary
                      : AppPalette.border,
                  width: customer == null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppPalette.primarySoft,
                    child: customer == null
                        ? const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 20,
                            color: AppPalette.primaryDark,
                          )
                        : Text(
                            customer!.initials,
                            style: AppTextStyles.caption1.copyWith(
                              color: AppPalette.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      customer?.name ?? 'Choose a customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body1.copyWith(
                        color: customer == null
                            ? AppPalette.textSecondary
                            : AppPalette.textPrimary,
                        fontWeight: customer == null
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),
                  ),

                  Text(
                    customer == null ? '' : 'Change',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w600,
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
        ),
      ],
    );
  }
}

// ============================================================
// ITEMS
// ============================================================
class _ItemsSection extends StatelessWidget {
  final TransactionDraft draft;
  final VoidCallback onAddItem;
  final ValueChanged<int> onIncrement;
  final ValueChanged<int> onDecrement;
  final void Function(int productId, double quantity) onSetQuantity;
  final ValueChanged<int> onRemove;

  const _ItemsSection({
    required this.draft,
    required this.onAddItem,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSetQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionLabel('What are they taking?')),
            if (draft.lines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  draft.itemCount == 1 ? '1 item' : '${draft.itemCount} items',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
              ),
          ],
        ),

        if (draft.lines.isEmpty)
          _EmptyCart(onAddItem: onAddItem)
        else ...[
          for (final line in draft.lines)
            _DraftLineCard(
              line: line,
              onIncrement: () => onIncrement(line.productId),
              onDecrement: () => onDecrement(line.productId),
              onSetQuantity: (quantity) =>
                  onSetQuantity(line.productId, quantity),
              onRemove: () => onRemove(line.productId),
            ),

          const SizedBox(height: 4),

          OutlinedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add another item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.primaryDark,
              side: const BorderSide(color: AppPalette.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onAddItem;

  const _EmptyCart({required this.onAddItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_basket_outlined,
            size: 34,
            color: AppPalette.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing added yet',
            style: AppTextStyles.body1.copyWith(
              color: AppPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search, scan, or quick add what they are taking.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add item'),
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.primaryDark,
              foregroundColor: AppPalette.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftLineCard extends StatelessWidget {
  final TransactionDraftLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<double> onSetQuantity;
  final VoidCallback onRemove;

  const _DraftLineCard({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSetQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body1.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // The snapshotted price, shown so the seller can
                    // see exactly what this line was agreed at (§7).
                    Text(
                      '${line.unitPrice.format()} / ${line.unit}',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppPalette.textMuted,
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              QuantityStepper(
                quantity: line.quantity,
                unit: line.unit,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
                onSetQuantity: onSetQuantity,
              ),

              const Spacer(),

              Text(
                line.subTotal.format(),
                style: AppTextStyles.body1.copyWith(
                  color: AppPalette.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NOTE
// ============================================================
class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NoteField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Note (optional)'),

        TextField(
          controller: controller,
          onChanged: onChanged,
          minLines: 2,
          maxLines: 4,
          maxLength: 200,
          style: AppTextStyles.body1.copyWith(color: AppPalette.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. "Will pay on Saturday"',
            hintStyle: AppTextStyles.body1.copyWith(
              color: AppPalette.textMuted,
            ),
            filled: true,
            fillColor: AppPalette.surface,
            contentPadding: const EdgeInsets.all(16),
            counterStyle: AppTextStyles.caption1.copyWith(
              color: AppPalette.textMuted,
            ),
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
      ],
    );
  }
}

// ============================================================
// SUBMIT BAR
// ============================================================
/*
  The running total (§8) and the one button that writes anything.

  When the draft cannot be submitted, the bar says WHY rather than
  just greying out — a disabled button with no explanation is the
  most common way a form dead-ends.
*/
class _SubmitBar extends StatelessWidget {
  final TransactionBuilderState state;
  final VoidCallback onSubmit;

  const _SubmitBar({required this.state, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final draft = state.draft;
    final problems = draft.problems;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  draft.total.format(),
                  style: AppTextStyles.title1.copyWith(
                    color: AppPalette.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            if (problems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppPalette.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      problems.first,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                // Disabled while submitting too — a double tap must
                // not write the utang twice.
                onPressed: state.canSubmit ? onSubmit : null,
                icon: state.isSubmitting
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
                  state.isSubmitting ? 'Recording...' : 'Record utang',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primaryDark,
                  foregroundColor: AppPalette.surface,
                  disabledBackgroundColor: AppPalette.textMuted.withValues(
                    alpha: 0.4,
                  ),
                  disabledForegroundColor: AppPalette.surface,
                  minimumSize: const Size.fromHeight(52),
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
