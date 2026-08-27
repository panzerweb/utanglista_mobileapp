import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_repository.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_state.dart';

/*
  ------------------------------------------------------------------
  Customer name and contact bounds, shared by the cubits that check.
  ------------------------------------------------------------------

  These mirror CustomersTable (name 2-60, contactNumber max 20). Drift
  would reject a violation anyway, but as an opaque DRIFT_ERROR —
  checking here tells the user what is actually wrong.
*/
const int _minNameLength = 2;
const int _maxNameLength = 60;
const int _maxContactLength = 20;

AppFailure? _validateCustomerName(String rawName) {
  final name = rawName.trim();

  if (name.length < _minNameLength || name.length > _maxNameLength) {
    return AppFailure(
      code: 'INVALID_FORMAT',
      message:
          'Customer name must be between $_minNameLength and '
          '$_maxNameLength characters.',
    );
  }

  return null;
}

/*
  §4 says contact is optional, so an empty value is valid. Only the
  length is enforced — Philippine numbers get written every possible
  way ('0917...', '+63 917...', 'globe 0917...'), and rejecting a
  format the seller uses would just stop them recording it at all.
*/
AppFailure? _validateContactNumber(String? rawContact) {
  final contact = rawContact?.trim() ?? '';

  if (contact.length > _maxContactLength) {
    return AppFailure(
      code: 'INVALID_FORMAT',
      message:
          'Contact number must be $_maxContactLength characters or fewer.',
    );
  }

  return null;
}

/*
  CUSTOMER LIST CUBIT:

  The people in one store, with what each of them owes.
*/
class CustomerListCubit extends Cubit<CustomerListState> {
  final CustomerRepository repository;
  final CustomerBalanceRepository balanceRepository;

  CustomerListCubit(
    this.repository,
    this.balanceRepository, {
    required int storeId,
  }) : super(CustomerListState(storeId: storeId));

  /*
    ------------------------------------------------------------------
    Why there is a sequence counter.
    ------------------------------------------------------------------

    Search fires a query per keystroke. Typing "juan" starts four
    overlapping reads, and nothing guarantees they finish in order — a
    slower query for "ju" can land after the one for "juan" and leave
    the list showing results for a search the user has moved past.

    Each load claims a ticket; only the newest is allowed to emit.
  */
  int _requestId = 0;

  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> loadCustomers() async {
    final int requestId = ++_requestId;

    emit(state.copyWith(error: null, status: CustomerListStateStatus.loading));

    try {
      final customers = await repository.fetchCustomers(
        state.storeId,
        search: state.search,
        includeInactive: state.includeInactive,
      );

      /*
        One batched query for every balance in the store — not one per
        customer. This is what fetchBalancesForStore exists for; a
        per-row lookup would be N+1 over three financial tables each.
      */
      final balances = await balanceRepository.fetchBalancesForStore(
        state.storeId,
      );

      // A newer search has started; its result is the one that counts.
      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          customers: customers,
          balances: balances,
          status: CustomerListStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      if (requestId != _requestId) return;
      emit(state.copyWith(error: e, status: CustomerListStateStatus.failure));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: CustomerListStateStatus.failure,
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
    _debounce = Timer(const Duration(milliseconds: 250), loadCustomers);
  }

  Future<void> clearSearch() async {
    if (state.search.isEmpty) return;

    _debounce?.cancel();
    emit(state.copyWith(search: ''));
    await loadCustomers();
  }

  /// §29: deactivated customers are hidden by default, never deleted.
  Future<void> setIncludeInactive(bool includeInactive) async {
    if (state.includeInactive == includeInactive) return;

    emit(state.copyWith(includeInactive: includeInactive));
    await loadCustomers();
  }

  CustomerBalance balanceOf(int customerId) => state.balanceFor(customerId);
}

/*
  CUSTOMER DETAIL CUBIT:

  One customer, their balance, and whether they may be deleted.
*/
class CustomerDetailCubit extends Cubit<CustomerDetailState> {
  final CustomerRepository repository;
  final CustomerBalanceRepository balanceRepository;

  CustomerDetailCubit(this.repository, this.balanceRepository)
    : super(const CustomerDetailState());

  Future<void> loadCustomer(int customerId) async {
    emit(
      state.copyWith(error: null, status: CustomerDetailStateStatus.loading),
    );

    try {
      final customer = await repository.fetchCustomerById(customerId);

      // Deleted from another screen while this one was open.
      if (customer == null) {
        emit(
          state.copyWith(
            customer: null,
            status: CustomerDetailStateStatus.failure,
            error: AppFailure(
              code: 'NOT_FOUND',
              message: 'This customer no longer exists.',
            ),
          ),
        );
        return;
      }

      final balance = await balanceRepository.fetchBalanceForCustomer(
        customerId,
      );
      final hasHistory = await repository.hasFinancialHistory(customerId);

      emit(
        state.copyWith(
          customer: customer,
          balance: balance,
          hasFinancialHistory: hasHistory,
          status: CustomerDetailStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: CustomerDetailStateStatus.failure));
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: CustomerDetailStateStatus.failure,
        ),
      );
    }
  }
}

/*
  CUSTOMER FORM CUBIT:

  Handles creation, update, deactivation, and delete of a customer.
*/
class CustomerFormCubit extends Cubit<CustomerFormState> {
  final CustomerRepository repository;

  CustomerFormCubit(this.repository) : super(CustomerFormInitial());

  // CREATE
  Future<void> insertCustomer(CustomerPayloadModel payload) async {
    emit(CustomerFormSubmitting());

    final failure =
        _validateCustomerName(payload.name) ??
        _validateContactNumber(payload.contactNumber);

    if (failure != null) {
      emit(CustomerFormFailure(failure));
      return;
    }

    try {
      final int customerId = await repository.createCustomer(payload);

      emit(CustomerFormSuccess(customerId));
    } on AppFailure catch (e) {
      emit(CustomerFormFailure(e));
    } catch (e) {
      emit(
        CustomerFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  // UPDATE
  Future<void> editCustomer(UpdateCustomerPayloadModel updatePayload) async {
    emit(CustomerFormUpdating());

    // Only validate what is actually being changed — a partial update
    // passes null for the fields it leaves alone.
    if (updatePayload.name != null) {
      final failure = _validateCustomerName(updatePayload.name!);
      if (failure != null) {
        emit(CustomerFormFailure(failure));
        return;
      }
    }

    if (updatePayload.contactNumber != null) {
      final failure = _validateContactNumber(updatePayload.contactNumber);
      if (failure != null) {
        emit(CustomerFormFailure(failure));
        return;
      }
    }

    try {
      await repository.updateCustomer(updatePayload);

      emit(CustomerFormUpdated(updatePayload.customerId));
    } on AppFailure catch (e) {
      emit(CustomerFormFailure(e));
    } catch (e) {
      emit(
        CustomerFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  /*
    §29: the normal way a customer leaves the active list. Their
    balance and history are untouched — they simply cannot take on new
    utang until reactivated.
  */
  Future<void> setActive(int customerId, {required bool isActive}) async {
    emit(CustomerFormUpdating());

    try {
      await repository.setActive(customerId, isActive: isActive);

      emit(CustomerActiveStateChanged(customerId, isActive));
    } on AppFailure catch (e) {
      emit(CustomerFormFailure(e));
    } catch (e) {
      emit(
        CustomerFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  /*
    Only ever succeeds for a customer with no financial history — the
    repository refuses the rest with HAS_FINANCIAL_HISTORY, which the
    UI turns into an offer to deactivate instead.
  */
  Future<void> deleteCustomer(int customerId) async {
    emit(CustomerFormDeleting());

    try {
      await repository.deleteCustomer(customerId);

      emit(CustomerFormDeleted(customerId));
    } on AppFailure catch (e) {
      emit(CustomerFormFailure(e));
    } catch (e) {
      emit(
        CustomerFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }
}
