import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/extensions/button_size_extensions.dart';

class AppElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  final IconData? icon;
  final bool isLoading;
  final bool enabled;
  final bool expand;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final AppButtonSize size;

  const AppElevatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.expand = true,
    this.backgroundColor,
    this.foregroundColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: size.iconSize),
              const SizedBox(width: 8),
              Text(label),
            ],
          )
        : Text(label);

    final button = ElevatedButton(
      onPressed: enabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(8.0),
        ),
        padding: size.padding,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
      child: child,
    );

    return expand
        ? SizedBox(width: double.infinity, height: size.height, child: button)
        : button;
  }
}
