import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/ledger/domain/entities/ledger_entry.dart';
import 'package:utanglista_mobileapp/features/ledger/domain/repositories/ledger_repository.dart';

const Object _unset = Object();

enum LedgerStateStatus { initial, loading, success, failure }

class LedgerState {
  final int customerId;

  /// Oldest first, with the running balance folded in. The UI reverses
  /// it for display — see LedgerRow.
  final List<LedgerRow> rows;

  final LedgerStateStatus status;
  final AppFailure? error;

  const LedgerState({
    required this.customerId,
    this.rows = const [],
    this.status = LedgerStateStatus.initial,
    this.error,
  });

  bool get isEmpty => status == LedgerStateStatus.success && rows.isEmpty;

  /// The balance after the LAST event — the customer's balance now.
  /// Equal to what CustomerBalance reports, arrived at from the other
  /// direction: event by event rather than by three SUMs.
  Money get currentBalance =>
      rows.isEmpty ? Money.zero : rows.last.balanceAfter;

  /// Newest first, which is how the ledger is rendered — so the top
  /// row carries the current balance.
  List<LedgerRow> get newestFirst => rows.reversed.toList();

  LedgerState copyWith({
    List<LedgerRow>? rows,
    LedgerStateStatus? status,
    Object? error = _unset,
  }) {
    return LedgerState(
      customerId: customerId,
      rows: rows ?? this.rows,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

/*
  The §17 ledger for one customer.

  Read-only by construction: there is nothing to mutate here, because
  every row is a projection of a financial record that lives elsewhere
  and is itself immutable (§14, §30).
*/
class LedgerCubit extends Cubit<LedgerState> {
  final LedgerRepository repository;

  LedgerCubit(this.repository, {required int customerId})
    : super(LedgerState(customerId: customerId));

  Future<void> loadLedger() async {
    emit(state.copyWith(error: null, status: LedgerStateStatus.loading));

    try {
      final rows = await repository.fetchLedgerForCustomer(state.customerId);

      emit(
        state.copyWith(
          rows: rows,
          status: LedgerStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: LedgerStateStatus.failure));
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: LedgerStateStatus.failure,
        ),
      );
    }
  }
}
