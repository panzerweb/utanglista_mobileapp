import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:intl/intl.dart';
import 'package:utanglista_mobileapp/features/stores/domain/entities/store_entity.dart';

class StoreModel {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final String? createdAt;

  StoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.createdAt,
  });

  factory StoreModel.fromTable(StoresTableData store) {
    final rawDate = store.createdAt ?? DateTime.now();

    return StoreModel(
      id: store.id,
      name: store.name,
      description: store.description ?? '',
      category: store.category ?? '',
      createdAt: DateFormat.yMMMMd().format(rawDate),
    );
  }

  StoreEntity toEntity() {
    return StoreEntity(
      id: id,
      name: name,
      description: description ?? '',
      category: category ?? '',
      createdAt: createdAt ?? 'Not Set',
    );
  }
}
