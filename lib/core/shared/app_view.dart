import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';

class AppView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppView({super.key, required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppPalette.surface,
          border: Border(top: BorderSide(color: AppPalette.border, width: 1.0)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 65,
            elevation: 0,
            backgroundColor: AppPalette.surface,
            indicatorColor: AppPalette.primarySoft,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppPalette.primary
                    : AppPalette.textSecondary,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();
              _goBranch(index);
            },
            destinations: [
              _menuItem(
                context,
                index: 0,
                currentIndex: navigationShell.currentIndex,
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
              ),
              _menuItem(
                context,
                index: 1,
                currentIndex: navigationShell.currentIndex,
                icon: Icons.store_outlined,
                selectedIcon: Icons.store_rounded,
                label: 'Stores',
              ),
              _menuItem(
                context,
                index: 2,
                currentIndex: navigationShell.currentIndex,
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: AppPalette.textSecondary),
      selectedIcon: Icon(selectedIcon, color: AppPalette.primary),
      label: label,
    );
  }
}
