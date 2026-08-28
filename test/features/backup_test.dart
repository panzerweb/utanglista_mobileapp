import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/services/data_reset_notifier.dart';
import 'package:utanglista_mobileapp/features/backup/data/datasource/backup_local_data_source.dart';
import 'package:utanglista_mobileapp/features/backup/domain/repositories/backup_repository.dart';
import 'package:utanglista_mobileapp/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_balance_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_repository.dart';
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

/*
  ==================================================================
  BACKUP AND RESTORE.
  ==================================================================

  A backup is the only copy of a store owner's ledger that survives
  losing the phone, so these tests care about two things above all:

    1. a round trip changes NOTHING — not a centavo, not a date, not
       a foreign key;
    2. a bad file is refused while the existing data is still intact.

  The §36 scenario is used as the payload for the round trip, because
  it is the one dataset in this project whose correct answer is
  already known and written down: ₱540.60.
*/
void main() {
  late AppDatabase db;
  late StoreRepository stores;
  late CustomerRepository customers;
  late ProductRepository products;
  late TransactionRepository transactions;
  late PaymentRepository payments;
  late CustomerBalanceRepository balances;
  late BackupRepository backup;

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
    backup = BackupRepositoryImplementation(
      BackupLocalDataSourceImplementation(db),
    );

    storeId = await stores.createStore(
      StorePayloadModel(
        name: 'Aling Nena Store',
        monthlyInterestEnabled: true,
        monthlyInterestRate: const InterestRate.fromBasisPoints(200),
      ),
    );
    juanId = await customers.createCustomer(
      CustomerPayloadModel(
        storeId: storeId,
        name: 'Juan Dela Cruz',
        contactNumber: '0917 555 1234',
      ),
    );
    riceId = await products.createProduct(
      ProductPayloadModel(
        storeId: storeId,
        name: 'Rice',
        price: Money.fromPesos(100),
        unit: 'kg',
        barcode: '4801234567890',
      ),
    );
  });

  tearDown(() async => db.close());

  Future<int> addUtang(Money amount, {String? note}) {
    return transactions.createTransaction(
      TransactionPayloadModel(
        storeId: storeId,
        customerId: juanId,
        note: note,
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

  Future<void> addInterest(Money amount, String periodKey) async {
    await db
        .into(db.interestRecordsTable)
        .insert(
          InterestRecordsTableCompanion.insert(
            storeId: storeId,
            customerId: juanId,
            rateBasisPoints: 200,
            baseAmount: Money.fromPesos(530).centavos,
            interestAmount: amount.centavos,
            periodKey: periodKey,
          ),
        );
  }

  Future<Money> outstanding() async =>
      (await balances.fetchBalanceForCustomer(juanId)).outstanding;

  // ======================================================================
  group('export', () {
    test('writes a self-describing envelope', () async {
      final json = jsonDecode(await backup.exportToJson());

      expect(json['app'], 'utanglista');
      expect(json['formatVersion'], 1);
      expect(json['schemaVersion'], db.schemaVersion);
      expect(json['exportedAt'], isA<String>());
      expect(json['tables'], isA<Map>());
    });

    test('covers every table in the schema', () async {
      final json = jsonDecode(await backup.exportToJson());
      final exported = (json['tables'] as Map).keys.toSet();

      // Not a hardcoded list: whatever the database actually has must
      // be in the file, or the backup is silently partial.
      final actual = db.allTables.map((t) => t.actualTableName).toSet();

      expect(exported, actual);
    });

    test('money is exported as raw centavos, never formatted', () async {
      await addUtang(Money.fromPesos(52.50));

      final json = jsonDecode(await backup.exportToJson());
      final rows = json['tables']['transactions_table'] as List;

      // 5250, not 52.5 and not "₱52.50". §26: no floating point, and
      // no locale-dependent string to parse back.
      expect(rows.single['total_amount'], 5250);
      expect(rows.single['total_amount'], isA<int>());
    });
  });

  // ======================================================================
  group('round trip', () {
    /*
      The §36 scenario, exported, wiped and restored. If a single value
      moved, the balance at the end would not still be ₱540.60.
    */
    test('the §36 ledger survives export, wipe and restore', () async {
      await addUtang(Money.fromPesos(500), note: '5kg rice');
      await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juanId,
          amount: Money.fromPesos(200),
          note: 'Partial payment',
        ),
      );
      await addUtang(Money.fromPesos(230));
      await addInterest(Money.fromPesos(10.60), '2026-08');

      expect(await outstanding(), Money.fromPesos(540.60));

      final file = await backup.exportToJson();

      // Wipe it the way losing a phone does.
      await stores.deleteStore(storeId);
      expect(await db.select(db.storesTable).get(), isEmpty);

      await backup.restoreFromJson(file);

      expect(await outstanding(), Money.fromPesos(540.60));
    });

    test('every field comes back exactly as it went in', () async {
      await addUtang(Money.fromPesos(230), note: 'for the fiesta');

      final file = await backup.exportToJson();
      await stores.deleteStore(storeId);
      await backup.restoreFromJson(file);

      final store = await stores.fetchStoreById(storeId);
      final customer = await customers.fetchCustomerById(juanId);
      final product = await products.fetchProductById(riceId);
      final history = await transactions.fetchTransactions(storeId);

      // Ids are preserved — every foreign key in the file depends on
      // it, and the fetches above are by the ORIGINAL ids.
      expect(store!.name, 'Aling Nena Store');
      expect(store.monthlyInterestEnabled, isTrue);
      expect(store.monthlyInterestRate, const InterestRate.fromBasisPoints(200));

      expect(customer!.name, 'Juan Dela Cruz');
      expect(customer.contactNumber, '0917 555 1234');

      expect(product!.price, Money.fromPesos(100));
      expect(product.barcode, '4801234567890');
      expect(product.unit, 'kg');

      expect(history.single.note, 'for the fiesta');
      expect(history.single.totalAmount, Money.fromPesos(230));
    });

    test('createdAt survives, so the ledger still sorts', () async {
      await addUtang(Money.fromPesos(100));

      final before = (await transactions.fetchTransactions(
        storeId,
      )).single.createdAt;

      final file = await backup.exportToJson();
      await stores.deleteStore(storeId);
      await backup.restoreFromJson(file);

      final after = (await transactions.fetchTransactions(
        storeId,
      )).single.createdAt;

      // Drift stores DateTime as unix SECONDS, so this compares at
      // that resolution — which is the resolution the ledger orders on.
      expect(
        after.millisecondsSinceEpoch ~/ 1000,
        before.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('a transaction keeps its items and its price snapshot', () async {
      final transactionId = await addUtang(Money.fromPesos(52.50));

      final file = await backup.exportToJson();
      await stores.deleteStore(storeId);
      await backup.restoreFromJson(file);

      final restored = await transactions.fetchTransactionById(transactionId);

      // §7: the snapshot is the whole point of the items table.
      expect(restored!.items, hasLength(1));
      expect(restored.items.single.unitPrice, Money.fromPesos(52.50));
      expect(restored.items.single.quantity, 1);
    });

    test('restoring replaces, it does not merge', () async {
      await addUtang(Money.fromPesos(100));

      final file = await backup.exportToJson();

      // Something that exists now but not in the backup.
      await customers.createCustomer(
        CustomerPayloadModel(storeId: storeId, name: 'Maria Santos'),
      );
      expect(await customers.fetchCustomers(storeId), hasLength(2));

      await backup.restoreFromJson(file);

      // Maria is gone. A merge would have kept her — and would have
      // had to invent an id for her that the backup may already use.
      final after = await customers.fetchCustomers(storeId);
      expect(after, hasLength(1));
      expect(after.single.name, 'Juan Dela Cruz');
    });

    test('a restored database still accepts new records', () async {
      // The autoincrement counters have to be usable afterwards, or
      // the first thing the seller does after restoring fails.
      await addUtang(Money.fromPesos(100));

      final file = await backup.exportToJson();
      await stores.deleteStore(storeId);
      await backup.restoreFromJson(file);

      final newCustomer = await customers.createCustomer(
        CustomerPayloadModel(storeId: storeId, name: 'Maria Santos'),
      );

      expect(newCustomer, isNot(juanId));
      expect(await customers.fetchCustomers(storeId), hasLength(2));

      await addUtang(Money.fromPesos(50));
      expect(await outstanding(), Money.fromPesos(150));
    });
  });

  // ======================================================================
  /*
    Every case below must leave the existing data untouched. That is
    asserted explicitly each time, because "it threw" is only half the
    requirement — a restore that fails after deleting is worse than
    one that never started.
  */
  group('a bad file is refused, and nothing is lost', () {
    setUp(() async => addUtang(Money.fromPesos(500)));

    Future<void> expectRefused(String file, String code) async {
      await expectLater(
        backup.restoreFromJson(file),
        throwsA(isA<AppFailure>().having((f) => f.code, 'code', code)),
      );

      // The ledger is still exactly as it was.
      expect(await outstanding(), Money.fromPesos(500));
      expect(await customers.fetchCustomers(storeId), hasLength(1));
    }

    test('a file that is not JSON', () async {
      await expectRefused('this is not a backup', 'INVALID_BACKUP');
    });

    test('JSON that is not ours', () async {
      await expectRefused('{"app":"something-else"}', 'INVALID_BACKUP');
    });

    test('a truncated file', () async {
      final file = await backup.exportToJson();

      await expectRefused(
        file.substring(0, file.length ~/ 2),
        'INVALID_BACKUP',
      );
    });

    test('a backup from a newer format version', () async {
      final json = jsonDecode(await backup.exportToJson()) as Map;
      json['formatVersion'] = BackupEnvelopeVersions.next;

      await expectRefused(jsonEncode(json), 'BACKUP_TOO_NEW');
    });

    test('a backup from a newer schema', () async {
      final json = jsonDecode(await backup.exportToJson()) as Map;
      json['schemaVersion'] = db.schemaVersion + 1;

      await expectRefused(jsonEncode(json), 'BACKUP_TOO_NEW');
    });

    test('a backup from an older schema', () async {
      final json = jsonDecode(await backup.exportToJson()) as Map;
      json['schemaVersion'] = db.schemaVersion - 1;

      await expectRefused(jsonEncode(json), 'BACKUP_TOO_OLD');
    });

    test('an empty backup, which would delete everything', () async {
      final json = jsonDecode(await backup.exportToJson()) as Map;
      json['tables'] = <String, List<Object?>>{};

      await expectRefused(jsonEncode(json), 'EMPTY_BACKUP');
    });

    test('a backup naming a table this build does not have', () async {
      final json = jsonDecode(await backup.exportToJson()) as Map;
      (json['tables'] as Map)['loyalty_points_table'] = [
        {'id': 1},
      ];

      await expectRefused(jsonEncode(json), 'BACKUP_TOO_NEW');
    });

    /*
      The one that proves the transaction is doing its job. The file is
      valid down to the last table, where a row references a customer
      that does not exist — so the foreign key fires AFTER the deletes
      and several thousand inserts have already run inside the
      transaction.

      Either it all rolls back or the ledger is gone.
    */
    test('a referentially broken file rolls the whole restore back',
        () async {
      final json = jsonDecode(await backup.exportToJson()) as Map;

      (json['tables'] as Map)['payments_table'] = [
        {
          'id': 1,
          'store_id': storeId,
          'customer_id': 999999, // no such customer
          'amount': 10000,
          'note': null,
          'created_at': 1756000000,
        },
      ];

      await expectLater(
        backup.restoreFromJson(jsonEncode(json)),
        throwsA(isA<AppFailure>()),
      );

      // Untouched: the original ₱500 utang, and no phantom payment.
      expect(await outstanding(), Money.fromPesos(500));
      expect(await payments.fetchPayments(storeId), isEmpty);
      expect(await customers.fetchCustomers(storeId), hasLength(1));
    });
  });

  // ======================================================================
  group('inspecting a file before restoring it', () {
    test('describes what is inside without applying it', () async {
      await addUtang(Money.fromPesos(500));
      await addUtang(Money.fromPesos(230));
      await payments.recordPayment(
        PaymentPayloadModel(
          storeId: storeId,
          customerId: juanId,
          amount: Money.fromPesos(200),
        ),
      );

      final summary = await backup.inspect(await backup.exportToJson());

      expect(summary.storeCount, 1);
      expect(summary.customerCount, 1);
      expect(summary.productCount, 1);
      expect(summary.transactionCount, 2);
      expect(summary.paymentCount, 1);
      expect(summary.financialRecordCount, 3);
      expect(summary.isEmpty, isFalse);

      // Reads as a sentence, because it goes inside a dialog.
      expect(summary.describe(), contains('1 store'));
      expect(summary.describe(), contains('2 utang records'));
      expect(summary.describe(), contains('1 payment'));

      // And nothing was written: the balance is what it was before
      // the file was inspected, not what the file says.
      expect(await outstanding(), Money.fromPesos(530));
    });

    test('a bad file is rejected at inspection, before any dialog',
        () async {
      await expectLater(
        backup.inspect('not a backup'),
        throwsA(
          isA<AppFailure>().having((f) => f.code, 'code', 'INVALID_BACKUP'),
        ),
      );
    });
  });

  // ======================================================================
  /*
    A restore replaces every table while the Dashboard and Stores tabs
    are sitting in the shell's IndexedStack holding their own data. The
    notifier is what tells them to read again — without it they would
    keep showing a total receivable for transactions that no longer
    exist, which is the "plausible and wrong" failure this app works
    hardest to avoid.
  */
  group('a restore tells the rest of the app to reload', () {
    test('the generation moves on a successful restore', () async {
      await addUtang(Money.fromPesos(500));
      final file = await backup.exportToJson();

      final cubit = BackupCubit(backup);
      final before = dataResetNotifier.generation;

      await cubit.confirmRestore(file);

      expect(cubit.state, isA<BackupRestored>());
      expect(dataResetNotifier.generation, before + 1);

      await cubit.close();
    });

    test('a refused restore leaves it alone', () async {
      // Nothing was replaced, so there is nothing to tell anyone about
      // — and a spurious signal would make every screen reload for no
      // reason while the user is looking at an error.
      final cubit = BackupCubit(backup);
      final before = dataResetNotifier.generation;

      await cubit.confirmRestore('not a backup at all');

      expect(cubit.state, isA<BackupFailed>());
      expect(dataResetNotifier.generation, before);

      await cubit.close();
    });
  });

  // ======================================================================
  group('backup file names', () {
    test('are sortable, and legal on every platform', () {
      final name = BackupCubit.buildFileName(DateTime(2026, 8, 28, 9, 35));

      expect(name, 'utanglista-backup-2026-08-28-0935.json');

      // A colon is illegal in a Windows filename and awkward in a
      // share sheet; these files land in Downloads folders and chat
      // threads where the name is all there is to go on.
      expect(name, isNot(contains(':')));
    });

    test('pad single-digit months, days and times', () {
      expect(
        BackupCubit.buildFileName(DateTime(2026, 1, 5, 7, 4)),
        'utanglista-backup-2026-01-05-0704.json',
      );
    });
  });
}

/// Keeps the "one past the current format" figure in one place, so a
/// format bump does not quietly turn that test into a no-op.
abstract final class BackupEnvelopeVersions {
  static const int next = 99;
}
