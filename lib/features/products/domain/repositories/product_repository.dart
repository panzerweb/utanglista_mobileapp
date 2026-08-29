import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/features/products/data/datasource/product_local_data_source.dart';
import 'package:utanglista_mobileapp/features/products/data/model/product_payload_model.dart';
import 'package:utanglista_mobileapp/features/products/domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<int> createProduct(ProductPayloadModel payload);
  Future<ProductEntity?> fetchProductById(int productId);
  Future<ProductEntity?> findByBarcode(int storeId, String barcode);
  Future<List<ProductEntity>> fetchProducts(
    int storeId, {
    String? search,
    bool includeInactive,
    ProductSort sort,
  });
  Future<int> updateProduct(UpdateProductPayloadModel updatePayload);
  Future<int> setActive(int productId, {required bool isActive});
  Future<int> deleteProduct(int productId);
  Future<bool> hasTransactionHistory(int productId);
}

class ProductRepositoryImplementation implements ProductRepository {
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImplementation(this.localDataSource);

  // ========================================================
  // ** PRODUCT METHODS **
  // ========================================================

  /*
    The unique (store_id, barcode) index would reject a duplicate on
    its own, but as a DRIFT_ERROR reading "Could not save this
    product" — true, useless, and it leaves the seller retyping a form
    that will fail again.

    Checking first lets the failure name the product that already owns
    the barcode, which is the thing they actually need to know.
  */
  @override
  Future<int> createProduct(ProductPayloadModel payload) async {
    await _assertBarcodeIsFree(
      storeId: payload.storeId,
      barcode: payload.normalisedBarcode,
    );

    return repositoryGuard(
      () => localDataSource.createProduct(payload),
      failureMessage: "Could not save this product.",
    );
  }

  @override
  Future<ProductEntity?> fetchProductById(int productId) {
    return repositoryGuard(() async {
      final model = await localDataSource.fetchProductById(productId);
      return model?.toEntity();
    }, failureMessage: "Could not load this product.");
  }

  /// Scan-to-find. Returns null when nothing in this store carries the
  /// barcode — the caller then offers to create it.
  @override
  Future<ProductEntity?> findByBarcode(int storeId, String barcode) {
    return repositoryGuard(() async {
      final model = await localDataSource.findByBarcode(storeId, barcode);
      return model?.toEntity();
    }, failureMessage: "Could not look up that barcode.");
  }

  @override
  Future<List<ProductEntity>> fetchProducts(
    int storeId, {
    String? search,
    bool includeInactive = true,
    ProductSort sort = ProductSort.name,
  }) {
    return repositoryGuard(() async {
      final models = await localDataSource.fetchProducts(
        storeId,
        search: search,
        includeInactive: includeInactive,
        sort: sort,
      );

      return models.map((model) => model.toEntity()).toList();
    }, failureMessage: "Could not load products.");
  }

  @override
  Future<int> updateProduct(UpdateProductPayloadModel updatePayload) async {
    // Same reasoning as create — name the conflicting product rather
    // than surfacing a raw constraint error.
    if (updatePayload.barcode != null) {
      final existing = await fetchProductById(updatePayload.productId);

      if (existing != null) {
        final trimmed = updatePayload.barcode!.trim();

        await _assertBarcodeIsFree(
          storeId: existing.storeId,
          barcode: trimmed.isEmpty ? null : trimmed,
          // Keeping its own barcode unchanged is not a conflict.
          ignoreProductId: updatePayload.productId,
        );
      }
    }

    return requireRowChanged(
      () => localDataSource.updateProduct(updatePayload),
      failureMessage: "Could not save your changes to this product.",
      notFoundMessage: "This product no longer exists.",
    );
  }

  /*
    §28: deactivation is how a product with history leaves the
    catalogue. It stops appearing when building new transactions, but
    the transaction items that reference it stay readable.
  */
  @override
  Future<int> setActive(int productId, {required bool isActive}) {
    return requireRowChanged(
      () => localDataSource.updateProduct(
        UpdateProductPayloadModel(productId: productId, isActive: isActive),
      ),
      failureMessage: isActive
          ? "Could not reactivate this product."
          : "Could not deactivate this product.",
      notFoundMessage: "This product no longer exists.",
    );
  }

  /*
    ------------------------------------------------------------------
    Deletion is refused for a product that appears in any transaction.
    ------------------------------------------------------------------

    §28 says historical transaction items must remain accessible, and
    §27 says changing a product must not change existing transaction
    prices. Deleting one would do both at once.

    The foreign key already refuses this — transaction_items references
    products with onDelete: noAction — so this check exists to turn a
    raw constraint error into a message that tells the seller to
    deactivate instead.
  */
  @override
  Future<int> deleteProduct(int productId) async {
    final hasHistory = await hasTransactionHistory(productId);

    if (hasHistory) {
      throw AppFailure(
        code: 'HAS_TRANSACTION_HISTORY',
        message:
            'This product appears in past transactions. Deactivate it '
            'instead — those records have to keep the price they were '
            'sold at.',
      );
    }

    return requireRowChanged(
      () => localDataSource.deleteProduct(productId),
      failureMessage: "Could not delete this product.",
      notFoundMessage: "This product has already been deleted.",
    );
  }

  @override
  Future<bool> hasTransactionHistory(int productId) {
    return repositoryGuard(
      () => localDataSource.hasTransactionHistory(productId),
      failureMessage: "Could not check this product's history.",
    );
  }

  // ========================================================

  /// Throws DUPLICATE_BARCODE naming the product that already has it.
  /// A null barcode is always free — many products may have none.
  Future<void> _assertBarcodeIsFree({
    required int storeId,
    required String? barcode,
    int? ignoreProductId,
  }) async {
    if (barcode == null) return;

    final existing = await findByBarcode(storeId, barcode);

    if (existing == null || existing.id == ignoreProductId) return;

    throw AppFailure(
      code: 'DUPLICATE_BARCODE',
      message: '"${existing.name}" already uses this barcode in this store.',
      details: {'productId': existing.id, 'productName': existing.name},
    );
  }
}
