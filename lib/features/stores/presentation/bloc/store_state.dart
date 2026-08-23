import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/features/stores/domain/entities/store_entity.dart';

/*
  ------------------------------------------------------------------
  Store list state, a single state to handle filters, and multiple
  states.
  ------------------------------------------------------------------
*/
enum StoreListStateStatus { initial, loading, success, failure }

class StoreListState {
  final List<StoreEntity> stores;
  final StoreListStateStatus status;
  final String? category;
  final AppFailure? error;

  const StoreListState({
    this.stores = const [],
    this.status = StoreListStateStatus.initial,
    this.category,
    this.error,
  });

  StoreListState copyWith({
    List<StoreEntity>? stores,
    StoreListStateStatus? status,
    String? category,
    AppFailure? error,
  }) {
    return StoreListState(
      stores: stores ?? this.stores,
      status: status ?? this.status,
      category: category ?? this.category,
      error: error ?? this.error,
    );
  }
}

/*
  ------------------------------------------------------------------
  Submission state of stores. Handles creation, update, as well as
  deletion of stores.
  ------------------------------------------------------------------
*/
sealed class StoreFormState {}

class StoreFormInitial extends StoreFormState {}

class StoreFormSubmitting extends StoreFormState {}

class StoreFormUpdating extends StoreFormState {}

class StoreFormDeleting extends StoreFormState {}

class StoreFormSuccess extends StoreFormState {
  final int storeId;

  StoreFormSuccess(this.storeId);
}

class StoreFormUpdated extends StoreFormState {
  final int storeId;

  StoreFormUpdated(this.storeId);
}

class StoreFormDeleted extends StoreFormState {
  final int storeId;

  StoreFormDeleted(this.storeId);
}

class StoreFormFailure extends StoreFormState {}
