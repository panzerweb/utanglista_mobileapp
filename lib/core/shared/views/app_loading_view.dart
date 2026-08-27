import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  COMPONENT: the loading half of every list screen.

  Usage:
    AppLoadingView(message: 'Loading stores...');
*/
class AppLoadingView extends StatelessWidget {
  final String? message;

  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppPalette.primary,
            ),
          ),

          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
