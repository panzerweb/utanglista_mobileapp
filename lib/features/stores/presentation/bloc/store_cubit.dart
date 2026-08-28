import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';
import 'package:utanglista_mobileapp/features/stores/domain/entities/store_entity.dart';
import 'package:utanglista_mobileapp/features/stores/domain/repositories/store_repository.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/bloc/store_state.dart';

/*
  ------------------------------------------------------------------
  Store name bounds, shared by every cubit that validates one.
  ------------------------------------------------------------------

  These mirror StoresTable.name (min: 2, max: 60). Drift would reject a
  violation anyway, but as an opaque DRIFT_ERROR — checking here means
  the user is told what is actually wrong with what they typed.
*/
const int _minNameLength = 2;
const int _maxNameLength = 60;

AppFailure? _validateStoreName(String rawName) {
  final name = rawName.trim();

  if (name.length < _minNameLength || name.length > _maxNameLength) {
    return AppFailure(
      code: 'INVALID_FORMAT',
      message:
          'Store name must be between $_minNameLength and '
          '$_maxNameLength characters.',
    );
  }

  return null;
}

/*
  §19: the rate must be 0%-5%. InterestRate owns the range itself so
  this check cannot drift from the one the settings tab uses.
*/
AppFailure? _validateInterest(bool enabled, InterestRate rate) {
  if (!enabled) return null;

  if (!rate.isValid) {
    return AppFailure(
      code: 'INVALID_INTEREST_RATE',
      message:
          'Monthly interest must be between 0% and '
          '${InterestRate.maximum.formatPercent()}.',
    );
  }

  return null;
}

/*
  STORE LIST CUBIT:

  Handles display store list.
*/
class StoreListCubit extends Cubit<StoreListState> {
  final StoreRepository repository;
  final CustomerBalanceRepository balanceRepository;

  StoreListCubit(this.repository, this.balanceRepository)
    : super(const StoreListState());

  /*
    ------------------------------------------------------------------
    Why an in-flight guard was replaced by a sequence counter.
    ------------------------------------------------------------------

    This list used to skip a load while another was running, with a
    [force] flag for filter changes that had to get through. That works
    while loads are rare. It breaks the moment a search field exists:
    every keystroke starts a read, the guard drops most of them, and
    the ones that do run can still finish out of order — a slow query
    for "al" landing after "aling" leaves the list showing results for
    a search the user has moved past.

    So the store list now uses the same ticket the customer and product
    lists use: every load claims one, and only the newest may emit.
    Nothing is dropped, nothing lands late, and [force] is no longer a
    thing a caller has to remember.
  */
  int _requestId = 0;

  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> loadAllStores() async {
    final int requestId = ++_requestId;

    // error: null actually clears now — see the sentinel in store_state.
    emit(state.copyWith(error: null, status: StoreListStateStatus.loading));

    try {
      final stores = await repository.fetchStores(
        state.category?.value,
        search: state.search,
        sort: state.sort,
      );

      /*
        One balance query per store rather than one per customer. Still
        N queries for N stores, but N here is the handful of businesses
        one person runs, not their customer list — and each query is a
        single aggregate. The per-customer batching that actually
        matters lives in fetchBalancesForStore.
      */
      final balances = <int, CustomerBalance>{};
      for (final store in stores) {
        balances[store.id] = await balanceRepository.fetchTotalForStore(
          store.id,
        );
      }

      // A newer search or filter has started; its result is the one
      // that counts.
      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          stores: _applyReceivableSort(stores, balances),
          balances: balances,
          status: StoreListStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      if (requestId != _requestId) return;
      emit(state.copyWith(error: e, status: StoreListStateStatus.failure));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: StoreListStateStatus.failure,
        ),
      );
    }
  }

  /*
    Debounced so a query does not run on every keystroke. The sequence
    counter still guards the result — debouncing reduces the races, it
    does not remove them.
  */
  void search(String term) {
    if (state.search == term) return;

    emit(state.copyWith(search: term));

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), loadAllStores);
  }

  Future<void> clearSearch() async {
    if (state.search.isEmpty) return;

    _debounce?.cancel();
    emit(state.copyWith(search: ''));
    await loadAllStores();
  }

  Future<void> setSort(StoreSort sort) async {
    if (state.sort == sort) return;

    emit(state.copyWith(sort: sort));
    await loadAllStores();
  }

  /*
    The receivable is the §15 aggregate across a store's customers, not
    a column on stores_table — the same situation as sorting customers
    by balance, one level up. It is ordered here because this is the
    layer holding both the stores and their totals; the datasource gave
    the page a deterministic name order to start from.
  */
  List<StoreEntity> _applyReceivableSort(
    List<StoreEntity> stores,
    Map<int, CustomerBalance> balances,
  ) {
    if (state.sort != StoreSort.receivable) return stores;

    Money owedBy(StoreEntity store) =>
        (balances[store.id] ?? CustomerBalance.zero).outstanding;

    final sorted = [...stores];

    sorted.sort((a, b) {
      final byReceivable = owedBy(b).compareTo(owedBy(a));

      return byReceivable != 0 ? byReceivable : a.id.compareTo(b.id);
    });

    return sorted;
  }

  /*
    Pass null for "All categories". The old signature took a non-null
    String, so the filter was a one-way door — there was no way back to
    an unfiltered list.

    No try/catch here: loadAllStores already converts every failure into
    a failure state and never throws.
  */
  Future<void> setFilter(StoreCategory? category) async {
    if (state.category == category) return;

    emit(state.copyWith(stores: const [], category: category));

    await loadAllStores();
  }
}

/*
  STORE DETAIL CUBIT:

  Loads one store, its settings and its receivable total.
*/
class StoreDetailCubit extends Cubit<StoreDetailState> {
  final StoreRepository repository;
  final CustomerBalanceRepository balanceRepository;

  StoreDetailCubit(this.repository, this.balanceRepository)
    : super(const StoreDetailState());

  Future<void> loadStore(int storeId) async {
    emit(state.copyWith(error: null, status: StoreDetailStateStatus.loading));

    try {
      final store = await repository.fetchStoreById(storeId);

      // Deleted from another screen while this one was open.
      if (store == null) {
        emit(
          state.copyWith(
            store: null,
            status: StoreDetailStateStatus.failure,
            error: AppFailure(
              code: 'NOT_FOUND',
              message: 'This store no longer exists.',
            ),
          ),
        );
        return;
      }

      final balance = await balanceRepository.fetchTotalForStore(storeId);

      emit(
        state.copyWith(
          store: store,
          balance: balance,
          status: StoreDetailStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: StoreDetailStateStatus.failure));
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: StoreDetailStateStatus.failure,
        ),
      );
    }
  }
}

/*
  FORM CUBIT:

  Handles creation, update, and delete of store.
*/
class StoreFormCubit extends Cubit<StoreFormState> {
  final StoreRepository repository;

  StoreFormCubit(this.repository) : super(StoreFormInitial());

  // CREATE
  Future<void> insertStore(StorePayloadModel payload) async {
    emit(StoreFormSubmitting());

    final nameFailure = _validateStoreName(payload.name);
    if (nameFailure != null) {
      emit(StoreFormFailure(nameFailure));
      return;
    }

    final interestFailure = _validateInterest(
      payload.monthlyInterestEnabled,
      payload.monthlyInterestRate,
    );
    if (interestFailure != null) {
      emit(StoreFormFailure(interestFailure));
      return;
    }

    try {
      final int storeId = await repository.createStore(payload);

      emit(StoreFormSuccess(storeId));
    } on AppFailure catch (e) {
      emit(StoreFormFailure(e));
    } catch (e) {
      emit(
        StoreFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  // UPDATE
  Future<void> editStoreDetail(UpdateStorePayloadModel updatePayload) async {
    emit(StoreFormUpdating());

    // Only validate a name that is actually being changed — a partial
    // update that leaves the name alone passes null.
    if (updatePayload.name != null) {
      final nameFailure = _validateStoreName(updatePayload.name!);
      if (nameFailure != null) {
        emit(StoreFormFailure(nameFailure));
        return;
      }
    }

    if (updatePayload.monthlyInterestRate != null) {
      final interestFailure = _validateInterest(
        updatePayload.monthlyInterestEnabled ?? true,
        updatePayload.monthlyInterestRate!,
      );
      if (interestFailure != null) {
        emit(StoreFormFailure(interestFailure));
        return;
      }
    }

    try {
      final int storeId = await repository.updateStore(updatePayload);

      emit(StoreFormUpdated(storeId));
    } on AppFailure catch (e) {
      emit(StoreFormFailure(e));
    } catch (e) {
      emit(
        StoreFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  // DELETE
  Future<void> deleteStore(int storeId) async {
    emit(StoreFormDeleting());

    try {
      final int result = await repository.deleteStore(storeId);

      emit(StoreFormDeleted(result));
    } on AppFailure catch (e) {
      emit(StoreFormFailure(e));
    } catch (e) {
      emit(
        StoreFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }
}
