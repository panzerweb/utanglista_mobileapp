import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_model.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';

abstract class CustomerLocalDataSource {
  Future<int> createCustomer(CustomerPayloadModel payload);
  Future<CustomerModel?> fetchCustomerById(int customerId);
  Future<List<CustomerModel>> fetchCustomers(
    int storeId, {
    String? search,
    bool includeInactive,
  });
  Future<int> updateCustomer(UpdateCustomerPayloadModel updatePayload);
  Future<int> deleteCustomer(int customerId);
  Future<bool> hasFinancialHistory(int customerId);
}

class CustomerLocalDataSourceImplementation implements CustomerLocalDataSource {
  final AppDatabase database;

  CustomerLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final customersTable = database.customersTable;
  late final transactionsTable = database.transactionsTable;
  late final paymentsTable = database.paymentsTable;
  late final interestRecordsTable = database.interestRecordsTable;

  // ========================================================
  // ** METHODS FOR TABLE **
  // ========================================================
  @override
  Future<int> createCustomer(CustomerPayloadModel payload) async {
    try {
      final int customerId = await database
          .into(customersTable)
          .insert(
            CustomersTableCompanion.insert(
              storeId: payload.storeId,
              name: payload.name,
              contactNumber: Value(payload.normalisedContactNumber),
            ),
          );

      return customerId;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomerModel?> fetchCustomerById(int customerId) async {
    try {
      final row = await (database.select(
        customersTable,
      )..where((tbl) => tbl.id.equals(customerId))).getSingleOrNull();

      if (row == null) return null;

      return CustomerModel.fromTable(row);
    } catch (e) {
      rethrow;
    }
  }

  /*
    [search] matches name or contact number, case-insensitively.
    [includeInactive] false hides deactivated customers (§29) — they
    stay reachable through the filter, never deleted.
  */
  @override
  Future<List<CustomerModel>> fetchCustomers(
    int storeId, {
    String? search,
    bool includeInactive = true,
  }) async {
    try {
      final query = database.select(customersTable)
        ..where((tbl) => tbl.storeId.equals(storeId));

      if (!includeInactive) {
        query.where((tbl) => tbl.isActive.equals(true));
      }

      final term = search?.trim() ?? '';
      if (term.isNotEmpty) {
        /*
          `like` is case-insensitive for ASCII in SQLite, but not for
          accented characters, so both sides are lowered explicitly —
          otherwise searching "jose" would miss "José".

          The term is passed as a bound variable, never concatenated
          into the SQL.
        */
        final pattern = '%${term.toLowerCase()}%';

        query.where(
          (tbl) =>
              tbl.name.lower().like(pattern) |
              tbl.contactNumber.lower().like(pattern),
        );
      }

      /*
        Active first, then newest. The id tiebreaker matters because
        drift stores DateTime as unix SECONDS — customers added in the
        same second would otherwise reshuffle between loads.
      */
      query.orderBy([
        (tbl) => OrderingTerm.desc(tbl.isActive),
        (tbl) => OrderingTerm.desc(tbl.createdAt),
        (tbl) => OrderingTerm.desc(tbl.id),
      ]);

      final rows = await query.get();

      return rows.map(CustomerModel.fromTable).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> updateCustomer(UpdateCustomerPayloadModel updatePayload) async {
    try {
      // An empty companion would match zero rows, which
      // requireRowChanged reads as NOT_FOUND for a customer that exists.
      if (!updatePayload.hasChanges) {
        final existing = await (database.select(
          customersTable,
        )..where((tbl) => tbl.id.equals(updatePayload.customerId)))
            .getSingleOrNull();

        return existing == null ? 0 : 1;
      }

      final int result =
          await (database.update(customersTable)
                ..where((tbl) => tbl.id.equals(updatePayload.customerId)))
              .write(updatePayload.toCompanion());

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /*
    Only ever reached for a customer with no financial history — the
    repository checks first, and the foreign keys refuse it regardless
    (§29, §30). Deactivation is the normal path.
  */
  @override
  Future<int> deleteCustomer(int customerId) async {
    try {
      final result = await (database.delete(
        customersTable,
      )..where((tbl) => tbl.id.equals(customerId))).go();

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /*
    Does this customer appear in any financial record?

    Decides whether the UI offers "deactivate" or "delete" (§29). Uses
    EXISTS with LIMIT 1 per table rather than counting rows: the answer
    is a yes/no, and a customer with a thousand transactions should not
    cost a thousand-row scan to establish that.
  */
  @override
  Future<bool> hasFinancialHistory(int customerId) async {
    try {
      final row = await database
          .customSelect(
            '''
            SELECT EXISTS(
              SELECT 1 FROM transactions_table    WHERE customer_id = :id
              UNION ALL
              SELECT 1 FROM payments_table        WHERE customer_id = :id
              UNION ALL
              SELECT 1 FROM interest_records_table WHERE customer_id = :id
              LIMIT 1
            ) AS has_history
            ''',
            variables: [Variable.withInt(customerId)],
            readsFrom: {
              transactionsTable,
              paymentsTable,
              interestRecordsTable,
            },
          )
          .getSingle();

      return row.read<int>('has_history') == 1;
    } catch (e) {
      rethrow;
    }
  }
}
