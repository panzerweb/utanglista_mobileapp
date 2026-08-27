import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';

class GlobalTextField extends StatelessWidget {
  final String label;
  final TextEditingController? fieldController;
  final bool hideText;
  final bool readOnly;

  /// Textarea options
  final bool expanding;
  final int? maxLines;
  final int? minLines;

  // Input Type
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const GlobalTextField({
    super.key,
    this.fieldController,
    required this.label,
    this.validator,
    this.hideText = false,
    this.readOnly = false,
    this.expanding = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: fieldController,
      obscureText: hideText,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,

      /// Important textarea logic
      expands: expanding,
      maxLines: expanding ? null : maxLines,
      minLines: expanding ? null : minLines,

      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: AppPalette.textMuted),
        filled: true,
        fillColor: AppPalette.accentSoft,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 20.0,
        ),
        // Border state when NOT focused
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppPalette.accentSoft, width: 1.0),
        ),
        // Border state when focused
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppPalette.accentSoft, width: 2.0),
        ),
        // Border state when there's an error
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
        ),
      ),
    );
  }
}
