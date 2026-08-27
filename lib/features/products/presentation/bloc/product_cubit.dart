import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/products/data/model/product_payload_model.dart';
import 'package:utanglista_mobileapp/features/products/domain/repositories/product_repository.dart';
import 'package:utanglista_mobileapp/features/products/presentation/bloc/product_state.dart';

/*
  ------------------------------------------------------------------
  Product field rules, shared by the cubits that check them.
  ------------------------------------------------------------------

  Bounds mirror ProductsTable (name 2-60, unit non-empty, barcode
  max 40). Drift would reject a violation anyway, but as an opaque
  DRIFT_ERROR — checking here says what is actually wrong.
*/
const int _minNameLength = 2;
const int _maxNameLength = 60;
const int _maxBarcodeLength = 40;

AppFailure? _validateProductName(String rawName) {
  final name = rawName.trim();

  if (name.length < _minNameLength || name.length > _maxNameLength) {
    return AppFailure(
      code: 'INVALID_FORMAT',
      message:
          'Product name must be between $_minNameLength and '
          '$_maxNameLength characters.',
    );
  }

  return null;
}

AppFailure? _validateUnit(String rawUnit) {
  if (rawUnit.trim().isEmpty) {
    return AppFailure(
      code: 'INVALID_FORMAT',
      message: 'Enter a unit, for example pc, kg or serving.',
    );
  }

  return null;
}

AppFailure? _validateBarcode(String? rawBarcode) {
  final barcode = rawBarcode?.trim() ?? '';

  // Blank is valid — street-vendor goods have no barcode.
  if (barcode.length > _maxBarcodeLength) {
    return AppFailure(
      code: 'INVALID_FORMAT',
      message: 'Barcode must be $_maxBarcodeLength characters or fewer.',
    );
  }

  return null;
}

/// §25: no monetary value may be negative.
AppFailure? _validatePrice(Money price) {
  if (price.isNegative) {
    return AppFailure(
      code: 'INVALID_AMOUNT',
      message: 'Price cannot be negative.',
    );
  }

  return null;
}

/*
  PRODUCT LIST CUBIT:

  One store's catalogue, with search over name and barcode.
*/
class ProductListCubit extends Cubit<ProductListState> {
  final ProductRepository repository;

  ProductListCubit(this.repository, {required int storeId})
    : super(ProductListState(storeId: storeId));

  /*
    Search fires per keystroke and nothing orders the results. A slow
    query for "ri" landing after "rice" would leave the list showing a
    search the user has already moved past, so each load claims a
    ticket and only the newest may emit. Same guard as the customer
    list.
  */
  int _requestId = 0;

  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> loadProducts() async {
    final int requestId = ++_requestId;

    emit(state.copyWith(error: null, status: ProductListStateStatus.loading));

    try {
      final products = await repository.fetchProducts(
        state.storeId,
        search: state.search,
        includeInactive: state.includeInactive,
      );

      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          products: products,
          status: ProductListStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      if (requestId != _requestId) return;
      emit(state.copyWith(error: e, status: ProductListStateStatus.failure));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: ProductListStateStatus.failure,
        ),
      );
    }
  }

  void search(String term) {
    if (state.search == term) return;

    emit(state.copyWith(search: term));

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), loadProducts);
  }

  Future<void> clearSearch() async {
    if (state.search.isEmpty) return;

    _debounce?.cancel();
    emit(state.copyWith(search: ''));
    await loadProducts();
  }

  Future<void> setIncludeInactive(bool includeInactive) async {
    if (state.includeInactive == includeInactive) return;

    emit(state.copyWith(includeInactive: includeInactive));
    await loadProducts();
  }
}

/*
  BARCODE LOOKUP CUBIT:

  Turns a scanned barcode into one of three outcomes the UI acts on.
  Deliberately separate from the list cubit — scanning is also used
  from the transaction builder in Phase 4, which has no product list.
*/
class BarcodeLookupCubit extends Cubit<BarcodeLookupState> {
  final ProductRepository repository;
  final int storeId;

  BarcodeLookupCubit(this.repository, {required this.storeId})
    : super(BarcodeLookupIdle());

  Future<void> lookup(String barcode) async {
    emit(BarcodeLookupSearching());

    try {
      final product = await repository.findByBarcode(storeId, barcode);

      if (product == null) {
        emit(BarcodeLookupNotFound(barcode.trim()));
        return;
      }

      // May be inactive — the UI offers to reactivate rather than
      // reporting "not found", which would push the user into creating
      // a duplicate the unique index then rejects.
      emit(BarcodeLookupFound(product));
    } on AppFailure catch (e) {
      emit(BarcodeLookupFailure(e));
    } catch (e) {
      emit(
        BarcodeLookupFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  void reset() => emit(BarcodeLookupIdle());
}

/*
  PRODUCT DETAIL CUBIT:

  Loads one product and whether it may be deleted.
*/
class ProductDetailCubit extends Cubit<ProductDetailState> {
  final ProductRepository repository;

  ProductDetailCubit(this.repository) : super(const ProductDetailState());

  Future<void> loadProduct(int productId) async {
    emit(state.copyWith(error: null, status: ProductDetailStateStatus.loading));

    try {
      final product = await repository.fetchProductById(productId);

      // Deleted from another screen while this one was open.
      if (product == null) {
        emit(
          state.copyWith(
            product: null,
            status: ProductDetailStateStatus.failure,
            error: AppFailure(
              code: 'NOT_FOUND',
              message: 'This product no longer exists.',
            ),
          ),
        );
        return;
      }

      final hasHistory = await repository.hasTransactionHistory(productId);

      emit(
        state.copyWith(
          product: product,
          hasTransactionHistory: hasHistory,
          status: ProductDetailStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: ProductDetailStateStatus.failure));
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: ProductDetailStateStatus.failure,
        ),
      );
    }
  }
}

/*
  PRODUCT FORM CUBIT:

  Handles creation, update, deactivation, and delete of a product.
*/
class ProductFormCubit extends Cubit<ProductFormState> {
  final ProductRepository repository;

  ProductFormCubit(this.repository) : super(ProductFormInitial());

  // CREATE
  Future<void> insertProduct(ProductPayloadModel payload) async {
    emit(ProductFormSubmitting());

    final failure =
        _validateProductName(payload.name) ??
        _validateUnit(payload.unit) ??
        _validateBarcode(payload.barcode) ??
        _validatePrice(payload.price);

    if (failure != null) {
      emit(ProductFormFailure(failure));
      return;
    }

    try {
      final int productId = await repository.createProduct(payload);

      emit(ProductFormSuccess(productId));
    } on AppFailure catch (e) {
      emit(ProductFormFailure(e));
    } catch (e) {
      emit(
        ProductFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  // UPDATE
  Future<void> editProduct(UpdateProductPayloadModel updatePayload) async {
    emit(ProductFormUpdating());

    // Only validate what is actually being changed — a partial update
    // passes null for the fields it leaves alone.
    AppFailure? failure;

    if (updatePayload.name != null) {
      failure = _validateProductName(updatePayload.name!);
    }
    if (failure == null && updatePayload.unit != null) {
      failure = _validateUnit(updatePayload.unit!);
    }
    if (failure == null && updatePayload.barcode != null) {
      failure = _validateBarcode(updatePayload.barcode);
    }
    if (failure == null && updatePayload.price != null) {
      failure = _validatePrice(updatePayload.price!);
    }

    if (failure != null) {
      emit(ProductFormFailure(failure));
      return;
    }

    try {
      await repository.updateProduct(updatePayload);

      emit(ProductFormUpdated(updatePayload.productId));
    } on AppFailure catch (e) {
      emit(ProductFormFailure(e));
    } catch (e) {
      emit(
        ProductFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  /*
    §28: the normal way a product leaves the catalogue. It stops
    appearing when building new transactions, but every transaction
    item that references it keeps working.
  */
  Future<void> setActive(int productId, {required bool isActive}) async {
    emit(ProductFormUpdating());

    try {
      await repository.setActive(productId, isActive: isActive);

      emit(ProductActiveStateChanged(productId, isActive));
    } on AppFailure catch (e) {
      emit(ProductFormFailure(e));
    } catch (e) {
      emit(
        ProductFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }

  /*
    Only ever succeeds for a product in no transaction — the repository
    refuses the rest with HAS_TRANSACTION_HISTORY, which the UI turns
    into an offer to deactivate instead.
  */
  Future<void> deleteProduct(int productId) async {
    emit(ProductFormDeleting());

    try {
      await repository.deleteProduct(productId);

      emit(ProductFormDeleted(productId));
    } on AppFailure catch (e) {
      emit(ProductFormFailure(e));
    } catch (e) {
      emit(
        ProductFormFailure(
          AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }
}
