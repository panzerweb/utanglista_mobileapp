import 'package:intl/intl.dart';

/*
  ------------------------------------------------------------------
  Money: the only way this app is allowed to hold a peso amount.
  ------------------------------------------------------------------

  WHY IT EXISTS:
  transaction_logic.md §26 forbids floating point for financial values,
  and §38 leans the whole ledger on exact comparisons. A double cannot
  do that:

    0.1 + 0.2 == 0.3        // false
    (1000 * 0.02) == 20.0   // true here, false for other rates

  A store owner would see a ₱0.01 phantom balance on a customer who has
  paid in full, and "fully paid" is the single most important thing this
  app tells them.

  So money is an INTEGER of centavos, and every operation on it lives in
  one place:

    ₱1,250.75  ->  Money(125075)

  HOW TO USE IT:
    Money.fromCentavos(row.totalAmount)   // reading from Drift
    money.centavos                        // writing back to Drift
    Money.parse('1,250.75')               // reading from a TextField
    money.format()                        // '₱1,250.75' for the UI

  Arithmetic returns new Money — instances are immutable:

    final total = items.fold(Money.zero, (sum, i) => sum + i.subTotal);

  ROUNDING happens in exactly two places, both of them here:
  multiplication by a quantity, and application of an interest rate.
  Every other operation is exact.
*/
class Money implements Comparable<Money> {
  /// The amount in centavos. ₱1,250.75 is 125075.
  final int centavos;

  const Money.fromCentavos(this.centavos);

  static const Money zero = Money.fromCentavos(0);

  /// For literals and tests where pesos read more clearly than centavos.
  /// Not for parsing user input — use [parse] or [tryParse] for that.
  factory Money.fromPesos(num pesos) =>
      Money.fromCentavos((pesos * 100).round());

  // ========================================================
  // ** PARSING **
  // ========================================================

  /*
    Parsed digit-by-digit rather than via double.parse(s) * 100.

    '0.29' * 100 evaluates to 28.999999999999996 in binary floating
    point. .round() rescues that particular case, but the failure mode
    is silent and input-dependent, and this is the boundary where a
    typo becomes a permanent financial record. Integer arithmetic on
    the two halves of the string cannot drift at all.
  */
  static Money? tryParse(String input) {
    // Tolerate what a user actually types: '₱1,250.75', ' 1250.75 '.
    final cleaned = input.replaceAll(RegExp(r'[₱,\s]'), '');
    if (cleaned.isEmpty) return null;

    final match = RegExp(r'^(-?)(\d*)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
    if (match == null) return null;

    final isNegative = match.group(1) == '-';
    final whole = match.group(2) ?? '';
    final fraction = match.group(3) ?? '';

    // '.' and '' are not amounts; '5' and '5.' and '.5' are.
    if (whole.isEmpty && fraction.isEmpty) return null;

    final pesos = whole.isEmpty ? 0 : int.parse(whole);
    // '5.5' means 50 centavos, not 5 — pad right, never left.
    final centavos = fraction.isEmpty
        ? 0
        : int.parse(fraction.padRight(2, '0'));

    final total = pesos * 100 + centavos;
    return Money.fromCentavos(isNegative ? -total : total);
  }

  /// Throws [FormatException] on invalid input. Prefer [tryParse] when
  /// the string came from a user.
  factory Money.parse(String input) {
    final parsed = tryParse(input);
    if (parsed == null) {
      throw FormatException('Not a valid peso amount', input);
    }
    return parsed;
  }

  // ========================================================
  // ** ARITHMETIC **
  // Exact, except where a comment says otherwise.
  // ========================================================

  Money operator +(Money other) =>
      Money.fromCentavos(centavos + other.centavos);

  Money operator -(Money other) =>
      Money.fromCentavos(centavos - other.centavos);

  Money operator -() => Money.fromCentavos(-centavos);

  /*
    Multiplication by a QUANTITY, which may be fractional (1.5 kg of
    rice). This is the one place a non-integer enters the calculation,
    so it rounds once, here, and the result is exact from then on.

    Half-away-from-zero, matching how a person rounds a receipt by hand.
  */
  Money operator *(num quantity) =>
      Money.fromCentavos((centavos * quantity).round());

  /*
    Interest (§20). Basis points keep the rate itself exact:
    2% is 200, and the §19 cap of 5% is the integer 500.

      ₱1,000.00 at 2%  ->  100000 * 200 / 10000  =  2000  =  ₱20.00

    Rounds once, like multiplication above.
  */
  Money applyRateBasisPoints(int basisPoints) =>
      Money.fromCentavos((centavos * basisPoints / 10000).round());

  // ========================================================
  // ** COMPARISON **
  // Exact integer comparison — this is the whole point of the class.
  // ========================================================

  bool operator <(Money other) => centavos < other.centavos;
  bool operator <=(Money other) => centavos <= other.centavos;
  bool operator >(Money other) => centavos > other.centavos;
  bool operator >=(Money other) => centavos >= other.centavos;

  bool get isZero => centavos == 0;
  bool get isPositive => centavos > 0;
  bool get isNegative => centavos < 0;

  Money get absolute => Money.fromCentavos(centavos.abs());

  @override
  int compareTo(Money other) => centavos.compareTo(other.centavos);

  @override
  bool operator ==(Object other) =>
      other is Money && other.centavos == centavos;

  @override
  int get hashCode => centavos.hashCode;

  // ========================================================
  // ** FORMATTING **
  // The single source of how a peso amount looks in this app.
  // ========================================================

  static final NumberFormat _withSymbol = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  static final NumberFormat _plain = NumberFormat('#,##0.00', 'en_PH');

  /// '₱1,250.75' — for display.
  String format() => _withSymbol.format(centavos / 100);

  /// '1,250.75' — for text fields, where the symbol is a prefix widget.
  String formatPlain() => _plain.format(centavos / 100);

  /// '1250.75' — for editing, where separators get in the user's way.
  String toEditableString() => (centavos / 100).toStringAsFixed(2);

  @override
  String toString() => format();
}

/*
  Sums a list without callers re-deriving the fold every time. Used for
  transaction totals (§8) and every branch of the balance calculation
  (§15).
*/
extension MoneyIterable on Iterable<Money> {
  Money sum() => fold(Money.zero, (total, amount) => total + amount);
}
