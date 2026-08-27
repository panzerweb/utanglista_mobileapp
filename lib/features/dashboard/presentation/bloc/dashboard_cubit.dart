import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utanglista_mobileapp/features/dashboard/domain/repositories/dashboard_repository.dart';

const Object _unset = Object();

enum DashboardStateStatus { initial, loading, success, failure }

class DashboardState {
  final DashboardSummary summary;
  final DashboardStateStatus status;
  final AppFailure? error;

  const DashboardState({
    this.summary = const DashboardSummary(),
    this.status = DashboardStateStatus.initial,
    this.error,
  });

  /// True only on the very first load — a refresh keeps the previous
  /// figures on screen underneath rather than blanking them.
  bool get isFirstLoad =>
      status == DashboardStateStatus.loading && !summary.hasStores;

  bool get isEmpty =>
      status == DashboardStateStatus.success && !summary.hasStores;

  DashboardState copyWith({
    DashboardSummary? summary,
    DashboardStateStatus? status,
    Object? error = _unset,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repository;

  DashboardCubit(this.repository) : super(const DashboardState());

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: DashboardStateStatus.loading, error: null));

    try {
      final summary = await repository.fetchSummary();

      emit(
        state.copyWith(
          summary: summary,
          status: DashboardStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: DashboardStateStatus.failure));
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: DashboardStateStatus.failure,
        ),
      );
    }
  }
}
