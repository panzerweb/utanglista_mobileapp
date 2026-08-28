import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';
import 'package:utanglista_mobileapp/features/products/domain/entities/product_entity.dart';
import 'package:utanglista_mobileapp/features/transactions/data/model/transaction_payload_model.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_draft.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:utanglista_mobileapp/features/transactions/presentation/bloc/transaction_state.dart';

/*
  TRANSACTION LIST CUBIT:

  A store's transaction history, or one customer's.
*/
class TransactionListCubit extends Cubit<TransactionListState> {
  final TransactionRepository repository;

  TransactionListCubit(
    this.repository, {
    required int storeId,
    int? customerId,
  }) : super(
         TransactionListState(storeId: storeId, customerId: customerId),
       );

  /// Every load claims a ticket; only the newest may emit. The long
  /// version of why is on CustomerListCubit — a debounce alone still
  /// lets a slow query land after a newer one.
  int _requestId = 0;

  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> loadTransactions() async {
    final int requestId = ++_requestId;

    emit(
      state.copyWith(error: null, status: TransactionListStateStatus.loading),
    );

    try {
      final transactions = await repository.fetchTransactions(
        state.storeId,
        customerId: state.customerId,
        search: state.search,
        sort: state.sort,
      );

      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          transactions: transactions,
          status: TransactionListStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(error: e, status: TransactionListStateStatus.failure),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: TransactionListStateStatus.failure,
        ),
      );
    }
  }

  void search(String term) {
    if (state.search == term) return;

    emit(state.copyWith(search: term));

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), loadTransactions);
  }

  Future<void> clearSearch() async {
    if (state.search.isEmpty) return;

    _debounce?.cancel();
    emit(state.copyWith(search: ''));
    await loadTransactions();
  }

  Future<void> setSort(TransactionSort sort) async {
    if (state.sort == sort) return;

    emit(state.copyWith(sort: sort));
    await loadTransactions();
  }
}

/*
  TRANSACTION DETAIL CUBIT:

  One transaction with every line it contains.
*/
class TransactionDetailCubit extends Cubit<TransactionDetailState> {
  final TransactionRepository repository;

  TransactionDetailCubit(this.repository)
    : super(const TransactionDetailState());

  Future<void> loadTransaction(int transactionId) async {
    emit(
      state.copyWith(
        error: null,
        status: TransactionDetailStateStatus.loading,
      ),
    );

    try {
      final transaction = await repository.fetchTransactionById(transactionId);

      if (transaction == null) {
        emit(
          state.copyWith(
            transaction: null,
            status: TransactionDetailStateStatus.failure,
            error: AppFailure(
              code: 'NOT_FOUND',
              message: 'This transaction no longer exists.',
            ),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          transaction: transaction,
          status: TransactionDetailStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(
        state.copyWith(error: e, status: TransactionDetailStateStatus.failure),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: TransactionDetailStateStatus.failure,
        ),
      );
    }
  }
}

/*
  ------------------------------------------------------------------
  TRANSACTION BUILDER CUBIT: the cart.
  ------------------------------------------------------------------

  Every method here edits an in-memory draft. Nothing reaches the
  database until submit(), which writes the transaction and all of its
  items in one atomic operation (§10).

  The §24/§38 rules live on TransactionDraft, not here — this cubit
  only moves lines around and asks the draft whether it may be
  committed.
*/
class TransactionBuilderCubit extends Cubit<TransactionBuilderState> {
  final TransactionRepository repository;

  TransactionBuilderCubit(this.repository, {required int storeId})
    : super(TransactionBuilderState(storeId: storeId));

  void selectCustomer(CustomerEntity customer) {
    emit(state.copyWith(draft: state.draft.copyWith(customer: customer)));
  }

  /*
    Adding a product already in the cart bumps its quantity instead of
    creating a second line. Two lines for the same product would both
    be valid and would total correctly, but a seller scanning the same
    packet twice means "two of these", not "list it twice".

    The unit price is snapshotted by TransactionDraftLine.fromProduct
    at THIS moment (§7) — the line keeps the price the product had when
    it was added, even if the product is repriced before submission.
  */
  void addProduct(ProductEntity product, {double quantity = 1}) {
    final existingIndex = state.draft.indexOfProduct(product.id);
    final lines = [...state.draft.lines];

    if (existingIndex >= 0) {
      final existing = lines[existingIndex];
      lines[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      lines.add(
        TransactionDraftLine.fromProduct(product, quantity: quantity),
      );
    }

    emit(state.copyWith(draft: state.draft.copyWith(lines: lines)));
  }

  /*
    Setting a quantity to zero or below REMOVES the line rather than
    keeping an invalid one. §38 forbids a zero quantity, and a line the
    seller has zeroed out is a line they meant to delete.
  */
  void setQuantity(int productId, double quantity) {
    final index = state.draft.indexOfProduct(productId);
    if (index < 0) return;

    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final lines = [...state.draft.lines];
    lines[index] = lines[index].copyWith(quantity: quantity);

    emit(state.copyWith(draft: state.draft.copyWith(lines: lines)));
  }

  void incrementQuantity(int productId) {
    final index = state.draft.indexOfProduct(productId);
    if (index < 0) return;

    setQuantity(productId, state.draft.lines[index].quantity + 1);
  }

  void decrementQuantity(int productId) {
    final index = state.draft.indexOfProduct(productId);
    if (index < 0) return;

    setQuantity(productId, state.draft.lines[index].quantity - 1);
  }

  void removeProduct(int productId) {
    final lines = state.draft.lines
        .where((line) => line.productId != productId)
        .toList();

    emit(state.copyWith(draft: state.draft.copyWith(lines: lines)));
  }

  void setNote(String note) {
    emit(state.copyWith(draft: state.draft.copyWith(note: note)));
  }

  void clearError() {
    if (state.error == null) return;

    emit(
      state.copyWith(error: null, status: TransactionBuilderStatus.editing),
    );
  }

  /*
    Commits the draft. Guarded against a double tap: a second call
    while the first is in flight would write the utang twice, and a
    duplicated debt is exactly the kind of error a customer cannot
    argue their way out of.
  */
  Future<void> submit() async {
    if (state.isSubmitting) return;

    if (!state.draft.canSubmit) {
      emit(
        state.copyWith(
          status: TransactionBuilderStatus.failure,
          error: AppFailure(
            code: 'INVALID_DRAFT',
            message: state.draft.problems.first,
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: TransactionBuilderStatus.submitting,
        error: null,
      ),
    );

    try {
      final transactionId = await repository.createTransaction(
        TransactionPayloadModel.fromDraft(
          state.draft,
          storeId: state.storeId,
        ),
      );

      emit(
        state.copyWith(
          status: TransactionBuilderStatus.submitted,
          createdTransactionId: transactionId,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(
        state.copyWith(status: TransactionBuilderStatus.failure, error: e),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: TransactionBuilderStatus.failure,
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }
}
