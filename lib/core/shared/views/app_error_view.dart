import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  COMPONENT: the failure half of every list screen.

  Takes an AppFailure directly rather than a String, because the whole
  point of repositoryGuard's `failureMessage` is that it is already
  written in user-facing language. Re-wording it at the widget layer
  would defeat that.

  The error code is shown only in debug builds — it helps while
  developing and means nothing to a store owner.

  Usage:
    AppErrorView(failure: state.error!, onRetry: cubit.loadAllStores);
*/
class AppErrorView extends StatelessWidget {
  final AppFailure failure;
  final VoidCallback? onRetry;

  const AppErrorView({super.key, required this.failure, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppPalette.danger,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle1.copyWith(
                color: AppPalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.textSecondary,
                height: 1.4,
              ),
            ),

            // Debug-only: the code is a developer aid, not user content.
            if (_isDebug) ...[
              const SizedBox(height: 8),
              Text(
                failure.code,
                style: AppTextStyles.caption1.copyWith(
                  color: AppPalette.textMuted,
                ),
              ),
            ],

            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.primaryDark,
                  side: const BorderSide(color: AppPalette.primary),
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

  static bool get _isDebug {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }
}
