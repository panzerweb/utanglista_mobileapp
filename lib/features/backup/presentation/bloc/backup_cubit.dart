import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/services/data_reset_notifier.dart';
import 'package:utanglista_mobileapp/features/backup/domain/entities/backup_summary.dart';
import 'package:utanglista_mobileapp/features/backup/domain/repositories/backup_repository.dart';

/*
  ------------------------------------------------------------------
  Backup states: a sealed hierarchy, per CLAUDE.md §4.4.
  ------------------------------------------------------------------

  These are mutations, not a list — every outcome is a one-shot event
  the screen reacts to exactly once (share this file, show this error,
  say the restore is done). A status enum would leave the listener
  asking "is this the same success I already handled?" every rebuild.
*/
sealed class BackupState {}

class BackupIdle extends BackupState {}

class BackupExporting extends BackupState {}

/// The file is ready. [json] has not left the app yet — handing it to
/// the share sheet is the screen's job, because sharing is a platform
/// concern and this layer stays testable without one.
class BackupExported extends BackupState {
  final String json;
  final String suggestedFileName;

  BackupExported({required this.json, required this.suggestedFileName});
}

class BackupReadingFile extends BackupState {}

/// A file was picked and read, and it is a valid backup. Nothing has
/// been written yet — this is the state the confirmation dialog is
/// built from, so the user is told what they are about to replace
/// their data WITH before anything replaces it.
class BackupReadyToRestore extends BackupState {
  final String json;
  final BackupSummary summary;

  BackupReadyToRestore({required this.json, required this.summary});
}

class BackupRestoring extends BackupState {}

class BackupRestored extends BackupState {
  final int rowCount;

  BackupRestored(this.rowCount);
}

class BackupFailed extends BackupState {
  final AppFailure error;

  BackupFailed(this.error);
}

/*
  ==================================================================
  BACKUP CUBIT.
  ==================================================================

  Restore is deliberately TWO steps — read, then apply — with the
  confirmation between them. A single "restore this file" call would
  have to either confirm before knowing whether the file is any good
  (asking someone to approve replacing their ledger with a file that
  turns out to be a photo), or confirm after writing, which is not a
  confirmation at all.
*/
class BackupCubit extends Cubit<BackupState> {
  final BackupRepository repository;

  BackupCubit(this.repository) : super(BackupIdle());

  Future<void> exportBackup() async {
    emit(BackupExporting());

    try {
      final json = await repository.exportToJson();

      emit(
        BackupExported(
          json: json,
          suggestedFileName: buildFileName(DateTime.now()),
        ),
      );
    } on AppFailure catch (e) {
      emit(BackupFailed(e));
    } catch (e) {
      emit(
        BackupFailed(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  /// Step one of a restore: read the picked file and describe it.
  Future<void> prepareRestore(String json) async {
    emit(BackupReadingFile());

    try {
      final summary = await repository.inspect(json);

      emit(BackupReadyToRestore(json: json, summary: summary));
    } on AppFailure catch (e) {
      emit(BackupFailed(e));
    } catch (e) {
      emit(
        BackupFailed(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  /// Step two: apply it. Only ever called after the user confirmed the
  /// summary from [prepareRestore].
  Future<void> confirmRestore(String json) async {
    emit(BackupRestoring());

    try {
      final rowCount = await repository.restoreFromJson(json);

      /*
        Every screen currently holding data is now holding data from a
        database that no longer exists. Raised here rather than in the
        settings screen because it is a fact about the DATA, not about
        this screen — and only ever on success, since a rolled-back
        restore changed nothing to tell anyone about.
      */
      dataResetNotifier.markReplaced();

      emit(BackupRestored(rowCount));
    } on AppFailure catch (e) {
      emit(BackupFailed(e));
    } catch (e) {
      emit(
        BackupFailed(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  void reset() => emit(BackupIdle());

  /*
    Sortable and readable at a glance, because these files pile up in
    a Downloads folder or a chat thread and the only thing
    distinguishing them is the name:

        utanglista-backup-2026-08-28-0935.json

    Colons are deliberately absent — they are illegal in filenames on
    Windows and awkward everywhere else.
  */
  static String buildFileName(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');

    return 'utanglista-backup-${now.year}-${two(now.month)}-'
        '${two(now.day)}-${two(now.hour)}${two(now.minute)}.json';
  }
}
