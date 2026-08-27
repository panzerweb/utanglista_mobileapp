import 'package:flutter_bloc/flutter_bloc.dart';
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
  final AppFailure? error;

  const InterestHistoryState({
    required this.storeId,
    this.customerId,
    this.records = const [],
    this.status = InterestHistoryStatus.initial,
    this.error,
  });

  bool get isEmpty =>
      status == InterestHistoryStatus.success && records.isEmpty;

  /// Records grouped by the month they charged, newest month first.
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
    Object? error = _unset,
  }) {
    return InterestHistoryState(
      storeId: storeId,
      customerId: customerId,
      records: records ?? this.records,
      status: status ?? this.status,
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

  Future<void> loadRecords() async {
    emit(state.copyWith(status: InterestHistoryStatus.loading, error: null));

    try {
      final records = await repository.fetchRecords(
        state.storeId,
        customerId: state.customerId,
      );

      emit(
        state.copyWith(
          records: records,
          status: InterestHistoryStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: InterestHistoryStatus.failure));
    } catch (e) {
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
}
