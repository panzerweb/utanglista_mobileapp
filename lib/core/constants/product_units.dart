/*
  ------------------------------------------------------------------
  Unit suggestions — NOT a closed set.
  ------------------------------------------------------------------

  `products.unit` is free text on purpose. A sari-sari store sells by
  piece and by kilo; a street vendor sells by stick, by serving, by
  bundle; someone repacking rice invents "1/4 kilo". An enum would mean
  the seller cannot describe what they actually sell, and the app would
  be wrong in a way they cannot fix.

  So these are quick-pick chips above a plain text field, ordered by how
  often a small Philippine seller would reach for them.
*/
abstract final class ProductUnits {
  static const List<String> suggestions = [
    'pc',
    'kg',
    'g',
    'pack',
    'sachet',
    'bottle',
    'can',
    'L',
    'mL',
    'box',
    'bundle',
    'serving',
    'stick',
    'dozen',
  ];

  /// A sensible starting value for a new product, so the field is not
  /// empty on a form where almost every answer is "by piece".
  static const String defaultUnit = 'pc';
}
