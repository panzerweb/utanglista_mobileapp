import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/transactions/data/model/transaction_model.dart';
import 'package:utanglista_mobileapp/features/transactions/data/model/transaction_payload_model.dart';

abstract class TransactionLocalDataSource {
  Future<int> createTransaction(TransactionPayloadModel payload);
  Future<TransactionModel?> fetchTransactionById(int transactionId);
  Future<List<TransactionModel>> fetchTransactions(
    int storeId, {
    int? customerId,
    int? limit,
  });
}

class TransactionLocalDataSourceImplementation
    implements TransactionLocalDataSource {
  final AppDatabase database;

  TransactionLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final transactionsTable = database.transactionsTable;
  late final transactionsItemTable = database.transactionsItemTable;
  late final customersTable = database.customersTable;
  late final productsTable = database.productsTable;

  // ========================================================
  // ** METHODS FOR TABLE **
  // ========================================================

  /*
    ------------------------------------------------------------------
    THE ATOMIC WRITE (§10, §33).
    ------------------------------------------------------------------

    §10 spells out the state that must be impossible:

        transactions        Transaction #1001, Total: ₱500
        transaction_items   (none)

    A transaction without its items is a debt with no explanation —
    the customer is told they owe ₱500 and nothing in the app can say
    what for. So everything below happens in ONE database transaction:
    if any single insert fails, the whole thing rolls back and no
    record is created at all.

    Four things are checked INSIDE the transaction rather than before
    it. Anything checked outside is checked against a database that
    can change before the write lands; inside, the checks and the write
    see the same consistent state:

      1. the customer exists and belongs to this store
      2. the customer is active (§29 — no new utang)
      3. every product exists and belongs to this store
      4. the persisted total equals the sum of what was actually
         written (§8), read back from the rows rather than trusted
  */
  @override
  Future<int> createTransaction(TransactionPayloadModel payload) async {
    try {
      return await database.transaction(() async {
        // ---- 1 & 2: the customer -------------------------------
        final customer = await (database.select(
          customersTable,
        )..where((tbl) => tbl.id.equals(payload.customerId))).getSingleOrNull();

        if (customer == null || customer.storeId != payload.storeId) {
          throw AppFailure(
            code: 'CUSTOMER_NOT_FOUND',
            message: 'That customer is no longer in this store.',
          );
        }

        if (!customer.isActive) {
          throw AppFailure(
            code: 'CUSTOMER_INACTIVE',
            message:
                '${customer.name} is deactivated and cannot take new utang.',
          );
        }

        // ---- 3: the products -----------------------------------
        final productIds = payload.items
            .map((item) => item.productId)
            .toSet();

        final products = await (database.select(
          productsTable,
        )..where((tbl) => tbl.id.isIn(productIds))).get();

        if (products.length != productIds.length ||
            products.any((product) => product.storeId != payload.storeId)) {
          throw AppFailure(
            code: 'PRODUCT_NOT_FOUND',
            message:
                'One of these products is no longer in this store. '
                'Remove it and try again.',
          );
        }

        // ---- the writes ----------------------------------------
        final int transactionId = await database
            .into(transactionsTable)
            .insert(
              TransactionsTableCompanion.insert(
                storeId: payload.storeId,
                customerId: payload.customerId,
                totalAmount: payload.totalAmount.centavos,
                note: Value(payload.normalisedNote),
              ),
            );

        for (final item in payload.items) {
          await database
              .into(transactionsItemTable)
              .insert(
                TransactionsItemTableCompanion.insert(
                  transactionId: transactionId,
                  productId: item.productId,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice.centavos,
                  // §7: the snapshot, written as given.
                  subTotal: item.subTotal.centavos,
                ),
              );
        }

        // ---- 4: §8, verified against what was written ----------
        /*
          Read back rather than trusting the payload. This catches a
          rounding disagreement between Money's arithmetic and what
          actually reached the columns — the one failure mode that
          would otherwise commit a transaction whose total does not
          match its own lines.
        */
        final writtenItems = await (database.select(
          transactionsItemTable,
        )..where((tbl) => tbl.transactionId.equals(transactionId))).get();

        if (writtenItems.length != payload.items.length) {
          throw AppFailure(
            code: 'TRANSACTION_INCOMPLETE',
            message: 'Could not save every item. Nothing was recorded.',
          );
        }

        final writtenTotal = writtenItems
            .map((item) => Money.fromCentavos(item.subTotal))
            .sum();

        if (writtenTotal != payload.totalAmount) {
          throw AppFailure(
            code: 'TOTAL_MISMATCH',
            message:
                'The total did not match the items. Nothing was recorded.',
          );
        }

        return transactionId;
      });
    } catch (e) {
      rethrow;
    }
  }

  /// One transaction with all of its items, product names joined in.
  @override
  Future<TransactionModel?> fetchTransactionById(int transactionId) async {
    try {
      final transactionQuery = database.select(transactionsTable).join([
        innerJoin(
          customersTable,
          customersTable.id.equalsExp(transactionsTable.customerId),
        ),
      ])..where(transactionsTable.id.equals(transactionId));

      final row = await transactionQuery.getSingleOrNull();
      if (row == null) return null;

      final transaction = row.readTable(transactionsTable);
      final customer = row.readTable(customersTable);

      final items = await _fetchItems(transactionId);

      return TransactionModel(
        id: transaction.id,
        storeId: transaction.storeId,
        customerId: transaction.customerId,
        customerName: customer.name,
        totalAmountCentavos: transaction.totalAmount,
        note: transaction.note,
        createdAt: transaction.createdAt,
        items: items,
      );
    } catch (e) {
      rethrow;
    }
  }

  /*
    Transaction history, newest first. Items are NOT loaded — a store
    with a year of trading would otherwise pull every line of every
    transaction to render a list that shows totals.

    [customerId] narrows it to one customer's utang tab.
  */
  @override
  Future<List<TransactionModel>> fetchTransactions(
    int storeId, {
    int? customerId,
    int? limit,
  }) async {
    try {
      final query = database.select(transactionsTable).join([
        innerJoin(
          customersTable,
          customersTable.id.equalsExp(transactionsTable.customerId),
        ),
      ])..where(transactionsTable.storeId.equals(storeId));

      if (customerId != null) {
        query.where(transactionsTable.customerId.equals(customerId));
      }

      /*
        The id tiebreaker is not optional here. Drift stores DateTime as
        unix SECONDS, and a seller recording three utangs in one minute
        is ordinary — without it those rows would reshuffle between
        loads, and the Phase 5 ledger built on this would show a running
        balance that changes order for no reason.
      */
      query.orderBy([
        OrderingTerm.desc(transactionsTable.createdAt),
        OrderingTerm.desc(transactionsTable.id),
      ]);

      if (limit != null) query.limit(limit);

      final rows = await query.get();

      return rows.map((row) {
        final transaction = row.readTable(transactionsTable);
        final customer = row.readTable(customersTable);

        return TransactionModel(
          id: transaction.id,
          storeId: transaction.storeId,
          customerId: transaction.customerId,
          customerName: customer.name,
          totalAmountCentavos: transaction.totalAmount,
          note: transaction.note,
          createdAt: transaction.createdAt,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ========================================================

  /*
    Product name and unit are joined live rather than snapshotted.

    §27 allows a rename to change how a record is DISPLAYED — only
    never to change its amounts, and the amounts live on the item row
    itself. The foreign key is noAction, so the product is always still
    there to join to.
  */
  Future<List<TransactionItemModel>> _fetchItems(int transactionId) async {
    final query = database.select(transactionsItemTable).join([
      innerJoin(
        productsTable,
        productsTable.id.equalsExp(transactionsItemTable.productId),
      ),
    ])..where(transactionsItemTable.transactionId.equals(transactionId));

    query.orderBy([OrderingTerm.asc(transactionsItemTable.id)]);

    final rows = await query.get();

    return rows.map((row) {
      final item = row.readTable(transactionsItemTable);
      final product = row.readTable(productsTable);

      return TransactionItemModel(
        id: item.id,
        transactionId: item.transactionId,
        productId: item.productId,
        productName: product.name,
        unit: product.unit,
        quantity: item.quantity,
        unitPriceCentavos: item.unitPrice,
        subTotalCentavos: item.subTotal,
      );
    }).toList();
  }
}
