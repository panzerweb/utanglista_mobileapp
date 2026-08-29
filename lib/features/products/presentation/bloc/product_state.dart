import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/features/products/domain/entities/product_entity.dart';

const Object _unset = Object();

/*
  ------------------------------------------------------------------
  Product list: one store's catalogue.
  ------------------------------------------------------------------
*/
enum ProductListStateStatus { initial, loading, success, failure }

class ProductListState {
  final int storeId;
  final List<ProductEntity> products;
  final ProductListStateStatus status;

  /// Free-text search over name and barcode. '' means no search.
  final String search;

  /// §28: deactivated products are hidden by default but never gone.
  final bool includeInactive;

  /// How the catalogue is ordered. Deactivated products sort last
  /// regardless — see the note on [ProductSort].
  final ProductSort sort;

  final AppFailure? error;

  const ProductListState({
    required this.storeId,
    this.products = const [],
    this.status = ProductListStateStatus.initial,
    this.search = '',
    this.includeInactive = false,
    this.sort = ProductSort.name,
    this.error,
  });

  bool get isEmpty =>
      status == ProductListStateStatus.success && products.isEmpty;

  bool get isFilteredEmpty => isEmpty && (search.isNotEmpty || includeInactive);

  int get activeCount => products.where((p) => p.isActive).length;

  /// How many carry a barcode — the seller's cue for whether scanning
  /// is going to be useful in this store at all.
  int get barcodedCount => products.where((p) => p.hasBarcode).length;

  ProductListState copyWith({
    List<ProductEntity>? products,
    ProductListStateStatus? status,
    String? search,
    bool? includeInactive,
    ProductSort? sort,
    Object? error = _unset,
  }) {
    return ProductListState(
      storeId: storeId,
      products: products ?? this.products,
      status: status ?? this.status,
      search: search ?? this.search,
      includeInactive: includeInactive ?? this.includeInactive,
      sort: sort ?? this.sort,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

/*
  ------------------------------------------------------------------
  Scan-to-find outcomes.
  ------------------------------------------------------------------

  A scan has three meaningful endings, and the UI does something
  different for each. Modelling them as states rather than returning a
  nullable product keeps that decision out of the widget.
*/
sealed class BarcodeLookupState {}

class BarcodeLookupIdle extends BarcodeLookupState {}

class BarcodeLookupSearching extends BarcodeLookupState {}

/// The barcode belongs to a product in this store. Note it may be
/// INACTIVE — scanning a deactivated product should offer to
/// reactivate it, not pretend it does not exist.
class BarcodeLookupFound extends BarcodeLookupState {
  final ProductEntity product;

  BarcodeLookupFound(this.product);
}

/// Nothing in this store carries the barcode. The UI offers to create
/// a product with it already filled in.
class BarcodeLookupNotFound extends BarcodeLookupState {
  final String barcode;

  BarcodeLookupNotFound(this.barcode);
}

class BarcodeLookupFailure extends BarcodeLookupState {
  final AppFailure error;

  BarcodeLookupFailure(this.error);
}

/*
  ------------------------------------------------------------------
  Product form: create, update, activate/deactivate, delete.
  ------------------------------------------------------------------
*/
sealed class ProductFormState {}

class ProductFormInitial extends ProductFormState {}

class ProductFormSubmitting extends ProductFormState {}

class ProductFormUpdating extends ProductFormState {}

class ProductFormDeleting extends ProductFormState {}

class ProductFormSuccess extends ProductFormState {
  final int productId;

  ProductFormSuccess(this.productId);
}

class ProductFormUpdated extends ProductFormState {
  final int productId;

  ProductFormUpdated(this.productId);
}

class ProductActiveStateChanged extends ProductFormState {
  final int productId;
  final bool isActive;

  ProductActiveStateChanged(this.productId, this.isActive);
}

class ProductFormDeleted extends ProductFormState {
  final int productId;

  ProductFormDeleted(this.productId);
}

class ProductFormFailure extends ProductFormState {
  final AppFailure error;

  ProductFormFailure(this.error);
}

/*
  ------------------------------------------------------------------
  Product detail/edit loading.
  ------------------------------------------------------------------
*/
enum ProductDetailStateStatus { initial, loading, success, failure }

class ProductDetailState {
  final ProductEntity? product;

  /// Whether deletion is even offered (§28).
  final bool hasTransactionHistory;

  final ProductDetailStateStatus status;
  final AppFailure? error;

  const ProductDetailState({
    this.product,
    this.hasTransactionHistory = false,
    this.status = ProductDetailStateStatus.initial,
    this.error,
  });

  /// §28 in practice: a product in any transaction is deactivated,
  /// never deleted.
  bool get canDelete => !hasTransactionHistory;

  ProductDetailState copyWith({
    Object? product = _unset,
    bool? hasTransactionHistory,
    ProductDetailStateStatus? status,
    Object? error = _unset,
  }) {
    return ProductDetailState(
      product: identical(product, _unset)
          ? this.product
          : product as ProductEntity?,
      hasTransactionHistory:
          hasTransactionHistory ?? this.hasTransactionHistory,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}
