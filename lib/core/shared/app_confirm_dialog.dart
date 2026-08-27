import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  COMPONENT: the gate in front of every destructive action.

  §30 requires deletion of financial data to be a deliberate act rather
  than a stray tap. Deleting a store cascades to its customers,
  products, transactions and payments, so this is the difference
  between an accident and a lost ledger.

  Returns true only when the user confirms. A dismissed dialog returns
  null, which `== true` treats as a no — so the call site never has to
  handle three cases.

  Usage:
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete this store?',
      message: 'Its customers, products and transaction history will be '
               'removed permanently. This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;
*/
abstract final class AppConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',

    /// Paints the confirm button in the danger colour. Use for anything
    /// that removes data.
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      // Force a deliberate choice on destructive actions.
      barrierDismissible: !isDestructive,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppPalette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: AppTextStyles.subtitle1.copyWith(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: AppTextStyles.body1.copyWith(
              color: AppPalette.textSecondary,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.textSecondary,
              ),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: isDestructive
                    ? AppPalette.danger
                    : AppPalette.primaryDark,
                foregroundColor: AppPalette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    // Dismissed (null) counts as "no".
    return result == true;
  }
}
