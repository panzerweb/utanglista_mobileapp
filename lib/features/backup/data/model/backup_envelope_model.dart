import 'dart:convert';

import 'package:utanglista_mobileapp/core/error/error_definition.dart';

/*
  ==================================================================
  THE BACKUP FILE FORMAT.
  ==================================================================

  A backup is one JSON object. It is the only thing standing between a
  store owner and a lost phone, so the shape is deliberately boring
  and deliberately self-describing:

      {
        "app": "utanglista",
        "formatVersion": 1,
        "schemaVersion": 5,
        "exportedAt": "2026-08-28T09:35:12.000Z",
        "tables": {
          "stores_table": [ { "id": 1, "name": "Aling Nena", ... } ],
          "customers_table": [ ... ],
          ...
        }
      }

  ------------------------------------------------------------------
  Why every value is a RAW COLUMN VALUE.
  ------------------------------------------------------------------

  Money is exported as the integer centavos it is stored as — never
  "₱1,250.75", never 1250.75. §26 forbids floating point for exact
  amounts, and a formatted string would have to be parsed back through
  a currency format that may differ by locale. The rule from CLAUDE.md
  §4.8 holds here too: the int is the money, and only the widget layer
  ever formats it.

  Dates are exported as the unix seconds drift stores. Booleans as the
  0/1 SQLite holds. In every case the backup carries what the DATABASE
  had, so a restore is a copy rather than a re-interpretation.

  ------------------------------------------------------------------
  The two version numbers, and why there are two.
  ------------------------------------------------------------------

    formatVersion   this envelope's own shape. Bumped if the wrapper
                    changes — a new top-level key, a different way of
                    holding the rows.

    schemaVersion   the database schema the rows came from. Bumped by
                    every table change (see core/config/migrations).

  They move independently: adding a column bumps the schema and leaves
  the format alone. Recording only one of them would eventually mean
  guessing at the other.
*/
class BackupEnvelopeModel {
  /// Marks the file as ours. A JSON file that is not a UtangLista
  /// backup must be refused before anything is read out of it.
  static const String appTag = 'utanglista';

  /// The envelope shape this build writes.
  static const int currentFormatVersion = 1;

  final String app;
  final int formatVersion;
  final int schemaVersion;
  final DateTime exportedAt;

  /// SQL table name -> its rows, each a column-name/value map holding
  /// raw SQLite values.
  final Map<String, List<Map<String, Object?>>> tables;

  const BackupEnvelopeModel({
    required this.app,
    required this.formatVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.tables,
  });

  BackupEnvelopeModel.now({
    required this.schemaVersion,
    required this.tables,
    required this.exportedAt,
  }) : app = appTag,
       formatVersion = currentFormatVersion;

  int get rowCount =>
      tables.values.fold(0, (total, rows) => total + rows.length);

  int rowsIn(String tableName) => tables[tableName]?.length ?? 0;

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert({
      'app': app,
      'formatVersion': formatVersion,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'tables': tables,
    });
  }

  /*
    ------------------------------------------------------------------
    Parsing is where a restore is made safe.
    ------------------------------------------------------------------

    Everything below runs BEFORE a single row of the user's database is
    touched. A file that is malformed, truncated, from another app, or
    from a future version of this one must be rejected while the
    existing ledger is still completely intact.

    Every failure is an AppFailure with a message a store owner can act
    on — "this is not a backup file" is useful, a JSON parser's
    "FormatException: Unexpected character (at line 1)" is not.
  */
  factory BackupEnvelopeModel.parse(String source) {
    final Object? decoded;

    try {
      decoded = jsonDecode(source);
    } catch (_) {
      throw AppFailure(
        code: 'INVALID_BACKUP',
        message:
            'This file is not readable as a backup. Choose the .json '
            'file UtangLista exported.',
      );
    }

    if (decoded is! Map<String, Object?>) {
      throw AppFailure(
        code: 'INVALID_BACKUP',
        message: 'This file is not a UtangLista backup.',
      );
    }

    if (decoded['app'] != appTag) {
      throw AppFailure(
        code: 'INVALID_BACKUP',
        message:
            'This file was not exported by UtangLista, so it cannot be '
            'restored.',
      );
    }

    final formatVersion = decoded['formatVersion'];
    final schemaVersion = decoded['schemaVersion'];

    if (formatVersion is! int || schemaVersion is! int) {
      throw AppFailure(
        code: 'INVALID_BACKUP',
        message: 'This backup is missing its version information.',
      );
    }

    // A backup from a LATER version of the app may hold keys and rows
    // this build has no idea what to do with. Refusing is the only
    // honest answer.
    if (formatVersion > currentFormatVersion) {
      throw AppFailure(
        code: 'BACKUP_TOO_NEW',
        message:
            'This backup was made by a newer version of UtangLista. '
            'Update the app, then restore it.',
      );
    }

    final rawTables = decoded['tables'];

    if (rawTables is! Map<String, Object?>) {
      throw AppFailure(
        code: 'INVALID_BACKUP',
        message: 'This backup has no data in it.',
      );
    }

    final tables = <String, List<Map<String, Object?>>>{};

    for (final entry in rawTables.entries) {
      final rows = entry.value;

      if (rows is! List) {
        throw AppFailure(
          code: 'INVALID_BACKUP',
          message: 'This backup is damaged: "${entry.key}" is unreadable.',
        );
      }

      tables[entry.key] = rows.map((row) {
        if (row is! Map<String, Object?>) {
          throw AppFailure(
            code: 'INVALID_BACKUP',
            message: 'This backup is damaged: "${entry.key}" is unreadable.',
          );
        }

        return row;
      }).toList();
    }

    /*
      exportedAt is INFORMATION, not a guard — it is shown to the user
      so they can tell one backup from another. A file with an
      unparseable date is still restorable, so this falls back rather
      than refusing.
    */
    final exportedAt =
        DateTime.tryParse(decoded['exportedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return BackupEnvelopeModel(
      app: appTag,
      formatVersion: formatVersion,
      schemaVersion: schemaVersion,
      exportedAt: exportedAt,
      tables: tables,
    );
  }
}
