import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/features/transactions/data/datasource/transaction_local_data_source.dart';
import 'package:utanglista_mobileapp/features/transactions/data/model/transaction_payload_model.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<int> createTransaction(TransactionPayloadModel payload);
  Future<TransactionEntity?> fetchTransactionById(int transactionId);
  Future<List<TransactionEntity>> fetchTransactions(
    int storeId, {
    int? customerId,
    int? limit,
    String? search,
    TransactionSort sort,
  });
}

class TransactionRepositoryImplementation implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImplementation(this.localDataSource);

  // ========================================================
  // ** TRANSACTION METHODS **
  // ========================================================

  /*
    §24 and §38, checked before the write reaches the database.

    The draft has already enforced these on the way in, and the
    datasource enforces the referential rules on the way out. This
    layer exists because a payload can also be built by something
    other than the builder screen — a future import, a test, Phase 6's
    interest job — and the invariants must hold for all of them.
  */
  /*
    `async` is load-bearing, not decoration.

    Without it a validation failure throws SYNCHRONOUSLY, before the
    Future is ever returned — so a caller doing
    `repository.createTransaction(...).catchError(...)` never sees it
    and the app gets an uncaught exception instead of a failure state.

    Marking the method async makes every failure arrive the same way:
    as a rejected Future, exactly like the ones from repositoryGuard.
  */
  @override
  Future<int> createTransaction(TransactionPayloadModel payload) async {
    final failure = _validate(payload);
    if (failure != null) throw failure;

    return repositoryGuard(
      () => localDataSource.createTransaction(payload),
      failureMessage: "Could not record this utang.",
    );
  }

  @override
  Future<TransactionEntity?> fetchTransactionById(int transactionId) {
    return repositoryGuard(() async {
      final model = await localDataSource.fetchTransactionById(transactionId);
      return model?.toEntity();
    }, failureMessage: "Could not load this transaction.");
  }

  @override
  Future<List<TransactionEntity>> fetchTransactions(
    int storeId, {
    int? customerId,
    int? limit,
    String? search,
    TransactionSort sort = TransactionSort.recent,
  }) {
    return repositoryGuard(() async {
      final models = await localDataSource.fetchTransactions(
        storeId,
        customerId: customerId,
        limit: limit,
        search: search,
        sort: sort,
      );

      return models.map((model) => model.toEntity()).toList();
    }, failureMessage: "Could not load transactions.");
  }

  // ========================================================

  AppFailure? _validate(TransactionPayloadModel payload) {
    // §24: a transaction must contain at least one item.
    if (payload.items.isEmpty) {
      return AppFailure(
        code: 'EMPTY_TRANSACTION',
        message: 'Add at least one item before recording this utang.',
      );
    }

    // §24, §38: quantity must be greater than zero.
    if (payload.items.any((item) => item.quantity <= 0)) {
      return AppFailure(
        code: 'INVALID_QUANTITY',
        message: 'Every item needs a quantity greater than zero.',
      );
    }

    // §25, §38: unit price and subtotal must not be negative.
    if (payload.items.any(
      (item) => item.unitPrice.isNegative || item.subTotal.isNegative,
    )) {
      return AppFailure(
        code: 'NEGATIVE_AMOUNT',
        message: 'An item has a negative amount.',
      );
    }

    // §24: the transaction total must be greater than zero.
    if (!payload.totalAmount.isPositive) {
      return AppFailure(
        code: 'ZERO_TOTAL',
        message: 'The total must be more than ₱0.00.',
      );
    }

    return null;
  }
}
