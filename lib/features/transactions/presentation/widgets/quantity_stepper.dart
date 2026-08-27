import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  −  [ 1.5 kg ]  +

  Tapping the number opens a keypad dialog, because goods sold by
  weight need 0.25 and tapping + twelve times is not a way to enter
  1.5 kg.

  §38 requires quantity > 0. This widget never emits a value at or
  below zero — the minus button stops at the smallest sensible step,
  and removing a line is done with the line's own remove button, not
  by decrementing into nothing.
*/
class QuantityStepper extends StatelessWidget {
  final double quantity;
  final String unit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<double> onSetQuantity;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.unit,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSetQuantity,
  });

  String get _label {
    final formatted = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();

    return '$formatted $unit';
  }

  Future<void> _editQuantity(BuildContext context) async {
    final entered = await showDialog<double>(
      context: context,
      builder: (_) => _QuantityDialog(quantity: quantity, unit: unit),
    );

    if (entered == null) return;

    onSetQuantity(entered);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            // Below 1 the minus would have to go to zero, which §38
            // forbids as a quantity. Remove the line instead.
            onTap: quantity > 1 ? onDecrement : null,
          ),

          InkWell(
            onTap: () => _editQuantity(context),
            child: Container(
              constraints: const BoxConstraints(minWidth: 64),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              alignment: Alignment.center,
              child: Text(
                _label,
                style: AppTextStyles.body1.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          _StepButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppPalette.textMuted : AppPalette.primaryDark,
        ),
      ),
    );
  }
}

/*
  Free entry for fractional quantities. Rejects zero and negatives
  outright (§38) rather than accepting them and failing at submit.
*/
class _QuantityDialog extends StatefulWidget {
  final double quantity;
  final String unit;

  const _QuantityDialog({required this.quantity, required this.unit});

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.quantity == widget.quantity.roundToDouble()
        ? widget.quantity.toInt().toString()
        : widget.quantity.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(double.parse(_controller.text.trim()));
  }

  String? _validate(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Enter a quantity';

    final parsed = double.tryParse(raw);
    if (parsed == null) return 'Enter a number';

    // §38: quantity must be greater than zero.
    if (parsed <= 0) return 'Quantity must be more than zero';
    if (parsed > 100000) return 'That quantity is too large';

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Quantity',
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
          ],
          style: AppTextStyles.body1.copyWith(
            color: AppPalette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            suffixText: widget.unit,
            helperText: 'Decimals are fine, e.g. 0.25',
            filled: true,
            fillColor: AppPalette.accentSoft,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            helperStyle: AppTextStyles.caption1.copyWith(
              color: AppPalette.textMuted,
            ),
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
          child: const Text('Set'),
        ),
      ],
    );
  }
}
