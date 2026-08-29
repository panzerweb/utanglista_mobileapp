import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';

/*
  A charge that was applied — §21's record, as the app reads it back.

  §20: "Interest should be represented as a financial event rather than
  simply recalculated every time the balance is displayed. This allows
  the application to preserve historical accounting."

  So everything needed to explain the charge is stored ON the row:
  the base it was computed from, the rate at that moment, and the
  period it covers. Changing the store's rate later cannot rewrite what
  was already charged — the same reasoning as §7's price snapshot.
*/
class InterestRecordEntity {
  final int id;
  final int storeId;
  final int customerId;

  /// Joined for display; §27 lets a rename change this and nothing else.
  final String customerName;

  /// §21: the balance the charge was computed against.
  final Money baseAmount;

  /// §21: the rate at the time of charging — a snapshot, not the
  /// store's current setting.
  final InterestRate rate;

  final Money interestAmount;

  /// 'YYYY-MM'. The unique (customerId, periodKey) index is what makes
  /// §22 a database guarantee rather than a hopeful check.
  final String periodKey;

  final DateTime createdAt;

  const InterestRecordEntity({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    required this.baseAmount,
    required this.rate,
    required this.interestAmount,
    required this.periodKey,
    required this.createdAt,
  });
}
