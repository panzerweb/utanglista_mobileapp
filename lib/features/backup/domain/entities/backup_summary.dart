/*
  What a backup contains, in the terms a store owner thinks in.

  The envelope holds SQL table names and raw rows; this is the same
  information said as "3 stores, 41 customers, 260 utang". It is what
  the confirmation dialog reads back before a restore replaces
  everything — a row count is not something anyone can check a backup
  against, but "41 customers" is.
*/
class BackupSummary {
  final DateTime exportedAt;
  final int storeCount;
  final int customerCount;
  final int productCount;
  final int transactionCount;
  final int paymentCount;
  final int interestRecordCount;

  const BackupSummary({
    required this.exportedAt,
    required this.storeCount,
    required this.customerCount,
    required this.productCount,
    required this.transactionCount,
    required this.paymentCount,
    required this.interestRecordCount,
  });

  /// Every financial record in the file. The figure that matters when
  /// deciding whether a backup is worth restoring over what is there.
  int get financialRecordCount =>
      transactionCount + paymentCount + interestRecordCount;

  bool get isEmpty =>
      storeCount == 0 && customerCount == 0 && financialRecordCount == 0;

  /*
    Reads as a sentence rather than a table, because it appears inside
    a confirmation dialog where a table would not fit and would not be
    read anyway.
  */
  String describe() {
    final parts = <String>[
      _plural(storeCount, 'store', 'stores'),
      _plural(customerCount, 'customer', 'customers'),
      _plural(productCount, 'product', 'products'),
      _plural(transactionCount, 'utang record', 'utang records'),
      _plural(paymentCount, 'payment', 'payments'),
    ];

    if (interestRecordCount > 0) {
      parts.add(
        _plural(interestRecordCount, 'interest charge', 'interest charges'),
      );
    }

    return parts.join(', ');
  }

  static String _plural(int count, String one, String many) =>
      '$count ${count == 1 ? one : many}';
}
