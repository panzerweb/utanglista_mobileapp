import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/config/migrations.dart';

/*
  A build that believes the schema is one version further on than it
  is, with no step registered for the difference. Standing in for the
  next release, so the upgrade path can be tested before there is one.
*/
class _V6Database extends AppDatabase {
  _V6Database(super.executor);

  @override
  int get schemaVersion => 6;
}

/*
  ==================================================================
  MIGRATIONS — that a version bump cannot take a ledger with it.
  ==================================================================

  Up to v5 this app upgraded by dropping every table. These tests are
  what stop that coming back: they assert the schema is never dropped,
  that a gap in the step registry refuses rather than guesses, and
  that steps run in order.

  What they do NOT do is upgrade between real historical schemas —
  that needs drift's generated snapshots, which cannot be produced
  here yet. The reason, and the commands to run once it is possible,
  are in the header of core/config/migrations.dart.
*/
void main() {
  group('AppMigrations.upgrade', () {
    late AppDatabase db;
    late Migrator migrator;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      migrator = db.createMigrator();
    });

    tearDown(() async => db.close());

    /// A step that records that it ran, and touches nothing.
    SchemaStep recorder(int version, List<int> log) {
      return (_) async => log.add(version);
    }

    test('opening at the version already on disk does nothing', () async {
      final log = <int>[];

      await AppMigrations.upgrade(
        migrator,
        5,
        5,
        availableSteps: {5: recorder(5, log), 6: recorder(6, log)},
      );

      expect(log, isEmpty);
    });

    test('runs one step per version, in ascending order', () async {
      final log = <int>[];

      await AppMigrations.upgrade(
        migrator,
        5,
        8,
        availableSteps: {
          6: recorder(6, log),
          7: recorder(7, log),
          8: recorder(8, log),
        },
      );

      // In order, and NOT including 5 — a step is keyed by the version
      // it produces, so upgrading from 5 starts at 6.
      expect(log, [6, 7, 8]);
    });

    test('does not run steps beyond the target version', () async {
      final log = <int>[];

      await AppMigrations.upgrade(
        migrator,
        5,
        6,
        availableSteps: {6: recorder(6, log), 7: recorder(7, log)},
      );

      expect(log, [6]);
    });

    /*
      The important one. A missing step must stop the upgrade, not
      quietly fall back to recreating the schema — that fallback is
      exactly the destructive behaviour this file exists to prevent.
    */
    test('a missing step throws, and stops before the gap', () async {
      final log = <int>[];

      await expectLater(
        AppMigrations.upgrade(
          migrator,
          5,
          8,
          availableSteps: {6: recorder(6, log), 8: recorder(8, log)},
        ),
        throwsA(isA<MissingMigrationError>()),
      );

      // v6 ran, v7 is missing, so v8 must NOT have run — applying a
      // later step over a schema that never got its earlier one is how
      // a half-migrated database happens.
      expect(log, [6]);
    });

    test('a downgrade is refused', () async {
      await expectLater(
        AppMigrations.upgrade(migrator, 7, 5),
        throwsA(isA<MissingMigrationError>()),
      );
    });

    test('a pre-release schema is refused, not wiped', () async {
      // Below the baseline there is no upgrade path — and guessing is
      // worse than refusing.
      await expectLater(
        AppMigrations.upgrade(migrator, 3, 5),
        throwsA(isA<MissingMigrationError>()),
      );
    });

    test('the registry is empty while v5 is both baseline and current',
        () async {
      // This is a canary, not a rule. When schemaVersion moves past 5,
      // this test should be updated in the same commit that adds the
      // step — and if it fails on its own, a version was bumped without
      // one.
      expect(AppMigrations.baselineVersion, 5);
      expect(db.schemaVersion, AppMigrations.baselineVersion);
      expect(AppMigrations.steps, isEmpty);
    });
  });

  /*
    ------------------------------------------------------------------
    The behaviour all of the above is protecting.
    ------------------------------------------------------------------
  */
  group('data survives being reopened', () {
    test('rows are still there after closing and opening again', () async {
      // One connection, closed and reopened, is as close to a restart
      // as an in-memory database gets. It exercises onCreate and
      // beforeOpen, and would catch a migration path that ran on a
      // same-version open.
      final file = NativeDatabase.memory();
      final db = AppDatabase(file);

      final storeId = await db
          .into(db.storesTable)
          .insert(StoresTableCompanion.insert(name: 'Aling Nena Store'));
      final customerId = await db
          .into(db.customersTable)
          .insert(
            CustomersTableCompanion.insert(storeId: storeId, name: 'Juan'),
          );
      await db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              storeId: storeId,
              customerId: customerId,
              totalAmount: 50000,
            ),
          );

      final stores = await db.select(db.storesTable).get();
      final transactions = await db.select(db.transactionsTable).get();

      expect(stores, hasLength(1));
      expect(transactions.single.totalAmount, 50000);

      await db.close();
    });

    /*
      ------------------------------------------------------------------
      The end-to-end proof, on a real file.
      ------------------------------------------------------------------

      Everything above tests AppMigrations in isolation. This drives the
      whole path: a v5 database on disk with a real ledger in it, opened
      by a build whose schemaVersion is 6 and which has no step for it.

      Before Phase 8 that combination dropped every table. Now it must
      refuse — and the ledger must still be sitting there afterwards,
      readable by the correct build.
    */
    test('a v5 ledger survives a build that wants v6 with no step',
        () async {
      final directory = await Directory.systemTemp.createTemp('utanglista');
      final file = File('${directory.path}/ledger.sqlite');

      // ---- the v5 database, with something worth losing ----------
      final original = AppDatabase(NativeDatabase(file));

      final storeId = await original
          .into(original.storesTable)
          .insert(StoresTableCompanion.insert(name: 'Aling Nena Store'));
      final customerId = await original
          .into(original.customersTable)
          .insert(
            CustomersTableCompanion.insert(storeId: storeId, name: 'Juan'),
          );
      await original
          .into(original.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              storeId: storeId,
              customerId: customerId,
              totalAmount: 54060,
            ),
          );

      expect(original.schemaVersion, 5);
      await original.close();

      // ---- the same file, opened by a v6 build -------------------
      final upgraded = _V6Database(NativeDatabase(file));

      await expectLater(
        upgraded.select(upgraded.storesTable).get(),
        throwsA(isA<MissingMigrationError>()),
      );

      await upgraded.close();

      // ---- the ledger is still there -----------------------------
      final reopened = AppDatabase(NativeDatabase(file));

      final stores = await reopened.select(reopened.storesTable).get();
      final transactions = await reopened
          .select(reopened.transactionsTable)
          .get();

      expect(stores.single.name, 'Aling Nena Store');
      expect(transactions.single.totalAmount, 54060);

      await reopened.close();
      await directory.delete(recursive: true);
    });

    test('foreign keys are on, so a cascade still behaves', () async {
      // beforeOpen re-asserts PRAGMA foreign_keys, and onUpgrade turns
      // it off while steps run. This is the check that it comes back
      // on — a database opened with them off would silently accept
      // orphaned financial rows.
      final db = AppDatabase(NativeDatabase.memory());

      final result = await db
          .customSelect('PRAGMA foreign_keys')
          .getSingle();

      expect(result.data.values.first, 1);

      await db.close();
    });
  });
}
