import 'package:utanglista_mobileapp/core/money/money.dart';

/*
  ------------------------------------------------------------------
  CustomerBalance: the one place the balance formula is written down.
  ------------------------------------------------------------------

  §15 and §16 are emphatic that the balance is DERIVED from financial
  events and is never a stored, mutable field:

      Outstanding = Σ transactions + Σ interest − Σ payments

  This class holds the three sums and derives the fourth. Nothing else
  in the app is allowed to write that subtraction — the customer row,
  the customer header, the dashboard total, the payment validator and
  the interest base all read `outstanding` from here.

  WHY THAT MATTERS:
  A second implementation is not a duplicate, it is a future
  disagreement. The moment the list says a customer owes ₱440 and the
  payment screen says ₱450, there is no way for a store owner to know
  which one is lying.

  The three components are kept rather than collapsed into a single
  number because the ledger, the customer header and the dashboard all
  want to show the breakdown, and recomputing it would mean querying
  twice.
*/
class CustomerBalance {
  /// Σ of transaction totals — what the customer took on credit.
  final Money totalUtang;

  /// Σ of interest charges applied to this customer (§21).
  final Money totalInterest;

  /// Σ of payments received (§11).
  final Money totalPaid;

  const CustomerBalance({
    required this.totalUtang,
    required this.totalInterest,
    required this.totalPaid,
  });

  static const CustomerBalance zero = CustomerBalance(
    totalUtang: Money.zero,
    totalInterest: Money.zero,
    totalPaid: Money.zero,
  );

  // ========================================================
  // ** THE DERIVED VALUE **
  // ========================================================

  /// §15. The only definition of what a customer owes.
  Money get outstanding => totalUtang + totalInterest - totalPaid;

  /// Everything the customer was ever charged, before payments.
  Money get totalCharged => totalUtang + totalInterest;

  /// Paid in full. Exact because Money is integer centavos — with
  /// doubles this comparison could not be trusted.
  bool get isSettled => outstanding.isZero;

  bool get hasDebt => outstanding.isPositive;

  /*
    Should be unreachable in V1: §23 forbids payments that exceed the
    balance, so a negative outstanding means either a bug or a future
    customer-credit feature. Exposed so the UI can show something
    honest rather than a minus sign it cannot explain.
  */
  bool get isOverpaid => outstanding.isNegative;

  bool get hasActivity =>
      !totalUtang.isZero || !totalInterest.isZero || !totalPaid.isZero;

  // ========================================================
  // ** RULES THAT DEPEND ON THE BALANCE **
  // Kept here so they cannot drift from the number they guard.
  // ========================================================

  /*
    §23: "For V1, payments should not exceed the customer's outstanding
    balance." The largest payment this customer may make right now.
  */
  Money get maximumPayment => hasDebt ? outstanding : Money.zero;

  /// §23 + §38: a payment must be positive and must not overshoot.
  bool canAcceptPayment(Money amount) =>
      amount.isPositive && amount <= outstanding;

  /*
    §20: interest is charged against the applicable outstanding balance.

    A customer who owes nothing is charged nothing — otherwise a settled
    account would start growing again on its own, which is the opposite
    of what §22 is trying to prevent.
  */
  Money interestFor(int rateBasisPoints) =>
      hasDebt ? outstanding.applyRateBasisPoints(rateBasisPoints) : Money.zero;

  // ========================================================

  CustomerBalance copyWith({
    Money? totalUtang,
    Money? totalInterest,
    Money? totalPaid,
  }) {
    return CustomerBalance(
      totalUtang: totalUtang ?? this.totalUtang,
      totalInterest: totalInterest ?? this.totalInterest,
      totalPaid: totalPaid ?? this.totalPaid,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CustomerBalance &&
      other.totalUtang == totalUtang &&
      other.totalInterest == totalInterest &&
      other.totalPaid == totalPaid;

  @override
  int get hashCode => Object.hash(totalUtang, totalInterest, totalPaid);

  @override
  String toString() =>
      'CustomerBalance(utang: $totalUtang, interest: $totalInterest, '
      'paid: $totalPaid, outstanding: $outstanding)';
}
