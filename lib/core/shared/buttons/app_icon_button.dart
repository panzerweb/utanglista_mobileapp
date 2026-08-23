import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/extensions/button_size_extensions.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  final String? tooltip;
  final bool selected;

  final AppButtonSize size;
  final Color backgroundColor;
  final Color foregroundColor;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.selected = false,
    required this.size,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      style: IconButton.styleFrom(backgroundColor: backgroundColor),
      onPressed: onPressed,
      icon: Icon(icon, size: size.iconSize, color: foregroundColor),
    );
  }
}
