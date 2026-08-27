import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_balance_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_repository.dart';
import 'package:utanglista_mobileapp/features/products/data/datasource/product_local_data_source.dart';
import 'package:utanglista_mobileapp/features/products/data/model/product_payload_model.dart';
import 'package:utanglista_mobileapp/features/products/domain/repositories/product_repository.dart';
import 'package:utanglista_mobileapp/features/stores/data/datasource/store_local_data_source.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';
import 'package:utanglista_mobileapp/features/stores/domain/repositories/store_repository.dart';
import 'package:utanglista_mobileapp/features/transactions/data/datasource/transaction_local_data_source.dart';
import 'package:utanglista_mobileapp/features/transactions/data/model/transaction_payload_model.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_draft.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late StoreRepository stores;
  late CustomerRepository customers;
  late ProductRepository products;
  late TransactionRepository transactions;
  late CustomerBalanceRepository balances;

  late int storeId;
  late int juanId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    stores = StoreRepositoryImplementation(
      StoreLocalDataSourceImplementation(db),
    );
    customers = CustomerRepositoryImplementation(
      CustomerLocalDataSourceImplementation(db),
    );
    products = ProductRepositoryImplementation(
      ProductLocalDataSourceImplementation(db),
    );
    transactions = TransactionRepositoryImplementation(
      TransactionLocalDataSourceImplementation(db),
    );
    balances = CustomerBalanceRepositoryImplementation(
      CustomerBalanceLocalDataSourceImplementation(db),
    );

    storeId = await stores.createStore(
      StorePayloadModel(name: 'Aling Nena Store'),
    );
    juanId = await customers.createCustomer(
      CustomerPayloadModel(storeId: storeId, name: 'Juan'),
    );
  });

  tearDown(() async => db.close());

  Future<int> addProduct(String name, Money price, {String unit = 'pc'}) {
    return products.createProduct(
      ProductPayloadModel(
        storeId: storeId,
        name: name,
        price: price,
        unit: unit,
      ),
    );
  }

  TransactionPayloadModel payload(
    List<TransactionItemPayloadModel> items, {
    int? customerId,
    String? note,
  }) {
    return TransactionPayloadModel(
      storeId: storeId,
      customerId: customerId ?? juanId,
      items: items,
      note: note,
    );
  }

  TransactionItemPayloadModel line(
    int productId,
    double quantity,
    Money unitPrice,
  ) {
    return TransactionItemPayloadModel(
      productId: productId,
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  // ======================================================================
  group('recording an utang', () {
    test('writes the transaction and its items', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100), unit: 'kg');

      final id = await transactions.createTransaction(
        payload([line(rice, 5, Money.fromPesos(100))]),
      );

      final transaction = await transactions.fetchTransactionById(id);
      expect(transaction!.totalAmount, Money.fromPesos(500));
      expect(transaction.items, hasLength(1));
      expect(transaction.items.single.quantity, 5);
      expect(transaction.items.single.subTotal, Money.fromPesos(500));
      expect(transaction.customerName, 'Juan');
    });

    test('the total is the sum of the item subtotals (§8)', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));
      final coffee = await addProduct('Coffee', Money.fromPesos(20));
      final sardines = await addProduct('Sardines', Money.fromPesos(30));

      // The §8 worked example: ₱500 + ₱40 + ₱90 = ₱630.
      final id = await transactions.createTransaction(
        payload([
          line(rice, 5, Money.fromPesos(100)),
          line(coffee, 2, Money.fromPesos(20)),
          line(sardines, 3, Money.fromPesos(30)),
        ]),
      );

      final transaction = await transactions.fetchTransactionById(id);
      expect(transaction!.totalAmount, Money.fromPesos(630));
      expect(transaction.totalMatchesItems, isTrue);
    });

    test('fractional quantities round once, at the line', () async {
      final rice = await addProduct('Rice', Money.fromPesos(99.99), unit: 'kg');

      // 1.5 × ₱99.99 = ₱149.985 -> ₱149.99
      final id = await transactions.createTransaction(
        payload([line(rice, 1.5, Money.fromPesos(99.99))]),
      );

      final transaction = await transactions.fetchTransactionById(id);
      expect(transaction!.totalAmount, Money.fromCentavos(14999));
    });

    test('a note is stored, and blank becomes none', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));

      final withNote = await transactions.createTransaction(
        payload([line(rice, 1, Money.fromPesos(100))], note: 'Pays Saturday'),
      );
      final withoutNote = await transactions.createTransaction(
        payload([line(rice, 1, Money.fromPesos(100))], note: '   '),
      );

      expect(
        (await transactions.fetchTransactionById(withNote))!.note,
        'Pays Saturday',
      );
      expect(
        (await transactions.fetchTransactionById(withoutNote))!.hasNote,
        isFalse,
      );
    });
  });

  // ======================================================================
  /*
    §10 and §33: a transaction must never exist without its items, and
    a failure must leave nothing behind at all.
  */
  group('atomicity (§10, §33)', () {
    test('a nonexistent product rolls the whole thing back', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));

      await expectLater(
        transactions.createTransaction(
          payload([
            line(rice, 5, Money.fromPesos(100)),
            // This product does not exist.
            line(9999, 2, Money.fromPesos(20)),
          ]),
        ),
        throwsA(isA<AppFailure>()),
      );

      // The §10 invalid state — a transaction with no items — must not
      // exist, and neither must a partial one.
      expect(await db.select(db.transactionsTable).get(), isEmpty);
      expect(await db.select(db.transactionsItemTable).get(), isEmpty);
    });

    test("a product from another store rolls it back too", () async {
      final otherStoreId = await stores.createStore(
        StorePayloadModel(name: 'Other Store'),
      );
      final theirRice = await products.createProduct(
        ProductPayloadModel(
          storeId: otherStoreId,
          name: 'Rice',
          price: Money.fromPesos(100),
          unit: 'kg',
        ),
      );

      await expectLater(
        transactions.createTransaction(
          payload([line(theirRice, 1, Money.fromPesos(100))]),
        ),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.code,
            'code',
            'PRODUCT_NOT_FOUND',
          ),
        ),
      );

      expect(await db.select(db.transactionsTable).get(), isEmpty);
    });

    test('a customer from another store is refused', () async {
      final otherStoreId = await stores.createStore(
        StorePayloadModel(name: 'Other Store'),
      );
      final theirCustomer = await customers.createCustomer(
        CustomerPayloadModel(storeId: otherStoreId, name: 'Pedro'),
      );
      final rice = await addProduct('Rice', Money.fromPesos(100));

      await expectLater(
        transactions.createTransaction(
          payload(
            [line(rice, 1, Money.fromPesos(100))],
            customerId: theirCustomer,
          ),
        ),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.code,
            'code',
            'CUSTOMER_NOT_FOUND',
          ),
        ),
      );

      expect(await db.select(db.transactionsTable).get(), isEmpty);
    });

    test('a deactivated customer cannot take new utang (§29)', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));
      await customers.setActive(juanId, isActive: false);

      await expectLater(
        transactions.createTransaction(
          payload([line(rice, 1, Money.fromPesos(100))]),
        ),
        throwsA(
          isA<AppFailure>().having((f) => f.code, 'code', 'CUSTOMER_INACTIVE'),
        ),
      );

      expect(await db.select(db.transactionsTable).get(), isEmpty);
    });

    test('a successful write leaves no orphan items', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));
      final coffee = await addProduct('Coffee', Money.fromPesos(20));

      final id = await transactions.createTransaction(
        payload([
          line(rice, 5, Money.fromPesos(100)),
          line(coffee, 2, Money.fromPesos(20)),
        ]),
      );

      final items = await db.select(db.transactionsItemTable).get();
      expect(items, hasLength(2));
      expect(items.every((item) => item.transactionId == id), isTrue);
    });
  });

  // ======================================================================
  /*
    §7 — the rule the whole snapshot design exists for. This is the
    most important group in the file.
  */
  group('price snapshots (§7, §27)', () {
    test('repricing a product does not move a past line', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100), unit: 'kg');

      final id = await transactions.createTransaction(
        payload([line(rice, 5, Money.fromPesos(100))]),
      );

      // Rice goes up to ₱110.
      await products.updateProduct(
        UpdateProductPayloadModel(
          productId: rice,
          price: Money.fromPesos(110),
        ),
      );

      final transaction = await transactions.fetchTransactionById(id);

      // §7 verbatim: it must remain 5 × ₱100 = ₱500, and must NOT
      // become 5 × ₱110 = ₱550.
      expect(transaction!.items.single.unitPrice, Money.fromPesos(100));
      expect(transaction.items.single.subTotal, Money.fromPesos(500));
      expect(transaction.totalAmount, Money.fromPesos(500));

      // The product's current price did change.
      expect(
        (await products.fetchProductById(rice))!.price,
        Money.fromPesos(110),
      );
    });

    test('renaming a product updates the display, not the amounts (§27)',
        () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));
      final id = await transactions.createTransaction(
        payload([line(rice, 5, Money.fromPesos(100))]),
      );

      await products.updateProduct(
        UpdateProductPayloadModel(
          productId: rice,
          name: 'Rice (Sinandomeng)',
        ),
      );

      final transaction = await transactions.fetchTransactionById(id);
      // Name is joined live — §27 permits that.
      expect(transaction!.items.single.productName, 'Rice (Sinandomeng)');
      // Amounts are snapshotted — §27 requires that.
      expect(transaction.items.single.subTotal, Money.fromPesos(500));
    });

    test('deactivating a product keeps its past lines readable (§28)',
        () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));
      final id = await transactions.createTransaction(
        payload([line(rice, 5, Money.fromPesos(100))]),
      );

      await products.setActive(rice, isActive: false);

      final transaction = await transactions.fetchTransactionById(id);
      expect(transaction!.items, hasLength(1));
      expect(transaction.items.single.productName, 'Rice');
    });

    test('the draft snapshots the price when the line is added', () {
      // The snapshot happens in the domain, before anything is written.
      const draftLine = TransactionDraftLine(
        productId: 1,
        productName: 'Rice',
        unit: 'kg',
        unitPrice: Money.fromCentavos(10000),
        quantity: 5,
      );

      expect(draftLine.subTotal, Money.fromPesos(500));
      expect(draftLine.isValid, isTrue);
    });
  });

  // ======================================================================
  group('validation (§24, §25, §38)', () {
    test('a transaction with no items is refused', () async {
      await expectLater(
        transactions.createTransaction(payload([])),
        throwsA(
          isA<AppFailure>().having((f) => f.code, 'code', 'EMPTY_TRANSACTION'),
        ),
      );
    });

    test('a zero quantity is refused', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));

      await expectLater(
        transactions.createTransaction(
          payload([line(rice, 0, Money.fromPesos(100))]),
        ),
        throwsA(
          isA<AppFailure>().having((f) => f.code, 'code', 'INVALID_QUANTITY'),
        ),
      );
    });

    test('a negative quantity is refused', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));

      await expectLater(
        transactions.createTransaction(
          payload([line(rice, -1, Money.fromPesos(100))]),
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('a negative unit price is refused (§25)', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));

      await expectLater(
        transactions.createTransaction(
          payload([line(rice, 1, Money.fromPesos(-50))]),
        ),
        throwsA(
          isA<AppFailure>().having((f) => f.code, 'code', 'NEGATIVE_AMOUNT'),
        ),
      );
    });

    test('a zero total is refused (§24)', () async {
      final freebie = await addProduct('Free sample', Money.zero);

      await expectLater(
        transactions.createTransaction(
          payload([line(freebie, 1, Money.zero)]),
        ),
        throwsA(
          isA<AppFailure>().having((f) => f.code, 'code', 'ZERO_TOTAL'),
        ),
      );
    });
  });

  // ======================================================================
  group('TransactionDraft rules', () {
    test('an empty draft cannot be submitted', () {
      const draft = TransactionDraft();

      expect(draft.canSubmit, isFalse);
      expect(draft.problems, contains('Choose a customer.'));
      expect(draft.problems, contains('Add at least one item.'));
    });

    test('adding the same product twice is one line, not two', () async {
      // Modelled here as the cubit does it: bump the quantity.
      const first = TransactionDraftLine(
        productId: 1,
        productName: 'Rice',
        unit: 'kg',
        unitPrice: Money.fromCentavos(10000),
        quantity: 1,
      );

      const draft = TransactionDraft(lines: [first]);
      expect(draft.indexOfProduct(1), 0);
      expect(draft.containsProduct(1), isTrue);
      expect(draft.containsProduct(2), isFalse);
    });

    test('the running total sums every line (§8)', () {
      const draft = TransactionDraft(
        lines: [
          TransactionDraftLine(
            productId: 1,
            productName: 'Rice',
            unit: 'kg',
            unitPrice: Money.fromCentavos(10000),
            quantity: 5,
          ),
          TransactionDraftLine(
            productId: 2,
            productName: 'Coffee',
            unit: 'pc',
            unitPrice: Money.fromCentavos(2000),
            quantity: 2,
          ),
        ],
      );

      expect(draft.total, Money.fromPesos(540));
    });
  });

  // ======================================================================
  group('history', () {
    test('lists newest first, even within the same second', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));

      // No delay: drift stores DateTime as unix SECONDS, so only the
      // id tiebreaker keeps this order stable.
      final first = await transactions.createTransaction(
        payload([line(rice, 1, Money.fromPesos(100))]),
      );
      final second = await transactions.createTransaction(
        payload([line(rice, 2, Money.fromPesos(100))]),
      );
      final third = await transactions.createTransaction(
        payload([line(rice, 3, Money.fromPesos(100))]),
      );

      final history = await transactions.fetchTransactions(storeId);
      expect(history.map((t) => t.id), [third, second, first]);
    });

    test('can be narrowed to one customer', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));
      final maria = await customers.createCustomer(
        CustomerPayloadModel(storeId: storeId, name: 'Maria'),
      );

      await transactions.createTransaction(
        payload([line(rice, 1, Money.fromPesos(100))]),
      );
      await transactions.createTransaction(
        payload([line(rice, 2, Money.fromPesos(100))], customerId: maria),
      );

      expect(
        await transactions.fetchTransactions(storeId, customerId: juanId),
        hasLength(1),
      );
      expect(
        await transactions.fetchTransactions(storeId, customerId: maria),
        hasLength(1),
      );
      expect(await transactions.fetchTransactions(storeId), hasLength(2));
    });

    test('list rows do not carry their items', () async {
      // A year of trading must not pull every line to render totals.
      final rice = await addProduct('Rice', Money.fromPesos(100));
      await transactions.createTransaction(
        payload([line(rice, 1, Money.fromPesos(100))]),
      );

      final history = await transactions.fetchTransactions(storeId);
      expect(history.single.items, isEmpty);
    });
  });

  // ======================================================================
  /*
    Transactions feeding the balance — the join between Phase 4 and the
    ledger model. Payments arrive in Phase 5.
  */
  group('effect on the customer balance (§15)', () {
    test('a transaction increases what the customer owes', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));

      expect(
        (await balances.fetchBalanceForCustomer(juanId)).outstanding,
        Money.zero,
      );

      await transactions.createTransaction(
        payload([line(rice, 5, Money.fromPesos(100))]),
      );

      final balance = await balances.fetchBalanceForCustomer(juanId);
      expect(balance.totalUtang, Money.fromPesos(500));
      expect(balance.outstanding, Money.fromPesos(500));
      expect(balance.hasDebt, isTrue);
    });

    test('§36 days 1, 2 and 4, through the real write path', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100), unit: 'kg');
      final coffee = await addProduct('Coffee', Money.fromPesos(20));
      final sardines = await addProduct('Sardines', Money.fromPesos(30));

      // Day 1 — 5 × Rice @ ₱100
      await transactions.createTransaction(
        payload([line(rice, 5, Money.fromPesos(100))]),
      );
      expect(
        (await balances.fetchBalanceForCustomer(juanId)).outstanding,
        Money.fromPesos(500),
      );

      // Day 2 — 2 × Coffee @ ₱20
      await transactions.createTransaction(
        payload([line(coffee, 2, Money.fromPesos(20))]),
      );
      expect(
        (await balances.fetchBalanceForCustomer(juanId)).outstanding,
        Money.fromPesos(540),
      );

      // Day 4 — 3 × Sardines @ ₱30  (day 3's payment lands in Phase 5)
      await transactions.createTransaction(
        payload([line(sardines, 3, Money.fromPesos(30))]),
      );

      final balance = await balances.fetchBalanceForCustomer(juanId);
      expect(balance.totalUtang, Money.fromPesos(630));

      // The store's receivable agrees with the customer's.
      final storeTotal = await balances.fetchTotalForStore(storeId);
      expect(storeTotal.outstanding, Money.fromPesos(630));
    });

    test('a customer with utang can no longer be deleted (§29)', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));
      await transactions.createTransaction(
        payload([line(rice, 1, Money.fromPesos(100))]),
      );

      await expectLater(
        customers.deleteCustomer(juanId),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.code,
            'code',
            'HAS_FINANCIAL_HISTORY',
          ),
        ),
      );
    });

    test('a sold product can no longer be deleted (§28)', () async {
      final rice = await addProduct('Rice', Money.fromPesos(100));
      await transactions.createTransaction(
        payload([line(rice, 1, Money.fromPesos(100))]),
      );

      await expectLater(
        products.deleteProduct(rice),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.code,
            'code',
            'HAS_TRANSACTION_HISTORY',
          ),
        ),
      );
    });
  });
}
