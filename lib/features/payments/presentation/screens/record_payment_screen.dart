import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/money_text_field.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/payments/presentation/bloc/payment_cubit.dart';

/*
  ------------------------------------------------------------------
  Recording money received.
  ------------------------------------------------------------------

  §23 forbids a payment that exceeds what the customer owes. That rule
  is enforced in THREE places, deliberately:

    here          the field caps and explains, so the seller is told
                  before they tap
    the cubit     rejects and refreshes a stale balance
    the datasource inside the same DB transaction as the insert —
                  the only one that actually cannot race

  A payment reduces the ACCOUNT balance (§11). It touches no
  transaction and is never allocated to products (§13).
*/
class RecordPaymentScreen extends StatelessWidget {
  final int storeId;
  final int customerId;

  /// Shown while the balance loads, so the header is not blank.
  final String? customerName;

  const RecordPaymentScreen({
    super.key,
    required this.storeId,
    required this.customerId,
    this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<RecordPaymentCubit>(
        param1: storeId,
        param2: customerId,
      )..loadBalance(customerName: customerName),
      child: const _RecordPaymentView(),
    );
  }
}

class _RecordPaymentView extends StatefulWidget {
  const _RecordPaymentView();

  @override
  State<_RecordPaymentView> createState() => _RecordPaymentViewState();
}

class _RecordPaymentViewState extends State<_RecordPaymentView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Fills the exact outstanding figure — the common case is a
  /// customer settling up, and typing ₱1,234.56 by hand invites a typo
  /// that §23 would then reject.
  void _payInFull(Money outstanding) {
    setState(() => _amountController.text = outstanding.toEditableString());
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = MoneyTextField.read(_amountController);
    if (amount == null) return;

    context.read<RecordPaymentCubit>().submit(
      amount,
      note: _noteController.text,
    );
  }

  void _onState(BuildContext context, RecordPaymentState state) {
    if (state.status == RecordPaymentStatus.submitted) {
      AppSnackBar.success(context, 'Payment recorded.');
      context.pop(state.createdPaymentId);
      return;
    }

    if (state.status == RecordPaymentStatus.failure && state.error != null) {
      AppSnackBar.failure(context, state.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecordPaymentCubit, RecordPaymentState>(
      listener: _onState,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppPalette.background,
          appBar: AppBar(
            backgroundColor: AppPalette.primaryDark,
            foregroundColor: AppPalette.surface,
            title: Text(
              'Record payment',
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, RecordPaymentState state) {
    final cubit = context.read<RecordPaymentCubit>();

    if (state.status == RecordPaymentStatus.loading) {
      return const AppLoadingView(message: 'Loading balance...');
    }

    // A failure before the balance ever loaded is a LOAD failure and
    // owns the screen. A rejected payment is not — that keeps the form
    // up and surfaces as a snackbar, so the seller can correct it.
    if (state.isLoadFailure && state.error != null) {
      return AppErrorView(failure: state.error!, onRetry: cubit.loadBalance);
    }

    /*
      §23 again: with nothing owed there is no valid payment to make,
      so the form is not shown at all. Showing a field that can only
      produce a rejection would be a dead end.
    */
    if (!state.hasOutstanding) {
      return _NothingOwed(
        customerName: state.customerName,
        isOverpaid: state.balance.isOverpaid,
      );
    }

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _BalanceHeader(state: state),

            const SizedBox(height: 24),

            MoneyTextField(
              controller: _amountController,
              label: 'Amount received',
              autofocus: true,
              helperText:
                  'Up to ${state.maximumPayment.format()}',
              // §23, as a field-level rule the seller sees immediately.
              extraValidator: (amount) {
                if (!amount.isPositive) {
                  return 'Enter an amount greater than ₱0.00';
                }
                if (amount > state.maximumPayment) {
                  return 'That is more than the '
                      '${state.maximumPayment.format()} owed';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _payInFull(state.maximumPayment),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text('Pay full ${state.maximumPayment.format()}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.primaryDark,
                side: const BorderSide(color: AppPalette.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              maxLength: 200,
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. "Partial payment"',
                filled: true,
                fillColor: AppPalette.surface,
                contentPadding: const EdgeInsets.all(16),
                labelStyle: AppTextStyles.body1.copyWith(
                  color: AppPalette.textSecondary,
                ),
                hintStyle: AppTextStyles.body1.copyWith(
                  color: AppPalette.textMuted,
                ),
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

            const SizedBox(height: 12),

            const _ImmutabilityNotice(),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: state.isSubmitting ? null : _submit,
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
                  state.isSubmitting ? 'Recording...' : 'Record payment',
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
    );
  }
}

// ============================================================
class _BalanceHeader extends StatelessWidget {
  final RecordPaymentState state;

  const _BalanceHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.customerName.isEmpty
                ? 'Currently owes'
                : '${state.customerName} currently owes',
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.primarySoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.balance.outstanding.format(),
            style: AppTextStyles.heading1.copyWith(
              color: AppPalette.surface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NothingOwed extends StatelessWidget {
  final String customerName;
  final bool isOverpaid;

  const _NothingOwed({required this.customerName, required this.isOverpaid});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppPalette.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 40,
                color: AppPalette.success,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isOverpaid ? 'Account is in credit' : 'Nothing owed',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle1.copyWith(
                color: AppPalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOverpaid
                  // Should be unreachable in V1 — §23 prevents it — but
                  // if it ever happens, say something true.
                  ? 'This account shows more paid than owed. Check the '
                        'ledger before recording anything further.'
                  : '${customerName.isEmpty ? 'This customer' : customerName} '
                        'has no outstanding utang, so there is nothing to '
                        'pay right now.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImmutabilityNotice extends StatelessWidget {
  const _ImmutabilityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppPalette.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A recorded payment cannot be edited or deleted. It reduces '
              'the balance without changing any past utang.',
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
