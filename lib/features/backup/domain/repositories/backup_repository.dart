import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/features/backup/data/datasource/backup_local_data_source.dart';
import 'package:utanglista_mobileapp/features/backup/data/model/backup_envelope_model.dart';
import 'package:utanglista_mobileapp/features/backup/domain/entities/backup_summary.dart';

/*
  ==================================================================
  BACKUP AND RESTORE, as the rest of the app sees it.
  ==================================================================

  Export produces a STRING, and import consumes one. Neither touches
  the file system, the share sheet or a file picker — those belong to
  the presentation layer, which is the only part of the app allowed to
  know that a backup leaves the device through the OS.

  That split is what keeps this testable: every rule below is
  exercised by writing a string and reading it back, with no plugin
  and no platform channel anywhere near it.

  And it is worth being explicit, since this is the one feature that
  moves data OFF the phone: nothing here opens a socket. The share
  sheet is the operating system's, the destination is the user's
  choice, and the app remains offline in the sense CLAUDE.md means it.
*/
abstract class BackupRepository {
  /// The whole database as a backup file's contents.
  Future<String> exportToJson();

  /// Reads a backup WITHOUT applying it, so the user can be told what
  /// they are about to replace their data with.
  Future<BackupSummary> inspect(String json);

  /// Replaces everything. Returns how many rows were written.
  Future<int> restoreFromJson(String json);
}

class BackupRepositoryImplementation implements BackupRepository {
  final BackupLocalDataSource localDataSource;

  BackupRepositoryImplementation(this.localDataSource);

  // ========================================================
  // ** BACKUP METHODS **
  // ========================================================
  @override
  Future<String> exportToJson() {
    return repositoryGuard(() async {
      final envelope = await localDataSource.exportAll();
      return envelope.toJsonString();
    }, failureMessage: "Could not create a backup of your data.");
  }

  @override
  Future<BackupSummary> inspect(String json) {
    return repositoryGuard(() async {
      final envelope = BackupEnvelopeModel.parse(json);
      _requireCompatibleSchema(envelope);

      return _summarise(envelope);
    }, failureMessage: "Could not read this backup file.");
  }

  /*
    ------------------------------------------------------------------
    The order here is the safety property.
    ------------------------------------------------------------------

    Parse, then check the schema, and only then hand anything to the
    datasource. Every rejection above happens while the user's existing
    data is untouched — and the datasource's own write is a single
    transaction, so the one step that CAN fail destructively cannot
    leave anything half-done.

    `async` is not decoration. A method that validates and throws
    before its first await throws SYNCHRONOUSLY, and a caller using
    .catchError never sees it — the Phase 4 bug, in a method where the
    failure mode is a wiped ledger rather than a missing snackbar.
  */
  @override
  Future<int> restoreFromJson(String json) async {
    return repositoryGuard(() async {
      final envelope = BackupEnvelopeModel.parse(json);
      _requireCompatibleSchema(envelope);

      if (envelope.rowCount == 0) {
        // Restoring an empty backup would silently delete everything
        // and put nothing back. If that is genuinely what someone
        // wants, deleting their stores says so out loud.
        throw AppFailure(
          code: 'EMPTY_BACKUP',
          message:
              'This backup is empty. Restoring it would remove '
              'everything and put nothing back.',
        );
      }

      return localDataSource.restore(envelope);
    }, failureMessage: "Could not restore this backup.");
  }

  // ========================================================

  /*
    A backup carries the schema version its rows came from, and rows
    only fit the shape they were written for.

    V1 requires an exact match. A backup from an OLDER schema would
    have to be migrated column by column before it could be inserted —
    real work, and work whose bugs cost people their ledgers, so it is
    not being guessed at here. When the schema first moves past v5,
    this is the method that gains that path; until then a mismatch is
    refused with a message that says which way the mismatch runs.
  */
  void _requireCompatibleSchema(BackupEnvelopeModel envelope) {
    final current = localDataSource.schemaVersion;

    if (envelope.schemaVersion == current) return;

    if (envelope.schemaVersion > current) {
      throw AppFailure(
        code: 'BACKUP_TOO_NEW',
        message:
            'This backup was made by a newer version of UtangLista. '
            'Update the app, then restore it.',
      );
    }

    throw AppFailure(
      code: 'BACKUP_TOO_OLD',
      message:
          'This backup was made by an older version of UtangLista and '
          'cannot be restored by this one.',
    );
  }

  BackupSummary _summarise(BackupEnvelopeModel envelope) {
    return BackupSummary(
      exportedAt: envelope.exportedAt,
      storeCount: envelope.rowsIn('stores_table'),
      customerCount: envelope.rowsIn('customers_table'),
      productCount: envelope.rowsIn('products_table'),
      transactionCount: envelope.rowsIn('transactions_table'),
      paymentCount: envelope.rowsIn('payments_table'),
      interestRecordCount: envelope.rowsIn('interest_records_table'),
    );
  }
}
