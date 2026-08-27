import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/products/domain/entities/product_entity.dart';

class ProductModel {
  final int id;
  final int storeId;
  final String name;
  final String? description;
  final String? barcode;

  /// Centavos, straight from the column.
  final int priceCentavos;

  final String unit;
  final bool isActive;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.barcode,
    required this.priceCentavos,
    required this.unit,
    required this.isActive,
    required this.createdAt,
  });

  factory ProductModel.fromTable(ProductsTableData product) {
    return ProductModel(
      id: product.id,
      storeId: product.storeId,
      name: product.name,
      description: product.description,
      barcode: product.barcode,
      priceCentavos: product.price,
      unit: product.unit,
      isActive: product.isActive,
      createdAt: product.createdAt,
    );
  }

  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      storeId: storeId,
      name: name,
      description: description ?? '',
      // A barcode stored as whitespace is the same as none.
      barcode: (barcode?.trim().isEmpty ?? true) ? null : barcode!.trim(),
      price: Money.fromCentavos(priceCentavos),
      unit: unit,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
