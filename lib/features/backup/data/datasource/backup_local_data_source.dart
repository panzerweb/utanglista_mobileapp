import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/features/backup/data/model/backup_envelope_model.dart';

/*
  ==================================================================
  READING AND WRITING THE WHOLE DATABASE.
  ==================================================================

  ------------------------------------------------------------------
  Why this is generic SQL rather than eight hand-written mappers.
  ------------------------------------------------------------------

  The obvious implementation writes a serialiser per table: read the
  stores, map their columns, read the customers, map theirs. It reads
  well and it rots immediately — the next column added to
  `app_tables.dart` is simply MISSING from every backup taken
  afterwards, and nothing fails. The bug surfaces months later, on a
  restore, as a column of nulls in someone's ledger.

  So the tables are read through `SELECT *` and written back from
  whatever column names came out. A new column is carried
  automatically, because this file never enumerates them. It is the
  one place in the app where being schema-agnostic is safer than being
  explicit.

  The table names are not user input — they come from drift's own
  `allTables` — so the interpolation below cannot be injected into.
  Row VALUES are always bound as variables, never interpolated.
*/
abstract class BackupLocalDataSource {
  Future<BackupEnvelopeModel> exportAll();
  Future<int> restore(BackupEnvelopeModel envelope);
  int get schemaVersion;
}

class BackupLocalDataSourceImplementation implements BackupLocalDataSource {
  final AppDatabase database;

  BackupLocalDataSourceImplementation(this.database);

  /*
    ------------------------------------------------------------------
    ** DEPENDENCY ORDER — parents first. **
    ------------------------------------------------------------------

    Rows are INSERTED in this order and DELETED in the reverse, so a
    foreign key is never dangling at any point in between.

    That ordering is doing real work, because SQLite ignores
    `PRAGMA foreign_keys` changes INSIDE a transaction — the usual
    "turn them off, bulk load, turn them back on" trick is unavailable
    here, and turning them off outside the transaction would leave a
    window where a failed restore could commit orphaned financial
    rows. Getting the order right instead means the constraints stay
    live throughout and still never fire.
  */
  static const List<String> _writeOrder = [
    'stores_table',
    'store_settings_table',
    'customers_table',
    'products_table',
    'transactions_table',
    'transactions_item_table',
    'payments_table',
    'interest_records_table',
  ];

  @override
  int get schemaVersion => database.schemaVersion;

  /*
    A table that exists in the schema but not in [_writeOrder] would be
    silently left out of every backup — the exact failure the generic
    SELECT above was written to avoid, reintroduced by a list.

    So the list is checked against the real schema on every use. This
    fails loudly the first time someone adds a table and forgets, which
    is in development, not on a device.
  */
  List<String> _orderedTables() {
    final actual = database.allTables
        .map((table) => table.actualTableName)
        .toSet();

    final missing = actual.difference(_writeOrder.toSet());

    if (missing.isNotEmpty) {
      throw AppFailure(
        code: 'BACKUP_SCHEMA_DRIFT',
        message:
            'Backup is not set up for every part of this version of '
            'the app: ${missing.join(', ')}. Do not rely on a backup '
            'until this is fixed.',
      );
    }

    return _writeOrder.where(actual.contains).toList();
  }

  @override
  Future<BackupEnvelopeModel> exportAll() async {
    try {
      final tables = <String, List<Map<String, Object?>>>{};

      for (final tableName in _orderedTables()) {
        final rows = await database
            .customSelect('SELECT * FROM "$tableName"')
            .get();

        // `data` is the raw column map: ints, doubles, strings, nulls.
        // Exactly what SQLite holds, which is what a backup should be.
        tables[tableName] = rows.map((row) => row.data).toList();
      }

      return BackupEnvelopeModel.now(
        schemaVersion: database.schemaVersion,
        exportedAt: DateTime.now(),
        tables: tables,
      );
    } catch (e) {
      rethrow;
    }
  }

  /*
    ------------------------------------------------------------------
    RESTORE — the most destructive thing this app can do.
    ------------------------------------------------------------------

    Everything the user currently has is replaced by what is in the
    file. There is no merge: two databases of the same shape both using
    autoincrement ids cannot be merged without rewriting every foreign
    key, and a merge that guessed wrong would corrupt a ledger rather
    than replace one.

    So the whole thing — every delete and every insert — happens in ONE
    `database.transaction { }`. Either the restore lands complete, or
    the database is exactly as it was. A file that turns out to be
    damaged halfway through cannot leave a half-restored ledger, which
    would be worse than either outcome: numbers that look plausible and
    are wrong.

    IDS ARE PRESERVED, deliberately. Every foreign key in the file
    refers to them, and rewriting them on the way in would mean
    remapping eight tables' worth of references — the one operation
    here with a real chance of silently mis-linking a payment to the
    wrong customer.
  */
  @override
  Future<int> restore(BackupEnvelopeModel envelope) async {
    try {
      final ordered = _orderedTables();

      /*
        A table in the file that this build does not have means the
        backup came from a version that knows something this one does
        not. Checked BEFORE the transaction opens — there is no reason
        to start deleting to discover this.
      */
      final unknown = envelope.tables.keys.toSet().difference(ordered.toSet());

      if (unknown.isNotEmpty) {
        throw AppFailure(
          code: 'BACKUP_TOO_NEW',
          message:
              'This backup contains data this version of UtangLista '
              'does not recognise. Update the app, then restore it.',
        );
      }

      return await database.transaction(() async {
        // Children first, so nothing is ever orphaned mid-delete.
        for (final tableName in ordered.reversed) {
          await database.customStatement('DELETE FROM "$tableName"');
        }

        var inserted = 0;

        for (final tableName in ordered) {
          final rows = envelope.tables[tableName] ?? const [];

          for (final row in rows) {
            if (row.isEmpty) continue;

            final columns = row.keys.toList();
            final placeholders = List.filled(columns.length, '?').join(', ');
            final quoted = columns.map((c) => '"$c"').join(', ');

            // Values bound, never interpolated.
            await database.customStatement(
              'INSERT INTO "$tableName" ($quoted) VALUES ($placeholders)',
              columns.map((column) => row[column]).toList(),
            );

            inserted++;
          }
        }

        /*
          Nothing is done to sqlite_sequence on purpose.

          Every id above was inserted explicitly, and SQLite raises an
          AUTOINCREMENT table's counter to any larger rowid it is
          handed — so after a restore the counter is already at least
          the highest id in the file, and the next new customer cannot
          collide with a restored one.

          When the restored data is SMALLER than what it replaced the
          counter stays high, and the next id simply skips a range.
          That is a gap in the numbering, not a fault: ids are
          identity here, never a count of anything.
        */
        return inserted;
      });
    } catch (e) {
      rethrow;
    }
  }
}
