import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import './tables/app_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    StoresTable,
    CustomersTable,
    ProductsTable,
    TransactionsTable,
    TransactionsItemTable,
    PaymentsTable,
    StoreSettingsTable,
    InterestRecordsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },

      /*
        DESTRUCTIVE UNTIL v5 — pre-release only.

        v5 converts every monetary column from REAL pesos to INTEGER
        centavos and adds NOT NULL columns with no sensible backfill
        (interest period_key). There is no user data to protect yet, so
        the schema is dropped and recreated rather than migrated.

        This is the LAST version where that is acceptable. From the
        first release onward, add a stepwise `from(x).to(y)` branch here
        and verify it with drift's migration test tooling — silently
        wiping a store owner's ledger is the worst bug this app could
        ship.
      */
      onUpgrade: (m, from, to) async {
        // Foreign keys must be off while tables are dropped, otherwise
        // the drop order itself trips the constraints.
        await customStatement('PRAGMA foreign_keys = OFF');

        for (final entity in allSchemaEntities.toList().reversed) {
          await m.drop(entity);
        }
        await m.createAll();

        await customStatement('PRAGMA foreign_keys = ON');
      },

      beforeOpen: (details) async {
        // Drift opens each connection with foreign keys OFF by default,
        // so this has to be re-asserted here, not just in onCreate.
        // Every cascade and restrict rule in app_tables.dart depends on it.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'utanglista_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  // Method to verify database connection
  Future<bool> testConnection() async {
    try {
      final result = await customSelect('SELECT 1').getSingle();
      debugPrint('Database is connected and created');
      return result.read<int>('1') == 1;
    } catch (e) {
      debugPrint('Database connection error: $e');
      return false;
    }
  }
}
