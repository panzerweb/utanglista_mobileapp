import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/extensions/button_size_extensions.dart';
import 'package:utanglista_mobileapp/core/shared/buttons/app_elevated_button.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.success,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              const Text(
                "UtangLista",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.surface,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Your Trusted Store Companion",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPalette.accentSoft, fontSize: 16),
              ),

              const SizedBox(height: 48),

              const Spacer(),

              AppElevatedButton(
                label: 'Enter Dashboard',
                backgroundColor: AppPalette.primaryDark,
                foregroundColor: AppPalette.surface,
                enabled: true,
                size: AppButtonSize.large,

                onPressed: () {
                  context.pushReplacement('/dashboard');
                },
              ),

              const SizedBox(height: 18),

              const Text(
                "UtangLista v1.0.0",
                style: TextStyle(color: AppPalette.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
