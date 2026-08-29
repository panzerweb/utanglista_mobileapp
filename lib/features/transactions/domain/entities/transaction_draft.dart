import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';
import 'package:utanglista_mobileapp/features/products/domain/entities/product_entity.dart';

/*
  ------------------------------------------------------------------
  The cart, before it becomes a financial record.
  ------------------------------------------------------------------

  A draft is what the transaction builder screen edits. It holds every
  §24 and §38 rule that decides whether it may be committed, so the
  screen only has to ask `canSubmit` and show `problems` — the rules
  themselves live here, in the domain, never in a widget (§37.13).

  Nothing here touches the database. Committing turns it into a payload
  and hands it to the repository, which writes it atomically (§10).
*/
class TransactionDraftLine {
  final int productId;
  final String productName;
  final String unit;

  /*
    §7: SNAPSHOTTED when the line is added, not read from the product
    on the way out.

    The gap matters even inside one screen — the seller can open the
    product editor, change the price, and come back to a half-built
    cart. Whatever price was shown when they added the line is the one
    the customer agreed to, and the one that gets committed.
  */
  final Money unitPrice;

  /// Fractional for goods sold by weight. §38: must be > 0.
  final double quantity;

  const TransactionDraftLine({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.unitPrice,
    required this.quantity,
  });

  factory TransactionDraftLine.fromProduct(
    ProductEntity product, {
    double quantity = 1,
  }) {
    return TransactionDraftLine(
      productId: product.id,
      productName: product.name,
      unit: product.unit,
      // The snapshot happens here, and only here.
      unitPrice: product.price,
      quantity: quantity,
    );
  }

  Money get subTotal => unitPrice * quantity;

  /// §38: quantity > 0, unit price >= 0, subtotal >= 0.
  bool get isValid =>
      quantity > 0 && !unitPrice.isNegative && !subTotal.isNegative;

  String get quantityLabel {
    final formatted = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();

    return '$formatted $unit';
  }

  TransactionDraftLine copyWith({double? quantity}) {
    return TransactionDraftLine(
      productId: productId,
      productName: productName,
      unit: unit,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

class TransactionDraft {
  final CustomerEntity? customer;
  final List<TransactionDraftLine> lines;
  final String note;

  const TransactionDraft({
    this.customer,
    this.lines = const [],
    this.note = '',
  });

  /// §8: the transaction total is the sum of its item subtotals.
  Money get total => lines.map((line) => line.subTotal).sum();

  bool get isEmpty => lines.isEmpty;

  int get itemCount => lines.length;

  /*
    ------------------------------------------------------------------
    Everything standing between this draft and a committed record.
    ------------------------------------------------------------------

    Returned as a list rather than a bool so the UI can say WHICH rule
    is unmet. Ordered by how the seller would fix them.

    §24  quantity > 0, at least one item, total > 0
    §25  no negative money
    §29  an inactive customer cannot take on new utang
  */
  List<String> get problems {
    final problems = <String>[];

    if (customer == null) {
      problems.add('Choose a customer.');
    } else if (!customer!.isActive) {
      problems.add(
        '${customer!.name} is deactivated and cannot take new utang.',
      );
    }

    if (lines.isEmpty) {
      problems.add('Add at least one item.');
      // The remaining rules are all about the items; with none, saying
      // "total must be more than ₱0.00" as well is just noise.
      return problems;
    }

    if (lines.any((line) => line.quantity <= 0)) {
      problems.add('Every item needs a quantity greater than zero.');
    }

    if (lines.any((line) => line.unitPrice.isNegative)) {
      problems.add('An item has a negative price.');
    }

    if (!total.isPositive) {
      problems.add('The total must be more than ₱0.00.');
    }

    return problems;
  }

  bool get canSubmit => problems.isEmpty;

  /// Where a product already in the cart sits, or -1. Adding the same
  /// product twice bumps its quantity instead of making a second line.
  int indexOfProduct(int productId) =>
      lines.indexWhere((line) => line.productId == productId);

  bool containsProduct(int productId) => indexOfProduct(productId) >= 0;

  TransactionDraft copyWith({
    CustomerEntity? customer,
    List<TransactionDraftLine>? lines,
    String? note,
  }) {
    return TransactionDraft(
      customer: customer ?? this.customer,
      lines: lines ?? this.lines,
      note: note ?? this.note,
    );
  }
}
