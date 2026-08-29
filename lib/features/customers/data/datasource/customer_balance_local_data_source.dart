import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_balance_model.dart';

abstract class CustomerBalanceLocalDataSource {
  Future<CustomerBalanceModel> fetchBalanceForCustomer(int customerId);
  Future<Map<int, CustomerBalanceModel>> fetchBalancesForStore(int storeId);
  Future<CustomerBalanceModel> fetchTotalForStore(int storeId);
  Future<CustomerBalanceModel> fetchTotalForAllStores();
}

/*
  ------------------------------------------------------------------
  Raw SQL rather than the query builder, deliberately.
  ------------------------------------------------------------------

  Every method here is a multi-table aggregate. Drift's builder can
  express these, but the resulting Dart obscures the one thing that
  actually matters — the shape of the joins — and the shape is where
  the bug lives. See the fan-out note on fetchBalancesForStore.

  COALESCE is on every SUM: a customer with no payments yet must read
  as zero, not as null. Without it, the very first customer created
  would show a null balance rather than ₱0.00.
*/
class CustomerBalanceLocalDataSourceImplementation
    implements CustomerBalanceLocalDataSource {
  final AppDatabase database;

  CustomerBalanceLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final transactionsTable = database.transactionsTable;
  late final paymentsTable = database.paymentsTable;
  late final interestRecordsTable = database.interestRecordsTable;
  late final customersTable = database.customersTable;

  /// The tables every balance query reads. Declared so drift can
  /// invalidate a `.watch()` correctly if these move to streams later.
  late final Set<ResultSetImplementation<dynamic, dynamic>> _balanceSources = {
    transactionsTable,
    paymentsTable,
    interestRecordsTable,
  };

  // ========================================================
  // ** METHODS FOR BALANCE **
  // ========================================================

  /*
    One customer, one round trip.

    Three correlated subqueries rather than three separate awaits: this
    is read on every customer detail open and before every payment, so
    it stays a single statement.
  */
  @override
  Future<CustomerBalanceModel> fetchBalanceForCustomer(int customerId) async {
    try {
      final row = await database
          .customSelect(
            '''
            SELECT
              (SELECT COALESCE(SUM(total_amount), 0)
                 FROM transactions_table
                WHERE customer_id = :customerId)    AS total_utang,

              (SELECT COALESCE(SUM(interest_amount), 0)
                 FROM interest_records_table
                WHERE customer_id = :customerId)    AS total_interest,

              (SELECT COALESCE(SUM(amount), 0)
                 FROM payments_table
                WHERE customer_id = :customerId)    AS total_paid
            ''',
            variables: [Variable.withInt(customerId)],
            readsFrom: _balanceSources,
          )
          .getSingle();

      return CustomerBalanceModel(
        totalUtangCentavos: row.read<int>('total_utang'),
        totalInterestCentavos: row.read<int>('total_interest'),
        totalPaidCentavos: row.read<int>('total_paid'),
      );
    } catch (e) {
      rethrow;
    }
  }

  /*
    Every customer in a store, still one round trip.

    ------------------------------------------------------------------
    THE FAN-OUT TRAP — why this joins subqueries, not tables.
    ------------------------------------------------------------------

    The obvious version is wrong:

      FROM customers c
      LEFT JOIN transactions t ON t.customer_id = c.id
      LEFT JOIN payments     p ON p.customer_id = c.id
      GROUP BY c.id

    A customer with 2 transactions and 3 payments produces 2 × 3 = 6
    rows, so SUM(t.total_amount) counts every transaction three times
    and SUM(p.amount) counts every payment twice. The customer's debt
    silently triples. Nothing errors; the number is just wrong, and it
    gets wronger the more the customer trades.

    Aggregating each table to one row per customer BEFORE joining means
    there is nothing left to multiply.
  */
  @override
  Future<Map<int, CustomerBalanceModel>> fetchBalancesForStore(
    int storeId,
  ) async {
    try {
      final rows = await database
          .customSelect(
            '''
            SELECT
              c.id                        AS customer_id,
              COALESCE(t.total, 0)        AS total_utang,
              COALESCE(i.total, 0)        AS total_interest,
              COALESCE(p.total, 0)        AS total_paid
            FROM customers_table c

            LEFT JOIN (
              SELECT customer_id, SUM(total_amount) AS total
                FROM transactions_table
               GROUP BY customer_id
            ) t ON t.customer_id = c.id

            LEFT JOIN (
              SELECT customer_id, SUM(interest_amount) AS total
                FROM interest_records_table
               GROUP BY customer_id
            ) i ON i.customer_id = c.id

            LEFT JOIN (
              SELECT customer_id, SUM(amount) AS total
                FROM payments_table
               GROUP BY customer_id
            ) p ON p.customer_id = c.id

            WHERE c.store_id = :storeId
            ''',
            variables: [Variable.withInt(storeId)],
            readsFrom: {..._balanceSources, customersTable},
          )
          .get();

      return {
        for (final row in rows)
          row.read<int>('customer_id'): CustomerBalanceModel(
            totalUtangCentavos: row.read<int>('total_utang'),
            totalInterestCentavos: row.read<int>('total_interest'),
            totalPaidCentavos: row.read<int>('total_paid'),
          ),
      };
    } catch (e) {
      rethrow;
    }
  }

  /*
    Store-wide totals for the dashboard.

    Summed over the store's own rows rather than over per-customer
    outstanding figures. The two agree only while §23 holds and no
    customer can be overpaid — if customer credits are ever introduced,
    this has to change to clamp each customer at zero first, or one
    overpaid customer would quietly reduce the store's receivable.
  */
  @override
  Future<CustomerBalanceModel> fetchTotalForStore(int storeId) async {
    try {
      final row = await database
          .customSelect(
            '''
            SELECT
              (SELECT COALESCE(SUM(total_amount), 0)
                 FROM transactions_table
                WHERE store_id = :storeId)          AS total_utang,

              (SELECT COALESCE(SUM(interest_amount), 0)
                 FROM interest_records_table
                WHERE store_id = :storeId)          AS total_interest,

              (SELECT COALESCE(SUM(amount), 0)
                 FROM payments_table
                WHERE store_id = :storeId)          AS total_paid
            ''',
            variables: [Variable.withInt(storeId)],
            readsFrom: _balanceSources,
          )
          .getSingle();

      return CustomerBalanceModel(
        totalUtangCentavos: row.read<int>('total_utang'),
        totalInterestCentavos: row.read<int>('total_interest'),
        totalPaidCentavos: row.read<int>('total_paid'),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Everything the user is owed, across every store. The dashboard's
  /// headline figure.
  @override
  Future<CustomerBalanceModel> fetchTotalForAllStores() async {
    try {
      final row = await database
          .customSelect(
            '''
            SELECT
              (SELECT COALESCE(SUM(total_amount), 0)
                 FROM transactions_table)           AS total_utang,

              (SELECT COALESCE(SUM(interest_amount), 0)
                 FROM interest_records_table)       AS total_interest,

              (SELECT COALESCE(SUM(amount), 0)
                 FROM payments_table)               AS total_paid
            ''',
            readsFrom: _balanceSources,
          )
          .getSingle();

      return CustomerBalanceModel(
        totalUtangCentavos: row.read<int>('total_utang'),
        totalInterestCentavos: row.read<int>('total_interest'),
        totalPaidCentavos: row.read<int>('total_paid'),
      );
    } catch (e) {
      rethrow;
    }
  }
}
