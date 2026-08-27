// `show Value` deliberately: drift also exports isNull/isNotNull as SQL
// expression helpers, which collide with the matcher package's versions.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/stores/data/datasource/store_local_data_source.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';
import 'package:utanglista_mobileapp/features/stores/domain/repositories/store_repository.dart';

/*
  Schema-level smoke tests.

  AppDatabase already accepts an injected QueryExecutor, so an in-memory
  database needs no extra plumbing and each test gets a clean schema.

  These cover the constraints that the business rules depend on but that
  no amount of reading the Dart can prove — the index really is unique,
  the foreign key really does block the delete. Those only become true
  once SQLite has the DDL.
*/
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('schema', () {
    test('creates and connects', () async {
      expect(await db.testConnection(), isTrue);
    });

    test('creates every table', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final tables = rows.map((r) => r.read<String>('name')).toSet();

      expect(
        tables,
        containsAll([
          'stores_table',
          'customers_table',
          'products_table',
          'transactions_table',
          'transactions_item_table',
          'payments_table',
          'store_settings_table',
          'interest_records_table',
        ]),
      );
    });

    test('creates every index — no name collisions dropped any', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final indexes = rows.map((r) => r.read<String>('name')).toSet();

      // The three that were silently lost to duplicate naming before.
      expect(indexes, contains('idx_payment_customer_created'));
      expect(indexes, contains('idx_interest_customer_created'));
      expect(indexes, contains('idx_interest_customer_period'));

      expect(
        indexes,
        containsAll([
          'idx_store_name_category',
          'idx_customer_store_name',
          'idx_product_store_name',
          'idx_product_store_barcode',
          'idx_txn_customer_created',
          'idx_txn_store_created',
          'idx_txn_item_transaction',
          'idx_txn_item_product',
          'idx_payment_store_created',
          'idx_store_settings_store',
          'idx_interest_store_created',
        ]),
      );
    });

    test('enforces foreign keys', () async {
      final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.read<int>('foreign_keys'), 1);
    });
  });

  group('constraints the business rules depend on', () {
    Future<int> insertStore() => db
        .into(db.storesTable)
        .insert(StoresTableCompanion.insert(name: 'Aling Nena Store'));

    Future<int> insertCustomer(int storeId) => db
        .into(db.customersTable)
        .insert(
          CustomersTableCompanion.insert(storeId: storeId, name: 'Juan'),
        );

    test('a short name is accepted — "Rice" and "Juan" are real names', () async {
      final storeId = await insertStore();

      // Would have thrown under the old min-length rules.
      await db
          .into(db.customersTable)
          .insert(CustomersTableCompanion.insert(storeId: storeId, name: 'Juan'));

      await db
          .into(db.productsTable)
          .insert(
            ProductsTableCompanion.insert(
              storeId: storeId,
              name: 'Rice',
              price: Money.fromPesos(100).centavos,
              unit: 'kg',
            ),
          );

      expect(await db.select(db.customersTable).get(), hasLength(1));
      expect(await db.select(db.productsTable).get(), hasLength(1));
    });

    test('contact number is optional (§4)', () async {
      final storeId = await insertStore();
      await insertCustomer(storeId);

      final customer = await db.select(db.customersTable).getSingle();
      expect(customer.contactNumber, isNull);
      expect(customer.isActive, isTrue); // defaults to active
    });

    test('createdAt defaults instead of arriving null', () async {
      await insertStore();
      final store = await db.select(db.storesTable).getSingle();

      expect(store.createdAt, isNotNull);
      expect(
        store.createdAt.difference(DateTime.now()).abs(),
        lessThan(const Duration(minutes: 1)),
      );
    });

    test('money survives the round trip as exact centavos', () async {
      final storeId = await insertStore();
      await db
          .into(db.productsTable)
          .insert(
            ProductsTableCompanion.insert(
              storeId: storeId,
              name: 'Rice',
              price: Money.fromPesos(1250.75).centavos,
              unit: 'kg',
            ),
          );

      final product = await db.select(db.productsTable).getSingle();
      expect(product.price, 125075);
      expect(Money.fromCentavos(product.price).format(), '₱1,250.75');
    });

    test('a barcode cannot repeat within one store', () async {
      final storeId = await insertStore();

      Future<void> addProduct(String name) => db
          .into(db.productsTable)
          .insert(
            ProductsTableCompanion.insert(
              storeId: storeId,
              name: name,
              price: 10000,
              unit: 'pc',
              barcode: const Value('4801234567890'),
            ),
          );

      await addProduct('Rice');
      expect(addProduct('Coffee'), throwsA(isA<Exception>()));
    });

    test('the same barcode is fine in a different store', () async {
      final storeA = await insertStore();
      final storeB = await db
          .into(db.storesTable)
          .insert(StoresTableCompanion.insert(name: 'Second Store'));

      Future<void> addProduct(int storeId) => db
          .into(db.productsTable)
          .insert(
            ProductsTableCompanion.insert(
              storeId: storeId,
              name: 'Rice',
              price: 10000,
              unit: 'kg',
              barcode: const Value('4801234567890'),
            ),
          );

      await addProduct(storeA);
      await addProduct(storeB); // must not throw
      expect(await db.select(db.productsTable).get(), hasLength(2));
    });

    test('unbarcoded products coexist — street vendors sell no barcodes', () async {
      final storeId = await insertStore();

      Future<void> addProduct(String name) => db
          .into(db.productsTable)
          .insert(
            ProductsTableCompanion.insert(
              storeId: storeId,
              name: name,
              price: 2500,
              unit: 'serving',
            ),
          );

      // A unique index permits many NULLs — both inserts must succeed.
      await addProduct('Fishball');
      await addProduct('Kwek Kwek');
      expect(await db.select(db.productsTable).get(), hasLength(2));
    });

    test('interest cannot be applied twice for one period (§22)', () async {
      final storeId = await insertStore();
      final customerId = await insertCustomer(storeId);

      Future<void> applyInterest() => db
          .into(db.interestRecordsTable)
          .insert(
            InterestRecordsTableCompanion.insert(
              storeId: storeId,
              customerId: customerId,
              rateBasisPoints: 200,
              baseAmount: 100000,
              interestAmount: 2000,
              periodKey: AppDateFormat.periodKey(DateTime(2026, 8)),
            ),
          );

      await applyInterest();

      // Opening the app again in August must not compound the charge.
      expect(applyInterest(), throwsA(isA<Exception>()));
      expect(await db.select(db.interestRecordsTable).get(), hasLength(1));
    });

    test('the next month is a separate period', () async {
      final storeId = await insertStore();
      final customerId = await insertCustomer(storeId);

      Future<void> applyInterest(DateTime month) => db
          .into(db.interestRecordsTable)
          .insert(
            InterestRecordsTableCompanion.insert(
              storeId: storeId,
              customerId: customerId,
              rateBasisPoints: 200,
              baseAmount: 100000,
              interestAmount: 2000,
              periodKey: AppDateFormat.periodKey(month),
            ),
          );

      await applyInterest(DateTime(2026, 8));
      await applyInterest(DateTime(2026, 9)); // must not throw
      expect(await db.select(db.interestRecordsTable).get(), hasLength(2));
    });

    test('a store may hold only one settings row', () async {
      final storeId = await insertStore();

      Future<void> addSettings() => db
          .into(db.storeSettingsTable)
          .insert(StoreSettingsTableCompanion.insert(storeId: storeId));

      await addSettings();
      expect(addSettings(), throwsA(isA<Exception>()));
    });

    test('deleting a product with history is blocked (§28)', () async {
      final storeId = await insertStore();
      final customerId = await insertCustomer(storeId);

      final productId = await db
          .into(db.productsTable)
          .insert(
            ProductsTableCompanion.insert(
              storeId: storeId,
              name: 'Rice',
              price: 10000,
              unit: 'kg',
            ),
          );

      final transactionId = await db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              storeId: storeId,
              customerId: customerId,
              totalAmount: 50000,
            ),
          );

      await db
          .into(db.transactionsItemTable)
          .insert(
            TransactionsItemTableCompanion.insert(
              transactionId: transactionId,
              productId: productId,
              quantity: 5,
              unitPrice: 10000,
              subTotal: 50000,
            ),
          );

      // The history must survive — deactivation is the supported path.
      expect(
        (db.delete(db.productsTable)
              ..where((t) => t.id.equals(productId)))
            .go(),
        throwsA(isA<Exception>()),
      );
    });

    test('deleting a customer with debt is blocked (§29)', () async {
      final storeId = await insertStore();
      final customerId = await insertCustomer(storeId);

      await db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              storeId: storeId,
              customerId: customerId,
              totalAmount: 50000,
            ),
          );

      expect(
        (db.delete(db.customersTable)
              ..where((t) => t.id.equals(customerId)))
            .go(),
        throwsA(isA<Exception>()),
      );
    });

    test('deleting a transaction removes its items, never the reverse', () async {
      final storeId = await insertStore();
      final customerId = await insertCustomer(storeId);
      final productId = await db
          .into(db.productsTable)
          .insert(
            ProductsTableCompanion.insert(
              storeId: storeId,
              name: 'Rice',
              price: 10000,
              unit: 'kg',
            ),
          );
      final transactionId = await db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              storeId: storeId,
              customerId: customerId,
              totalAmount: 50000,
            ),
          );
      await db
          .into(db.transactionsItemTable)
          .insert(
            TransactionsItemTableCompanion.insert(
              transactionId: transactionId,
              productId: productId,
              quantity: 5,
              unitPrice: 10000,
              subTotal: 50000,
            ),
          );

      await (db.delete(db.transactionsTable)
            ..where((t) => t.id.equals(transactionId)))
          .go();

      // Orphaned line items would be the §10 invalid state.
      expect(await db.select(db.transactionsItemTable).get(), isEmpty);
    });
  });

  /*
    The Phase 0 exit criterion: the slice that already existed still
    works end to end on the new schema.
  */
  group('store CRUD through the repository', () {
    late StoreRepository repository;

    setUp(() {
      repository = StoreRepositoryImplementation(
        StoreLocalDataSourceImplementation(db),
      );
    });

    test('creates and reads back', () async {
      final id = await repository.createStore(
        StorePayloadModel(
          name: 'Aling Nena Store',
          description: 'Corner sari-sari',
          category: StoreCategory.retail,
        ),
      );

      final store = await repository.fetchStoreById(id);
      expect(store, isNotNull);
      expect(store!.name, 'Aling Nena Store');
      expect(store.category, StoreCategory.retail);
      expect(store.createdAt, isA<DateTime>());

      // Created together with the store, in one transaction.
      expect(store.monthlyInterestEnabled, isFalse);
      expect(store.monthlyInterestRate, InterestRate.zero);
    });

    test('filters by category, and null means all', () async {
      await repository.createStore(
        StorePayloadModel(name: 'Nena Store', category: StoreCategory.retail),
      );
      await repository.createStore(
        StorePayloadModel(name: 'Fishball Cart', category: StoreCategory.street),
      );

      expect(await repository.fetchStores('retail'), hasLength(1));
      expect(await repository.fetchStores('street'), hasLength(1));
      expect(await repository.fetchStores(null), hasLength(2));
    });

    test('updates only the fields supplied', () async {
      final id = await repository.createStore(
        StorePayloadModel(
          name: 'Nena Store',
          description: 'Original description',
          category: StoreCategory.retail,
        ),
      );

      await repository.updateStore(
        UpdateStorePayloadModel(storeId: id, name: 'Nena Mini Mart'),
      );

      final store = await repository.fetchStoreById(id);
      expect(store!.name, 'Nena Mini Mart');
      // Absent fields must survive a partial update.
      expect(store.description, 'Original description');
      expect(store.category, StoreCategory.retail);
    });

    test('updating a missing store reports NOT_FOUND', () async {
      // requireRowChanged turns "0 rows affected" into a real failure,
      // rather than reporting success for a row that does not exist.
      await expectLater(
        repository.updateStore(
          UpdateStorePayloadModel(storeId: 999, name: 'Ghost Store'),
        ),
        throwsA(
          isA<AppFailure>().having((f) => f.code, 'code', 'NOT_FOUND'),
        ),
      );
    });

    test('deletes, and deleting twice reports NOT_FOUND', () async {
      final id = await repository.createStore(
        StorePayloadModel(name: 'Temporary Store'),
      );

      expect(await repository.deleteStore(id), 1);
      expect(await repository.fetchStoreById(id), isNull);

      await expectLater(
        repository.deleteStore(id),
        throwsA(
          isA<AppFailure>().having((f) => f.code, 'code', 'NOT_FOUND'),
        ),
      );
    });

    test('an over-long name surfaces as a failure, not a crash', () async {
      await expectLater(
        repository.createStore(
          StorePayloadModel(name: 'x' * 61), // max is 60
        ),
        throwsA(isA<AppFailure>()),
      );
    });
  });
}
