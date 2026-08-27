import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/transactions/domain/entities/transaction_draft.dart';

/*
  What gets written. Built from a validated TransactionDraft, so by the
  time one of these exists the §24/§38 rules have already passed.
*/
class TransactionItemPayloadModel {
  final int productId;
  final double quantity;

  /// §7: the snapshot carried through from the draft.
  final Money unitPrice;

  const TransactionItemPayloadModel({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  Money get subTotal => unitPrice * quantity;
}

class TransactionPayloadModel {
  final int storeId;
  final int customerId;
  final String? note;
  final List<TransactionItemPayloadModel> items;

  const TransactionPayloadModel({
    required this.storeId,
    required this.customerId,
    required this.items,
    this.note,
  });

  /*
    ------------------------------------------------------------------
    The total is DERIVED here, never passed in.
    ------------------------------------------------------------------

    §8 requires the persisted total to agree with the item subtotals.
    The surest way to guarantee that is to give the caller no way to
    disagree — there is no `totalAmount` parameter to get wrong. The
    datasource re-checks this against what it actually wrote, inside
    the transaction, as a second line of defence.
  */
  Money get totalAmount => items.map((item) => item.subTotal).sum();

  String? get normalisedNote {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Turns a validated draft into the shape the datasource writes.
  factory TransactionPayloadModel.fromDraft(
    TransactionDraft draft, {
    required int storeId,
  }) {
    return TransactionPayloadModel(
      storeId: storeId,
      customerId: draft.customer!.id,
      note: draft.note,
      items: draft.lines
          .map(
            (line) => TransactionItemPayloadModel(
              productId: line.productId,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
            ),
          )
          .toList(),
    );
  }
}
