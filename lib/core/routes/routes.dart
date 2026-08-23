import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/shared/app_view.dart';
import 'package:utanglista_mobileapp/features/dashboard_screen.dart';
import 'package:utanglista_mobileapp/features/home_screen.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/screens/stores_screen.dart';

// NAVIGATOR KEYS
final _routerKey = GlobalKey<NavigatorState>();

final _shellNavigatorDashboardsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellDashboard',
);
final _shellNavigatorStoresKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellStores',
);
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellSettings',
);

final router = GoRouter(
  navigatorKey: _routerKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return HomeScreen();
      },
    ),
    // ROUTES INSIDE STATEFUL SHELL ROUTE AND BOTTOM NAVIGATION BAR
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppView(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorDashboardsKey,
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) {
                return DashboardScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorStoresKey,
          routes: [
            GoRoute(
              path: '/stores',
              builder: (context, state) {
                return StoresScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSettingsKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                return Center(child: Text("Settings"));
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
