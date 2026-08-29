import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/interest/domain/entities/interest_preview.dart';
import 'package:utanglista_mobileapp/features/interest/domain/entities/interest_record_entity.dart';

abstract class InterestLocalDataSource {
  Future<InterestPreview> buildPreview({
    required int storeId,
    required String periodKey,
    required InterestRate rate,
  });

  Future<InterestApplicationResult> applyInterest({
    required int storeId,
    required String periodKey,
    required InterestRate rate,
  });

  Future<List<InterestRecordEntity>> fetchRecords(
    int storeId, {
    int? customerId,
    String? periodKey,
    String? search,
    InterestSort sort,
  });
}

class InterestLocalDataSourceImplementation implements InterestLocalDataSource {
  final AppDatabase database;

  InterestLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final interestRecordsTable = database.interestRecordsTable;
  late final customersTable = database.customersTable;
  late final transactionsTable = database.transactionsTable;
  late final paymentsTable = database.paymentsTable;

  // ========================================================
  // ** PREVIEW **
  // ========================================================

  /*
    Every customer in the store, the balance they carried INTO this
    period, and whether the period has already been charged — in one
    query.

    ------------------------------------------------------------------
    The base is the balance at the period's START, not "now".
    ------------------------------------------------------------------

    §20 says interest is charged on the "applicable outstanding
    balance". Applicable means what the customer owed ENTERING the
    month: every event strictly before `:cutoff`, and nothing from the
    month itself.

    Two things follow, both deliberate:

      a debt taken on 20 August is NOT charged in August. It first
      attracts interest in September — about a month after it was
      created, rather than on whatever day the seller happened to run
      the charge.

      charging a PAST month uses that month's numbers. Without the
      cutoff, stepping back to August in September computed 2% of the
      September balance and labelled it August.

    Interest records are included in the base, so charges compound —
    and because each is dated to the period it covers (see
    AppDateFormat.interestEffectiveDate), August's charge falls inside
    September's cutoff even if the seller ran it late.

    Same fan-out-safe shape as the balance query: each financial table
    is aggregated to one row per customer BEFORE joining, so two
    transactions and three payments cannot multiply each other.
  */
  @override
  Future<InterestPreview> buildPreview({
    required int storeId,
    required String periodKey,
    required InterestRate rate,
  }) async {
    try {
      final cutoff = AppDateFormat.periodStart(periodKey);
      if (cutoff == null) {
        throw AppFailure(
          code: 'INVALID_PERIOD',
          message: 'That month is not valid.',
        );
      }

      final rows = await database
          .customSelect(
            '''
            SELECT
              c.id                   AS customer_id,
              c.name                 AS customer_name,
              c.is_active            AS is_active,
              COALESCE(t.total, 0)   AS total_utang,
              COALESCE(i.total, 0)   AS total_interest,
              COALESCE(p.total, 0)   AS total_paid,
              EXISTS(
                SELECT 1 FROM interest_records_table r
                 WHERE r.customer_id = c.id
                   AND r.period_key = :periodKey
              )                      AS already_applied
            FROM customers_table c

            LEFT JOIN (
              SELECT customer_id, SUM(total_amount) AS total
                FROM transactions_table
               WHERE created_at < :cutoff
               GROUP BY customer_id
            ) t ON t.customer_id = c.id

            LEFT JOIN (
              SELECT customer_id, SUM(interest_amount) AS total
                FROM interest_records_table
               WHERE created_at < :cutoff
               GROUP BY customer_id
            ) i ON i.customer_id = c.id

            LEFT JOIN (
              SELECT customer_id, SUM(amount) AS total
                FROM payments_table
               WHERE created_at < :cutoff
               GROUP BY customer_id
            ) p ON p.customer_id = c.id

            WHERE c.store_id = :storeId
            ORDER BY c.name ASC, c.id ASC
            ''',
            variables: [
              Variable.withString(periodKey),
              Variable.withDateTime(cutoff),
              Variable.withInt(storeId),
            ],
            readsFrom: {
              customersTable,
              transactionsTable,
              paymentsTable,
              interestRecordsTable,
            },
          )
          .get();

      final lines = rows
          .map((row) => _previewLine(row, rate))
          .toList();

      return InterestPreview(
        periodKey: periodKey,
        rate: rate,
        lines: lines,
      );
    } catch (e) {
      rethrow;
    }
  }

  InterestPreviewLine _previewLine(QueryRow row, InterestRate rate) {
    final customerId = row.read<int>('customer_id');
    final customerName = row.read<String>('customer_name');
    final isActive = row.read<bool>('is_active');
    final alreadyApplied = row.read<int>('already_applied') == 1;

    // §15, exactly as CustomerBalance computes it.
    final outstanding =
        Money.fromCentavos(row.read<int>('total_utang')) +
        Money.fromCentavos(row.read<int>('total_interest')) -
        Money.fromCentavos(row.read<int>('total_paid'));

    final interest = outstanding.isPositive
        ? outstanding.applyRateBasisPoints(rate.basisPoints)
        : Money.zero;

    /*
      Order matters. §22 comes first — a customer already charged this
      month is reported as such even if their balance has since gone to
      zero, because "already charged" is the more useful answer.
    */
    final status = alreadyApplied
        ? InterestPreviewStatus.alreadyApplied
        : !isActive
        ? InterestPreviewStatus.inactive
        : !outstanding.isPositive
        ? InterestPreviewStatus.nothingOwed
        : interest.isZero
        ? InterestPreviewStatus.roundsToZero
        : InterestPreviewStatus.willApply;

    return InterestPreviewLine(
      customerId: customerId,
      customerName: customerName,
      baseAmount: outstanding,
      interestAmount: interest,
      status: status,
    );
  }

  // ========================================================
  // ** APPLY **
  // ========================================================

  /*
    ------------------------------------------------------------------
    ONE TRANSACTION PER CUSTOMER, not one for the batch.
    ------------------------------------------------------------------

    §33 describes applying interest as its own BEGIN/COMMIT:

        BEGIN
        Calculate applicable balance
        Create interest record
        COMMIT

    That is per customer, and it is right. Wrapping fifty customers in
    one transaction would mean the fiftieth failing undoes the other
    forty-nine — and the most likely failure is §22's unique index
    firing because that customer was already charged. A partial batch
    is the CORRECT outcome there, not a compromise: the ones that
    succeeded should stay.

    The balance is recomputed inside each transaction rather than taken
    from the preview. The preview may be minutes old by the time the
    seller confirms, and §21 requires the recorded base to be the
    balance the charge was actually computed from.
  */
  @override
  Future<InterestApplicationResult> applyInterest({
    required int storeId,
    required String periodKey,
    required InterestRate rate,
  }) async {
    try {
      final preview = await buildPreview(
        storeId: storeId,
        periodKey: periodKey,
        rate: rate,
      );

      final cutoff = AppDateFormat.periodStart(periodKey);
      if (cutoff == null) {
        throw AppFailure(
          code: 'INVALID_PERIOD',
          message: 'That month is not valid.',
        );
      }

      // Dated to the period it covers, not the wall clock — see
      // AppDateFormat.interestEffectiveDate for why both the ledger and
      // compounding depend on that.
      final effectiveDate = AppDateFormat.interestEffectiveDate(periodKey);

      var appliedCount = 0;
      var totalCharged = Money.zero;
      final failures = <String, String>{};

      for (final line in preview.toCharge) {
        try {
          final charged = await database.transaction(() async {
            // Re-read: the preview is a snapshot, this is the truth at
            // the moment of writing. Same cutoff, so a transaction
            // added since the preview cannot sneak into the base.
            final outstanding = await _outstandingBalance(
              line.customerId,
              before: cutoff,
            );

            if (!outstanding.isPositive) return Money.zero;

            final interest = outstanding.applyRateBasisPoints(
              rate.basisPoints,
            );

            // A zero charge is not worth a permanent record.
            if (interest.isZero) return Money.zero;

            await database
                .into(interestRecordsTable)
                .insert(
                  InterestRecordsTableCompanion.insert(
                    storeId: storeId,
                    customerId: line.customerId,
                    // §21: rate and base recorded WITH the charge, so
                    // changing the store's rate later cannot rewrite
                    // what was already applied.
                    rateBasisPoints: rate.basisPoints,
                    baseAmount: outstanding.centavos,
                    interestAmount: interest.centavos,
                    periodKey: periodKey,
                    createdAt: Value(effectiveDate),
                  ),
                );

            return interest;
          });

          if (charged.isPositive) {
            appliedCount++;
            totalCharged = totalCharged + charged;
          }
        } catch (e) {
          /*
            Almost always §22's unique index: something charged this
            customer for this period between the preview and now. That
            is the guard working, so it is reported rather than thrown —
            the rest of the batch must still complete.
          */
          failures[line.customerName] =
              'Could not charge — may already have been charged '
              'for this month.';
        }
      }

      return InterestApplicationResult(
        periodKey: periodKey,
        appliedCount: appliedCount,
        totalCharged: totalCharged,
        failures: failures,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================
  // ** HISTORY **
  // ========================================================
  @override
  Future<List<InterestRecordEntity>> fetchRecords(
    int storeId, {
    int? customerId,
    String? periodKey,
    String? search,
    InterestSort sort = InterestSort.newestPeriod,
  }) async {
    try {
      final query = database.select(interestRecordsTable).join([
        innerJoin(
          customersTable,
          customersTable.id.equalsExp(interestRecordsTable.customerId),
        ),
      ])..where(interestRecordsTable.storeId.equals(storeId));

      if (customerId != null) {
        query.where(interestRecordsTable.customerId.equals(customerId));
      }
      if (periodKey != null) {
        query.where(interestRecordsTable.periodKey.equals(periodKey));
      }

      /*
        Searches the charged customer's name only. A charge has no note
        of its own — §21 records figures, not prose — so there is
        nothing else here worth matching on.
      */
      final term = search?.trim() ?? '';
      if (term.isNotEmpty) {
        query.where(
          customersTable.name.lower().like('%${term.toLowerCase()}%'),
        );
      }

      /*
        Ordered by the period a charge COVERS, not when it was written.
        periodKey is zero-padded 'YYYY-MM', so it sorts chronologically
        as text — see AppDateFormat.periodKey. §21 dates a charge to its
        period deliberately; sorting by createdAt would put an August
        charge applied in September among the September ones.
      */
      query.orderBy(switch (sort) {
        InterestSort.newestPeriod => [
          OrderingTerm.desc(interestRecordsTable.periodKey),
          OrderingTerm.desc(interestRecordsTable.id),
        ],
        InterestSort.oldestPeriod => [
          OrderingTerm.asc(interestRecordsTable.periodKey),
          OrderingTerm.asc(interestRecordsTable.id),
        ],
        InterestSort.amountHighLow => [
          OrderingTerm.desc(interestRecordsTable.interestAmount),
          OrderingTerm.desc(interestRecordsTable.id),
        ],
      });

      final rows = await query.get();

      return rows.map((row) {
        final record = row.readTable(interestRecordsTable);
        final customer = row.readTable(customersTable);

        return InterestRecordEntity(
          id: record.id,
          storeId: record.storeId,
          customerId: record.customerId,
          customerName: customer.name,
          baseAmount: Money.fromCentavos(record.baseAmount),
          rate: InterestRate.fromBasisPoints(record.rateBasisPoints),
          interestAmount: Money.fromCentavos(record.interestAmount),
          periodKey: record.periodKey,
          createdAt: record.createdAt,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================

  /*
    §15, as of a point in time, computed inside the caller's
    transaction.

    [before] is the period start: only events strictly before it count
    toward the base. That is what "the balance the customer carried
    into this month" means.

    The second of the two places this formula is duplicated — the other
    is the payment guard, for the same reason: a balance read outside
    the write's transaction can be stale by the time the write lands.
    Both sites say so; nothing else may copy it.
  */
  Future<Money> _outstandingBalance(
    int customerId, {
    required DateTime before,
  }) async {
    final row = await database
        .customSelect(
          '''
          SELECT
            (SELECT COALESCE(SUM(total_amount), 0)
               FROM transactions_table
              WHERE customer_id = :customerId
                AND created_at < :before)           AS total_utang,

            (SELECT COALESCE(SUM(interest_amount), 0)
               FROM interest_records_table
              WHERE customer_id = :customerId
                AND created_at < :before)           AS total_interest,

            (SELECT COALESCE(SUM(amount), 0)
               FROM payments_table
              WHERE customer_id = :customerId
                AND created_at < :before)           AS total_paid
          ''',
          variables: [
            Variable.withInt(customerId),
            Variable.withDateTime(before),
          ],
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
}
