import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:drift/drift.dart';

enum StoreCategory {
  retail('sari_sari'),
  online('online_store');

  const StoreCategory(this.nameString);

  final String nameString;
}

class StorePayloadModel {
  final String name;
  final String? description;
  final StoreCategory? category;

  StorePayloadModel({required this.name, this.description, this.category});

  // This getter safely returns the string or null
  // Use payload.categoryString when saving to the database.
  String? get categoryString => category?.nameString;
}

class UpdateStorePayloadModel {
  final int storeId;
  final String? name;
  final String? description;
  final StoreCategory? category;

  UpdateStorePayloadModel({
    required this.storeId,
    this.name,
    this.description,
    this.category,
  });

  // This getter safely returns the string or null
  // Use payload.categoryString when saving to the database.
  String? get categoryString => category?.nameString;

  StoresTableCompanion toCompanion() {
    return StoresTableCompanion(
      name: name == null ? const Value.absent() : Value(name!),
      description: description == null
          ? const Value.absent()
          : Value(description!),
      category: categoryString == null
          ? const Value.absent()
          : Value(categoryString!),
    );
  }
}
