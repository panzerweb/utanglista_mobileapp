import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/extensions/button_size_extensions.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';

class AppFilledButton extends StatelessWidget {
  final String buttonText;
  final IconData icon;
  final VoidCallback? onSubmitButton;

  /// Controls whether the button is enabled.
  final bool conditionBool;

  /// Controls the overall size of the button.
  final AppButtonSize size;

  /// Whether the button should take up the available width.
  final bool fullWidth;

  const AppFilledButton({
    super.key,
    required this.buttonText,
    required this.icon,
    required this.onSubmitButton,
    this.conditionBool = true,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: size.height,
      child: FilledButton.icon(
        onPressed: conditionBool ? onSubmitButton : null,
        icon: Icon(icon, size: size.iconSize),
        label: Text(buttonText, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primaryDark,
          foregroundColor: AppPalette.surface,

          disabledBackgroundColor: AppPalette.surfaceSubtle.withValues(
            alpha: 0.4,
          ),

          disabledForegroundColor: AppPalette.textMuted.withValues(alpha: 0.6),

          elevation: 0,

          padding: size.padding,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
