import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';

/*
  How each category LOOKS, kept out of the enum itself.

  StoreCategory lives in core/constants and is used by the data layer;
  giving it a Color would drag Flutter into files that have no business
  importing it. The same split as button_size_extensions.dart.
*/
extension StoreCategoryExtensions on StoreCategory {
  IconData get icon {
    switch (this) {
      case StoreCategory.retail:
        return Icons.storefront_rounded;

      case StoreCategory.street:
        return Icons.local_dining_rounded;

      case StoreCategory.personal:
        return Icons.person_rounded;
    }
  }

  /// Text and icon colour for the badge.
  Color get color {
    switch (this) {
      case StoreCategory.retail:
        return AppPalette.primaryDark;

      case StoreCategory.street:
        return AppPalette.warning;

      case StoreCategory.personal:
        return AppPalette.accent;
    }
  }

  /// Badge background — the same hue at low opacity, so the three read
  /// as one family rather than three unrelated tags.
  Color get softColor => color.withValues(alpha: 0.12);
}
