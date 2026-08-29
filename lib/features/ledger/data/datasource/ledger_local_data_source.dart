import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/ledger/domain/entities/ledger_entry.dart';

abstract class LedgerLocalDataSource {
  Future<List<LedgerEntry>> fetchEntriesForCustomer(int customerId);
}

/*
  ------------------------------------------------------------------
  One query across the three financial event tables.
  ------------------------------------------------------------------

  §17: "The ledger can be constructed from transactions, payments,
  interest_records. There is no requirement for a separate ledger
  table in the initial implementation."

  UNION ALL rather than three round trips, so the whole chronology
  arrives in one read. Each branch pads the columns it does not have,
  because a UNION needs matching shapes.

  The utang branch counts its items with a correlated subquery instead
  of joining transaction_items — a join would multiply the transaction
  row once per line, and the amounts would be wrong in exactly the
  fan-out way the balance query already had to avoid.
*/
class LedgerLocalDataSourceImplementation implements LedgerLocalDataSource {
  final AppDatabase database;

  LedgerLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final transactionsTable = database.transactionsTable;
  late final transactionsItemTable = database.transactionsItemTable;
  late final paymentsTable = database.paymentsTable;
  late final interestRecordsTable = database.interestRecordsTable;

  // ========================================================
  // ** METHODS **
  // ========================================================
  @override
  Future<List<LedgerEntry>> fetchEntriesForCustomer(int customerId) async {
    try {
      final rows = await database
          .customSelect(
            '''
            SELECT
              'utang'                       AS kind,
              t.id                          AS source_id,
              t.created_at                  AS occurred_at,
              t.total_amount                AS amount,
              COALESCE(t.note, '')          AS note,
              0                             AS rate_basis_points,
              ''                            AS period_key,
              (SELECT COUNT(*)
                 FROM transactions_item_table i
                WHERE i.transaction_id = t.id) AS item_count
            FROM transactions_table t
            WHERE t.customer_id = :customerId

            UNION ALL

            SELECT
              'payment',
              p.id,
              p.created_at,
              p.amount,
              COALESCE(p.note, ''),
              0,
              '',
              0
            FROM payments_table p
            WHERE p.customer_id = :customerId

            UNION ALL

            SELECT
              'interest',
              r.id,
              r.created_at,
              r.interest_amount,
              '',
              r.rate_basis_points,
              r.period_key,
              0
            FROM interest_records_table r
            WHERE r.customer_id = :customerId

            ORDER BY occurred_at ASC, source_id ASC
            ''',
            variables: [Variable.withInt(customerId)],
            readsFrom: {
              transactionsTable,
              transactionsItemTable,
              paymentsTable,
              interestRecordsTable,
            },
          )
          .get();

      return rows.map(_toEntry).toList();
    } catch (e) {
      rethrow;
    }
  }

  LedgerEntry _toEntry(QueryRow row) {
    final kind = row.read<String>('kind');
    final sourceId = row.read<int>('source_id');
    final occurredAt = row.read<DateTime>('occurred_at');
    final amount = Money.fromCentavos(row.read<int>('amount'));

    switch (kind) {
      case 'payment':
        return LedgerPaymentEntry(
          sourceId: sourceId,
          occurredAt: occurredAt,
          paid: amount,
          note: row.read<String>('note'),
        );

      case 'interest':
        return LedgerInterestEntry(
          sourceId: sourceId,
          occurredAt: occurredAt,
          charged: amount,
          rateBasisPoints: row.read<int>('rate_basis_points'),
          periodKey: row.read<String>('period_key'),
        );

      default:
        return LedgerUtangEntry(
          sourceId: sourceId,
          occurredAt: occurredAt,
          total: amount,
          itemCount: row.read<int>('item_count'),
          note: row.read<String>('note'),
        );
    }
  }
}
