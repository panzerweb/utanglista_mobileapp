import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      beforeOpen: (details) async {
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
      print('Database is connected and created');
      return result.read<int>('1') == 1;
    } catch (e) {
      print('Database connection error: $e');
      return false;
    }
  }
}
