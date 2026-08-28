import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import './migrations.dart';
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
        STEPWISE — see core/config/migrations.dart.

        This used to drop every table and recreate the schema, which
        was acceptable exactly once: v5 converted the money columns
        from REAL pesos to INTEGER centavos while no real data existed
        anywhere.

        That is over. v5 is the released baseline, and from here every
        version bump runs a registered step or refuses to open. A
        database that will not open keeps its rows; a database that was
        dropped does not.

        Foreign keys are turned OFF for the duration. SQLite cannot add
        or rebuild a constrained table with them live, and a step that
        recreates a table would otherwise trip its own referential
        checks halfway through. They go back on in beforeOpen, which
        runs after this.
      */
      onUpgrade: (m, from, to) async {
        await customStatement('PRAGMA foreign_keys = OFF');

        await AppMigrations.upgrade(m, from, to);

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
