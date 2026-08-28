import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';

const Object _unset = Object();

/*
  ------------------------------------------------------------------
  Customer list: the people in one store, and what each of them owes.
  ------------------------------------------------------------------

  Customers and balances are held separately rather than as a combined
  view model, because they come from different queries — the customer
  rows from customers_table, the balances from one batched aggregate
  over three financial tables (§15).
*/
enum CustomerListStateStatus { initial, loading, success, failure }

class CustomerListState {
  final int storeId;
  final List<CustomerEntity> customers;

  /// Outstanding per customer id, from one batched query — never one
  /// query per row.
  final Map<int, CustomerBalance> balances;

  final CustomerListStateStatus status;

  /// Free-text search over name and contact number. '' means no search.
  final String search;

  /// §29: deactivated customers are hidden by default but never gone.
  final bool includeInactive;

  /// How the list is ordered. Deactivated customers sort last
  /// regardless — see the note on [CustomerSort].
  final CustomerSort sort;

  final AppFailure? error;

  const CustomerListState({
    required this.storeId,
    this.customers = const [],
    this.balances = const {},
    this.status = CustomerListStateStatus.initial,
    this.search = '',
    this.includeInactive = false,
    this.sort = CustomerSort.recent,
    this.error,
  });

  bool get isEmpty =>
      status == CustomerListStateStatus.success && customers.isEmpty;

  /// Empty because of a search or filter rather than because the store
  /// has no customers — the empty state should say so.
  bool get isFilteredEmpty => isEmpty && (search.isNotEmpty || includeInactive);

  CustomerBalance balanceFor(int customerId) =>
      balances[customerId] ?? CustomerBalance.zero;

  /// Everything owed across the customers currently listed.
  Money get totalOutstanding =>
      customers.map((c) => balanceFor(c.id).outstanding).sum();

  /// How many of the listed customers actually owe something — more
  /// useful at a glance than the raw customer count.
  int get debtorCount =>
      customers.where((c) => balanceFor(c.id).hasDebt).length;

  CustomerListState copyWith({
    List<CustomerEntity>? customers,
    Map<int, CustomerBalance>? balances,
    CustomerListStateStatus? status,
    String? search,
    bool? includeInactive,
    CustomerSort? sort,
    Object? error = _unset,
  }) {
    return CustomerListState(
      storeId: storeId,
      customers: customers ?? this.customers,
      balances: balances ?? this.balances,
      status: status ?? this.status,
      search: search ?? this.search,
      includeInactive: includeInactive ?? this.includeInactive,
      sort: sort ?? this.sort,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

/*
  ------------------------------------------------------------------
  Customer detail: one customer and their balance.
  ------------------------------------------------------------------
*/
enum CustomerDetailStateStatus { initial, loading, success, failure }

class CustomerDetailState {
  final CustomerEntity? customer;
  final CustomerBalance balance;

  /// Whether deletion is even offered (§29). Loaded alongside the
  /// customer so the action menu never has to guess.
  final bool hasFinancialHistory;

  final CustomerDetailStateStatus status;
  final AppFailure? error;

  const CustomerDetailState({
    this.customer,
    this.balance = CustomerBalance.zero,
    this.hasFinancialHistory = false,
    this.status = CustomerDetailStateStatus.initial,
    this.error,
  });

  /// §30 in practice: a customer with any financial record is
  /// deactivated, never deleted.
  bool get canDelete => !hasFinancialHistory;

  CustomerDetailState copyWith({
    Object? customer = _unset,
    CustomerBalance? balance,
    bool? hasFinancialHistory,
    CustomerDetailStateStatus? status,
    Object? error = _unset,
  }) {
    return CustomerDetailState(
      customer: identical(customer, _unset)
          ? this.customer
          : customer as CustomerEntity?,
      balance: balance ?? this.balance,
      hasFinancialHistory: hasFinancialHistory ?? this.hasFinancialHistory,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

/*
  ------------------------------------------------------------------
  Customer form: create, edit, activate/deactivate, delete.
  ------------------------------------------------------------------
*/
sealed class CustomerFormState {}

class CustomerFormInitial extends CustomerFormState {}

class CustomerFormSubmitting extends CustomerFormState {}

class CustomerFormUpdating extends CustomerFormState {}

class CustomerFormDeleting extends CustomerFormState {}

class CustomerFormSuccess extends CustomerFormState {
  final int customerId;

  CustomerFormSuccess(this.customerId);
}

class CustomerFormUpdated extends CustomerFormState {
  final int customerId;

  CustomerFormUpdated(this.customerId);
}

/// Emitted for both directions so the listener can word the message
/// correctly without re-reading the customer.
class CustomerActiveStateChanged extends CustomerFormState {
  final int customerId;
  final bool isActive;

  CustomerActiveStateChanged(this.customerId, this.isActive);
}

class CustomerFormDeleted extends CustomerFormState {
  final int customerId;

  CustomerFormDeleted(this.customerId);
}

class CustomerFormFailure extends CustomerFormState {
  final AppFailure error;

  CustomerFormFailure(this.error);
}
