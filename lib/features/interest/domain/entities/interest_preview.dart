import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';

/*
  ------------------------------------------------------------------
  What applying interest WOULD do, before anything is written.
  ------------------------------------------------------------------

  Interest is the only operation in this app that changes many
  customers' balances at once, and §21 makes each change a permanent
  record. So it is previewed first: who is affected, on what base, for
  how much — and who is being skipped and why.

  Every line reports a status rather than being silently filtered out.
  A seller who expects eight customers to be charged and sees six
  needs to know which two were skipped, not wonder whether the app
  missed them.
*/
enum InterestPreviewStatus {
  /// Will be charged when applied.
  willApply,

  /// §22: this customer already has a record for this period. A second
  /// run must not compound it.
  alreadyApplied,

  /*
    Nothing was owed at the START of this period, so §20's "applicable
    outstanding balance" is zero.

    This covers two cases that look different to the seller: a settled
    account, and a debt taken DURING this month — which is not charged
    until the next one, so that interest runs from roughly when the
    debt was created.
  */
  nothingOwed,

  /// The computed interest rounds to ₱0.00. Writing a zero-peso charge
  /// would put a meaningless row in the ledger.
  roundsToZero,

  /// §29: deactivated. See the note on InterestPreview.
  inactive,
}

class InterestPreviewLine {
  final int customerId;
  final String customerName;

  /// §21: the balance the charge is computed against, recorded with it.
  final Money baseAmount;

  /// §20: base × rate, rounded once.
  final Money interestAmount;

  final InterestPreviewStatus status;

  const InterestPreviewLine({
    required this.customerId,
    required this.customerName,
    required this.baseAmount,
    required this.interestAmount,
    required this.status,
  });

  bool get willApply => status == InterestPreviewStatus.willApply;

  /// Why this customer is being skipped, in the seller's words.
  String? get skipReason {
    switch (status) {
      case InterestPreviewStatus.willApply:
        return null;
      case InterestPreviewStatus.alreadyApplied:
        return 'Already charged for this month';
      case InterestPreviewStatus.nothingOwed:
        return 'Owed nothing at the start of this month';
      case InterestPreviewStatus.roundsToZero:
        return 'Interest rounds to ₱0.00';
      case InterestPreviewStatus.inactive:
        return 'Deactivated';
    }
  }
}

/*
  ------------------------------------------------------------------
  A DECISION worth revisiting: deactivated customers are skipped.
  ------------------------------------------------------------------

  §29 says an inactive customer "cannot normally receive new
  transactions" and "retains their financial history". Interest is
  neither exactly — it is a new charge against an old debt.

  This implementation SKIPS them, on the reasoning that deactivating
  someone is the seller's signal to stop the relationship growing, and
  silently inflating a debt they have stepped away from would surprise
  them. It is the reversible choice: a seller who wants the charge can
  reactivate the customer.

  If the business rule turns out to be the opposite, this is the one
  place to change it.
*/
class InterestPreview {
  /// 'YYYY-MM' — the period being charged (§22).
  final String periodKey;

  final InterestRate rate;

  /// Every customer in the store, charged or skipped.
  final List<InterestPreviewLine> lines;

  const InterestPreview({
    required this.periodKey,
    required this.rate,
    required this.lines,
  });

  List<InterestPreviewLine> get toCharge =>
      lines.where((line) => line.willApply).toList();

  List<InterestPreviewLine> get skipped =>
      lines.where((line) => !line.willApply).toList();

  int get chargeCount => toCharge.length;

  /// What the store's receivable grows by if this is applied.
  Money get totalInterest =>
      toCharge.map((line) => line.interestAmount).sum();

  /// Combined balances the charge is computed against.
  Money get totalBase => toCharge.map((line) => line.baseAmount).sum();

  bool get hasAnythingToApply => toCharge.isNotEmpty;

  /// True when every skip is "already charged" — i.e. this month is
  /// done, rather than there being nothing to do.
  bool get isFullyApplied =>
      !hasAnythingToApply &&
      lines.isNotEmpty &&
      lines.any(
        (line) => line.status == InterestPreviewStatus.alreadyApplied,
      );
}

/*
  What actually happened. Reported per customer rather than as a single
  success, because a batch can partly succeed — see the note in the
  datasource on why that is correct rather than a compromise.
*/
class InterestApplicationResult {
  final String periodKey;
  final int appliedCount;
  final Money totalCharged;

  /// Customers the run could not charge, with the reason. Empty on a
  /// clean run.
  final Map<String, String> failures;

  const InterestApplicationResult({
    required this.periodKey,
    required this.appliedCount,
    required this.totalCharged,
    this.failures = const {},
  });

  bool get hasFailures => failures.isNotEmpty;
}
