import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_draft.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_entity.dart';

const Object _unset = Object();

/*
  ------------------------------------------------------------------
  Transaction history: a store's, or one customer's.
  ------------------------------------------------------------------
*/
enum TransactionListStateStatus { initial, loading, success, failure }

class TransactionListState {
  final int storeId;

  /// null == the whole store; set == one customer's utang tab.
  final int? customerId;

  final List<TransactionEntity> transactions;
  final TransactionListStateStatus status;

  /// Free-text search over the customer's name and the note. An empty
  /// string means no search.
  final String search;

  /// How the history is ordered. Also decides whether it is grouped by
  /// day at all -- see [isGroupedByDay].
  final TransactionSort sort;

  final AppFailure? error;

  const TransactionListState({
    required this.storeId,
    this.customerId,
    this.transactions = const [],
    this.status = TransactionListStateStatus.initial,
    this.search = '',
    this.sort = TransactionSort.recent,
    this.error,
  });

  bool get isEmpty =>
      status == TransactionListStateStatus.success && transactions.isEmpty;

  /// Empty because of the search rather than because nothing was ever
  /// recorded — the empty state should offer to clear it.
  bool get isFilteredEmpty => isEmpty && search.isNotEmpty;

  /*
    Day headings belong to a CHRONOLOGICAL list. Sorted by amount, the
    rows no longer run in date order, so grouping them under dates
    would produce headings that jump backwards and forwards. The list
    renders flat instead.
  */
  bool get isGroupedByDay => sort != TransactionSort.amountHighLow;

  /// Everything ever put on credit in this scope. NOT the outstanding
  /// balance — payments are not subtracted here (§15, §18). The
  /// customer's balance comes from CustomerBalance, never from this.
  Money get totalRecorded =>
      transactions.map((transaction) => transaction.totalAmount).sum();

  /*
    Transactions grouped by calendar day, newest day first, preserving
    the newest-first order within each day.

    Grouped in the state rather than the widget so the list builder
    stays a flat index lookup instead of regrouping on every rebuild.
  */
  List<TransactionDayGroup> get grouped {
    final groups = <DateTime, List<TransactionEntity>>{};

    for (final transaction in transactions) {
      final day = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );

      groups.putIfAbsent(day, () => []).add(transaction);
    }

    /*
      The day headings follow the sort. Newest-first is the default, but
      an oldest-first list under newest-first headings would read as a
      bug — the first heading would be the last day.
    */
    final days = groups.keys.toList()
      ..sort(
        (a, b) =>
            sort == TransactionSort.oldest ? a.compareTo(b) : b.compareTo(a),
      );

    return days
        .map((day) => TransactionDayGroup(day: day, transactions: groups[day]!))
        .toList();
  }

  TransactionListState copyWith({
    List<TransactionEntity>? transactions,
    TransactionListStateStatus? status,
    String? search,
    TransactionSort? sort,
    Object? error = _unset,
  }) {
    return TransactionListState(
      storeId: storeId,
      customerId: customerId,
      transactions: transactions ?? this.transactions,
      status: status ?? this.status,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

class TransactionDayGroup {
  final DateTime day;
  final List<TransactionEntity> transactions;

  const TransactionDayGroup({required this.day, required this.transactions});

  Money get total =>
      transactions.map((transaction) => transaction.totalAmount).sum();
}

/*
  ------------------------------------------------------------------
  One transaction and its items.
  ------------------------------------------------------------------
*/
enum TransactionDetailStateStatus { initial, loading, success, failure }

class TransactionDetailState {
  final TransactionEntity? transaction;
  final TransactionDetailStateStatus status;
  final AppFailure? error;

  const TransactionDetailState({
    this.transaction,
    this.status = TransactionDetailStateStatus.initial,
    this.error,
  });

  TransactionDetailState copyWith({
    Object? transaction = _unset,
    TransactionDetailStateStatus? status,
    Object? error = _unset,
  }) {
    return TransactionDetailState(
      transaction: identical(transaction, _unset)
          ? this.transaction
          : transaction as TransactionEntity?,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

/*
  ------------------------------------------------------------------
  The builder: a draft, plus what is available to put in it.
  ------------------------------------------------------------------

  A single state class rather than a sealed hierarchy, because the
  screen edits one long-lived thing. Submission outcomes ride along as
  a status enum so a BlocListener can still fire exactly once.
*/
enum TransactionBuilderStatus {
  editing,
  submitting,
  submitted,
  failure,
}

class TransactionBuilderState {
  final int storeId;
  final TransactionDraft draft;
  final TransactionBuilderStatus status;

  /// The id of the committed transaction, once submitted.
  final int? createdTransactionId;

  final AppFailure? error;

  const TransactionBuilderState({
    required this.storeId,
    this.draft = const TransactionDraft(),
    this.status = TransactionBuilderStatus.editing,
    this.createdTransactionId,
    this.error,
  });

  bool get isSubmitting => status == TransactionBuilderStatus.submitting;

  /// Disabled while submitting as well as while invalid — a double tap
  /// on "Record utang" must not write the transaction twice.
  bool get canSubmit => draft.canSubmit && !isSubmitting;

  TransactionBuilderState copyWith({
    TransactionDraft? draft,
    TransactionBuilderStatus? status,
    Object? createdTransactionId = _unset,
    Object? error = _unset,
  }) {
    return TransactionBuilderState(
      storeId: storeId,
      draft: draft ?? this.draft,
      status: status ?? this.status,
      createdTransactionId: identical(createdTransactionId, _unset)
          ? this.createdTransactionId
          : createdTransactionId as int?,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}
