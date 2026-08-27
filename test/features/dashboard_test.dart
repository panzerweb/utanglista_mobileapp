import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_balance_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_repository.dart';
import 'package:utanglista_mobileapp/features/dashboard/data/datasource/dashboard_local_data_source.dart';
import 'package:utanglista_mobileapp/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utanglista_mobileapp/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:utanglista_mobileapp/features/interest/data/datasource/interest_local_data_source.dart';
import 'package:utanglista_mobileapp/features/interest/domain/repositories/interest_repository.dart';
import 'package:utanglista_mobileapp/features/payments/data/datasource/payment_local_data_source.dart';
import 'package:utanglista_mobileapp/features/payments/data/model/payment_model.dart';
import 'package:utanglista_mobileapp/features/payments/domain/repositories/payment_repository.dart';
import 'package:utanglista_mobileapp/features/products/data/datasource/product_local_data_source.dart';
import 'package:utanglista_mobileapp/features/products/data/model/product_payload_model.dart';
import 'package:utanglista_mobileapp/features/products/domain/repositories/product_repository.dart';
import 'package:utanglista_mobileapp/features/stores/data/datasource/store_local_data_source.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';
import 'package:utanglista_mobileapp/features/stores/domain/repositories/store_repository.dart';
import 'package:utanglista_mobileapp/features/transactions/data/datasource/transaction_local_data_source.dart';
import 'package:utanglista_mobileapp/features/transactions/data/model/transaction_payload_model.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late StoreRepository stores;
  late CustomerRepository customers;
  late ProductRepository products;
  late TransactionRepository transactions;
  late PaymentRepository payments;
  late CustomerBalanceRepository balances;
  late DashboardRepository dashboard;

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
    payments = PaymentRepositoryImplementation(
      PaymentLocalDataSourceImplementation(db),
    );
    balances = CustomerBalanceRepositoryImplementation(
      CustomerBalanceLocalDataSourceImplementation(db),
    );
    dashboard = DashboardRepositoryImplementation(
      DashboardLocalDataSourceImplementation(db),
      balances,
      stores,
      InterestRepositoryImplementation(
        InterestLocalDataSourceImplementation(db),
      ),
    );
  });

  tearDown(() async => db.close());

  Future<int> addStore(
    String name, {
    bool interest = false,
    InterestRate rate = InterestRate.zero,
  }) {
    return stores.createStore(
      StorePayloadModel(
        name: name,
        monthlyInterestEnabled: interest,
        monthlyInterestRate: rate,
      ),
    );
  }

  Future<int> addCustomer(int storeId, String name) =>
      customers.createCustomer(
        CustomerPayloadModel(storeId: storeId, name: name),
      );

  Future<int> addProduct(int storeId) => products.createProduct(
    ProductPayloadModel(
      storeId: storeId,
      name: 'Rice',
      price: Money.fromPesos(100),
      unit: 'kg',
    ),
  );

  /// Records a debt, optionally backdated.
  Future<int> owe(
    int storeId,
    int customerId,
    Money amount, {
    DateTime? on,
  }) async {
    final productId = await addProduct(storeId);
    final id = await transactions.createTransaction(
      TransactionPayloadModel(
        storeId: storeId,
        customerId: customerId,
        items: [
          TransactionItemPayloadModel(
            productId: productId,
            quantity: 1,
            unitPrice: amount,
          ),
        ],
      ),
    );

    if (on != null) {
      await db.customStatement(
        'UPDATE transactions_table SET created_at = ? WHERE id = ?',
        [on.millisecondsSinceEpoch ~/ 1000, id],
      );
    }

    return id;
  }

  // ======================================================================
  group('an empty app', () {
    test('reports zero rather than failing', () async {
      final summary = await dashboard.fetchSummary();

      expect(summary.hasStores, isFalse);
      expect(summary.totalReceivable, Money.zero);
      expect(summary.topDebtors, isEmpty);
      expect(summary.recentActivity, isEmpty);
    });

    test('a store with no customers reports zero', () async {
      await addStore('Aling Nena Store');

      final summary = await dashboard.fetchSummary();

      expect(summary.stores, hasLength(1));
      expect(summary.stores.single.customerCount, 0);
      expect(summary.stores.single.debtorCount, 0);
      expect(summary.totalReceivable, Money.zero);
    });
  });

  // ======================================================================
  group('totals', () {
    test('the headline equals the sum of the stores', () async {
      final storeA = await addStore('Store A');
      final storeB = await addStore('Store B');
      final juan = await addCustomer(storeA, 'Juan');
      final pedro = await addCustomer(storeB, 'Pedro');

      await owe(storeA, juan, Money.fromPesos(500));
      await owe(storeB, pedro, Money.fromPesos(300));

      final summary = await dashboard.fetchSummary();

      expect(summary.totalReceivable, Money.fromPesos(800));

      // Two independent paths to the same number — if these ever
      // disagree, the dashboard has grown its own arithmetic.
      final perStore = summary.stores
          .map((store) => store.balance.outstanding)
          .sum();
      expect(perStore, summary.totalReceivable);
    });

    test('agrees with CustomerBalanceRepository', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');
      await owe(storeId, juan, Money.fromPesos(500));
      await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juan,
          amount: Money.fromPesos(200),
        ),
      );

      final summary = await dashboard.fetchSummary();
      final direct = await balances.fetchTotalForAllStores();

      expect(summary.totalReceivable, direct.outstanding);
      expect(summary.totalReceivable, Money.fromPesos(300));
    });

    test('payments reduce the headline (§15)', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');
      await owe(storeId, juan, Money.fromPesos(500));

      expect(
        (await dashboard.fetchSummary()).totalReceivable,
        Money.fromPesos(500),
      );

      await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juan,
          amount: Money.fromPesos(500),
        ),
      );

      expect(
        (await dashboard.fetchSummary()).totalReceivable,
        Money.zero,
      );
    });

    test('counts debtors, not just customers', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');
      await addCustomer(storeId, 'Maria');
      await addCustomer(storeId, 'Pedro');
      await owe(storeId, juan, Money.fromPesos(500));

      final summary = await dashboard.fetchSummary();

      expect(summary.totalCustomers, 3);
      expect(summary.totalDebtors, 1);
      expect(summary.stores.single.debtorCount, 1);
    });

    test('a settled customer stops counting as a debtor', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');
      await owe(storeId, juan, Money.fromPesos(500));
      await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juan,
          amount: Money.fromPesos(500),
        ),
      );

      expect((await dashboard.fetchSummary()).totalDebtors, 0);
    });

    /*
      The fan-out trap, one more time. A customer with several
      transactions AND several payments must not have them multiplied
      by a naive join.
    */
    test('several transactions and payments do not multiply', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');

      await owe(storeId, juan, Money.fromPesos(500));
      await owe(storeId, juan, Money.fromPesos(300));

      for (var i = 0; i < 3; i++) {
        await payments.recordPayment(
          PaymentPayloadModel(
            storeId: storeId,
            customerId: juan,
            amount: Money.fromPesos(100),
          ),
        );
      }

      final summary = await dashboard.fetchSummary();

      expect(summary.totalReceivable, Money.fromPesos(500));
      expect(summary.stores.single.balance.totalUtang, Money.fromPesos(800));
      expect(summary.stores.single.balance.totalPaid, Money.fromPesos(300));
      expect(summary.topDebtors.single.balance.outstanding, Money.fromPesos(500));
    });
  });

  // ======================================================================
  group('top debtors', () {
    test('ranks by outstanding, highest first', () async {
      final storeId = await addStore('Aling Nena Store');
      final small = await addCustomer(storeId, 'Small');
      final big = await addCustomer(storeId, 'Big');
      final middle = await addCustomer(storeId, 'Middle');

      await owe(storeId, small, Money.fromPesos(100));
      await owe(storeId, big, Money.fromPesos(900));
      await owe(storeId, middle, Money.fromPesos(500));

      final debtors = (await dashboard.fetchSummary()).topDebtors;

      expect(debtors.map((d) => d.customerName), ['Big', 'Middle', 'Small']);
    });

    test('excludes anyone who owes nothing', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');
      await addCustomer(storeId, 'Settled');
      await owe(storeId, juan, Money.fromPesos(500));

      final debtors = (await dashboard.fetchSummary()).topDebtors;

      expect(debtors, hasLength(1));
      expect(debtors.single.customerName, 'Juan');
    });

    test('spans stores and names which one', () async {
      final storeA = await addStore('Store A');
      final storeB = await addStore('Store B');
      final juan = await addCustomer(storeA, 'Juan');
      final pedro = await addCustomer(storeB, 'Pedro');

      await owe(storeA, juan, Money.fromPesos(300));
      await owe(storeB, pedro, Money.fromPesos(900));

      final debtors = (await dashboard.fetchSummary()).topDebtors;

      expect(debtors.first.customerName, 'Pedro');
      expect(debtors.first.storeName, 'Store B');
      expect(debtors.last.storeName, 'Store A');
    });

    test('ranks on the balance AFTER payments', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');
      final maria = await addCustomer(storeId, 'Maria');

      // Juan takes more but pays most of it back.
      await owe(storeId, juan, Money.fromPesos(1000));
      await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juan,
          amount: Money.fromPesos(900),
        ),
      );
      await owe(storeId, maria, Money.fromPesos(500));

      final debtors = (await dashboard.fetchSummary()).topDebtors;

      expect(debtors.first.customerName, 'Maria');
    });
  });

  // ======================================================================
  group('recent activity', () {
    test('shows utang and payments, newest first', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');

      await owe(storeId, juan, Money.fromPesos(500), on: DateTime(2026, 8, 1));
      final paymentId = await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juan,
          amount: Money.fromPesos(200),
        ),
      );
      await db.customStatement(
        'UPDATE payments_table SET created_at = ? WHERE id = ?',
        [DateTime(2026, 8, 5).millisecondsSinceEpoch ~/ 1000, paymentId],
      );

      final activity = (await dashboard.fetchSummary()).recentActivity;

      expect(activity, hasLength(2));
      expect(activity.first.kind, ActivityKind.payment);
      expect(activity.first.isCredit, isTrue);
      expect(activity.last.kind, ActivityKind.utang);
      expect(activity.last.isCredit, isFalse);
    });

    test('carries the customer and store name', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');
      await owe(storeId, juan, Money.fromPesos(500));

      final activity = (await dashboard.fetchSummary()).recentActivity.single;

      expect(activity.customerName, 'Juan');
      expect(activity.storeName, 'Aling Nena Store');
      expect(activity.amount, Money.fromPesos(500));
    });

    test('spans stores', () async {
      final storeA = await addStore('Store A');
      final storeB = await addStore('Store B');
      final juan = await addCustomer(storeA, 'Juan');
      final pedro = await addCustomer(storeB, 'Pedro');

      await owe(storeA, juan, Money.fromPesos(500));
      await owe(storeB, pedro, Money.fromPesos(300));

      expect(
        (await dashboard.fetchSummary()).recentActivity,
        hasLength(2),
      );
    });
  });

  // ======================================================================
  group('interest nudge', () {
    test('is off for a store without interest', () async {
      final storeId = await addStore('Aling Nena Store');
      final juan = await addCustomer(storeId, 'Juan');
      await owe(
        storeId,
        juan,
        Money.fromPesos(1000),
        on: DateTime(2026, 6, 15),
      );

      final summary = await dashboard.fetchSummary();

      expect(summary.stores.single.interestDue, isFalse);
      expect(summary.storesNeedingInterest, isEmpty);
    });

    test('is off when interest is enabled at 0% (§19)', () async {
      // Enabled at zero charges nothing, so nudging would promise a
      // feature that produces no records.
      final storeId = await addStore(
        'Aling Nena Store',
        interest: true,
        rate: InterestRate.zero,
      );
      final juan = await addCustomer(storeId, 'Juan');
      await owe(
        storeId,
        juan,
        Money.fromPesos(1000),
        on: DateTime(2026, 6, 15),
      );

      expect(
        (await dashboard.fetchSummary()).stores.single.interestDue,
        isFalse,
      );
    });

    test('is on when there is something chargeable this month', () async {
      final storeId = await addStore(
        'Aling Nena Store',
        interest: true,
        rate: const InterestRate.fromBasisPoints(200),
      );
      final juan = await addCustomer(storeId, 'Juan');

      // Backdated so it is carried INTO the current month — the
      // Phase 6 rule.
      final lastMonth = DateTime.now().subtract(const Duration(days: 45));
      await owe(storeId, juan, Money.fromPesos(1000), on: lastMonth);

      final summary = await dashboard.fetchSummary();

      expect(summary.stores.single.interestDue, isTrue);
      expect(summary.storesNeedingInterest, hasLength(1));
    });

    test('turns off once this month has been charged (§22)', () async {
      final storeId = await addStore(
        'Aling Nena Store',
        interest: true,
        rate: const InterestRate.fromBasisPoints(200),
      );
      final juan = await addCustomer(storeId, 'Juan');
      final lastMonth = DateTime.now().subtract(const Duration(days: 45));
      await owe(storeId, juan, Money.fromPesos(1000), on: lastMonth);

      final interest = InterestRepositoryImplementation(
        InterestLocalDataSourceImplementation(db),
      );
      await interest.applyInterest(
        storeId: storeId,
        periodKey: AppDateFormat.periodKey(DateTime.now()),
        rate: const InterestRate.fromBasisPoints(200),
      );

      expect(
        (await dashboard.fetchSummary()).stores.single.interestDue,
        isFalse,
      );
    });

    test('is off when nobody carried a balance into this month', () async {
      // A debt taken THIS month is not chargeable until next month, so
      // the nudge must not appear — tapping through would show
      // "nothing to charge".
      final storeId = await addStore(
        'Aling Nena Store',
        interest: true,
        rate: const InterestRate.fromBasisPoints(200),
      );
      final juan = await addCustomer(storeId, 'Juan');
      await owe(storeId, juan, Money.fromPesos(1000));

      expect(
        (await dashboard.fetchSummary()).stores.single.interestDue,
        isFalse,
      );
    });
  });

  // ======================================================================
  test('interest raises the headline receivable', () async {
    final storeId = await addStore(
      'Aling Nena Store',
      interest: true,
      rate: const InterestRate.fromBasisPoints(200),
    );
    final juan = await addCustomer(storeId, 'Juan');
    final lastMonth = DateTime.now().subtract(const Duration(days: 45));
    await owe(storeId, juan, Money.fromPesos(1000), on: lastMonth);

    final interest = InterestRepositoryImplementation(
      InterestLocalDataSourceImplementation(db),
    );
    await interest.applyInterest(
      storeId: storeId,
      periodKey: AppDateFormat.periodKey(DateTime.now()),
      rate: const InterestRate.fromBasisPoints(200),
    );

    final summary = await dashboard.fetchSummary();

    expect(summary.totalReceivable, Money.fromPesos(1020));
    expect(summary.overall.totalInterest, Money.fromPesos(20));
  });
}
