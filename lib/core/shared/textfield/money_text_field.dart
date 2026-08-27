import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  ------------------------------------------------------------------
  The only way a peso amount is typed in this app.
  ------------------------------------------------------------------

  Product price, payment amount, transaction line — all of them come
  through here, so the parsing and the §25 "never negative" rule live
  in one place instead of being re-implemented per form.

  Reads back as Money, never as a String or a double:

    final price = MoneyTextField.read(_priceController);
    if (price == null) return;              // already rejected by validate()

  The input formatter blocks anything that is not a valid partial
  amount as it is typed. Rejecting a keystroke is friendlier than
  accepting "12.3.4" and explaining afterwards, and it means the
  validator only ever has to handle empty and out-of-range.
*/
class MoneyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? helperText;

  /// When false, an empty field is valid and reads back as null.
  final bool isRequired;

  /// Extra rule on top of parsing and the non-negative check — used by
  /// the payment screen for the §23 overpayment cap.
  final String? Function(Money amount)? extraValidator;

  final void Function(String value)? onChanged;
  final bool autofocus;

  const MoneyTextField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.hintText = '0.00',
    this.helperText,
    this.isRequired = true,
    this.extraValidator,
    this.onChanged,
    this.autofocus = false,
  });

  /// Parses a money controller's current text. null when empty or
  /// unparseable — callers should validate the form first.
  static Money? read(TextEditingController controller) =>
      Money.tryParse(controller.text);

  String? _validate(String? value) {
    final raw = value?.trim() ?? '';

    if (raw.isEmpty) {
      return isRequired ? 'Enter an amount' : null;
    }

    final amount = Money.tryParse(raw);
    if (amount == null) return 'Enter a valid amount';

    // §25: price, unit price, subtotal, payment and interest amounts
    // must never be negative.
    if (amount.isNegative) return 'Amount cannot be negative';

    return extraValidator?.call(amount);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: _validate,
      onChanged: onChanged,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_PesoInputFormatter()],
      style: AppTextStyles.body1.copyWith(
        color: AppPalette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixText: '₱ ',
        prefixStyle: AppTextStyles.body1.copyWith(
          color: AppPalette.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppPalette.accentSoft,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        labelStyle: AppTextStyles.body1.copyWith(
          color: AppPalette.textSecondary,
        ),
        hintStyle: AppTextStyles.body1.copyWith(color: AppPalette.textMuted),
        helperStyle: AppTextStyles.caption1.copyWith(
          color: AppPalette.textMuted,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.accentSoft, width: 1),
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
    );
  }
}

/*
  Allows only what can still become a peso amount: digits, at most one
  decimal point, at most two digits after it.

  '' and '12.' are permitted mid-typing even though neither is a
  complete amount — blocking them would make the field impossible to
  type into. The validator catches what is left.
*/
class _PesoInputFormatter extends TextInputFormatter {
  static final RegExp _partialAmount = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    return _partialAmount.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
