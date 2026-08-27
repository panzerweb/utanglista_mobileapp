import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_balance_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_repository.dart';
import 'package:utanglista_mobileapp/features/ledger/data/datasource/ledger_local_data_source.dart';
import 'package:utanglista_mobileapp/features/ledger/domain/entities/ledger_entry.dart';
import 'package:utanglista_mobileapp/features/ledger/domain/repositories/ledger_repository.dart';
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
  late LedgerRepository ledger;

  late int storeId;
  late int juanId;
  late int riceId;

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
    ledger = LedgerRepositoryImplementation(
      LedgerLocalDataSourceImplementation(db),
    );

    storeId = await stores.createStore(
      StorePayloadModel(name: 'Aling Nena Store'),
    );
    juanId = await customers.createCustomer(
      CustomerPayloadModel(storeId: storeId, name: 'Juan'),
    );
    riceId = await products.createProduct(
      ProductPayloadModel(
        storeId: storeId,
        name: 'Rice',
        price: Money.fromPesos(100),
        unit: 'kg',
      ),
    );
  });

  tearDown(() async => db.close());

  /// Records an utang of [amount] by selling 1 unit at that price.
  Future<int> addUtang(Money amount, {int? customerId}) {
    return transactions.createTransaction(
      TransactionPayloadModel(
        storeId: storeId,
        customerId: customerId ?? juanId,
        items: [
          TransactionItemPayloadModel(
            productId: riceId,
            quantity: 1,
            unitPrice: amount,
          ),
        ],
      ),
    );
  }

  Future<int> pay(Money amount, {String? note, int? customerId}) {
    return payments.recordPayment(
      PaymentPayloadModel(
        storeId: storeId,
        customerId: customerId ?? juanId,
        amount: amount,
        note: note,
      ),
    );
  }

  Future<void> addInterest(Money amount, String periodKey) {
    return db
        .into(db.interestRecordsTable)
        .insert(
          InterestRecordsTableCompanion.insert(
            storeId: storeId,
            customerId: juanId,
            rateBasisPoints: 200,
            baseAmount: 0,
            interestAmount: amount.centavos,
            periodKey: periodKey,
          ),
        );
  }

  Future<Money> outstanding() async =>
      (await balances.fetchBalanceForCustomer(juanId)).outstanding;

  // ======================================================================
  group('recording a payment', () {
    test('reduces the balance without touching the transaction (§14)',
        () async {
      final transactionId = await addUtang(Money.fromPesos(500));

      await pay(Money.fromPesos(100));

      expect(await outstanding(), Money.fromPesos(400));

      // §14 verbatim: the transaction must NOT become ₱400, and must
      // not gain a remaining_amount.
      final transaction = await transactions.fetchTransactionById(
        transactionId,
      );
      expect(transaction!.totalAmount, Money.fromPesos(500));
      expect(transaction.items.single.subTotal, Money.fromPesos(500));
    });

    test('partial payments accumulate (§12)', () async {
      await addUtang(Money.fromPesos(500));

      await pay(Money.fromPesos(100));
      await pay(Money.fromPesos(150));

      expect(await outstanding(), Money.fromPesos(250));
    });

    test('one payment covers several transactions (§13)', () async {
      // §13's worked example: ₱500 + ₱300 + ₱200, pay ₱700, owe ₱300.
      await addUtang(Money.fromPesos(500));
      await addUtang(Money.fromPesos(300));
      await addUtang(Money.fromPesos(200));

      await pay(Money.fromPesos(700));

      expect(await outstanding(), Money.fromPesos(300));

      // Nothing was allocated to any particular transaction — all
      // three still carry their original totals.
      final history = await transactions.fetchTransactions(storeId);
      expect(
        history.map((t) => t.totalAmount).toList(),
        containsAll([
          Money.fromPesos(500),
          Money.fromPesos(300),
          Money.fromPesos(200),
        ]),
      );
    });

    test('paying the exact balance settles it to exactly zero', () async {
      await addUtang(Money.fromPesos(540.60));

      await pay(Money.fromPesos(540.60));

      final balance = await balances.fetchBalanceForCustomer(juanId);
      // Exact because Money is integer centavos.
      expect(balance.outstanding, Money.zero);
      expect(balance.isSettled, isTrue);
    });

    test('a note is kept, blank becomes none', () async {
      await addUtang(Money.fromPesos(500));

      final withNote = await pay(Money.fromPesos(100), note: 'Partial');
      final withoutNote = await pay(Money.fromPesos(100), note: '  ');

      expect((await payments.fetchPaymentById(withNote))!.note, 'Partial');
      expect(
        (await payments.fetchPaymentById(withoutNote))!.hasNote,
        isFalse,
      );
    });

    test('a deactivated customer may still settle their debt', () async {
      // §29 stops NEW utang, not repayment — an old debt still needs
      // to be settleable.
      await addUtang(Money.fromPesos(500));
      await customers.setActive(juanId, isActive: false);

      await pay(Money.fromPesos(500));

      expect(await outstanding(), Money.zero);
    });
  });

  // ======================================================================
  /*
    §23 — the rule, and the race it would otherwise have.
  */
  group('overpayment guard (§23)', () {
    test('rejects more than is owed, and names the real figure', () async {
      await addUtang(Money.fromPesos(500));

      await expectLater(
        pay(Money.fromPesos(700)),
        throwsA(
          isA<AppFailure>()
              .having((f) => f.code, 'code', 'OVERPAYMENT')
              .having((f) => f.message, 'message', contains('₱500.00')),
        ),
      );

      // §23: do not silently create Balance = −₱200.
      expect(await outstanding(), Money.fromPesos(500));
      expect(await db.select(db.paymentsTable).get(), isEmpty);
    });

    test('rejects one centavo over', () async {
      await addUtang(Money.fromPesos(500));

      await expectLater(
        pay(Money.fromCentavos(50001)),
        throwsA(isA<AppFailure>()),
      );

      // ...and accepts exactly the balance.
      await pay(Money.fromCentavos(50000));
      expect(await outstanding(), Money.zero);
    });

    test('rejects a zero or negative payment (§38)', () async {
      await addUtang(Money.fromPesos(500));

      await expectLater(pay(Money.zero), throwsA(isA<AppFailure>()));
      await expectLater(
        pay(Money.fromPesos(-100)),
        throwsA(isA<AppFailure>()),
      );

      expect(await db.select(db.paymentsTable).get(), isEmpty);
    });

    test('rejects paying a customer who owes nothing', () async {
      await expectLater(
        pay(Money.fromPesos(100)),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.code,
            'code',
            'NO_OUTSTANDING_BALANCE',
          ),
        ),
      );
    });

    /*
      ------------------------------------------------------------------
      THE RACE.
      ------------------------------------------------------------------

      Two payments for the full balance, fired without awaiting the
      first. If the check and the insert were not in one transaction,
      both would read ₱500, both would pass, and the balance would end
      at −₱500 — a state §23 says must be impossible.
    */
    test('two simultaneous full payments cannot both succeed', () async {
      await addUtang(Money.fromPesos(500));

      final results = await Future.wait([
        pay(Money.fromPesos(500)).then((_) => true).catchError((_) => false),
        pay(Money.fromPesos(500)).then((_) => true).catchError((_) => false),
      ]);

      // Exactly one wins.
      expect(results.where((ok) => ok).length, 1);
      expect(await db.select(db.paymentsTable).get(), hasLength(1));

      // And the balance never went negative.
      expect(await outstanding(), Money.zero);
    });

    test('many simultaneous payments never overshoot', () async {
      await addUtang(Money.fromPesos(500));

      // Five × ₱200 against a ₱500 balance: at most two can fit.
      final results = await Future.wait(
        List.generate(
          5,
          (_) => pay(
            Money.fromPesos(200),
          ).then((_) => true).catchError((_) => false),
        ),
      );

      expect(results.where((ok) => ok).length, 2);

      final balance = await outstanding();
      expect(balance, Money.fromPesos(100));
      expect(balance.isNegative, isFalse);
    });

    test('interest raises the ceiling a payment may reach', () async {
      await addUtang(Money.fromPesos(500));
      await addInterest(Money.fromPesos(10), '2026-08');

      // ₱510 owed now, so ₱510 is payable and ₱511 is not.
      await expectLater(
        pay(Money.fromPesos(511)),
        throwsA(isA<AppFailure>()),
      );

      await pay(Money.fromPesos(510));
      expect(await outstanding(), Money.zero);
    });

    test('payments are scoped to their store', () async {
      final otherStoreId = await stores.createStore(
        StorePayloadModel(name: 'Other Store'),
      );

      await addUtang(Money.fromPesos(500));

      await expectLater(
        payments.recordPayment(
          PaymentPayloadModel(
            storeId: otherStoreId,
            customerId: juanId,
            amount: Money.fromPesos(100),
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
    });
  });

  // ======================================================================
  group('ledger (§17)', () {
    test('merges all three kinds of event', () async {
      await addUtang(Money.fromPesos(500));
      await pay(Money.fromPesos(200));
      await addInterest(Money.fromPesos(9), '2026-08');

      final rows = await ledger.fetchLedgerForCustomer(juanId);

      expect(rows, hasLength(3));
      expect(
        rows.map((r) => r.entry.kind),
        containsAll([
          LedgerEntryKind.utang,
          LedgerEntryKind.payment,
          LedgerEntryKind.interest,
        ]),
      );
    });

    test('signs follow §15 — utang and interest add, payments subtract',
        () async {
      await addUtang(Money.fromPesos(500));
      await pay(Money.fromPesos(200));
      await addInterest(Money.fromPesos(9), '2026-08');

      final rows = await ledger.fetchLedgerForCustomer(juanId);

      for (final row in rows) {
        switch (row.entry.kind) {
          case LedgerEntryKind.payment:
            expect(row.entry.signedAmount.isNegative, isTrue);
          case LedgerEntryKind.utang:
          case LedgerEntryKind.interest:
            expect(row.entry.signedAmount.isNegative, isFalse);
        }
      }
    });

    test('the running balance never goes negative within one second',
        () async {
      /*
        An utang and the payment settling it, written in the same
        second — a customer paying at the counter for what they just
        took. Drift stores DateTime as unix SECONDS, so both carry the
        identical timestamp.

        Without the kind ordering (utang before payment), the payment
        could sort first and the ledger would show a momentarily
        NEGATIVE balance for a customer who never owed one.
      */
      await addUtang(Money.fromPesos(500));
      await pay(Money.fromPesos(500));

      final rows = await ledger.fetchLedgerForCustomer(juanId);

      expect(rows.first.entry.kind, LedgerEntryKind.utang);
      expect(rows.first.balanceAfter, Money.fromPesos(500));
      expect(rows.last.balanceAfter, Money.zero);

      for (final row in rows) {
        expect(
          row.balanceAfter.isNegative,
          isFalse,
          reason: 'running balance went negative at ${row.entry.kind}',
        );
      }
    });

    test('the final running balance equals CustomerBalance', () async {
      // Two independent paths to the same number: event-by-event, and
      // three SUMs. If they ever disagree, one of them is wrong.
      await addUtang(Money.fromPesos(500));
      await addUtang(Money.fromPesos(40));
      await pay(Money.fromPesos(100));
      await addUtang(Money.fromPesos(90));
      await addInterest(Money.fromPesos(10.60), '2026-08');

      final rows = await ledger.fetchLedgerForCustomer(juanId);

      expect(rows.last.balanceAfter, await outstanding());
      expect(rows.last.balanceAfter, Money.fromPesos(540.60));
    });

    test('is empty for a customer with no history', () async {
      expect(await ledger.fetchLedgerForCustomer(juanId), isEmpty);
    });

    test('only covers the customer asked for', () async {
      final maria = await customers.createCustomer(
        CustomerPayloadModel(storeId: storeId, name: 'Maria'),
      );

      await addUtang(Money.fromPesos(500));
      await addUtang(Money.fromPesos(300), customerId: maria);

      expect(await ledger.fetchLedgerForCustomer(juanId), hasLength(1));
      expect(
        (await ledger.fetchLedgerForCustomer(juanId))
            .single
            .entry
            .signedAmount,
        Money.fromPesos(500),
      );
    });

    test('an utang row carries its item count, not its items', () async {
      final coffee = await products.createProduct(
        ProductPayloadModel(
          storeId: storeId,
          name: 'Coffee',
          price: Money.fromPesos(20),
          unit: 'pc',
        ),
      );

      await transactions.createTransaction(
        TransactionPayloadModel(
          storeId: storeId,
          customerId: juanId,
          items: [
            TransactionItemPayloadModel(
              productId: riceId,
              quantity: 5,
              unitPrice: Money.fromPesos(100),
            ),
            TransactionItemPayloadModel(
              productId: coffee,
              quantity: 2,
              unitPrice: Money.fromPesos(20),
            ),
          ],
        ),
      );

      final entry =
          (await ledger.fetchLedgerForCustomer(juanId)).single.entry
              as LedgerUtangEntry;

      // A join would have fanned the row out once per line and
      // doubled the amount.
      expect(entry.itemCount, 2);
      expect(entry.total, Money.fromPesos(540));
      expect(entry.description, '2 items');
    });
  });

  // ======================================================================
  /*
    The §36 canonical scenario, now complete through Day 3's payment.
    Interest is applied manually here; Phase 6 automates it.
  */
  group('transaction_logic.md §36 — end to end', () {
    /*
      §36 plays out over four days, so the test dates the records to
      match. Drift stores DateTime as unix SECONDS and everything
      inserted here would otherwise land in the same one — at which
      point the ledger's same-second rule (utang before payments, so a
      running balance never dips negative) would reorder them away from
      §36's day-by-day story.

      Dating them is not a workaround: multi-day ordering is what the
      ledger is actually for, and the same-second case has its own test.
    */
    Future<void> dateTransaction(int id, DateTime when) {
      return db.customStatement(
        'UPDATE transactions_table SET created_at = ? WHERE id = ?',
        [when.millisecondsSinceEpoch ~/ 1000, id],
      );
    }

    Future<void> datePayment(int id, DateTime when) {
      return db.customStatement(
        'UPDATE payments_table SET created_at = ? WHERE id = ?',
        [when.millisecondsSinceEpoch ~/ 1000, id],
      );
    }

    Future<void> dateInterest(DateTime when) {
      return db.customStatement(
        'UPDATE interest_records_table SET created_at = ?',
        [when.millisecondsSinceEpoch ~/ 1000],
      );
    }

    test('Juan ends the month owing ₱540.60', () async {
      final coffee = await products.createProduct(
        ProductPayloadModel(
          storeId: storeId,
          name: 'Coffee',
          price: Money.fromPesos(20),
          unit: 'pc',
        ),
      );
      final sardines = await products.createProduct(
        ProductPayloadModel(
          storeId: storeId,
          name: 'Sardines',
          price: Money.fromPesos(30),
          unit: 'can',
        ),
      );

      Future<int> sell(int productId, double qty, Money price) {
        return transactions.createTransaction(
          TransactionPayloadModel(
            storeId: storeId,
            customerId: juanId,
            items: [
              TransactionItemPayloadModel(
                productId: productId,
                quantity: qty,
                unitPrice: price,
              ),
            ],
          ),
        );
      }

      // Day 1 — 5 × Rice @ ₱100
      await dateTransaction(
        await sell(riceId, 5, Money.fromPesos(100)),
        DateTime(2026, 8, 20, 9),
      );
      expect(await outstanding(), Money.fromPesos(500));

      // Day 2 — 2 × Coffee @ ₱20
      await dateTransaction(
        await sell(coffee, 2, Money.fromPesos(20)),
        DateTime(2026, 8, 21, 10),
      );
      expect(await outstanding(), Money.fromPesos(540));

      // Day 3 — pays ₱100
      await datePayment(
        await pay(Money.fromPesos(100)),
        DateTime(2026, 8, 22, 11),
      );
      expect(await outstanding(), Money.fromPesos(440));

      // Day 4 — 3 × Sardines @ ₱30
      await dateTransaction(
        await sell(sardines, 3, Money.fromPesos(30)),
        DateTime(2026, 8, 23, 12),
      );
      expect(await outstanding(), Money.fromPesos(530));

      // End of month — 2% of the outstanding balance
      final balance = await balances.fetchBalanceForCustomer(juanId);
      final interest = balance.interestFor(200);
      expect(interest, Money.fromPesos(10.60));

      await addInterest(interest, AppDateFormat.periodKey(DateTime(2026, 8)));
      await dateInterest(DateTime(2026, 8, 31, 18));

      // §36's answer.
      expect(await outstanding(), Money.fromPesos(540.60));

      /*
        The ledger tells the same story event by event — §36's own
        running balance column:

            Day 1    UTANG       +₱500.00     ₱500.00
            Day 2    UTANG        +₱40.00     ₱540.00
            Day 3    PAYMENT     −₱100.00     ₱440.00
            Day 4    UTANG        +₱90.00     ₱530.00
            Month    INTEREST     +₱10.60     ₱540.60
      */
      final rows = await ledger.fetchLedgerForCustomer(juanId);
      expect(rows, hasLength(5));
      expect(
        rows.map((r) => r.balanceAfter.format()).toList(),
        ['₱500.00', '₱540.00', '₱440.00', '₱530.00', '₱540.60'],
      );
      expect(
        rows.map((r) => r.entry.kind).toList(),
        [
          LedgerEntryKind.utang,
          LedgerEntryKind.utang,
          LedgerEntryKind.payment,
          LedgerEntryKind.utang,
          LedgerEntryKind.interest,
        ],
      );

      // The originals are untouched (§14, §16).
      final finalBalance = await balances.fetchBalanceForCustomer(juanId);
      expect(finalBalance.totalUtang, Money.fromPesos(630));
      expect(finalBalance.totalPaid, Money.fromPesos(100));
      expect(finalBalance.totalInterest, Money.fromPesos(10.60));
    });
  });
}
