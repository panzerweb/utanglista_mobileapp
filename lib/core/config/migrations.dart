import 'package:drift/drift.dart';

/*
  ==================================================================
  SCHEMA MIGRATIONS — the code that must never lose a ledger.
  ==================================================================

  Up to and including v5 this app upgraded DESTRUCTIVELY: every table
  was dropped and recreated. That was defensible exactly once, while
  there was no real data anywhere and the money columns were being
  converted from floating-point pesos to integer centavos.

  From the first release onward it is not defensible at all. A store
  owner's ledger is the only copy of what their customers owe. Losing
  it to a version bump is the worst bug this app could ship — worse
  than any crash, because a crash is visible and recoverable and this
  is neither.

  So this file replaces "drop everything" with a stepwise upgrade:

    v5 is the BASELINE — the schema of the first release.
    Every later version registers exactly one step in [steps].
    An upgrade runs each step between `from` and `to`, in order.
    Anything it cannot account for THROWS rather than guesses.

  ------------------------------------------------------------------
  Why an unregistered step throws instead of recreating the schema.
  ------------------------------------------------------------------

  The tempting fallback — "if no step is registered, just call
  createAll" — silently drops back to the destructive behaviour at the
  exact moment a developer forgot something. The failure would land on
  a user's device, not in development.

  Throwing is loud, and a database that refuses to open keeps its data.
  A missing step is then a shipping bug that is fixed by shipping the
  step, with every row still there. That is a recoverable Tuesday
  rather than an unrecoverable one.

  ------------------------------------------------------------------
  ADDING A MIGRATION — the whole checklist.
  ------------------------------------------------------------------

    1. Change the tables in `tables/app_tables.dart`.
    2. Re-run build_runner.
    3. Bump `schemaVersion` in `app_database.dart` to N.
    4. Register a step under key N in [steps] below, using the
       Migrator API (`addColumn`, `createTable`, `createIndex`, ...).
       Never `deleteTable` a table holding financial history.
    5. Add a test to `test/core/migration_test.dart` that seeds data
       at N-1, upgrades, and asserts the rows survived with the right
       values.

  Step N is the migration FROM N-1 TO N — it is keyed by the version
  it produces.

  ------------------------------------------------------------------
  On drift's own migration tooling.
  ------------------------------------------------------------------

  drift ships `drift_dev schema dump` / `schema steps`, which generate
  versioned snapshots and let a test upgrade between real historical
  schemas. That is the belt to this file's braces and it should be
  adopted as soon as it runs here:

      dart run drift_dev schema dump lib/core/config/app_database.dart drift_schemas/
      dart run drift_dev schema generate drift_schemas/ test/generated_migrations/

  It currently does not run in this project: drift_dev is held at
  2.34.0 by the Flutter SDK's pinned analyzer, and 2.34.0's schema
  command is broken against drift 2.34.3 (it resolves the drift3
  preview `GeneratedDatabase`, which has no `allSchemaEntities`).
  Re-try the commands above after a Flutter SDK bump lets drift_dev
  move to 2.34.5 or later.

  Until then the tests in `test/core/migration_test.dart` cover the
  parts that matter most: that nothing is dropped, that a gap is
  refused, and that steps run in order.
*/

/// One version's worth of schema change. Keyed by the version it
/// produces — step 6 upgrades a v5 database to v6.
typedef SchemaStep = Future<void> Function(Migrator migrator);

/// Thrown when an upgrade cannot be performed safely. The database is
/// left untouched: refusing to open preserves the data, which is the
/// entire point.
class MissingMigrationError extends Error {
  final String message;

  MissingMigrationError(this.message);

  @override
  String toString() => 'MissingMigrationError: $message';
}

abstract final class AppMigrations {
  /*
    The schema of the first release. Versions below this only ever
    existed on development devices, and the destructive upgrade that
    got them here is gone — so there is no path from them.
  */
  static const int baselineVersion = 5;

  /*
    One entry per version above the baseline.

    EMPTY IS CORRECT TODAY: v5 is both the baseline and the current
    schema, so no upgrade has ever needed to run. The first entry
    arrives with the first post-release schema change.

        static const Map<int, SchemaStep> steps = {
          6: _v6AddCustomerAddress,
        };

        static Future<void> _v6AddCustomerAddress(Migrator m) async {
          await m.addColumn(m.database.customersTable, ...);
        }
  */
  static const Map<int, SchemaStep> steps = {};

  /*
    Runs every step between [from] and [to].

    [availableSteps] exists for tests, which need to drive the ordering
    and gap logic without inventing real schema changes. Production
    callers pass nothing and get [steps].
  */
  static Future<void> upgrade(
    Migrator migrator,
    int from,
    int to, {
    Map<int, SchemaStep>? availableSteps,
  }) async {
    final registry = availableSteps ?? steps;

    // Opening at the version already on disk. Not an error, and not
    // something to do work for.
    if (from == to) return;

    /*
      A DOWNGRADE — the installed app is older than the database.
      Usually a sideloaded older APK.

      There is nothing safe to do here: the newer schema may hold
      columns this build cannot read, and "fixing" that means deleting
      them. Refuse, and let the user reinstall the newer version with
      their data intact.
    */
    if (to < from) {
      throw MissingMigrationError(
        'This database was written by a newer version of UtangLista '
        '(schema v$from; this build understands v$to). Install the '
        'newer version again — the data is intact.',
      );
    }

    /*
      Below the baseline: a pre-release development database. The
      destructive upgrade that used to handle these is deliberately
      gone, and guessing at a v3 schema is not something to do with
      someone's data.
    */
    if (from < baselineVersion) {
      throw MissingMigrationError(
        'This database predates the first release (schema v$from, '
        'baseline v$baselineVersion). There is no upgrade path from a '
        'pre-release schema; reinstall the app to start fresh.',
      );
    }

    for (var version = from + 1; version <= to; version++) {
      final step = registry[version];

      if (step == null) {
        // See the header: this is loud on purpose. A silent createAll
        // here would be the destructive behaviour coming back in
        // through the side door.
        throw MissingMigrationError(
          'No migration registered for schema v$version. The database '
          'was left untouched. Register a step in AppMigrations.steps '
          'and ship it — the data is still there.',
        );
      }

      await step(migrator);
    }
  }
}
