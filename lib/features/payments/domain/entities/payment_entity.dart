import 'package:utanglista_mobileapp/core/money/money.dart';

/*
  ------------------------------------------------------------------
  Money actually received from a customer.
  ------------------------------------------------------------------

  §11: a payment belongs to the CUSTOMER'S ACCOUNT, not to a
  transaction and not to a product. There is deliberately no
  transactionId here and no allocation logic anywhere.

      Transaction #1 = ₱500
      Transaction #2 = ₱300
      Customer owes  = ₱800
      Customer pays  = ₱450
      Remaining      = ₱350

  The app never needs to decide which products were "paid for" (§13),
  and §14 forbids a payment from touching the transactions at all.
  What is left is derived by CustomerBalance (§15).
*/
class PaymentEntity {
  final int id;
  final int storeId;
  final int customerId;

  /// Joined for display. §27: renaming a customer changes how this
  /// reads and nothing about the amount.
  final String customerName;

  /// §38: always greater than zero. A refund would be an explicit
  /// business event (§25), never a negative payment.
  final Money amount;

  final String note;
  final DateTime createdAt;

  const PaymentEntity({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  bool get hasNote => note.trim().isNotEmpty;
}
