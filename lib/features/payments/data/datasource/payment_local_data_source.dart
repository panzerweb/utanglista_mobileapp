import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/payments/data/model/payment_model.dart';

abstract class PaymentLocalDataSource {
  Future<int> recordPayment(PaymentPayloadModel payload);
  Future<PaymentModel?> fetchPaymentById(int paymentId);
  Future<List<PaymentModel>> fetchPayments(
    int storeId, {
    int? customerId,
    int? limit,
    String? search,
    PaymentSort sort,
  });
}

class PaymentLocalDataSourceImplementation implements PaymentLocalDataSource {
  final AppDatabase database;

  PaymentLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final paymentsTable = database.paymentsTable;
  late final customersTable = database.customersTable;
  late final transactionsTable = database.transactionsTable;
  late final interestRecordsTable = database.interestRecordsTable;

  // ========================================================
  // ** METHODS FOR TABLE **
  // ========================================================

  /*
    ------------------------------------------------------------------
    THE OVERPAYMENT GUARD (§23) — and why it lives in here.
    ------------------------------------------------------------------

    §23: "For V1, payments should not exceed the customer's outstanding
    balance." Do not silently create Balance = −₱200.

    The obvious implementation reads the balance, compares, then
    inserts. That has a race the seller would never be able to explain:

        balance is ₱500
        tap 1 reads ₱500, passes its check
        tap 2 reads ₱500, passes its check      <- still the old balance
        tap 1 inserts ₱500
        tap 2 inserts ₱500
        balance is now −₱500

    A double tap, or the same phone used twice in quick succession, and
    the ledger is wrong in a direction the app claims is impossible.

    So the balance is read and the payment inserted inside ONE
    database transaction. Drift serialises transactions on its single
    connection, so the balance this reads cannot change before this
    write lands — the check and the insert see the same state.

    The UI's own check (CustomerBalance.canAcceptPayment) is a
    courtesy so the seller is told before they tap. THIS is the one
    that actually holds.
  */
  @override
  Future<int> recordPayment(PaymentPayloadModel payload) async {
    try {
      return await database.transaction(() async {
        final customer = await (database.select(
          customersTable,
        )..where((tbl) => tbl.id.equals(payload.customerId))).getSingleOrNull();

        if (customer == null || customer.storeId != payload.storeId) {
          throw AppFailure(
            code: 'CUSTOMER_NOT_FOUND',
            message: 'That customer is no longer in this store.',
          );
        }

        // §38: a payment is always positive. A refund would be an
        // explicit business event, never a negative payment (§25).
        if (!payload.amount.isPositive) {
          throw AppFailure(
            code: 'INVALID_AMOUNT',
            message: 'Enter an amount greater than ₱0.00.',
          );
        }

        /*
          The §15 balance, computed here rather than through
          CustomerBalanceRepository — that repository opens its own
          query outside this transaction, which is exactly the race
          described above. Same formula, read inside the lock.
        */
        final outstanding = await _outstandingBalance(payload.customerId);

        if (!outstanding.isPositive) {
          throw AppFailure(
            code: 'NO_OUTSTANDING_BALANCE',
            message: '${customer.name} does not owe anything right now.',
          );
        }

        if (payload.amount > outstanding) {
          throw AppFailure(
            code: 'OVERPAYMENT',
            // The actual figure, so the seller can fix it in one step
            // instead of guessing.
            message:
                '${customer.name} only owes ${outstanding.format()}. '
                'Enter that or less.',
            details: {'outstandingCentavos': outstanding.centavos},
          );
        }

        return database
            .into(paymentsTable)
            .insert(
              PaymentsTableCompanion.insert(
                storeId: payload.storeId,
                customerId: payload.customerId,
                amount: payload.amount.centavos,
                note: Value(payload.normalisedNote),
              ),
            );
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaymentModel?> fetchPaymentById(int paymentId) async {
    try {
      final query = database.select(paymentsTable).join([
        innerJoin(
          customersTable,
          customersTable.id.equalsExp(paymentsTable.customerId),
        ),
      ])..where(paymentsTable.id.equals(paymentId));

      final row = await query.getSingleOrNull();
      if (row == null) return null;

      return _toModel(row.readTable(paymentsTable), row.readTable(customersTable));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PaymentModel>> fetchPayments(
    int storeId, {
    int? customerId,
    int? limit,
    String? search,
    PaymentSort sort = PaymentSort.recent,
  }) async {
    try {
      final query = database.select(paymentsTable).join([
        innerJoin(
          customersTable,
          customersTable.id.equalsExp(paymentsTable.customerId),
        ),
      ])..where(paymentsTable.storeId.equals(storeId));

      if (customerId != null) {
        query.where(paymentsTable.customerId.equals(customerId));
      }

      /*
        Searches the payer's name and the payment's note — "bayad ni
        Juan" and "partial" are the two things a seller remembers. The
        customer table is already joined for the name.
      */
      final term = search?.trim() ?? '';
      if (term.isNotEmpty) {
        final pattern = '%${term.toLowerCase()}%';

        query.where(
          customersTable.name.lower().like(pattern) |
              paymentsTable.note.lower().like(pattern),
        );
      }

      /*
        The id tiebreaker again: drift stores DateTime as unix seconds,
        and two payments in one minute is ordinary. It follows the
        direction of the sort — oldest-first breaking ties by descending
        id would reverse same-second pairs.
      */
      query.orderBy(switch (sort) {
        PaymentSort.recent => [
          OrderingTerm.desc(paymentsTable.createdAt),
          OrderingTerm.desc(paymentsTable.id),
        ],
        PaymentSort.oldest => [
          OrderingTerm.asc(paymentsTable.createdAt),
          OrderingTerm.asc(paymentsTable.id),
        ],
        PaymentSort.amountHighLow => [
          OrderingTerm.desc(paymentsTable.amount),
          OrderingTerm.desc(paymentsTable.id),
        ],
      });

      if (limit != null) query.limit(limit);

      final rows = await query.get();

      return rows
          .map(
            (row) => _toModel(
              row.readTable(paymentsTable),
              row.readTable(customersTable),
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================

  /*
    §15: Σ transactions + Σ interest − Σ payments.

    Deliberately the same formula CustomerBalance uses. It is repeated
    here ONLY because it must run inside the payment's transaction —
    see the guard note above. If §15 ever changes, both must change:
    this is the one place in the app where that duplication is
    accepted, and it is accepted because the alternative is a race on
    the app's most sensitive write.
  */
  Future<Money> _outstandingBalance(int customerId) async {
    final row = await database
        .customSelect(
          '''
          SELECT
            (SELECT COALESCE(SUM(total_amount), 0)
               FROM transactions_table
              WHERE customer_id = :customerId)      AS total_utang,

            (SELECT COALESCE(SUM(interest_amount), 0)
               FROM interest_records_table
              WHERE customer_id = :customerId)      AS total_interest,

            (SELECT COALESCE(SUM(amount), 0)
               FROM payments_table
              WHERE customer_id = :customerId)      AS total_paid
          ''',
          variables: [Variable.withInt(customerId)],
          readsFrom: {
            transactionsTable,
            interestRecordsTable,
            paymentsTable,
          },
        )
        .getSingle();

    return Money.fromCentavos(row.read<int>('total_utang')) +
        Money.fromCentavos(row.read<int>('total_interest')) -
        Money.fromCentavos(row.read<int>('total_paid'));
  }

  PaymentModel _toModel(
    PaymentsTableData payment,
    CustomersTableData customer,
  ) {
    return PaymentModel(
      id: payment.id,
      storeId: payment.storeId,
      customerId: payment.customerId,
      customerName: customer.name,
      amountCentavos: payment.amount,
      note: payment.note,
      createdAt: payment.createdAt,
    );
  }
}
