import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/dashboard/domain/entities/dashboard_summary.dart';

abstract class DashboardLocalDataSource {
  Future<List<StoreSummary>> fetchStoreSummaries();
  Future<List<TopDebtor>> fetchTopDebtors({int limit});
  Future<List<RecentActivity>> fetchRecentActivity({int limit});
}

/*
  ------------------------------------------------------------------
  Three queries for the whole dashboard.
  ------------------------------------------------------------------

  Raw SQL for the same reason the balance queries use it: these are
  multi-table aggregates, and the shape of the joins is the thing that
  matters. Every one of them re-expresses the §15 formula —

      Σ transactions + Σ interest − Σ payments

  — never a variation of it.
*/
class DashboardLocalDataSourceImplementation
    implements DashboardLocalDataSource {
  final AppDatabase database;

  DashboardLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final storesTable = database.storesTable;
  late final customersTable = database.customersTable;
  late final transactionsTable = database.transactionsTable;
  late final paymentsTable = database.paymentsTable;
  late final interestRecordsTable = database.interestRecordsTable;

  late final Set<ResultSetImplementation<dynamic, dynamic>> _financialTables = {
    transactionsTable,
    paymentsTable,
    interestRecordsTable,
  };

  // ========================================================
  // ** STORE SUMMARIES **
  // ========================================================

  /*
    Per-store totals sum the STORE's own rows rather than folding
    per-customer balances, which is cheaper and agrees with them while
    §23 holds and nobody can be overpaid — the same reasoning, and the
    same caveat, as CustomerBalanceRepository.fetchTotalForStore.

    `debtor_count` is the expensive part: it has to evaluate a balance
    per customer. It is worth it — "4 of 12 owe you" is the number a
    seller actually reads — and N here is the handful of businesses one
    person runs, not their customer list.
  */
  @override
  Future<List<StoreSummary>> fetchStoreSummaries() async {
    try {
      final rows = await database
          .customSelect(
            '''
            SELECT
              s.id                AS store_id,
              s.name              AS store_name,
              s.category          AS category,

              (SELECT COUNT(*) FROM customers_table c
                WHERE c.store_id = s.id)                AS customer_count,

              (SELECT COALESCE(SUM(total_amount), 0)
                 FROM transactions_table
                WHERE store_id = s.id)                  AS total_utang,

              (SELECT COALESCE(SUM(interest_amount), 0)
                 FROM interest_records_table
                WHERE store_id = s.id)                  AS total_interest,

              (SELECT COALESCE(SUM(amount), 0)
                 FROM payments_table
                WHERE store_id = s.id)                  AS total_paid,

              (SELECT COUNT(*) FROM customers_table c
                WHERE c.store_id = s.id
                  AND (
                        COALESCE((SELECT SUM(total_amount)
                                    FROM transactions_table
                                   WHERE customer_id = c.id), 0)
                      + COALESCE((SELECT SUM(interest_amount)
                                    FROM interest_records_table
                                   WHERE customer_id = c.id), 0)
                      - COALESCE((SELECT SUM(amount)
                                    FROM payments_table
                                   WHERE customer_id = c.id), 0)
                      ) > 0
              )                                          AS debtor_count

            FROM stores_table s
            ORDER BY s.created_at DESC, s.id DESC
            ''',
            readsFrom: {customersTable, storesTable, ..._financialTables},
          )
          .get();

      return rows.map((row) {
        return StoreSummary(
          storeId: row.read<int>('store_id'),
          storeName: row.read<String>('store_name'),
          category: StoreCategory.fromValue(
            row.read<String?>('category'),
          ),
          customerCount: row.read<int>('customer_count'),
          debtorCount: row.read<int>('debtor_count'),
          balance: CustomerBalance(
            totalUtang: Money.fromCentavos(row.read<int>('total_utang')),
            totalInterest: Money.fromCentavos(
              row.read<int>('total_interest'),
            ),
            totalPaid: Money.fromCentavos(row.read<int>('total_paid')),
          ),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================
  // ** TOP DEBTORS **
  // ========================================================

  /*
    Who owes the most, across every store.

    The balance is computed in an inner SELECT and filtered in the
    outer one, because SQLite cannot reference a column alias from a
    WHERE clause — repeating the whole expression there would be a
    second place for the formula to drift.

    Pre-aggregated subqueries again: joining the raw tables would
    multiply a customer's transactions by their payments.
  */
  @override
  Future<List<TopDebtor>> fetchTopDebtors({int limit = 5}) async {
    try {
      final rows = await database
          .customSelect(
            '''
            SELECT * FROM (
              SELECT
                c.id                     AS customer_id,
                c.store_id               AS store_id,
                c.name                   AS customer_name,
                s.name                   AS store_name,
                COALESCE(t.total, 0)     AS total_utang,
                COALESCE(i.total, 0)     AS total_interest,
                COALESCE(p.total, 0)     AS total_paid
              FROM customers_table c

              INNER JOIN stores_table s ON s.id = c.store_id

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
            )
            WHERE (total_utang + total_interest - total_paid) > 0
            ORDER BY (total_utang + total_interest - total_paid) DESC,
                     customer_id ASC
            LIMIT :limit
            ''',
            variables: [Variable.withInt(limit)],
            readsFrom: {customersTable, storesTable, ..._financialTables},
          )
          .get();

      return rows.map((row) {
        return TopDebtor(
          customerId: row.read<int>('customer_id'),
          storeId: row.read<int>('store_id'),
          customerName: row.read<String>('customer_name'),
          storeName: row.read<String>('store_name'),
          balance: CustomerBalance(
            totalUtang: Money.fromCentavos(row.read<int>('total_utang')),
            totalInterest: Money.fromCentavos(
              row.read<int>('total_interest'),
            ),
            totalPaid: Money.fromCentavos(row.read<int>('total_paid')),
          ),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================
  // ** RECENT ACTIVITY **
  // ========================================================

  /*
    The latest utang and payments, across every store.

    Interest is deliberately left out: it arrives as a monthly batch
    that would swamp the list, and it is already visible on the store
    that charged it.

    The `id` tiebreak is per-table, so two events in the same second
    from different tables have no guaranteed order between them. That
    is fine for a glanceable feed — the customer ledger is where order
    is load-bearing, and it sorts by kind for exactly that reason.
  */
  @override
  Future<List<RecentActivity>> fetchRecentActivity({int limit = 8}) async {
    try {
      final rows = await database
          .customSelect(
            '''
            SELECT
              'utang'          AS kind,
              t.id             AS source_id,
              t.store_id       AS store_id,
              t.customer_id    AS customer_id,
              c.name           AS customer_name,
              s.name           AS store_name,
              t.total_amount   AS amount,
              t.created_at     AS occurred_at
            FROM transactions_table t
            INNER JOIN customers_table c ON c.id = t.customer_id
            INNER JOIN stores_table s ON s.id = t.store_id

            UNION ALL

            SELECT
              'payment',
              p.id,
              p.store_id,
              p.customer_id,
              c.name,
              s.name,
              p.amount,
              p.created_at
            FROM payments_table p
            INNER JOIN customers_table c ON c.id = p.customer_id
            INNER JOIN stores_table s ON s.id = p.store_id

            ORDER BY occurred_at DESC, source_id DESC
            LIMIT :limit
            ''',
            variables: [Variable.withInt(limit)],
            readsFrom: {
              customersTable,
              storesTable,
              transactionsTable,
              paymentsTable,
            },
          )
          .get();

      return rows.map((row) {
        return RecentActivity(
          kind: row.read<String>('kind') == 'payment'
              ? ActivityKind.payment
              : ActivityKind.utang,
          sourceId: row.read<int>('source_id'),
          storeId: row.read<int>('store_id'),
          customerId: row.read<int>('customer_id'),
          customerName: row.read<String>('customer_name'),
          storeName: row.read<String>('store_name'),
          amount: Money.fromCentavos(row.read<int>('amount')),
          occurredAt: row.read<DateTime>('occurred_at'),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
