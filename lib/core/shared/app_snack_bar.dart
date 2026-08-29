import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  COMPONENT: every transient message in the app goes through here.

  BlocListener is where these belong — a snackbar is a side effect of a
  state transition, not something a BlocBuilder should rebuild into
  existence. Calling this from a builder fires it on every rebuild.

  Usage:
    BlocListener<StoreFormCubit, StoreFormState>(
      listener: (context, state) => switch (state) {
        StoreFormSuccess() => AppSnackBar.success(context, 'Store saved.'),
        StoreFormFailure(:final error) => AppSnackBar.failure(context, error),
        _ => null,
      },
      ...
    );
*/
abstract final class AppSnackBar {
  /// Shows an AppFailure using the message the repository already wrote.
  static void failure(BuildContext context, AppFailure error) {
    _show(
      context,
      message: error.message,
      background: AppPalette.danger,
      icon: Icons.error_outline_rounded,
    );
  }

  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      background: AppPalette.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      background: AppPalette.accent,
      icon: Icons.info_outline_rounded,
    );
  }

  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      background: AppPalette.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color background,
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // Replace rather than queue: a stack of stale snackbars outlives the
    // screen that caused them.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: AppPalette.surface, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.surface,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
