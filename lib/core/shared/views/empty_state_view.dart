import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  COMPONENT: the "nothing here yet" half of every list screen.

  Every list in this app has three non-success states — empty, loading,
  error — and they should look the same everywhere. This is the first
  of the three.

  Empty is not an error: the message points at what to do next rather
  than apologising, which is why [actionLabel] exists.

  Usage:
    EmptyStateView(
      icon: Icons.store_outlined,
      title: 'No stores yet',
      message: 'Add your first store to start tracking utang.',
      actionLabel: 'Add store',
      onAction: () => context.push('/stores/new'),
    );
*/
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  /// Optional call to action. Both must be supplied for the button to show.
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final showAction = actionLabel != null && onAction != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppPalette.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppPalette.primary),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle1.copyWith(
                color: AppPalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body1.copyWith(
                  color: AppPalette.textSecondary,
                  height: 1.4,
                ),
              ),
            ],

            if (showAction) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primaryDark,
                  foregroundColor: AppPalette.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
