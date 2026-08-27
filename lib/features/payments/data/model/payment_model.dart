import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/payments/domain/entities/payment_entity.dart';

class PaymentModel {
  final int id;
  final int storeId;
  final int customerId;
  final String customerName;
  final int amountCentavos;
  final String? note;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    required this.amountCentavos,
    required this.note,
    required this.createdAt,
  });

  PaymentEntity toEntity() {
    return PaymentEntity(
      id: id,
      storeId: storeId,
      customerId: customerId,
      customerName: customerName,
      amount: Money.fromCentavos(amountCentavos),
      note: note ?? '',
      createdAt: createdAt,
    );
  }
}

class PaymentPayloadModel {
  final int storeId;
  final int customerId;
  final Money amount;
  final String? note;

  const PaymentPayloadModel({
    required this.storeId,
    required this.customerId,
    required this.amount,
    this.note,
  });

  String? get normalisedNote {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
