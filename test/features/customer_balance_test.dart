import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_balance_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';

void main() {
  /*
    ----------------------------------------------------------------
    The formula itself, with no database in the way.
    ----------------------------------------------------------------
  */
  group('CustomerBalance formula (§15)', () {
    test('outstanding = utang + interest − payments', () {
      const balance = CustomerBalance(
        totalUtang: Money.fromCentavos(100000), // ₱1,000.00
        totalInterest: Money.fromCentavos(2000), // ₱20.00
        totalPaid: Money.fromCentavos(30000), // ₱300.00
      );

      // The §15 worked example: ₱1,000 + ₱20 − ₱300 = ₱720
      expect(balance.outstanding, Money.fromPesos(720));
      expect(balance.totalCharged, Money.fromPesos(1020));
    });

    test('a new customer owes nothing', () {
      expect(CustomerBalance.zero.outstanding, Money.zero);
      expect(CustomerBalance.zero.isSettled, isTrue);
      expect(CustomerBalance.zero.hasDebt, isFalse);
      expect(CustomerBalance.zero.hasActivity, isFalse);
    });

    test('paying the exact balance settles it', () {
      const balance = CustomerBalance(
        totalUtang: Money.fromCentavos(54060),
        totalInterest: Money.zero,
        totalPaid: Money.fromCentavos(54060),
      );

      // Exact because Money is integer centavos.
      expect(balance.isSettled, isTrue);
      expect(balance.hasDebt, isFalse);
      // ...but the history is still there.
      expect(balance.hasActivity, isTrue);
    });
  });

  /*
    ----------------------------------------------------------------
    The rules that hang off the balance. These live on the entity so
    they cannot drift away from the number they guard.
    ----------------------------------------------------------------
  */
  group('payment rules (§23)', () {
    const balance = CustomerBalance(
      totalUtang: Money.fromCentavos(50000), // ₱500.00 owed
      totalInterest: Money.zero,
      totalPaid: Money.zero,
    );

    test('accepts a partial payment', () {
      expect(balance.canAcceptPayment(Money.fromPesos(100)), isTrue);
    });

    test('accepts payment of the exact balance', () {
      expect(balance.canAcceptPayment(Money.fromPesos(500)), isTrue);
    });

    test('rejects overpayment — V1 forbids a negative balance', () {
      expect(balance.canAcceptPayment(Money.fromPesos(700)), isFalse);
      // One centavo over is still over.
      expect(balance.canAcceptPayment(Money.fromCentavos(50001)), isFalse);
    });

    test('rejects zero and negative payments (§38)', () {
      expect(balance.canAcceptPayment(Money.zero), isFalse);
      expect(balance.canAcceptPayment(Money.fromPesos(-100)), isFalse);
    });

    test('a settled customer can accept nothing', () {
      expect(CustomerBalance.zero.canAcceptPayment(Money.fromPesos(1)), isFalse);
      expect(CustomerBalance.zero.maximumPayment, Money.zero);
    });

    test('maximumPayment is what the "pay full balance" shortcut fills', () {
      expect(balance.maximumPayment, Money.fromPesos(500));
    });
  });

  group('interest base (§20)', () {
    test('charges against the outstanding balance', () {
      const balance = CustomerBalance(
        totalUtang: Money.fromCentavos(100000), // ₱1,000.00
        totalInterest: Money.zero,
        totalPaid: Money.zero,
      );

      expect(balance.interestFor(200), Money.fromPesos(20)); // 2%
    });

    test('charges on what is left after payments, not the original debt', () {
      const balance = CustomerBalance(
        totalUtang: Money.fromCentavos(100000), // ₱1,000.00
        totalInterest: Money.zero,
        totalPaid: Money.fromCentavos(50000), // ₱500.00
      );

      // 2% of ₱500 outstanding, not of the ₱1,000 originally taken.
      expect(balance.interestFor(200), Money.fromPesos(10));
    });

    test('a settled account is not charged interest', () {
      // Otherwise a paid-off customer would start owing money again on
      // their own, which is the opposite of what §22 protects against.
      expect(CustomerBalance.zero.interestFor(500), Money.zero);
    });
  });

  /*
    ----------------------------------------------------------------
    The queries, against a real database.
    ----------------------------------------------------------------
  */
  group('balance queries', () {
    late AppDatabase db;
    late CustomerBalanceRepository repository;
    late int storeId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = CustomerBalanceRepositoryImplementation(
        CustomerBalanceLocalDataSourceImplementation(db),
      );
      storeId = await db
          .into(db.storesTable)
          .insert(StoresTableCompanion.insert(name: 'Aling Nena Store'));
    });

    tearDown(() async => db.close());

    Future<int> addCustomer(String name) => db
        .into(db.customersTable)
        .insert(CustomersTableCompanion.insert(storeId: storeId, name: name));

    Future<void> addTransaction(int customerId, Money amount) => db
        .into(db.transactionsTable)
        .insert(
          TransactionsTableCompanion.insert(
            storeId: storeId,
            customerId: customerId,
            totalAmount: amount.centavos,
          ),
        );

    Future<void> addPayment(int customerId, Money amount) => db
        .into(db.paymentsTable)
        .insert(
          PaymentsTableCompanion.insert(
            storeId: storeId,
            customerId: customerId,
            amount: amount.centavos,
          ),
        );

    Future<void> addInterest(
      int customerId,
      Money amount,
      String periodKey,
    ) => db
        .into(db.interestRecordsTable)
        .insert(
          InterestRecordsTableCompanion.insert(
            storeId: storeId,
            customerId: customerId,
            rateBasisPoints: 200,
            baseAmount: 0,
            interestAmount: amount.centavos,
            periodKey: periodKey,
          ),
        );

    test('a customer with no activity reads as zero, not null', () async {
      final customerId = await addCustomer('Juan');
      final balance = await repository.fetchBalanceForCustomer(customerId);

      // Without COALESCE this would be null and the row would render blank.
      expect(balance, CustomerBalance.zero);
      expect(balance.outstanding, Money.zero);
    });

    test('sums transactions, interest and payments', () async {
      final customerId = await addCustomer('Juan');

      await addTransaction(customerId, Money.fromPesos(500));
      await addTransaction(customerId, Money.fromPesos(300));
      await addTransaction(customerId, Money.fromPesos(200));
      await addPayment(customerId, Money.fromPesos(100));
      await addPayment(customerId, Money.fromPesos(200));
      await addInterest(customerId, Money.fromPesos(20), '2026-08');

      final balance = await repository.fetchBalanceForCustomer(customerId);

      expect(balance.totalUtang, Money.fromPesos(1000));
      expect(balance.totalPaid, Money.fromPesos(300));
      expect(balance.totalInterest, Money.fromPesos(20));
      // The §15 worked example.
      expect(balance.outstanding, Money.fromPesos(720));
    });

    /*
      ----------------------------------------------------------------
      THE FAN-OUT TEST.
      ----------------------------------------------------------------

      This is the one that catches the join bug described in the
      datasource. With a naive LEFT JOIN across the raw tables, a
      customer holding 2 transactions and 3 payments produces 6 rows,
      so the transactions are counted 3× and the payments 2×:

        wrong utang = ₱800 × 3 = ₱2,400
        wrong paid  = ₱300 × 2 = ₱600

      Nothing throws. The store owner is simply told the wrong number.
    */
    test('multiple transactions and payments do not multiply each other',
        () async {
      final customerId = await addCustomer('Juan');

      await addTransaction(customerId, Money.fromPesos(500));
      await addTransaction(customerId, Money.fromPesos(300));

      await addPayment(customerId, Money.fromPesos(100));
      await addPayment(customerId, Money.fromPesos(100));
      await addPayment(customerId, Money.fromPesos(100));

      final single = await repository.fetchBalanceForCustomer(customerId);
      expect(single.totalUtang, Money.fromPesos(800));
      expect(single.totalPaid, Money.fromPesos(300));
      expect(single.outstanding, Money.fromPesos(500));

      // The batch query is the one that actually joins — same answer.
      final batch = await repository.fetchBalancesForStore(storeId);
      expect(batch[customerId], single);
    });

    test('interest records do not multiply the other sums either', () async {
      final customerId = await addCustomer('Juan');

      await addTransaction(customerId, Money.fromPesos(500));
      await addTransaction(customerId, Money.fromPesos(500));
      await addInterest(customerId, Money.fromPesos(10), '2026-07');
      await addInterest(customerId, Money.fromPesos(10), '2026-08');

      final batch = await repository.fetchBalancesForStore(storeId);

      expect(batch[customerId]!.totalUtang, Money.fromPesos(1000));
      expect(batch[customerId]!.totalInterest, Money.fromPesos(20));
      expect(batch[customerId]!.outstanding, Money.fromPesos(1020));
    });

    test('the batch query keeps customers separate', () async {
      final juan = await addCustomer('Juan');
      final maria = await addCustomer('Maria');

      await addTransaction(juan, Money.fromPesos(500));
      await addTransaction(maria, Money.fromPesos(200));
      await addPayment(maria, Money.fromPesos(50));

      final balances = await repository.fetchBalancesForStore(storeId);

      expect(balances[juan]!.outstanding, Money.fromPesos(500));
      expect(balances[maria]!.outstanding, Money.fromPesos(150));
    });

    test('the batch query includes customers with no activity', () async {
      final juan = await addCustomer('Juan');
      final maria = await addCustomer('Maria');
      await addTransaction(juan, Money.fromPesos(500));

      final balances = await repository.fetchBalancesForStore(storeId);

      // Maria must be present as zero, not missing — otherwise the list
      // row has to guess what an absent key means.
      expect(balances.keys, containsAll([juan, maria]));
      expect(balances[maria], CustomerBalance.zero);
    });

    test('the batch query ignores other stores', () async {
      final otherStoreId = await db
          .into(db.storesTable)
          .insert(StoresTableCompanion.insert(name: 'Second Store'));
      final otherCustomer = await db
          .into(db.customersTable)
          .insert(
            CustomersTableCompanion.insert(
              storeId: otherStoreId,
              name: 'Pedro',
            ),
          );

      final juan = await addCustomer('Juan');
      await addTransaction(juan, Money.fromPesos(500));

      final balances = await repository.fetchBalancesForStore(storeId);
      expect(balances.keys, contains(juan));
      expect(balances.keys, isNot(contains(otherCustomer)));
    });

    test('store totals aggregate every customer', () async {
      final juan = await addCustomer('Juan');
      final maria = await addCustomer('Maria');

      await addTransaction(juan, Money.fromPesos(500));
      await addTransaction(maria, Money.fromPesos(300));
      await addPayment(juan, Money.fromPesos(100));

      final total = await repository.fetchTotalForStore(storeId);
      expect(total.totalUtang, Money.fromPesos(800));
      expect(total.totalPaid, Money.fromPesos(100));
      expect(total.outstanding, Money.fromPesos(700));
    });

    test('the all-stores total spans stores', () async {
      final otherStoreId = await db
          .into(db.storesTable)
          .insert(StoresTableCompanion.insert(name: 'Fishball Cart'));
      final pedro = await db
          .into(db.customersTable)
          .insert(
            CustomersTableCompanion.insert(
              storeId: otherStoreId,
              name: 'Pedro',
            ),
          );

      final juan = await addCustomer('Juan');
      await addTransaction(juan, Money.fromPesos(500));

      await db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              storeId: otherStoreId,
              customerId: pedro,
              totalAmount: Money.fromPesos(250).centavos,
            ),
          );

      final total = await repository.fetchTotalForAllStores();
      expect(total.outstanding, Money.fromPesos(750));
    });

    /*
      ----------------------------------------------------------------
      The §36 canonical scenario, this time through real SQL rather
      than arithmetic in Dart. If the queries and the formula ever
      disagree, this is where it shows.
      ----------------------------------------------------------------
    */
    test('§36: Juan ends the month owing ₱540.60', () async {
      final juan = await addCustomer('Juan');

      // Day 1 — 5 × Rice @ ₱100
      await addTransaction(juan, Money.fromPesos(100) * 5);
      expect(
        (await repository.fetchBalanceForCustomer(juan)).outstanding,
        Money.fromPesos(500),
      );

      // Day 2 — 2 × Coffee @ ₱20
      await addTransaction(juan, Money.fromPesos(20) * 2);
      expect(
        (await repository.fetchBalanceForCustomer(juan)).outstanding,
        Money.fromPesos(540),
      );

      // Day 3 — pays ₱100. The transactions must not change (§14).
      await addPayment(juan, Money.fromPesos(100));
      expect(
        (await repository.fetchBalanceForCustomer(juan)).outstanding,
        Money.fromPesos(440),
      );

      // Day 4 — 3 × Sardines @ ₱30
      await addTransaction(juan, Money.fromPesos(30) * 3);

      final beforeInterest = await repository.fetchBalanceForCustomer(juan);
      expect(beforeInterest.outstanding, Money.fromPesos(530));

      // End of month — 2% on the outstanding balance
      final interest = beforeInterest.interestFor(200);
      expect(interest, Money.fromPesos(10.60));

      await addInterest(
        juan,
        interest,
        AppDateFormat.periodKey(DateTime(2026, 8)),
      );

      final finalBalance = await repository.fetchBalanceForCustomer(juan);
      expect(finalBalance.outstanding, Money.fromPesos(540.60));
      expect(finalBalance.outstanding.format(), '₱540.60');

      // The originals are untouched — §14 and §16.
      expect(finalBalance.totalUtang, Money.fromPesos(630));
      expect(finalBalance.totalPaid, Money.fromPesos(100));
      expect(finalBalance.totalInterest, Money.fromPesos(10.60));
    });
  });
}
