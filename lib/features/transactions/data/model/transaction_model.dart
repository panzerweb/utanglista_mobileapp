import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_entity.dart';

class TransactionItemModel {
  final int id;
  final int transactionId;
  final int productId;
  final String productName;
  final String unit;
  final double quantity;
  final int unitPriceCentavos;
  final int subTotalCentavos;

  const TransactionItemModel({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPriceCentavos,
    required this.subTotalCentavos,
  });

  TransactionItemEntity toEntity() {
    return TransactionItemEntity(
      id: id,
      transactionId: transactionId,
      productId: productId,
      productName: productName,
      unit: unit,
      quantity: quantity,
      // §7: read back exactly as it was written, never recomputed
      // from the product's current price.
      unitPrice: Money.fromCentavos(unitPriceCentavos),
      subTotal: Money.fromCentavos(subTotalCentavos),
    );
  }
}

class TransactionModel {
  final int id;
  final int storeId;
  final int customerId;
  final String customerName;
  final int totalAmountCentavos;
  final String? note;
  final DateTime createdAt;

  /// Empty for list rows; populated by the detail query.
  final List<TransactionItemModel> items;

  const TransactionModel({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    required this.totalAmountCentavos,
    required this.note,
    required this.createdAt,
    this.items = const [],
  });

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      storeId: storeId,
      customerId: customerId,
      customerName: customerName,
      totalAmount: Money.fromCentavos(totalAmountCentavos),
      note: note ?? '',
      createdAt: createdAt,
      items: items.map((item) => item.toEntity()).toList(),
    );
  }

  TransactionModel copyWith({List<TransactionItemModel>? items}) {
    return TransactionModel(
      id: id,
      storeId: storeId,
      customerId: customerId,
      customerName: customerName,
      totalAmountCentavos: totalAmountCentavos,
      note: note,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}
