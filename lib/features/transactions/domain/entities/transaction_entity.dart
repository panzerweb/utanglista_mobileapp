import 'package:utanglista_mobileapp/core/money/money.dart';

/*
  ------------------------------------------------------------------
  A committed transaction: what a customer took on credit.
  ------------------------------------------------------------------

  §14 and §31: once committed this is an immutable financial record.
  Payments do not touch it, and it carries no payment state — no
  `remaining_amount`, no PAID/UNPAID status. What the customer still
  owes is derived at the account level by CustomerBalance (§15, §18).

  `totalAmount` is a snapshot of SUM(item.subTotal) (§8). The two are
  asserted equal inside the same database transaction that writes them,
  so a disagreement can never be committed.
*/
class TransactionEntity {
  final int id;
  final int storeId;
  final int customerId;

  /// Joined from the customer row for display. Renaming a customer
  /// changes how this reads and nothing about the amounts (§27).
  final String customerName;

  final Money totalAmount;
  final String note;
  final DateTime createdAt;

  /// Only populated by the detail query — the history list does not
  /// load every line of every transaction.
  final List<TransactionItemEntity> items;

  const TransactionEntity({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.note,
    required this.createdAt,
    this.items = const [],
  });

  bool get hasNote => note.trim().isNotEmpty;

  int get itemCount => items.length;

  /*
    §8: the persisted total must equal the sum of its items.

    Only meaningful once items are loaded — the list query leaves them
    empty, which is why this is not asserted on every entity.
  */
  bool get totalMatchesItems =>
      items.isEmpty || items.map((item) => item.subTotal).sum() == totalAmount;

  /// '3 items' / '1 item' — the summary a history row shows.
  String get itemSummary => '$itemCount ${itemCount == 1 ? 'item' : 'items'}';
}

/*
  ------------------------------------------------------------------
  One line of a transaction — and a price snapshot.
  ------------------------------------------------------------------

  §7 is the rule this whole class exists for:

      transaction_items.unit_price is a historical price snapshot.

  Rice sold at ₱100 stays ₱100 on this line forever, even after the
  product is repriced to ₱110. `unitPrice` is COPIED from the product
  when the transaction is built and never read back from it.

  `productName` is joined live rather than snapshotted, which is
  deliberate: §27 allows a rename to change how a record is displayed,
  only never to change its amounts. The foreign key is `noAction`, so
  the product row is always still there to join to.
*/
class TransactionItemEntity {
  final int id;
  final int transactionId;
  final int productId;

  /// Joined from the product row — display only, see the class note.
  final String productName;
  final String unit;

  /// Fractional because goods are sold by weight as well as by piece.
  final double quantity;

  /// §7: the price AT THE TIME OF SALE. Never the product's price now.
  final Money unitPrice;

  /// quantity × unitPrice, snapshotted with the rest.
  final Money subTotal;

  const TransactionItemEntity({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.subTotal,
  });

  /// '5 kg' — trailing '.0' trimmed, because "5.0 kg" reads like a
  /// precision the seller did not ask for.
  String get quantityLabel {
    final formatted = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();

    return '$formatted $unit';
  }

  /// '5 × ₱100.00' — the §7 worked example, as the UI renders it.
  String get lineLabel => '$quantityLabel × ${unitPrice.format()}';
}
