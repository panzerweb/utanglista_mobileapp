import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/features/stores/data/datasource/store_local_data_source.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';
import 'package:utanglista_mobileapp/features/stores/domain/repositories/store_repository.dart';

void main() {
  /*
    ----------------------------------------------------------------
    The §19 range, on its own.
    ----------------------------------------------------------------
  */
  group('InterestRate (§19)', () {
    test('parses what a user actually types', () {
      expect(InterestRate.tryParsePercent('2')!.basisPoints, 200);
      expect(InterestRate.tryParsePercent('2.5')!.basisPoints, 250);
      expect(InterestRate.tryParsePercent('2.50')!.basisPoints, 250);
      expect(InterestRate.tryParsePercent(' 2.5 % ')!.basisPoints, 250);
      expect(InterestRate.tryParsePercent('0')!.basisPoints, 0);
    });

    test("'2.5' is two and a half percent, not two point oh five", () {
      // Pad right, never left — the same trap as Money.parse.
      expect(InterestRate.tryParsePercent('2.5')!.basisPoints, 250);
      expect(InterestRate.tryParsePercent('2.05')!.basisPoints, 205);
    });

    test('rejects what is not a number', () {
      expect(InterestRate.tryParsePercent(''), isNull);
      expect(InterestRate.tryParsePercent('abc'), isNull);
      expect(InterestRate.tryParsePercent('.'), isNull);
    });

    test('accepts the whole 0%-5% range', () {
      expect(const InterestRate.fromBasisPoints(0).isValid, isTrue);
      expect(const InterestRate.fromBasisPoints(250).isValid, isTrue);
      expect(const InterestRate.fromBasisPoints(500).isValid, isTrue);
    });

    test('rejects outside it, exactly at the boundary', () {
      // The cap is an integer comparison, so 5.01% fails cleanly.
      expect(const InterestRate.fromBasisPoints(501).isValid, isFalse);
      expect(const InterestRate.fromBasisPoints(-1).isValid, isFalse);
      expect(const InterestRate.fromBasisPoints(4000).isValid, isFalse);
    });

    test('out-of-range values still parse, so the form can explain why', () {
      final rate = InterestRate.tryParsePercent('40');
      expect(rate, isNotNull);
      expect(rate!.isValid, isFalse);
    });

    test('formats without inventing precision', () {
      expect(const InterestRate.fromBasisPoints(200).formatPercent(), '2%');
      expect(const InterestRate.fromBasisPoints(250).formatPercent(), '2.5%');
      expect(const InterestRate.fromBasisPoints(205).formatPercent(), '2.05%');
      expect(const InterestRate.fromBasisPoints(0).formatPercent(), '0%');
    });

    test('round-trips through the editable form', () {
      for (final basisPoints in [0, 100, 250, 205, 500]) {
        final rate = InterestRate.fromBasisPoints(basisPoints);
        expect(
          InterestRate.tryParsePercent(rate.toEditableString()),
          rate,
          reason: 'failed to round-trip $basisPoints',
        );
      }
    });
  });

  /*
    ----------------------------------------------------------------
    Stores and their settings row.
    ----------------------------------------------------------------
  */
  group('store + settings', () {
    late AppDatabase db;
    late StoreRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = StoreRepositoryImplementation(
        StoreLocalDataSourceImplementation(db),
      );
    });

    tearDown(() async => db.close());

    test('creating a store creates its settings row too', () async {
      final id = await repository.createStore(
        StorePayloadModel(name: 'Aling Nena Store'),
      );

      // The unique index says "at most one"; the transaction is what
      // makes it "exactly one".
      final settings = await db.select(db.storeSettingsTable).get();
      expect(settings, hasLength(1));
      expect(settings.single.storeId, id);
    });

    test('interest defaults to off (§19 — it is optional)', () async {
      final id = await repository.createStore(
        StorePayloadModel(name: 'Aling Nena Store'),
      );

      final store = await repository.fetchStoreById(id);
      expect(store!.monthlyInterestEnabled, isFalse);
      expect(store.monthlyInterestRate, InterestRate.zero);
      expect(store.chargesInterest, isFalse);
    });

    test('persists interest settings given at creation', () async {
      final id = await repository.createStore(
        StorePayloadModel(
          name: 'Aling Nena Store',
          monthlyInterestEnabled: true,
          monthlyInterestRate: const InterestRate.fromBasisPoints(250),
        ),
      );

      final store = await repository.fetchStoreById(id);
      expect(store!.monthlyInterestEnabled, isTrue);
      expect(store.monthlyInterestRate.formatPercent(), '2.5%');
      expect(store.chargesInterest, isTrue);
    });

    test('interest enabled at 0% does not count as charging interest',
        () async {
      // Otherwise the UI badges a rate that would produce no records.
      final id = await repository.createStore(
        StorePayloadModel(
          name: 'Aling Nena Store',
          monthlyInterestEnabled: true,
          monthlyInterestRate: InterestRate.zero,
        ),
      );

      final store = await repository.fetchStoreById(id);
      expect(store!.monthlyInterestEnabled, isTrue);
      expect(store.chargesInterest, isFalse);
    });

    test('a failed store insert leaves no settings row behind', () async {
      // 61 characters — one over the column limit, so the store insert
      // fails and the transaction must roll back entirely.
      await expectLater(
        repository.createStore(StorePayloadModel(name: 'x' * 61)),
        throwsA(anything),
      );

      expect(await db.select(db.storesTable).get(), isEmpty);
      expect(await db.select(db.storeSettingsTable).get(), isEmpty);
    });

    test('updating interest leaves the other fields alone', () async {
      final id = await repository.createStore(
        StorePayloadModel(
          name: 'Aling Nena Store',
          description: 'Corner sari-sari',
          category: StoreCategory.retail,
        ),
      );

      await repository.updateStore(
        UpdateStorePayloadModel(
          storeId: id,
          monthlyInterestEnabled: true,
          monthlyInterestRate: const InterestRate.fromBasisPoints(200),
        ),
      );

      final store = await repository.fetchStoreById(id);
      expect(store!.monthlyInterestRate.formatPercent(), '2%');
      expect(store.name, 'Aling Nena Store');
      expect(store.description, 'Corner sari-sari');
      expect(store.category, StoreCategory.retail);
    });

    test('renaming a store does not switch interest off', () async {
      final id = await repository.createStore(
        StorePayloadModel(
          name: 'Aling Nena Store',
          monthlyInterestEnabled: true,
          monthlyInterestRate: const InterestRate.fromBasisPoints(200),
        ),
      );

      // A partial update passes null for the settings it does not touch.
      await repository.updateStore(
        UpdateStorePayloadModel(storeId: id, name: 'Nena Mini Mart'),
      );

      final store = await repository.fetchStoreById(id);
      expect(store!.name, 'Nena Mini Mart');
      expect(store.monthlyInterestEnabled, isTrue);
      expect(store.monthlyInterestRate.formatPercent(), '2%');
    });

    test('a store with no settings row still reads as interest off',
        () async {
      final id = await repository.createStore(
        StorePayloadModel(name: 'Aling Nena Store'),
      );

      await (db.delete(
        db.storeSettingsTable,
      )..where((t) => t.storeId.equals(id))).go();

      // LEFT OUTER JOIN — the store must stay readable.
      final store = await repository.fetchStoreById(id);
      expect(store, isNotNull);
      expect(store!.monthlyInterestEnabled, isFalse);
    });

    test('updating a store whose settings row is missing recreates it',
        () async {
      final id = await repository.createStore(
        StorePayloadModel(name: 'Aling Nena Store'),
      );
      await (db.delete(
        db.storeSettingsTable,
      )..where((t) => t.storeId.equals(id))).go();

      await repository.updateStore(
        UpdateStorePayloadModel(
          storeId: id,
          monthlyInterestEnabled: true,
          monthlyInterestRate: const InterestRate.fromBasisPoints(300),
        ),
      );

      // Upsert, not update — otherwise the switch would silently do
      // nothing for this store.
      final store = await repository.fetchStoreById(id);
      expect(store!.monthlyInterestEnabled, isTrue);
      expect(store.monthlyInterestRate.formatPercent(), '3%');
    });

    test('deleting a store takes its settings with it', () async {
      final id = await repository.createStore(
        StorePayloadModel(name: 'Aling Nena Store'),
      );

      await repository.deleteStore(id);

      expect(await db.select(db.storeSettingsTable).get(), isEmpty);
    });

    test('lists newest first, even within the same second', () async {
      // No delay between these on purpose. Drift stores DateTime as
      // unix seconds, so both rows carry the same timestamp and only
      // the id tiebreaker keeps the order stable.
      await repository.createStore(StorePayloadModel(name: 'First Store'));
      await repository.createStore(StorePayloadModel(name: 'Second Store'));
      await repository.createStore(StorePayloadModel(name: 'Third Store'));

      final stores = await repository.fetchStores(null);
      expect(
        stores.map((s) => s.name),
        ['Third Store', 'Second Store', 'First Store'],
      );
    });

    test('an unrecognised category reads as null, not a crash', () async {
      final id = await repository.createStore(
        StorePayloadModel(name: 'Aling Nena Store'),
      );
      await db.customStatement(
        "UPDATE stores_table SET category = 'wholesale' WHERE id = ?",
        [id],
      );

      // A category removed in a later version must not strand the user
      // on a list they cannot load.
      final store = await repository.fetchStoreById(id);
      expect(store!.category, isNull);
    });
  });
}
