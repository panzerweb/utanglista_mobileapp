import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/features/stores/domain/entities/store_entity.dart';

class StoreModel {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final DateTime createdAt;

  /// From the store's settings row. Defaulted rather than nullable: a
  /// store whose settings row is somehow missing reads as "interest
  /// off", which is the safe answer — it charges nobody anything.
  final bool monthlyInterestEnabled;
  final int monthlyInterestRateBasisPoints;

  const StoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.createdAt,
    this.monthlyInterestEnabled = false,
    this.monthlyInterestRateBasisPoints = 0,
  });

  /// The store row on its own — settings fall back to "off".
  factory StoreModel.fromTable(StoresTableData store) {
    return StoreModel(
      id: store.id,
      name: store.name,
      description: store.description,
      category: store.category,
      createdAt: store.createdAt,
    );
  }

  /// A store joined to its settings row, which is how the list and the
  /// detail screen always read it.
  factory StoreModel.fromTableWithSettings(
    StoresTableData store,
    StoreSettingsTableData? settings,
  ) {
    return StoreModel(
      id: store.id,
      name: store.name,
      description: store.description,
      category: store.category,
      createdAt: store.createdAt,
      monthlyInterestEnabled: settings?.monthlyInterestEnabled ?? false,
      monthlyInterestRateBasisPoints:
          settings?.monthlyInterestRateBasisPoints ?? 0,
    );
  }

  StoreEntity toEntity() {
    return StoreEntity(
      id: id,
      name: name,
      description: description ?? '',
      // Unrecognised values become null rather than throwing — see
      // StoreCategory.fromValue.
      category: StoreCategory.fromValue(category),
      createdAt: createdAt,
      monthlyInterestEnabled: monthlyInterestEnabled,
      monthlyInterestRate: InterestRate.fromBasisPoints(
        monthlyInterestRateBasisPoints,
      ),
    );
  }
}
