import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_model.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';

abstract class StoreLocalDataSource {
  Future<int> createStore(StorePayloadModel payload);
  Future<StoreModel?> fetchStoreById(int storeId);
  Future<List<StoreModel>> fetchStores(String? category);
  Future<int> updateStore(UpdateStorePayloadModel updatePayload);
  Future<int> deleteStore(int storeId);
}

class StoreLocalDataSourceImplementation implements StoreLocalDataSource {
  final AppDatabase database;

  StoreLocalDataSourceImplementation(this.database);

  // ========================================================
  // ** CONSTANTS FOR TABLE **
  // ========================================================
  late final storesTable = database.storesTable;
  late final storeSettingsTable = database.storeSettingsTable;

  // ========================================================
  // ** METHODS FOR TABLE **
  // ========================================================

  /*
    A store and its settings row are created together or not at all.

    The unique index on store_settings.store_id says there is exactly
    one settings row per store; this transaction is what makes "exactly
    one" true rather than "at most one". Without it, a failure between
    the two inserts leaves a store whose interest settings cannot be
    read or written, and the only visible symptom would be a settings
    tab that silently does nothing.
  */
  @override
  Future<int> createStore(StorePayloadModel payload) async {
    try {
      return await database.transaction(() async {
        final int storeId = await database
            .into(storesTable)
            .insert(
              StoresTableCompanion.insert(
                name: payload.name,
                description: Value(payload.description),
                category: Value(payload.categoryString),
              ),
            );

        await database
            .into(storeSettingsTable)
            .insert(
              StoreSettingsTableCompanion.insert(
                storeId: storeId,
                monthlyInterestEnabled: Value(payload.monthlyInterestEnabled),
                monthlyInterestRateBasisPoints: Value(
                  payload.monthlyInterestRate.basisPoints,
                ),
              ),
            );

        return storeId;
      });
    } catch (e) {
      rethrow;
    }
  }

  /*
    Joined to the settings row so a caller never has to make a second
    trip for the interest configuration.

    LEFT OUTER rather than INNER: a store created before settings
    existed, or one whose settings row was lost, must still be
    readable — StoreModel defaults it to "interest off".
  */
  @override
  Future<StoreModel?> fetchStoreById(int storeId) async {
    try {
      final query = database.select(storesTable).join([
        leftOuterJoin(
          storeSettingsTable,
          storeSettingsTable.storeId.equalsExp(storesTable.id),
        ),
      ])..where(storesTable.id.equals(storeId));

      final row = await query.getSingleOrNull();
      if (row == null) return null;

      return StoreModel.fromTableWithSettings(
        row.readTable(storesTable),
        row.readTableOrNull(storeSettingsTable),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// [category] null means every category.
  @override
  Future<List<StoreModel>> fetchStores(String? category) async {
    try {
      final query = database.select(storesTable).join([
        leftOuterJoin(
          storeSettingsTable,
          storeSettingsTable.storeId.equalsExp(storesTable.id),
        ),
      ]);

      if (category != null) {
        query.where(storesTable.category.equals(category));
      }

      /*
        Newest first: the store a user just created should be the one
        they see, without scrolling.

        The id tiebreaker is not decoration. Drift stores DateTime as
        unix SECONDS, so two rows created in the same second compare
        equal and SQLite is free to return them in any order — the list
        would reshuffle between loads for no visible reason.

        Ordering by the autoincrement id second makes it deterministic,
        and id order is creation order. The ledger in Phase 5 merges
        three tables by createdAt and will need the same treatment.
      */
      query.orderBy([
        OrderingTerm.desc(storesTable.createdAt),
        OrderingTerm.desc(storesTable.id),
      ]);

      final rows = await query.get();

      return rows
          .map(
            (row) => StoreModel.fromTableWithSettings(
              row.readTable(storesTable),
              row.readTableOrNull(storeSettingsTable),
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /*
    Returns the number of rows changed in the STORES table, so
    requireRowChanged still reports NOT_FOUND for a store that is gone.

    Settings are upserted rather than updated: a store from before the
    settings row existed would otherwise silently ignore an interest
    change, and the user would toggle a switch that does nothing.
  */
  @override
  Future<int> updateStore(UpdateStorePayloadModel updatePayload) async {
    try {
      return await database.transaction(() async {
        /*
          An interest-only edit changes no store column, so writing an
          all-absent companion would match zero rows and be reported as
          NOT_FOUND for a store that is sitting right there. When there
          is nothing to write, confirm the store exists instead — the
          answer requireRowChanged actually wants.
        */
        final int rowsAffected;

        if (updatePayload.hasStoreChanges) {
          rowsAffected =
              await (database.update(storesTable)
                    ..where((tbl) => tbl.id.equals(updatePayload.storeId)))
                  .write(updatePayload.toCompanion());
        } else {
          final existing = await (database.select(
            storesTable,
          )..where((tbl) => tbl.id.equals(updatePayload.storeId))).getSingleOrNull();

          rowsAffected = existing == null ? 0 : 1;
        }

        // The store does not exist, so there is no settings row worth
        // creating for it either.
        if (rowsAffected == 0) return 0;

        if (updatePayload.hasSettingsChanges) {
          final settingsChanged =
              await (database.update(storeSettingsTable)..where(
                    (tbl) => tbl.storeId.equals(updatePayload.storeId),
                  ))
                  .write(updatePayload.toSettingsCompanion());

          if (settingsChanged == 0) {
            await database
                .into(storeSettingsTable)
                .insert(
                  StoreSettingsTableCompanion.insert(
                    storeId: updatePayload.storeId,
                    monthlyInterestEnabled: Value(
                      updatePayload.monthlyInterestEnabled ?? false,
                    ),
                    monthlyInterestRateBasisPoints: Value(
                      updatePayload.monthlyInterestRate?.basisPoints ?? 0,
                    ),
                  ),
                );
          }
        }

        return rowsAffected;
      });
    } catch (e) {
      rethrow;
    }
  }

  /*
    Settings, customers, products, transactions and payments all cascade
    from the store row, so this one delete removes the whole business.
    The confirmation dialog in front of it is not decoration.
  */
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
