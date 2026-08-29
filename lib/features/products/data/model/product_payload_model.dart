import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';

class ProductPayloadModel {
  final int storeId;
  final String name;
  final String? description;

  /// Optional — street-vendor goods have no barcode (§7 note, §28).
  final String? barcode;

  final Money price;
  final String unit;

  ProductPayloadModel({
    required this.storeId,
    required this.name,
    required this.price,
    required this.unit,
    this.description,
    this.barcode,
  });

  /// Blank input is stored as NULL, so "no barcode" has exactly one
  /// representation — and the unique (store, barcode) index treats
  /// many NULLs as distinct, which is what lets unbarcoded products
  /// coexist.
  String? get normalisedBarcode {
    final trimmed = barcode?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String? get normalisedDescription {
    final trimmed = description?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

/*
  Partial updates: null means "leave alone".

  As with the customer payload, that leaves no way to say "remove the
  barcode", because the clearing value IS null. So for barcode only:

      null   ->  leave whatever is stored
      ''     ->  clear it (writes NULL)
      '4801' ->  set it

  Same convention for description.
*/
class UpdateProductPayloadModel {
  final int productId;
  final String? name;
  final String? description;
  final String? barcode;
  final Money? price;
  final String? unit;
  final bool? isActive;

  UpdateProductPayloadModel({
    required this.productId,
    this.name,
    this.description,
    this.barcode,
    this.price,
    this.unit,
    this.isActive,
  });

  ProductsTableCompanion toCompanion() {
    return ProductsTableCompanion(
      name: name == null ? const Value.absent() : Value(name!),
      description: description == null
          ? const Value.absent()
          : Value(description!.trim().isEmpty ? null : description!.trim()),
      barcode: barcode == null
          ? const Value.absent()
          : Value(barcode!.trim().isEmpty ? null : barcode!.trim()),
      price: price == null ? const Value.absent() : Value(price!.centavos),
      unit: unit == null ? const Value.absent() : Value(unit!),
      isActive: isActive == null ? const Value.absent() : Value(isActive!),
    );
  }

  /// False when there is nothing to write, so the datasource can tell
  /// "no changes" apart from "no such product".
  bool get hasChanges =>
      name != null ||
      description != null ||
      barcode != null ||
      price != null ||
      unit != null ||
      isActive != null;
}
