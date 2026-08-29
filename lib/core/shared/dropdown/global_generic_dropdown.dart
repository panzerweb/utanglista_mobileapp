import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/// A generic dropdown form field that works with any data type [T]
/// (int, enum, model, String, ...).
///
/// Because [T] can be anything, provide [itemLabel] to tell the dropdown how
/// to render each item as text in both the field and the menu.
///
/// ```dart
/// INTEGER
/// GlobalGenericDropdown<int>(
///   labelOfDropdown: 'Quantity',
///   selectedValue: qty,
///   itemsList: const [1, 2, 3, 4, 5],
///   itemLabel: (value) => '$value pcs',
///   onChanged: (value) => setState(() => qty = value),
/// );
///
/// ENUM
/// GlobalGenericDropdown<ProductType>(
///   labelOfDropdown: 'Product type',
///   selectedValue: type,
///   itemsList: ProductType.values,
///   itemLabel: (t) => t.label,
///   onChanged: (t) => setState(() => type = t),
/// );
/// ```
class GlobalGenericDropdown<T> extends StatelessWidget {
  final String? labelOfDropdown;
  final T? selectedValue;
  final IconData? icon;
  final List<T> itemsList;
  final ValueChanged<T?> onChanged;

  /// Maps an item of type [T] to the text shown in the field and the menu.
  final String Function(T item) itemLabel;

  final String? hintText;

  /// When true (default), an empty selection fails validation.
  /// Ignored when a custom [validator] is supplied.
  final bool isRequired;

  /// Optional custom validator. Overrides the built-in required check.
  final String? Function(T? value)? validator;

  const GlobalGenericDropdown({
    super.key,
    required this.selectedValue,
    required this.itemsList,
    required this.onChanged,
    required this.itemLabel,
    this.labelOfDropdown = 'Category',
    this.icon,
    this.hintText,
    this.isRequired = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: selectedValue,
      isExpanded: true,
      style: AppTextStyles.body1.copyWith(color: AppPalette.textPrimary),
      dropdownColor: AppPalette.primarySoft,
      borderRadius: BorderRadius.circular(8.0),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppPalette.textMuted,
      ),
      decoration: InputDecoration(
        labelText: labelOfDropdown,
        hintText: hintText,
        filled: true,
        fillColor: AppPalette.primarySoft,
        contentPadding: const EdgeInsets.all(18.0),
        labelStyle: AppTextStyles.body1.copyWith(
          color: AppPalette.textSecondary,
        ),
        floatingLabelStyle: AppTextStyles.caption1.copyWith(
          fontWeight: FontWeight.w500,
          color: AppPalette.primaryDark,
        ),
        hintStyle: AppTextStyles.body1.copyWith(color: AppPalette.textMuted),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: AppPalette.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppPalette.textMuted, width: 1.5),
        ),
        // Subtle navy focus accent — the one moment of color.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: AppPalette.primaryDark,
            width: 2.0,
          ),
        ),
        // Palette has no semantic error color, so a darker shade carries
        // the "attention" weight instead of red.
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: AppPalette.primaryDark,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: AppPalette.primaryDark,
            width: 2.0,
          ),
        ),
        errorStyle: AppTextStyles.caption1.copyWith(
          color: AppPalette.textPrimary,
        ),
      ),
      items: itemsList.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body1.copyWith(color: AppPalette.textPrimary),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator:
          validator ??
          (isRequired
              ? (value) => value == null
                    ? 'Please select a ${labelOfDropdown ?? 'value'}'
                    : null
              : null),
    );
  }
}
