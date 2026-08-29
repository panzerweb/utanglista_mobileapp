import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_balance_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';

/*
  ------------------------------------------------------------------
  The single authoritative path to "what does this customer owe?"
  ------------------------------------------------------------------

  §16 forbids a stored balance, and CLAUDE.md §5 forbids deriving one in
  two places. Everything that displays or validates against a balance
  goes through here:

    customer list row        fetchBalancesForStore  (one query, not N)
    customer detail header   fetchBalanceForCustomer
    payment validation       fetchBalanceForCustomer -> canAcceptPayment
    interest base            fetchBalanceForCustomer -> interestFor
    dashboard totals         fetchTotalForStore / fetchTotalForAllStores

  If a screen ever needs a balance and the method it wants is not here,
  add it here — do not compute it at the call site.
*/
abstract class CustomerBalanceRepository {
  Future<CustomerBalance> fetchBalanceForCustomer(int customerId);
  Future<Map<int, CustomerBalance>> fetchBalancesForStore(int storeId);
  Future<CustomerBalance> fetchTotalForStore(int storeId);
  Future<CustomerBalance> fetchTotalForAllStores();
}

class CustomerBalanceRepositoryImplementation
    implements CustomerBalanceRepository {
  final CustomerBalanceLocalDataSource localDataSource;

  CustomerBalanceRepositoryImplementation(this.localDataSource);

  // ========================================================
  // ** BALANCE METHODS **
  // ========================================================
  @override
  Future<CustomerBalance> fetchBalanceForCustomer(int customerId) {
    return repositoryGuard(() async {
      final model = await localDataSource.fetchBalanceForCustomer(customerId);
      return model.toEntity();
    }, failureMessage: "Could not calculate this customer's balance.");
  }

  /*
    Returns one entry per customer in the store, including customers
    with no activity at all — those come back as CustomerBalance.zero
    rather than being absent, so a list row never has to decide what a
    missing key means.
  */
  @override
  Future<Map<int, CustomerBalance>> fetchBalancesForStore(int storeId) {
    return repositoryGuard(() async {
      final models = await localDataSource.fetchBalancesForStore(storeId);
      return models.map((id, model) => MapEntry(id, model.toEntity()));
    }, failureMessage: "Could not calculate customer balances.");
  }

  @override
  Future<CustomerBalance> fetchTotalForStore(int storeId) {
    return repositoryGuard(() async {
      final model = await localDataSource.fetchTotalForStore(storeId);
      return model.toEntity();
    }, failureMessage: "Could not calculate this store's total.");
  }

  @override
  Future<CustomerBalance> fetchTotalForAllStores() {
    return repositoryGuard(() async {
      final model = await localDataSource.fetchTotalForAllStores();
      return model.toEntity();
    }, failureMessage: "Could not calculate your total receivables.");
  }
}
