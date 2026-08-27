import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_balance_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_repository.dart';
import 'package:utanglista_mobileapp/features/interest/data/datasource/interest_local_data_source.dart';
import 'package:utanglista_mobileapp/features/interest/domain/entities/interest_preview.dart';
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
  late InterestRepository interest;

  late int storeId;
  late int riceId;

  const twoPercent = InterestRate.fromBasisPoints(200);

  /*
    ------------------------------------------------------------------
    Why every debt here is BACKDATED.
    ------------------------------------------------------------------

    Interest is charged on the balance a customer carried INTO the
    month — every event strictly before the period start. A debt
    created "now" therefore belongs to the current month's balance and
    is not charged until the following one, which is the whole point of
    the rule.

    So the tests put the debt in June and charge July and August. That
    is not a workaround; it is the ordinary case: you owe money, a
    month turns over, you are charged.
  */
  const july = '2026-07';
  const august = '2026-08';

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
    interest = InterestRepositoryImplementation(
      InterestLocalDataSourceImplementation(db),
    );

    storeId = await stores.createStore(
      StorePayloadModel(
        name: 'Aling Nena Store',
        monthlyInterestEnabled: true,
        monthlyInterestRate: twoPercent,
      ),
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

  Future<int> addCustomer(String name) => customers.createCustomer(
    CustomerPayloadModel(storeId: storeId, name: name),
  );

  /// Records a debt and dates it, so tests can place it before or
  /// inside the charged period.
  Future<int> owe(
    int customerId,
    Money amount, {
    DateTime? on,
  }) async {
    final id = await transactions.createTransaction(
      TransactionPayloadModel(
        storeId: storeId,
        customerId: customerId,
        items: [
          TransactionItemPayloadModel(
            productId: riceId,
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

  /// The default: a debt from June, so it is carried into both July
  /// and August.
  Future<int> oweFromJune(int customerId, Money amount) =>
      owe(customerId, amount, on: DateTime(2026, 6, 15));

  Future<Money> outstanding(int customerId) async =>
      (await balances.fetchBalanceForCustomer(customerId)).outstanding;

  Future<InterestPreview> preview({
    String periodKey = july,
    InterestRate rate = twoPercent,
  }) {
    return interest.buildPreview(
      storeId: storeId,
      periodKey: periodKey,
      rate: rate,
    );
  }

  Future<InterestApplicationResult> apply({
    String periodKey = july,
    InterestRate rate = twoPercent,
  }) {
    return interest.applyInterest(
      storeId: storeId,
      periodKey: periodKey,
      rate: rate,
    );
  }

  // ======================================================================
  group('preview', () {
    test('computes §20 interest against the outstanding balance', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      final line = (await preview()).toCharge.single;

      // §20's worked example: ₱1,000 × 2% = ₱20.
      expect(line.baseAmount, Money.fromPesos(1000));
      expect(line.interestAmount, Money.fromPesos(20));
      expect(line.status, InterestPreviewStatus.willApply);
    });

    test('charges on what is left after payments, not the original debt',
        () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      // Paid in June as well, so both events are carried into July.
      final paymentId = await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juan,
          amount: Money.fromPesos(500),
        ),
      );
      await db.customStatement(
        'UPDATE payments_table SET created_at = ? WHERE id = ?',
        [DateTime(2026, 6, 20).millisecondsSinceEpoch ~/ 1000, paymentId],
      );

      final line = (await preview()).toCharge.single;

      // 2% of ₱500 remaining, not of the ₱1,000 originally taken.
      expect(line.baseAmount, Money.fromPesos(500));
      expect(line.interestAmount, Money.fromPesos(10));
    });

    test('skips a customer who owes nothing', () async {
      await addCustomer('Settled');

      final result = await preview();

      expect(result.toCharge, isEmpty);
      expect(
        result.skipped.single.status,
        InterestPreviewStatus.nothingOwed,
      );
    });

    test('skips a deactivated customer', () async {
      // A documented judgment call, not a spec rule — see the note on
      // InterestPreview.
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await customers.setActive(juan, isActive: false);

      final result = await preview();

      expect(result.toCharge, isEmpty);
      expect(result.skipped.single.status, InterestPreviewStatus.inactive);
    });

    test('skips a charge that rounds to zero', () async {
      // ₱0.10 at 2% is ₱0.002 -> ₱0.00. A zero-peso record would be
      // noise in the ledger.
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromCentavos(10));

      final result = await preview();

      expect(result.toCharge, isEmpty);
      expect(result.skipped.single.status, InterestPreviewStatus.roundsToZero);
    });

    test('lists every customer, charged or skipped', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await addCustomer('Maria');

      final result = await preview();

      // A seller expecting two names must see two names.
      expect(result.lines, hasLength(2));
      expect(result.chargeCount, 1);
      expect(result.skipped, hasLength(1));
    });

    test('totals what the run would charge', () async {
      final juan = await addCustomer('Juan');
      final maria = await addCustomer('Maria');
      await oweFromJune(juan, Money.fromPesos(1000));
      await oweFromJune(maria, Money.fromPesos(500));

      final result = await preview();

      expect(result.totalBase, Money.fromPesos(1500));
      expect(result.totalInterest, Money.fromPesos(30));
      expect(result.chargeCount, 2);
    });

    test('does not reach into another store', () async {
      final otherStoreId = await stores.createStore(
        StorePayloadModel(name: 'Other Store'),
      );
      final theirCustomer = await customers.createCustomer(
        CustomerPayloadModel(storeId: otherStoreId, name: 'Pedro'),
      );
      await db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              storeId: otherStoreId,
              customerId: theirCustomer,
              totalAmount: Money.fromPesos(1000).centavos,
            ),
          );

      expect((await preview()).lines, isEmpty);
    });

    test('does not write anything', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      await preview();

      expect(await db.select(db.interestRecordsTable).get(), isEmpty);
      expect(await outstanding(juan), Money.fromPesos(1000));
    });
  });

  // ======================================================================
  group('applying', () {
    test('writes a record and raises the balance (§20, §21)', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      final result = await apply();

      expect(result.appliedCount, 1);
      expect(result.totalCharged, Money.fromPesos(20));
      expect(await outstanding(juan), Money.fromPesos(1020));
    });

    test('records the base and rate WITH the charge (§21)', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      await apply();

      final record = await db.select(db.interestRecordsTable).getSingle();
      expect(record.baseAmount, Money.fromPesos(1000).centavos);
      expect(record.rateBasisPoints, 200);
      expect(record.interestAmount, Money.fromPesos(20).centavos);
      expect(record.periodKey, july);
    });

    test('a later rate change does not rewrite a past charge', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await apply();

      // The store moves to 5% and charges the next month.
      await apply(
        periodKey: august,
        rate: const InterestRate.fromBasisPoints(500),
      );

      // Sorted in Dart rather than SQL — importing drift here would
      // pull in its isNull/isNotNull, which collide with matcher's.
      final records = await db.select(db.interestRecordsTable).get()
        ..sort((a, b) => a.periodKey.compareTo(b.periodKey));

      // August keeps the rate it was charged at — the same snapshot
      // reasoning as §7's unit price.
      expect(records.first.rateBasisPoints, 200);
      expect(records.last.rateBasisPoints, 500);
    });

    test('charges several customers in one run', () async {
      final juan = await addCustomer('Juan');
      final maria = await addCustomer('Maria');
      await oweFromJune(juan, Money.fromPesos(1000));
      await oweFromJune(maria, Money.fromPesos(500));

      final result = await apply();

      expect(result.appliedCount, 2);
      expect(result.totalCharged, Money.fromPesos(30));
      expect(await outstanding(juan), Money.fromPesos(1020));
      expect(await outstanding(maria), Money.fromPesos(510));
    });

    test('writes nothing for skipped customers', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await addCustomer('Settled');

      await apply();

      expect(await db.select(db.interestRecordsTable).get(), hasLength(1));
    });
  });

  // ======================================================================
  /*
    §22 — the rule this whole feature is built around.
  */
  group('never applied twice for one period (§22)', () {
    test('a second run for the same month charges nothing', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      final first = await apply();
      expect(first.appliedCount, 1);

      // §22's example: opening the app again must not add a second
      // ₱20 for August.
      final second = await apply();
      expect(second.appliedCount, 0);
      expect(second.totalCharged, Money.zero);
      expect(second.hasFailures, isFalse);

      expect(await db.select(db.interestRecordsTable).get(), hasLength(1));
      expect(await outstanding(juan), Money.fromPesos(1020));
    });

    test('running three times still leaves one record', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      await apply();
      await apply();
      await apply();

      expect(await db.select(db.interestRecordsTable).get(), hasLength(1));
      expect(await outstanding(juan), Money.fromPesos(1020));
    });

    test('the preview reports the already-charged customer as such',
        () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await apply();

      final result = await preview();

      expect(result.toCharge, isEmpty);
      expect(
        result.skipped.single.status,
        InterestPreviewStatus.alreadyApplied,
      );
      expect(result.isFullyApplied, isTrue);
    });

    test('the NEXT month is a separate period, and compounds', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      await apply();
      final second = await apply(periodKey: august);

      expect(second.appliedCount, 1);

      /*
        August compounds on July's ₱1,020: 2% = ₱20.40.

        This only works because July's charge is DATED to July (see
        AppDateFormat.interestEffectiveDate). Dated by wall clock it
        would fall after 1 August and drop out of August's base, and
        the compounding would silently not happen.
      */
      expect(second.totalCharged, Money.fromPesos(20.40));
      expect(await outstanding(juan), Money.fromPesos(1040.40));
      expect(await db.select(db.interestRecordsTable).get(), hasLength(2));
    });

    test('the database refuses a duplicate even bypassing the app',
        () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await apply();

      // The unique (customer_id, period_key) index is the guarantee —
      // not the code path above it.
      await expectLater(
        db
            .into(db.interestRecordsTable)
            .insert(
              InterestRecordsTableCompanion.insert(
                storeId: storeId,
                customerId: juan,
                rateBasisPoints: 200,
                baseAmount: 100000,
                interestAmount: 2000,
                periodKey: july,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('a customer charged mid-run is reported, not thrown', () async {
      // Simulates the race the preview cannot see: someone charged
      // between building the preview and confirming it.
      final juan = await addCustomer('Juan');
      final maria = await addCustomer('Maria');
      await oweFromJune(juan, Money.fromPesos(1000));
      await oweFromJune(maria, Money.fromPesos(1000));

      await db
          .into(db.interestRecordsTable)
          .insert(
            InterestRecordsTableCompanion.insert(
              storeId: storeId,
              customerId: juan,
              rateBasisPoints: 200,
              baseAmount: 100000,
              interestAmount: 2000,
              periodKey: july,
            ),
          );

      // Juan is already charged, so only Maria is chargeable — and the
      // run completes rather than failing wholesale.
      final result = await apply();
      expect(result.appliedCount, 1);
      expect(await db.select(db.interestRecordsTable).get(), hasLength(2));
    });
  });

  // ======================================================================
  /*
    The rule that says WHEN a debt starts attracting interest.
  */
  group('interest starts from the debt, not the calendar run', () {
    test('a debt taken DURING the month is not charged that month',
        () async {
      final juan = await addCustomer('Juan');
      // Taken on 20 July — the month being charged.
      await owe(juan, Money.fromPesos(1000), on: DateTime(2026, 7, 20));

      final result = await preview();

      expect(result.toCharge, isEmpty);
      expect(
        result.skipped.single.status,
        InterestPreviewStatus.nothingOwed,
      );
    });

    test('...and IS charged the following month', () async {
      final juan = await addCustomer('Juan');
      await owe(juan, Money.fromPesos(1000), on: DateTime(2026, 7, 20));

      // Nothing in July...
      final julyRun = await apply();
      expect(julyRun.appliedCount, 0);

      // ...but August charges it, roughly a month after it was taken.
      final augustRun = await apply(periodKey: august);
      expect(augustRun.appliedCount, 1);
      expect(augustRun.totalCharged, Money.fromPesos(20));
    });

    test('charging a PAST month uses that month\'s balance', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      // A second debt taken in August must not inflate July's charge.
      await owe(juan, Money.fromPesos(5000), on: DateTime(2026, 8, 5));

      final result = await preview();

      // 2% of the ₱1,000 carried into July — not of the ₱6,000 owed now.
      expect(result.toCharge.single.baseAmount, Money.fromPesos(1000));
      expect(result.toCharge.single.interestAmount, Money.fromPesos(20));
    });

    test('a payment made during the month does not reduce that month\'s base',
        () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      // Paid on 10 July — after the July cutoff.
      final paymentId = await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juan,
          amount: Money.fromPesos(500),
        ),
      );
      await db.customStatement(
        'UPDATE payments_table SET created_at = ? WHERE id = ?',
        [DateTime(2026, 7, 10).millisecondsSinceEpoch ~/ 1000, paymentId],
      );

      // July charges the ₱1,000 carried in; the payment counts from
      // August onwards.
      final result = await preview();
      expect(result.toCharge.single.baseAmount, Money.fromPesos(1000));

      final augustPreview = await preview(periodKey: august);
      expect(augustPreview.toCharge.single.baseAmount, Money.fromPesos(500));
    });

    test('a charge is dated to the month it covers, not when it was run',
        () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      await apply();

      // Run "now" (August, per the test clock) but recorded as July.
      final record = await db.select(db.interestRecordsTable).getSingle();
      expect(record.periodKey, july);
      expect(record.createdAt.year, 2026);
      expect(record.createdAt.month, 7);
    });

    test('the charge lands in the right place in the ledger', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await apply();

      final record = await db.select(db.interestRecordsTable).getSingle();

      // §17 orders the ledger by date. A July charge surfacing in
      // August would read as though the customer was charged twice.
      expect(record.createdAt.isBefore(DateTime(2026, 8)), isTrue);
      expect(record.createdAt.isAfter(DateTime(2026, 7)), isTrue);
    });
  });

  // ======================================================================
  group('rate validation (§19)', () {
    test('rejects a rate above 5%', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      await expectLater(
        apply(rate: const InterestRate.fromBasisPoints(501)),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.code,
            'code',
            'INVALID_INTEREST_RATE',
          ),
        ),
      );

      expect(await db.select(db.interestRecordsTable).get(), isEmpty);
    });

    test('accepts exactly 5%', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));

      final result = await apply(rate: InterestRate.maximum);
      expect(result.totalCharged, Money.fromPesos(50));
    });

    test('rejects a negative rate', () async {
      await expectLater(
        apply(rate: const InterestRate.fromBasisPoints(-100)),
        throwsA(isA<AppFailure>()),
      );
    });

    test('rejects a zero rate rather than reporting a silent no-op',
        () async {
      await expectLater(
        apply(rate: InterestRate.zero),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.code,
            'code',
            'ZERO_INTEREST_RATE',
          ),
        ),
      );
    });

    test('rejects a malformed period key', () async {
      // A bad key would sidestep the unique index and let interest be
      // applied twice.
      await expectLater(
        apply(periodKey: 'August'),
        throwsA(
          isA<AppFailure>().having((f) => f.code, 'code', 'INVALID_PERIOD'),
        ),
      );
    });
  });

  // ======================================================================
  group('interaction with payments and history', () {
    test('interest raises the ceiling a payment may reach (§23)', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await apply();

      // ₱1,020 owed now.
      await expectLater(
        payments.recordPayment(
          PaymentPayloadModel(
            storeId: storeId,
            customerId: juan,
            amount: Money.fromPesos(1021),
          ),
        ),
        throwsA(isA<AppFailure>()),
      );

      await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juan,
          amount: Money.fromPesos(1020),
        ),
      );
      expect(await outstanding(juan), Money.zero);
    });

    test('history is grouped and readable', () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await apply();
      await apply(periodKey: august);

      final records = await interest.fetchRecords(storeId);

      expect(records, hasLength(2));
      // periodKey is zero-padded, so text order is chronological.
      expect(records.first.periodKey, august);
      expect(records.last.periodKey, july);
      expect(records.last.rate.formatPercent(), '2%');
    });

    test('history can be narrowed to one customer', () async {
      final juan = await addCustomer('Juan');
      final maria = await addCustomer('Maria');
      await oweFromJune(juan, Money.fromPesos(1000));
      await oweFromJune(maria, Money.fromPesos(1000));
      await apply();

      expect(
        await interest.fetchRecords(storeId, customerId: juan),
        hasLength(1),
      );
      expect(await interest.fetchRecords(storeId), hasLength(2));
    });

    test('a customer charged interest can no longer be deleted (§29)',
        () async {
      final juan = await addCustomer('Juan');
      await oweFromJune(juan, Money.fromPesos(1000));
      await apply();

      await expectLater(
        customers.deleteCustomer(juan),
        throwsA(isA<AppFailure>()),
      );
    });
  });
}
