import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/shared/app_view.dart';
import 'package:utanglista_mobileapp/core/shared/scanner/barcode_scanner_screen.dart';
import 'package:utanglista_mobileapp/features/backup/presentation/screens/settings_screen.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:utanglista_mobileapp/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:utanglista_mobileapp/features/payments/presentation/screens/record_payment_screen.dart';
import 'package:utanglista_mobileapp/features/products/presentation/screens/product_form_screen.dart';
import 'package:utanglista_mobileapp/features/home_screen.dart';
import 'package:utanglista_mobileapp/features/interest/presentation/screens/apply_interest_screen.dart';
import 'package:utanglista_mobileapp/features/interest/presentation/screens/interest_history_screen.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/screens/store_detail_screen.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/screens/transaction_builder_screen.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/screens/store_form_screen.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/screens/stores_screen.dart';

/*
  ------------------------------------------------------------------
  ALL NAVIGATION GOES THROUGH GO_ROUTER.
  ------------------------------------------------------------------

  Use context.push / context.go / context.pop. Do not call
  Navigator.push directly — a second navigation system means two places
  to look when a back button misbehaves, and routes that cannot be
  deep-linked or restored.

  The one exception is DIALOGS and BOTTOM SHEETS. showDialog and
  showModalBottomSheet are not routes go_router owns; they are the
  Flutter APIs for transient overlays, and AppConfirmDialog and
  ManualBarcodeEntryDialog correctly use them.

  RETURN VALUES work through go_router the same way they do through
  Navigator:

      final barcode = await context.push<String>(ScanRoute.path);
      // ...and inside the scanner:
      context.pop(barcode);

  ------------------------------------------------------------------
  WHERE A ROUTE BELONGS.
  ------------------------------------------------------------------

  Nested in a shell branch   keeps the bottom navigation bar visible.
                             Use for browsing screens the user moves
                             between freely — store detail, for example.

  parentNavigatorKey:        covers the whole screen, bottom bar
  _routerKey                 included. Use for focused tasks: forms and
                             the scanner, where the bar is an invitation
                             to lose half-entered work.
*/

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

/*
  Route paths as constants rather than string literals at call sites.
  A typo in context.push('/stroes/new') is a runtime failure that only
  shows up when someone taps the button.
*/
abstract final class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';

  static const String stores = '/stores';
  static const String newStore = '/stores/new';
  static const String scan = '/scan';

  static String storeDetail(int storeId) => '/stores/$storeId';
  static String editStore(int storeId) => '/stores/$storeId/edit';

  static String newCustomer(int storeId) => '/stores/$storeId/customers/new';
  static String customerDetail(int storeId, int customerId) =>
      '/stores/$storeId/customers/$customerId';
  static String editCustomer(int storeId, int customerId) =>
      '/stores/$storeId/customers/$customerId/edit';

  static String newProduct(int storeId) => '/stores/$storeId/products/new';
  static String editProduct(int storeId, int productId) =>
      '/stores/$storeId/products/$productId';

  static String newTransaction(int storeId) =>
      '/stores/$storeId/transactions/new';
  static String transactionDetail(int storeId, int transactionId) =>
      '/stores/$storeId/transactions/$transactionId';

  static String newPayment(int storeId, int customerId) =>
      '/stores/$storeId/customers/$customerId/payments/new';

  static String applyInterest(int storeId) =>
      '/stores/$storeId/interest/apply';

  static String interestHistory(int storeId, {int? customerId}) =>
      customerId == null
      ? '/stores/$storeId/interest'
      : '/stores/$storeId/interest?customerId=$customerId';
}

final router = GoRouter(
  navigatorKey: _routerKey,
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) {
        return HomeScreen();
      },
    ),

    /*
      Full-screen, over the bottom bar. Pops the scanned barcode back to
      whoever pushed it:

        final barcode = await context.push<String>(AppRoutes.scan);
    */
    GoRoute(
      path: AppRoutes.scan,
      parentNavigatorKey: _routerKey,
      builder: (context, state) {
        final extra = state.extra as ScanRequest?;

        return BarcodeScannerScreen(
          title: extra?.title ?? 'Scan barcode',
          subtitle: extra?.subtitle,
        );
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
              path: AppRoutes.dashboard,
              builder: (context, state) {
                return const DashboardScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorStoresKey,
          routes: [
            GoRoute(
              path: AppRoutes.stores,
              builder: (context, state) {
                return const StoresScreen();
              },
              routes: [
                /*
                  'new' is declared BEFORE ':storeId'. go_router matches
                  in order, so the reverse would make /stores/new parse
                  as a store whose id is the word "new".
                */
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _routerKey,
                  builder: (context, state) {
                    return const StoreFormScreen();
                  },
                ),
                GoRoute(
                  path: ':storeId',
                  builder: (context, state) {
                    final storeId = int.tryParse(
                      state.pathParameters['storeId'] ?? '',
                    );

                    if (storeId == null) {
                      return const _InvalidRouteScreen(
                        message: 'That store link is not valid.',
                      );
                    }

                    return StoreDetailScreen(storeId: storeId);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final storeId = int.tryParse(
                          state.pathParameters['storeId'] ?? '',
                        );

                        if (storeId == null) {
                          return const _InvalidRouteScreen(
                            message: 'That store link is not valid.',
                          );
                        }

                        return StoreFormScreen(storeId: storeId);
                      },
                    ),

                    /*
                      Customers live under their store, because that is
                      what scopes them — the same person buying from two
                      stores is two customer rows with two ledgers.
                    */
                    /*
                      Multi-segment paths rather than a 'customers'
                      parent route. There is no screen at
                      /stores/1/customers — the list is a tab inside the
                      store detail — so a parent route would need a
                      builder for a page that does not exist.

                      'customers/new' is declared BEFORE
                      'customers/:customerId': go_router matches in
                      order, so the reverse would parse "new" as a
                      customer id.
                    */
                    /*
                      Interest is applied per STORE, from its settings
                      tab — the rate belongs to the store, and the run
                      covers every customer in it.
                    */
                    GoRoute(
                      path: 'interest/apply',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final storeId = int.tryParse(
                          state.pathParameters['storeId'] ?? '',
                        );
                        final request = state.extra as ApplyInterestRequest?;

                        if (storeId == null || request == null) {
                          return const _InvalidRouteScreen(
                            message: 'That interest link is not valid.',
                          );
                        }

                        return ApplyInterestScreen(
                          storeId: storeId,
                          rate: request.rate,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'interest',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final storeId = int.tryParse(
                          state.pathParameters['storeId'] ?? '',
                        );

                        if (storeId == null) {
                          return const _InvalidRouteScreen(
                            message: 'That store link is not valid.',
                          );
                        }

                        final customerId = int.tryParse(
                          state.uri.queryParameters['customerId'] ?? '',
                        );

                        return InterestHistoryScreen(
                          storeId: storeId,
                          customerId: customerId,
                        );
                      },
                    ),

                    /*
                      Full-screen: recording money received deserves
                      the same focus as building a cart.
                    */
                    GoRoute(
                      path: 'customers/:customerId/payments/new',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final ids = _storeAndCustomerIds(state);

                        if (ids == null) {
                          return const _InvalidRouteScreen(
                            message: 'That customer link is not valid.',
                          );
                        }

                        final request = state.extra as RecordPaymentRequest?;

                        return RecordPaymentScreen(
                          storeId: ids.$1,
                          customerId: ids.$2,
                          customerName: request?.customerName,
                        );
                      },
                    ),

                    /*
                      The builder is full-screen (parentNavigatorKey):
                      a half-built cart is exactly the kind of work the
                      bottom bar invites people to lose.

                      'transactions/new' before 'transactions/:id' —
                      go_router matches in order.
                    */
                    GoRoute(
                      path: 'transactions/new',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final storeId = int.tryParse(
                          state.pathParameters['storeId'] ?? '',
                        );

                        if (storeId == null) {
                          return const _InvalidRouteScreen(
                            message: 'That store link is not valid.',
                          );
                        }

                        final request =
                            state.extra as TransactionBuilderRequest?;

                        return TransactionBuilderScreen(
                          storeId: storeId,
                          customerId: request?.customerId,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'transactions/:transactionId',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final storeId = int.tryParse(
                          state.pathParameters['storeId'] ?? '',
                        );
                        final transactionId = int.tryParse(
                          state.pathParameters['transactionId'] ?? '',
                        );

                        if (storeId == null || transactionId == null) {
                          return const _InvalidRouteScreen(
                            message: 'That transaction link is not valid.',
                          );
                        }

                        return TransactionDetailScreen(
                          storeId: storeId,
                          transactionId: transactionId,
                        );
                      },
                    ),

                    /*
                      Products, like customers, are scoped to their
                      store — the same barcode may exist in two stores
                      as two separate products with two prices.

                      There is no separate product DETAIL route: the
                      form doubles as it. See ProductFormScreen.
                    */
                    GoRoute(
                      path: 'products/new',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final storeId = int.tryParse(
                          state.pathParameters['storeId'] ?? '',
                        );

                        if (storeId == null) {
                          return const _InvalidRouteScreen(
                            message: 'That store link is not valid.',
                          );
                        }

                        final request = state.extra as ProductFormRequest?;

                        return ProductFormScreen(
                          storeId: storeId,
                          initialBarcode: request?.barcode,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'products/:productId',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final storeId = int.tryParse(
                          state.pathParameters['storeId'] ?? '',
                        );
                        final productId = int.tryParse(
                          state.pathParameters['productId'] ?? '',
                        );

                        if (storeId == null || productId == null) {
                          return const _InvalidRouteScreen(
                            message: 'That product link is not valid.',
                          );
                        }

                        return ProductFormScreen(
                          storeId: storeId,
                          productId: productId,
                        );
                      },
                    ),

                    GoRoute(
                      path: 'customers/new',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final storeId = int.tryParse(
                          state.pathParameters['storeId'] ?? '',
                        );

                        if (storeId == null) {
                          return const _InvalidRouteScreen(
                            message: 'That store link is not valid.',
                          );
                        }

                        return CustomerFormScreen(storeId: storeId);
                      },
                    ),
                    GoRoute(
                      path: 'customers/:customerId',
                      parentNavigatorKey: _routerKey,
                      builder: (context, state) {
                        final ids = _storeAndCustomerIds(state);

                        if (ids == null) {
                          return const _InvalidRouteScreen(
                            message: 'That customer link is not valid.',
                          );
                        }

                        return CustomerDetailScreen(
                          storeId: ids.$1,
                          customerId: ids.$2,
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'edit',
                          parentNavigatorKey: _routerKey,
                          builder: (context, state) {
                            final ids = _storeAndCustomerIds(state);

                            if (ids == null) {
                              return const _InvalidRouteScreen(
                                message: 'That customer link is not valid.',
                              );
                            }

                            return CustomerFormScreen(
                              storeId: ids.$1,
                              customerId: ids.$2,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSettingsKey,
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/*
  Carries a scanned barcode into the new-product form, so a scan that
  found nothing can go straight to creating it with the field filled.
*/
class ProductFormRequest {
  final String? barcode;

  const ProductFormRequest({this.barcode});
}

/*
  Pre-selects the customer when the builder is opened from that
  customer's own screen, so they are not asked to pick someone they
  have already chosen.
*/
class TransactionBuilderRequest {
  final int? customerId;

  const TransactionBuilderRequest({this.customerId});
}

/// Lets the payment screen show the customer's name while the balance
/// is still loading, instead of a blank header.
class RecordPaymentRequest {
  final String? customerName;

  const RecordPaymentRequest({this.customerName});
}

/*
  Carries the store's rate into the interest screen.

  Passed rather than re-read so the screen charges the rate the seller
  was just looking at in settings — §21 snapshots it onto every record
  it produces, so which rate is used is not a detail.
*/
class ApplyInterestRequest {
  final InterestRate rate;

  const ApplyInterestRequest({required this.rate});
}

/*
  Optional context for the scanner, passed through `extra` so the
  screen can say what the scan is for without a second route.
*/
class ScanRequest {
  final String title;
  final String? subtitle;

  const ScanRequest({this.title = 'Scan barcode', this.subtitle});
}

/// Both ids from a nested customer route, or null if either is not a
/// number. Returned together because every customer screen needs both.
(int, int)? _storeAndCustomerIds(GoRouterState state) {
  final storeId = int.tryParse(state.pathParameters['storeId'] ?? '');
  final customerId = int.tryParse(state.pathParameters['customerId'] ?? '');

  if (storeId == null || customerId == null) return null;

  return (storeId, customerId);
}

/// Shown when a path parameter cannot be parsed, instead of throwing
/// and leaving the user on a red screen they cannot navigate out of.
class _InvalidRouteScreen extends StatelessWidget {
  final String message;

  const _InvalidRouteScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(message)),
    );
  }
}
