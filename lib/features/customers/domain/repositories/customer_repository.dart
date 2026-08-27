import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<int> createCustomer(CustomerPayloadModel payload);
  Future<CustomerEntity?> fetchCustomerById(int customerId);
  Future<List<CustomerEntity>> fetchCustomers(
    int storeId, {
    String? search,
    bool includeInactive,
  });
  Future<int> updateCustomer(UpdateCustomerPayloadModel updatePayload);
  Future<int> setActive(int customerId, {required bool isActive});
  Future<int> deleteCustomer(int customerId);
  Future<bool> hasFinancialHistory(int customerId);
}

class CustomerRepositoryImplementation implements CustomerRepository {
  final CustomerLocalDataSource localDataSource;

  CustomerRepositoryImplementation(this.localDataSource);

  // ========================================================
  // ** CUSTOMER METHODS **
  // ========================================================
  @override
  Future<int> createCustomer(CustomerPayloadModel payload) {
    return repositoryGuard(
      () => localDataSource.createCustomer(payload),
      failureMessage: "Could not save this customer.",
    );
  }

  @override
  Future<CustomerEntity?> fetchCustomerById(int customerId) {
    return repositoryGuard(() async {
      final model = await localDataSource.fetchCustomerById(customerId);
      return model?.toEntity();
    }, failureMessage: "Could not load this customer.");
  }

  @override
  Future<List<CustomerEntity>> fetchCustomers(
    int storeId, {
    String? search,
    bool includeInactive = true,
  }) {
    return repositoryGuard(() async {
      final models = await localDataSource.fetchCustomers(
        storeId,
        search: search,
        includeInactive: includeInactive,
      );

      return models.map((model) => model.toEntity()).toList();
    }, failureMessage: "Could not load customers.");
  }

  @override
  Future<int> updateCustomer(UpdateCustomerPayloadModel updatePayload) {
    return requireRowChanged(
      () => localDataSource.updateCustomer(updatePayload),
      failureMessage: "Could not save your changes to this customer.",
      notFoundMessage: "This customer no longer exists.",
    );
  }

  /*
    §29: deactivation is how a customer with history leaves the active
    list. Their record and balance stay exactly as they were; they just
    cannot take on new utang.
  */
  @override
  Future<int> setActive(int customerId, {required bool isActive}) {
    return requireRowChanged(
      () => localDataSource.updateCustomer(
        UpdateCustomerPayloadModel(customerId: customerId, isActive: isActive),
      ),
      failureMessage: isActive
          ? "Could not reactivate this customer."
          : "Could not deactivate this customer.",
      notFoundMessage: "This customer no longer exists.",
    );
  }

  /*
    ------------------------------------------------------------------
    Deletion is refused for anyone with a financial record.
    ------------------------------------------------------------------

    §29: "A customer with an outstanding balance should never be
    silently deleted." §30 goes further — deleting financial records
    changes accounting history, so it is not offered at all in V1.

    The foreign keys already refuse this: transactions, payments and
    interest records all reference customers with onDelete: noAction,
    so the database would throw. Checking here turns that raw
    constraint error into a message that tells the user what to do
    instead.
  */
  @override
  Future<int> deleteCustomer(int customerId) async {
    final hasHistory = await hasFinancialHistory(customerId);

    if (hasHistory) {
      throw AppFailure(
        code: 'HAS_FINANCIAL_HISTORY',
        message:
            'This customer has transactions or payments on record. '
            'Deactivate them instead — their history has to be kept.',
      );
    }

    return requireRowChanged(
      () => localDataSource.deleteCustomer(customerId),
      failureMessage: "Could not delete this customer.",
      notFoundMessage: "This customer has already been deleted.",
    );
  }

  @override
  Future<bool> hasFinancialHistory(int customerId) {
    return repositoryGuard(
      () => localDataSource.hasFinancialHistory(customerId),
      failureMessage: "Could not check this customer's history.",
    );
  }
}
