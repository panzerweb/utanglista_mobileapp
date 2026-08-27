import 'package:utanglista_mobileapp/core/money/money.dart';

/*
  Something a store sells.

  ------------------------------------------------------------------
  `price` is the CURRENT selling price. It is not history.
  ------------------------------------------------------------------

  §5 and §7 are emphatic about this: when a product goes into a
  transaction, the price is COPIED into the transaction item as a
  snapshot. Repricing rice from ₱100 to ₱110 later must not turn a past
  ₱500 line into ₱550.

  So nothing outside the transaction builder should ever read this
  field to display what something cost — only what it costs now.
*/
class ProductEntity {
  final int id;
  final int storeId;
  final String name;
  final String description;

  /*
    §7 note aside, barcode is OPTIONAL — street vendors sell fishball
    and kwek-kwek, which have no barcode at all. Unique within a store
    when present, so scan-to-find is never ambiguous.
  */
  final String? barcode;

  /// Current selling price. See the class note.
  final Money price;

  /// Free text: 'pc', 'kg', 'serving', '1/4 kilo'. See ProductUnits.
  final String unit;

  /// §28: a product with transaction history is deactivated, never
  /// deleted. Inactive products stay out of new transactions but remain
  /// readable in the ones they already appear in.
  final bool isActive;

  final DateTime createdAt;

  const ProductEntity({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.barcode,
    required this.price,
    required this.unit,
    required this.isActive,
    required this.createdAt,
  });

  bool get hasBarcode => barcode != null && barcode!.trim().isNotEmpty;

  bool get hasDescription => description.trim().isNotEmpty;

  /// '₱100.00 / kg' — how the price reads on a card.
  String get priceWithUnit => '${price.format()} / $unit';

  /*
    Can this product be added to a NEW transaction?

    §28 keeps inactive products out. A zero price is allowed to exist
    in the catalogue but not to enter a transaction: §24 requires a
    transaction total greater than zero, so a free item would have to
    be a deliberate future feature rather than an accident.
  */
  bool get isSellable => isActive && price.isPositive;

  ProductEntity copyWith({
    int? id,
    int? storeId,
    String? name,
    String? description,
    String? barcode,
    Money? price,
    String? unit,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
