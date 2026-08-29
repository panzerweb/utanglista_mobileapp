import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  ------------------------------------------------------------------
  The way in when the camera is not.
  ------------------------------------------------------------------

  Reached from three directions, all of them ordinary rather than
  exceptional:

    - the user denied camera permission
    - the device has no usable camera
    - the barcode is scratched, curved, or worn unreadable

  Returns the entered barcode, or null if cancelled — the same contract
  as BarcodeScannerScreen, so a caller can treat the two identically.
*/
abstract final class ManualBarcodeEntryDialog {
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _ManualBarcodeEntryDialog(),
    );
  }
}

class _ManualBarcodeEntryDialog extends StatefulWidget {
  const _ManualBarcodeEntryDialog();

  @override
  State<_ManualBarcodeEntryDialog> createState() =>
      _ManualBarcodeEntryDialogState();
}

class _ManualBarcodeEntryDialogState extends State<_ManualBarcodeEntryDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  /*
    Deliberately permissive.

    Retail barcodes are 8-14 digits, but this app also has to cope with
    the handwritten codes a store owner invents for repacked goods, and
    with Code 128 labels that carry letters. Rejecting those would push
    the user back to the camera they already could not use.

    So: require something, cap the length, and let the (store, barcode)
    unique index catch the only error that actually matters — the same
    barcode used twice in one store.
  */
  String? _validate(String? value) {
    final barcode = value?.trim() ?? '';

    if (barcode.isEmpty) return 'Enter the barcode';
    if (barcode.length > 40) return 'That barcode is too long';

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Enter barcode',
        style: AppTextStyles.subtitle1.copyWith(
          color: AppPalette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          validator: _validate,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),

          // Numeric-first, because almost every printed barcode is
          // digits — but not digits-only, so a Code 128 label with
          // letters can still be typed.
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],

          style: AppTextStyles.body1.copyWith(
            color: AppPalette.textPrimary,
            letterSpacing: 1.2,
          ),
          decoration: InputDecoration(
            hintText: '4801234567890',
            hintStyle: AppTextStyles.body1.copyWith(
              color: AppPalette.textMuted,
              letterSpacing: 1.2,
            ),
            filled: true,
            fillColor: AppPalette.accentSoft,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
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
              borderSide: const BorderSide(color: AppPalette.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppPalette.danger, width: 2),
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppPalette.textSecondary,
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.primaryDark,
            foregroundColor: AppPalette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Use barcode'),
        ),
      ],
    );
  }
}
