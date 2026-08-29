import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/features/stores/data/datasource/store_local_data_source.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';
import 'package:utanglista_mobileapp/features/stores/domain/entities/store_entity.dart';

abstract class StoreRepository {
  Future<int> createStore(StorePayloadModel payload);
  Future<StoreEntity?> fetchStoreById(int storeId);
  Future<List<StoreEntity>> fetchStores(
    String? category, {
    String? search,
    StoreSort sort,
  });
  Future<int> updateStore(UpdateStorePayloadModel updatePayload);
  Future<int> deleteStore(int storeId);
}

class StoreRepositoryImplementation implements StoreRepository {
  final StoreLocalDataSource localDataSource;

  StoreRepositoryImplementation(this.localDataSource);

  // ========================================================
  // ** STORE METHODS **
  // Each returns the auto-increment row id Drift generated.
  // ========================================================
  @override
  Future<int> createStore(StorePayloadModel payload) {
    return repositoryGuard(
      () => localDataSource.createStore(payload),
      failureMessage: "Could not save the store.",
    );
  }

  @override
  Future<StoreEntity?> fetchStoreById(int storeId) {
    return repositoryGuard(() async {
      final model = await localDataSource.fetchStoreById(storeId);
      return model?.toEntity();
    }, failureMessage: "Could not fetch the store");
  }

  @override
  Future<List<StoreEntity>> fetchStores(
    String? category, {
    String? search,
    StoreSort sort = StoreSort.recent,
  }) {
    return repositoryGuard(() async {
      final storesModel = await localDataSource.fetchStores(
        category,
        search: search,
        sort: sort,
      );
      final stores = storesModel.map((model) => model.toEntity()).toList();

      return stores;
    }, failureMessage: "Could not fetch stores.");
  }

  @override
  Future<int> updateStore(UpdateStorePayloadModel updatePayload) {
    return requireRowChanged(
      () {
        return localDataSource.updateStore(updatePayload);
      },
      failureMessage: "Could not update this store.",
      notFoundMessage: "This store no longer exists.",
    );
  }

  @override
  Future<int> deleteStore(int storeId) {
    return requireRowChanged(
      () {
        return localDataSource.deleteStore(storeId);
      },
      failureMessage: "Could not delete this store.",
      notFoundMessage: "This store has already been deleted",
    );
  }
}
