/*
  ------------------------------------------------------------------
  InterestRate: the 0%-5% rule, written down once.
  ------------------------------------------------------------------

  §19 sets a hard range:

      The allowed rate is 0% to 5%.
      The application must reject rates below 0% or above 5%.

  That check will be needed by the store form, the store settings tab,
  the repository that persists it and the job that applies interest. If
  each writes its own comparison, they will eventually disagree, and the
  one that is wrong will be the one that lets a 40% rate through.

  Stored as BASIS POINTS — hundredths of a percent — so both the value
  and the cap are exact integers:

      2%    -> 200
      2.5%  -> 250
      5%    -> 500   (the maximum)

  A double would make `rate <= 0.05` a floating-point comparison at the
  exact boundary the rule cares about.
*/
class InterestRate implements Comparable<InterestRate> {
  /// Hundredths of a percent. 200 == 2%.
  final int basisPoints;

  const InterestRate.fromBasisPoints(this.basisPoints);

  static const InterestRate zero = InterestRate.fromBasisPoints(0);

  // ========================================================
  // ** THE §19 RANGE **
  // ========================================================

  static const int minBasisPoints = 0; // 0%
  static const int maxBasisPoints = 500; // 5%

  static const InterestRate maximum = InterestRate.fromBasisPoints(
    maxBasisPoints,
  );

  /// The single definition of an acceptable rate.
  bool get isValid =>
      basisPoints >= minBasisPoints && basisPoints <= maxBasisPoints;

  bool get isZero => basisPoints == 0;

  // ========================================================
  // ** PARSING **
  // ========================================================

  /*
    Reads what a user types into a percent field: '2', '2.5', '2.50',
    ' 2.5 % '. Returns null if it is not a number at all.

    Parsed digit-by-digit rather than through double for the same reason
    Money is — '2.5' * 100 is exact here, but the same expression is not
    for every input, and a rate is persisted permanently onto every
    interest record it produces.

    Out-of-range values still parse. Validation is `isValid`'s job, so
    the form can say "must be between 0% and 5%" instead of the far less
    helpful "that is not a number".
  */
  static InterestRate? tryParsePercent(String input) {
    final cleaned = input.replaceAll(RegExp(r'[%\s]'), '');
    if (cleaned.isEmpty) return null;

    final match = RegExp(r'^(-?)(\d*)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
    if (match == null) return null;

    final isNegative = match.group(1) == '-';
    final whole = match.group(2) ?? '';
    final fraction = match.group(3) ?? '';

    if (whole.isEmpty && fraction.isEmpty) return null;

    final percent = whole.isEmpty ? 0 : int.parse(whole);
    // '2.5' is 2.50%, not 2.05% — pad right.
    final hundredths = fraction.isEmpty
        ? 0
        : int.parse(fraction.padRight(2, '0'));

    final total = percent * 100 + hundredths;
    return InterestRate.fromBasisPoints(isNegative ? -total : total);
  }

  // ========================================================
  // ** FORMATTING **
  // ========================================================

  /// '2%', '2.5%', '0%' — trailing zeros trimmed, because "2.00%" reads
  /// like a precision the store owner did not ask for.
  String formatPercent() {
    final percent = basisPoints / 100;

    if (basisPoints % 100 == 0) return '${percent.toStringAsFixed(0)}%';
    if (basisPoints % 10 == 0) return '${percent.toStringAsFixed(1)}%';

    return '${percent.toStringAsFixed(2)}%';
  }

  /// '2' / '2.5' — for a text field where '%' is a suffix widget.
  String toEditableString() {
    if (basisPoints % 100 == 0) return (basisPoints ~/ 100).toString();
    if (basisPoints % 10 == 0) return (basisPoints / 100).toStringAsFixed(1);

    return (basisPoints / 100).toStringAsFixed(2);
  }

  @override
  int compareTo(InterestRate other) =>
      basisPoints.compareTo(other.basisPoints);

  @override
  bool operator ==(Object other) =>
      other is InterestRate && other.basisPoints == basisPoints;

  @override
  int get hashCode => basisPoints.hashCode;

  @override
  String toString() => formatPercent();
}
