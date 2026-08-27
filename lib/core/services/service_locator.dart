import 'package:get_it/get_it.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_balance_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_repository.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:utanglista_mobileapp/features/dashboard/data/datasource/dashboard_local_data_source.dart';
import 'package:utanglista_mobileapp/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:utanglista_mobileapp/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:utanglista_mobileapp/features/interest/data/datasource/interest_local_data_source.dart';
import 'package:utanglista_mobileapp/features/interest/domain/repositories/interest_repository.dart';
import 'package:utanglista_mobileapp/features/interest/presentation/bloc/interest_cubit.dart';
import 'package:utanglista_mobileapp/features/ledger/data/datasource/ledger_local_data_source.dart';
import 'package:utanglista_mobileapp/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:utanglista_mobileapp/features/ledger/presentation/bloc/ledger_cubit.dart';
import 'package:utanglista_mobileapp/features/payments/data/datasource/payment_local_data_source.dart';
import 'package:utanglista_mobileapp/features/payments/domain/repositories/payment_repository.dart';
import 'package:utanglista_mobileapp/features/payments/presentation/bloc/payment_cubit.dart';
import 'package:utanglista_mobileapp/features/products/data/datasource/product_local_data_source.dart';
import 'package:utanglista_mobileapp/features/products/domain/repositories/product_repository.dart';
import 'package:utanglista_mobileapp/features/products/presentation/bloc/product_cubit.dart';
import 'package:utanglista_mobileapp/features/stores/data/datasource/store_local_data_source.dart';
import 'package:utanglista_mobileapp/features/stores/domain/repositories/store_repository.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/bloc/store_cubit.dart';
import 'package:utanglista_mobileapp/features/transactions/data/datasource/transaction_local_data_source.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/bloc/transaction_cubit.dart';

final GetIt locator = GetIt.instance;

/*
  ------------------------------------------------------------------
  Registration rules, so every feature added later looks the same.
  ------------------------------------------------------------------

  AppDatabase          singleton. One connection for the whole app —
                       a second one would mean a second write lock.

  Datasources          lazy singletons. Stateless wrappers over the
  Repositories         database; there is no reason to build more than
                       one, and holding one avoids rebuilding it per
                       screen.

  Cubits               FACTORY, never singleton. A cubit holds the
                       state of one screen and is closed when that
                       screen is disposed. A singleton cubit would be
                       reused after close() and throw, and two screens
                       showing the same list would fight over one
                       filter.

  Registration order matters: a lazy singleton's factory runs on first
  resolve, so dependencies only have to be registered before that —
  but keeping them in dependency order makes the graph readable.
*/
void setupLocator() {
  // ========================================================
  // ** CORE **
  // ========================================================
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // ========================================================
  // ** STORES **
  // ========================================================
  locator.registerLazySingleton<StoreLocalDataSource>(
    () => StoreLocalDataSourceImplementation(locator<AppDatabase>()),
  );

  locator.registerLazySingleton<StoreRepository>(
    () => StoreRepositoryImplementation(locator<StoreLocalDataSource>()),
  );

  locator.registerFactory<StoreListCubit>(
    () => StoreListCubit(
      locator<StoreRepository>(),
      locator<CustomerBalanceRepository>(),
    ),
  );

  locator.registerFactory<StoreDetailCubit>(
    () => StoreDetailCubit(
      locator<StoreRepository>(),
      locator<CustomerBalanceRepository>(),
    ),
  );

  locator.registerFactory<StoreFormCubit>(
    () => StoreFormCubit(locator<StoreRepository>()),
  );

  // ========================================================
  // ** CUSTOMER BALANCES **
  // Registered ahead of the rest of the customers feature because
  // several slices read balances: the customer list, the payment
  // validator, the interest base and the dashboard totals. It is the
  // single authoritative path (§16), so it is registered once here
  // rather than constructed per feature.
  // ========================================================
  locator.registerLazySingleton<CustomerBalanceLocalDataSource>(
    () => CustomerBalanceLocalDataSourceImplementation(locator<AppDatabase>()),
  );

  locator.registerLazySingleton<CustomerBalanceRepository>(
    () => CustomerBalanceRepositoryImplementation(
      locator<CustomerBalanceLocalDataSource>(),
    ),
  );

  // ========================================================
  // ** CUSTOMERS **
  // ========================================================
  locator.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSourceImplementation(locator<AppDatabase>()),
  );

  locator.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImplementation(locator<CustomerLocalDataSource>()),
  );

  /*
    registerFactoryParam because the customer list is always scoped to
    one store — there is no such thing as "all customers" in this app.
    Resolved as locator<CustomerListCubit>(param1: storeId).
  */
  locator.registerFactoryParam<CustomerListCubit, int, void>(
    (storeId, _) => CustomerListCubit(
      locator<CustomerRepository>(),
      locator<CustomerBalanceRepository>(),
      storeId: storeId,
    ),
  );

  locator.registerFactory<CustomerDetailCubit>(
    () => CustomerDetailCubit(
      locator<CustomerRepository>(),
      locator<CustomerBalanceRepository>(),
    ),
  );

  locator.registerFactory<CustomerFormCubit>(
    () => CustomerFormCubit(locator<CustomerRepository>()),
  );

  // ========================================================
  // ** PRODUCTS **
  // ========================================================
  locator.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImplementation(locator<AppDatabase>()),
  );

  locator.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImplementation(locator<ProductLocalDataSource>()),
  );

  // Store-scoped, like the customer list.
  locator.registerFactoryParam<ProductListCubit, int, void>(
    (storeId, _) =>
        ProductListCubit(locator<ProductRepository>(), storeId: storeId),
  );

  /*
    Store-scoped too: a barcode identifies a product WITHIN one store,
    so the lookup cannot be shared across them. Phase 4's transaction
    builder resolves its own instance for the same reason.
  */
  locator.registerFactoryParam<BarcodeLookupCubit, int, void>(
    (storeId, _) =>
        BarcodeLookupCubit(locator<ProductRepository>(), storeId: storeId),
  );

  locator.registerFactory<ProductDetailCubit>(
    () => ProductDetailCubit(locator<ProductRepository>()),
  );

  locator.registerFactory<ProductFormCubit>(
    () => ProductFormCubit(locator<ProductRepository>()),
  );

  // ========================================================
  // ** TRANSACTIONS **
  // ========================================================
  locator.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImplementation(locator<AppDatabase>()),
  );

  locator.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImplementation(
      locator<TransactionLocalDataSource>(),
    ),
  );

  /*
    Two params: the store, and optionally one customer. The same list
    serves the store's Transactions tab (customerId null) and a
    customer's Utang tab.
  */
  locator.registerFactoryParam<TransactionListCubit, int, int?>(
    (storeId, customerId) => TransactionListCubit(
      locator<TransactionRepository>(),
      storeId: storeId,
      customerId: customerId,
    ),
  );

  locator.registerFactory<TransactionDetailCubit>(
    () => TransactionDetailCubit(locator<TransactionRepository>()),
  );

  locator.registerFactoryParam<TransactionBuilderCubit, int, void>(
    (storeId, _) => TransactionBuilderCubit(
      locator<TransactionRepository>(),
      storeId: storeId,
    ),
  );

  // ========================================================
  // ** PAYMENTS **
  // ========================================================
  locator.registerLazySingleton<PaymentLocalDataSource>(
    () => PaymentLocalDataSourceImplementation(locator<AppDatabase>()),
  );

  locator.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImplementation(locator<PaymentLocalDataSource>()),
  );

  locator.registerFactoryParam<PaymentListCubit, int, int?>(
    (storeId, customerId) => PaymentListCubit(
      locator<PaymentRepository>(),
      storeId: storeId,
      customerId: customerId,
    ),
  );

  locator.registerFactoryParam<RecordPaymentCubit, int, int>(
    (storeId, customerId) => RecordPaymentCubit(
      locator<PaymentRepository>(),
      locator<CustomerBalanceRepository>(),
      storeId: storeId,
      customerId: customerId,
    ),
  );

  // ========================================================
  // ** LEDGER **
  // A read model over transactions, payments and interest (§17) —
  // its own slice because it belongs to none of the three.
  // ========================================================
  locator.registerLazySingleton<LedgerLocalDataSource>(
    () => LedgerLocalDataSourceImplementation(locator<AppDatabase>()),
  );

  locator.registerLazySingleton<LedgerRepository>(
    () => LedgerRepositoryImplementation(locator<LedgerLocalDataSource>()),
  );

  locator.registerFactoryParam<LedgerCubit, int, void>(
    (customerId, _) =>
        LedgerCubit(locator<LedgerRepository>(), customerId: customerId),
  );

  // ========================================================
  // ** INTEREST **
  // ========================================================
  locator.registerLazySingleton<InterestLocalDataSource>(
    () => InterestLocalDataSourceImplementation(locator<AppDatabase>()),
  );

  locator.registerLazySingleton<InterestRepository>(
    () => InterestRepositoryImplementation(locator<InterestLocalDataSource>()),
  );

  locator.registerFactoryParam<InterestHistoryCubit, int, int?>(
    (storeId, customerId) => InterestHistoryCubit(
      locator<InterestRepository>(),
      storeId: storeId,
      customerId: customerId,
    ),
  );

  // ========================================================
  // ** DASHBOARD **
  // A read model over every other slice — registered last because it
  // depends on the balance, store and interest repositories.
  // ========================================================
  locator.registerLazySingleton<DashboardLocalDataSource>(
    () => DashboardLocalDataSourceImplementation(locator<AppDatabase>()),
  );

  locator.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImplementation(
      locator<DashboardLocalDataSource>(),
      locator<CustomerBalanceRepository>(),
      locator<StoreRepository>(),
      locator<InterestRepository>(),
    ),
  );

  locator.registerFactory<DashboardCubit>(
    () => DashboardCubit(locator<DashboardRepository>()),
  );

  /*
    ApplyInterestCubit is constructed directly by its screen rather
    than registered: it needs a store, a rate AND a period, which is
    one parameter more than registerFactoryParam supports. It resolves
    its repository through `locator()` in the constructor call.
  */
}
