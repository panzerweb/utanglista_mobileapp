import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/interest/domain/entities/interest_preview.dart';
import 'package:utanglista_mobileapp/features/interest/domain/entities/interest_record_entity.dart';
import 'package:utanglista_mobileapp/features/interest/domain/repositories/interest_repository.dart';

const Object _unset = Object();

/*
  ------------------------------------------------------------------
  Applying a month's interest: preview, confirm, apply.
  ------------------------------------------------------------------

  Never applied without being shown first. §21 makes each charge a
  permanent record and V1 has no reversal, so the seller sees exactly
  who is affected and for how much before anything is written.
*/
enum ApplyInterestStatus {
  loading,
  previewed,
  applying,
  applied,
  failure,
}

class ApplyInterestState {
  final int storeId;
  final InterestRate rate;

  /// 'YYYY-MM'. Defaults to the current month; the seller can step back
  /// to charge a month they missed.
  final String periodKey;

  final InterestPreview? preview;
  final InterestApplicationResult? result;
  final ApplyInterestStatus status;
  final AppFailure? error;

  const ApplyInterestState({
    required this.storeId,
    required this.rate,
    required this.periodKey,
    this.preview,
    this.result,
    this.status = ApplyInterestStatus.loading,
    this.error,
  });

  bool get isApplying => status == ApplyInterestStatus.applying;

  bool get canApply =>
      status == ApplyInterestStatus.previewed &&
      (preview?.hasAnythingToApply ?? false);

  /// 'August 2026' — for headings and the confirmation dialog.
  String get periodLabel => AppDateFormat.periodLabel(periodKey);

  ApplyInterestState copyWith({
    String? periodKey,
    Object? preview = _unset,
    Object? result = _unset,
    ApplyInterestStatus? status,
    Object? error = _unset,
  }) {
    return ApplyInterestState(
      storeId: storeId,
      rate: rate,
      periodKey: periodKey ?? this.periodKey,
      preview: identical(preview, _unset)
          ? this.preview
          : preview as InterestPreview?,
      result: identical(result, _unset)
          ? this.result
          : result as InterestApplicationResult?,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

class ApplyInterestCubit extends Cubit<ApplyInterestState> {
  final InterestRepository repository;

  ApplyInterestCubit(
    this.repository, {
    required int storeId,
    required InterestRate rate,
    required String periodKey,
  }) : super(
         ApplyInterestState(
           storeId: storeId,
           rate: rate,
           periodKey: periodKey,
         ),
       );

  Future<void> loadPreview() async {
    emit(state.copyWith(status: ApplyInterestStatus.loading, error: null));

    try {
      final preview = await repository.buildPreview(
        storeId: state.storeId,
        periodKey: state.periodKey,
        rate: state.rate,
      );

      emit(
        state.copyWith(
          preview: preview,
          status: ApplyInterestStatus.previewed,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: ApplyInterestStatus.failure));
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: ApplyInterestStatus.failure,
        ),
      );
    }
  }

  /// Steps the charged month backwards or forwards, then re-previews.
  Future<void> shiftPeriod(int months) async {
    final parts = state.periodKey.split('-');
    final year = int.tryParse(parts.first);
    final month = int.tryParse(parts.last);
    if (year == null || month == null) return;

    // DateTime normalises month 0 and 13 into the neighbouring year.
    final shifted = DateTime(year, month + months);

    emit(
      state.copyWith(
        periodKey: AppDateFormat.periodKey(shifted),
        preview: null,
        result: null,
      ),
    );

    await loadPreview();
  }

  /*
    Guarded against a double tap. §22's unique index would reject the
    second run anyway — the batch would simply report every customer as
    a failure — but not starting it is better than explaining it.
  */
  Future<void> apply() async {
    if (state.isApplying || !state.canApply) return;

    emit(state.copyWith(status: ApplyInterestStatus.applying, error: null));

    try {
      final result = await repository.applyInterest(
        storeId: state.storeId,
        periodKey: state.periodKey,
        rate: state.rate,
      );

      emit(
        state.copyWith(
          result: result,
          status: ApplyInterestStatus.applied,
          error: null,
        ),
      );

      // Refresh so the list now reads "already charged" for everyone
      // just charged — the same guard the seller would hit on a retry.
      await loadPreview();
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: ApplyInterestStatus.failure));
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: ApplyInterestStatus.failure,
        ),
      );
    }
  }
}

/*
  ------------------------------------------------------------------
  Interest history — a store's, or one customer's.
  ------------------------------------------------------------------
*/
enum InterestHistoryStatus { initial, loading, success, failure }

class InterestHistoryState {
  final int storeId;
  final int? customerId;
  final List<InterestRecordEntity> records;
  final InterestHistoryStatus status;

  /// Free-text search over the charged customer's name.
  final String search;

  final InterestSort sort;

  final AppFailure? error;

  const InterestHistoryState({
    required this.storeId,
    this.customerId,
    this.records = const [],
    this.status = InterestHistoryStatus.initial,
    this.search = '',
    this.sort = InterestSort.newestPeriod,
    this.error,
  });

  bool get isEmpty =>
      status == InterestHistoryStatus.success && records.isEmpty;

  /// Empty because of the search, not because interest was never
  /// charged in this store.
  bool get isFilteredEmpty => isEmpty && search.isNotEmpty;

  /*
    Month headings only make sense while the list runs in month order.
    Sorted by amount, the rows cross months freely, so the screen shows
    a flat list rather than headings that repeat and jump.
  */
  bool get isGroupedByPeriod => sort != InterestSort.amountHighLow;

  /*
    Records grouped by the month they charged.

    A LinkedHashMap in insertion order, so the group order follows
    whatever the query returned — newest month first by default, oldest
    first when the sort says so. Nothing re-sorts here.
  */
  Map<String, List<InterestRecordEntity>> get byPeriod {
    final grouped = <String, List<InterestRecordEntity>>{};

    for (final record in records) {
      grouped.putIfAbsent(record.periodKey, () => []).add(record);
    }

    return grouped;
  }

  InterestHistoryState copyWith({
    List<InterestRecordEntity>? records,
    InterestHistoryStatus? status,
    String? search,
    InterestSort? sort,
    Object? error = _unset,
  }) {
    return InterestHistoryState(
      storeId: storeId,
      customerId: customerId,
      records: records ?? this.records,
      status: status ?? this.status,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

class InterestHistoryCubit extends Cubit<InterestHistoryState> {
  final InterestRepository repository;

  InterestHistoryCubit(
    this.repository, {
    required int storeId,
    int? customerId,
  }) : super(InterestHistoryState(storeId: storeId, customerId: customerId));

  /// Every load claims a ticket; only the newest may emit. See
  /// CustomerListCubit for why the debounce is not enough on its own.
  int _requestId = 0;

  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> loadRecords() async {
    final int requestId = ++_requestId;

    emit(state.copyWith(status: InterestHistoryStatus.loading, error: null));

    try {
      final records = await repository.fetchRecords(
        state.storeId,
        customerId: state.customerId,
        search: state.search,
        sort: state.sort,
      );

      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          records: records,
          status: InterestHistoryStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      if (requestId != _requestId) return;
      emit(state.copyWith(error: e, status: InterestHistoryStatus.failure));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: InterestHistoryStatus.failure,
        ),
      );
    }
  }

  void search(String term) {
    if (state.search == term) return;

    emit(state.copyWith(search: term));

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), loadRecords);
  }

  Future<void> clearSearch() async {
    if (state.search.isEmpty) return;

    _debounce?.cancel();
    emit(state.copyWith(search: ''));
    await loadRecords();
  }

  Future<void> setSort(InterestSort sort) async {
    if (state.sort == sort) return;

    emit(state.copyWith(sort: sort));
    await loadRecords();
  }
}
