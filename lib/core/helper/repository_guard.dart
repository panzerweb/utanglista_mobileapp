/*
  ------------------------------------------------------------------
  _guard: the single error-translation point for this repository.
  ------------------------------------------------------------------

  WHY IT EXISTS:
  Every method below used to repeat the same 15-line try/catch. Worse,
  all nine copies reported the same message ("Creation of store failed") 
  even on READ operations, so a failed store listing told the
  user that a creation had failed. Now each method passes its own
  failureMessage, so what the UI shows actually matches what broke.

  HOW TO USE IT:
  Wrap the datasource call and describe the operation in user-facing
  language, because this message can be surfaced straight to a SnackBar:

    @override
    Future<int> createBatch(CreateBatchPayload payload) => guard(
          failureMessage: 'Could not create the draft batch.',
          () => localDataSource.createBatch(payload),
        );

  ERROR CODES IT PRODUCES (what a cubit or screen can branch on):
    DRIFT_ERROR      -> the database itself rejected the operation,
                        e.g. a foreign key or unique constraint failed.
    UNEXPECTED_ERROR -> anything else; treat as a bug, not user error.

  An AppFailure thrown from deeper down is passed through untouched, so a
  more specific code never gets downgraded into a generic one.
  */
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';

Future<T> repositoryGuard<T>(
  Future<T> Function() action, {
  required String failureMessage,
}) async {
  try {
    return await action();
  } on AppFailure catch (e) {
    rethrow;
  } on DriftWrappedException catch (e) {
    debugPrint("Drift Error: ${e.message}");
    debugPrint("Native Database Failure: ${e.cause}");
    throw AppFailure(code: 'DRIFT_ERROR', message: failureMessage);
  } catch (e) {
    print('Generic or unexpected error: $e');
    throw AppFailure(code: 'UNEXPECTED_ERROR', message: failureMessage);
  }
}

/*
  ------------------------------------------------------------------
  _requireRowChanged: turns "0 rows affected" into a real failure.
  ------------------------------------------------------------------

  Drift's update and delete both answer with a row count rather than
  throwing when the id matches nothing. Left alone, that means editing a
  draft someone already deleted on another screen would report success
  and the UI would happily show "Saved" for a row that does not exist.

  Every mutation below funnels through here so that case becomes a
  NOT_FOUND AppFailure, which the UI already knows how to branch on.

  HOW TO USE:
    @override
    Future<void> updateBatch(UpdateBatchPayload payload) => _requireRowChanged(
      () => localDataSource.updateBatch(payload),
      failureMessage: 'Could not save your changes to this batch.',
      notFoundMessage: 'This batch no longer exists.',
    );
*/
Future<void> requireRowChanged(
  Future<int> Function() action, {
  required String failureMessage,
  required String notFoundMessage,
}) async {
  final int rowsAffected = await repositoryGuard(
    action,
    failureMessage: failureMessage,
  );

  if (rowsAffected == 0) {
    throw AppFailure(code: 'NOT_FOUND', message: notFoundMessage);
  }
}
