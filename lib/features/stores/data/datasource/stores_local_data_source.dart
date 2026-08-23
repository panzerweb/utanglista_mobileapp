import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_model.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';

abstract class StoresLocalDataSource {
  Future<int> createStore(StorePayloadModel payload);
  Future<StoreModel?> fetchStoreById(int storeId);
  Future<List<StoreModel>> fetchStores();
  Future<int> updateStore(UpdateStorePayloadModel updatePayload);
  Future<int> deleteStore(int storeId);
}

class StoresLocalDataSourceImplementation implements StoresLocalDataSource {
  final AppDatabase database;

  StoresLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final storesTable = database.storesTable;

  // ========================================================
  // ** METHODS FOR TABLE **
  // ========================================================
  @override
  Future<int> createStore(StorePayloadModel payload) async {
    try {
      final int productId = await database
          .into(storesTable)
          .insert(
            StoresTableCompanion.insert(
              name: payload.name,
              description: Value(payload.description),
              category: Value(payload.categoryString),
            ),
          );

      return productId;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<StoreModel?> fetchStoreById(int storeId) async {
    try {
      final StoresTableData? storeTableData = await (database.select(
        storesTable,
      )..where((store) => store.id.equals(storeId))).getSingleOrNull();

      if (storeTableData == null) {
        return null;
      }

      final store = StoreModel.fromTable(storeTableData);

      return store;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<StoreModel>> fetchStores() async {
    try {
      final SimpleSelectStatement<$StoresTableTable, StoresTableData> query =
          (database.select(storesTable));

      final List<StoresTableData> rows = await query.get();
      final List<StoreModel> stores = rows
          .map((store) => StoreModel.fromTable(store))
          .toList();

      return stores;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> updateStore(UpdateStorePayloadModel updatePayload) async {
    try {
      final int result =
          await (database.update(storesTable)
                ..where((tbl) => tbl.id.equals(updatePayload.storeId)))
              .write(updatePayload.toCompanion());

      return result;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> deleteStore(int storeId) async {
    try {
      final result = await (database.delete(
        storesTable,
      )..where((store) => store.id.equals(storeId))).go();

      return result;
    } catch (e) {
      rethrow;
    }
  }
}
