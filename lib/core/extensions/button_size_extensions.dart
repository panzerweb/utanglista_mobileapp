import 'package:flutter/material.dart';

enum AppButtonSize { small, medium, large }

extension ButtonSizeExtensions on AppButtonSize {
  // Returning the height base on set size
  double get height {
    switch (this) {
      case AppButtonSize.small:
        return 40;

      case AppButtonSize.medium:
        return 48;

      case AppButtonSize.large:
        return 56;
    }
  }

  // Returning the padding
  EdgeInsets get padding {
    switch (this) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12);

      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16);

      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24);
    }
  }

  // Returning the icon size
  double get iconSize {
    switch (this) {
      case AppButtonSize.small:
        return 18;

      case AppButtonSize.medium:
        return 20;

      case AppButtonSize.large:
        return 24;
    }
  }
}
