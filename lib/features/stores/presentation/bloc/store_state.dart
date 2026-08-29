import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/stores/domain/entities/store_entity.dart';

/*
  ------------------------------------------------------------------
  Store list state, a single state to handle filters, and multiple
  states.
  ------------------------------------------------------------------
*/
enum StoreListStateStatus { initial, loading, success, failure }

/*
  ------------------------------------------------------------------
  _unset: lets copyWith tell "leave this alone" apart from "clear it".
  ------------------------------------------------------------------

  The usual `value ?? this.value` cannot express null as a NEW value —
  passing null just falls through to the old one. For two fields here
  that silently broke things:

    error     copyWith(error: null) was a no-op, so a stale failure
              survived a successful reload and the list showed an error
              banner over fresh data.

    category  the filter could never go back to "All", because clearing
              it means setting it to null.

  A private sentinel distinguishes the two cases: absent means keep,
  explicit null means clear.
*/
const Object _unset = Object();

class StoreListState {
  final List<StoreEntity> stores;

  /*
    Outstanding receivable per store id, loaded in one batched query
    rather than one per row. A store missing from the map is still
    loading its total; a store present with zero genuinely has none.
  */
  final Map<int, CustomerBalance> balances;

  final StoreListStateStatus status;

  /// null means "All categories" — no filter applied.
  final StoreCategory? category;

  /// Free-text search over the store name. '' means no search.
  final String search;

  /// How the list is ordered.
  final StoreSort sort;

  final AppFailure? error;

  const StoreListState({
    this.stores = const [],
    this.balances = const {},
    this.status = StoreListStateStatus.initial,
    this.category,
    this.search = '',
    this.sort = StoreSort.recent,
    this.error,
  });

  bool get isEmpty =>
      status == StoreListStateStatus.success && stores.isEmpty;

  /// True when the list is empty only because of the search or the
  /// category filter — the empty state should then offer to clear
  /// them, not to add a store.
  bool get isFilteredEmpty =>
      isEmpty && (category != null || search.isNotEmpty);

  CustomerBalance balanceFor(int storeId) =>
      balances[storeId] ?? CustomerBalance.zero;

  /// Everything owed across the stores currently listed.
  Money get totalOutstanding => stores
      .map((store) => balanceFor(store.id).outstanding)
      .sum();

  /*
    Pass nothing to keep a field, or pass null explicitly to clear it:

      state.copyWith(status: loading, error: null)   // clears the error
      state.copyWith(status: loading)                // keeps it
  */
  StoreListState copyWith({
    List<StoreEntity>? stores,
    Map<int, CustomerBalance>? balances,
    StoreListStateStatus? status,
    Object? category = _unset,
    String? search,
    StoreSort? sort,
    Object? error = _unset,
  }) {
    return StoreListState(
      stores: stores ?? this.stores,
      balances: balances ?? this.balances,
      status: status ?? this.status,
      category: identical(category, _unset)
          ? this.category
          : category as StoreCategory?,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
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

class StoreFormFailure extends StoreFormState {
  final AppFailure error;

  StoreFormFailure(this.error);
}

/*
  ------------------------------------------------------------------
  Store detail: one store, its settings, and its receivable total.
  ------------------------------------------------------------------

  Separate from the list state because the detail screen outlives a
  list refresh and needs its own loading and failure handling — a tab
  the user is reading should not blank out because the list behind it
  reloaded.
*/
enum StoreDetailStateStatus { initial, loading, success, failure }

class StoreDetailState {
  final StoreEntity? store;
  final CustomerBalance balance;
  final StoreDetailStateStatus status;
  final AppFailure? error;

  const StoreDetailState({
    this.store,
    this.balance = CustomerBalance.zero,
    this.status = StoreDetailStateStatus.initial,
    this.error,
  });

  StoreDetailState copyWith({
    Object? store = _unset,
    CustomerBalance? balance,
    StoreDetailStateStatus? status,
    Object? error = _unset,
  }) {
    return StoreDetailState(
      store: identical(store, _unset) ? this.store : store as StoreEntity?,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}
