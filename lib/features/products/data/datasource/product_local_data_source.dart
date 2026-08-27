import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/features/products/data/model/product_model.dart';
import 'package:utanglista_mobileapp/features/products/data/model/product_payload_model.dart';

abstract class ProductLocalDataSource {
  Future<int> createProduct(ProductPayloadModel payload);
  Future<ProductModel?> fetchProductById(int productId);
  Future<ProductModel?> findByBarcode(int storeId, String barcode);
  Future<List<ProductModel>> fetchProducts(
    int storeId, {
    String? search,
    bool includeInactive,
  });
  Future<int> updateProduct(UpdateProductPayloadModel updatePayload);
  Future<int> deleteProduct(int productId);
  Future<bool> hasTransactionHistory(int productId);
}

class ProductLocalDataSourceImplementation implements ProductLocalDataSource {
  final AppDatabase database;

  ProductLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final productsTable = database.productsTable;
  late final transactionsItemTable = database.transactionsItemTable;

  // ========================================================
  // ** METHODS FOR TABLE **
  // ========================================================
  @override
  Future<int> createProduct(ProductPayloadModel payload) async {
    try {
      final int productId = await database
          .into(productsTable)
          .insert(
            ProductsTableCompanion.insert(
              storeId: payload.storeId,
              name: payload.name,
              price: payload.price.centavos,
              unit: payload.unit,
              description: Value(payload.normalisedDescription),
              barcode: Value(payload.normalisedBarcode),
            ),
          );

      return productId;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProductModel?> fetchProductById(int productId) async {
    try {
      final row = await (database.select(
        productsTable,
      )..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();

      if (row == null) return null;

      return ProductModel.fromTable(row);
    } catch (e) {
      rethrow;
    }
  }

  /*
    The lookup behind scan-to-find.

    Scoped to the store, and exact rather than LIKE — a barcode is an
    identifier, not a search term. The unique (store_id, barcode) index
    guarantees at most one hit, which is what makes getSingleOrNull
    safe here.

    Inactive products are INCLUDED on purpose: scanning something the
    seller deactivated should say "this is deactivated, reactivate it?"
    rather than "no such product", which would push them into creating
    a duplicate the unique index would then reject.
  */
  @override
  Future<ProductModel?> findByBarcode(int storeId, String barcode) async {
    try {
      final trimmed = barcode.trim();
      if (trimmed.isEmpty) return null;

      final row =
          await (database.select(productsTable)..where(
                (tbl) =>
                    tbl.storeId.equals(storeId) & tbl.barcode.equals(trimmed),
              ))
              .getSingleOrNull();

      if (row == null) return null;

      return ProductModel.fromTable(row);
    } catch (e) {
      rethrow;
    }
  }

  /// [search] matches name or barcode. [includeInactive] false hides
  /// deactivated products (§28).
  @override
  Future<List<ProductModel>> fetchProducts(
    int storeId, {
    String? search,
    bool includeInactive = true,
  }) async {
    try {
      final query = database.select(productsTable)
        ..where((tbl) => tbl.storeId.equals(storeId));

      if (!includeInactive) {
        query.where((tbl) => tbl.isActive.equals(true));
      }

      final term = search?.trim() ?? '';
      if (term.isNotEmpty) {
        // Both sides lowered: SQLite's LIKE is case-insensitive for
        // ASCII only, so "niño" would not match "Niño" otherwise.
        final pattern = '%${term.toLowerCase()}%';

        query.where(
          (tbl) =>
              tbl.name.lower().like(pattern) |
              tbl.barcode.lower().like(pattern),
        );
      }

      /*
        Active first, then alphabetical. A catalogue is browsed by name,
        unlike the customer list which is browsed by recency.

        The id tiebreaker keeps two identically-named products in a
        stable order between loads.
      */
      query.orderBy([
        (tbl) => OrderingTerm.desc(tbl.isActive),
        (tbl) => OrderingTerm.asc(tbl.name),
        (tbl) => OrderingTerm.asc(tbl.id),
      ]);

      final rows = await query.get();

      return rows.map(ProductModel.fromTable).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> updateProduct(UpdateProductPayloadModel updatePayload) async {
    try {
      // An empty companion would match zero rows, which
      // requireRowChanged reads as NOT_FOUND for a product that exists.
      if (!updatePayload.hasChanges) {
        final existing = await (database.select(
          productsTable,
        )..where((tbl) => tbl.id.equals(updatePayload.productId)))
            .getSingleOrNull();

        return existing == null ? 0 : 1;
      }

      final int result =
          await (database.update(productsTable)
                ..where((tbl) => tbl.id.equals(updatePayload.productId)))
              .write(updatePayload.toCompanion());

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /*
    Only ever reached for a product that appears in no transaction item
    — the repository checks first, and the foreign key refuses it
    regardless (§28). Deactivation is the normal path.
  */
  @override
  Future<int> deleteProduct(int productId) async {
    try {
      final result = await (database.delete(
        productsTable,
      )..where((tbl) => tbl.id.equals(productId))).go();

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /*
    Does this product appear in any transaction?

    §28: "existing transaction items must remain accessible because they
    represent historical records". A product that is referenced can only
    be deactivated.

    EXISTS with LIMIT 1 rather than a count — the answer is a yes/no,
    and a product sold a thousand times should not cost a thousand-row
    scan to establish that.
  */
  @override
  Future<bool> hasTransactionHistory(int productId) async {
    try {
      final row = await database
          .customSelect(
            '''
            SELECT EXISTS(
              SELECT 1 FROM transactions_item_table
               WHERE product_id = :id
               LIMIT 1
            ) AS has_history
            ''',
            variables: [Variable.withInt(productId)],
            readsFrom: {transactionsItemTable},
          )
          .getSingle();

      return row.read<int>('has_history') == 1;
    } catch (e) {
      rethrow;
    }
  }
}
