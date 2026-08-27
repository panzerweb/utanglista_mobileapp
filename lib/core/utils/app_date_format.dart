import 'package:intl/intl.dart';

/*
  ------------------------------------------------------------------
  One place for how a date looks, and one place for the period key.
  ------------------------------------------------------------------

  The ledger (§17), transaction history and dashboard all render dates,
  and they must agree. More importantly, `periodKey` is not a display
  concern at all: it is the value the unique (customer_id, period_key)
  index uses to stop interest being applied twice for the same month
  (§22). It is defined here so there is exactly one definition of what
  "this month" means.
*/
abstract final class AppDateFormat {
  static final DateFormat _full = DateFormat('MMMM d, y'); // August 23, 2026
  static final DateFormat _medium = DateFormat('MMM d, y'); // Aug 23, 2026
  static final DateFormat _short = DateFormat('MMM d'); // Aug 23
  static final DateFormat _monthYear = DateFormat('MMMM y'); // August 2026
  static final DateFormat _withTime = DateFormat(
    'MMM d, y • h:mm a',
  ); // Aug 23, 2026 • 2:30 PM

  static String full(DateTime date) => _full.format(date);
  static String medium(DateTime date) => _medium.format(date);
  static String short(DateTime date) => _short.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String withTime(DateTime date) => _withTime.format(date);

  /*
    'YYYY-MM' — the interest period identifier stored on every interest
    record. Padded so it sorts lexicographically as well as
    chronologically: '2026-08' < '2026-09' < '2026-10'.
  */
  static String periodKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';

  /// Turns a stored period key back into a heading like 'August 2026'.
  static String periodLabel(String periodKey) {
    final month = periodStart(periodKey);
    if (month == null) return periodKey;

    return monthYear(month);
  }

  /*
    ------------------------------------------------------------------
    The first instant of a period — the interest cutoff.
    ------------------------------------------------------------------

    Monthly interest is charged on what a customer owed ENTERING the
    month, so this is the boundary the base balance is computed
    against: every financial event strictly before it counts, and
    everything from the month itself does not.

    That is what makes a debt taken on 20 August first attract interest
    in September rather than immediately — roughly a month after it was
    created, which is the point.
  */
  static DateTime? periodStart(String periodKey) {
    final parts = periodKey.split('-');
    if (parts.length != 2) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;
    if (month < 1 || month > 12) return null;

    return DateTime(year, month);
  }

  /// The last instant of a period. `DateTime(y, m + 1)` normalises
  /// December into the next January, so no month-length table is needed.
  static DateTime? periodEnd(String periodKey) {
    final start = periodStart(periodKey);
    if (start == null) return null;

    return DateTime(
      start.year,
      start.month + 1,
    ).subtract(const Duration(seconds: 1));
  }

  /*
    ------------------------------------------------------------------
    When an interest charge is DATED.
    ------------------------------------------------------------------

    Not the wall clock. A charge is dated to the period it covers, so
    running August's interest late — on the 20th of September, say —
    still records it as an August event.

    Two things depend on this:

      the ledger    §17 orders events by date. An August charge that
                    surfaced in late September would read as though the
                    customer was charged twice that month.

      compounding   September's base is everything before 1 September.
                    A wall-clock-dated August charge would fall outside
                    it, and the compounding the store expects would
                    silently not happen.

    Clamped to `now` so charging the current month never produces a
    future-dated ledger entry.
  */
  static DateTime interestEffectiveDate(String periodKey, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final start = periodStart(periodKey);
    final end = periodEnd(periodKey);

    if (start == null || end == null) return at;

    if (at.isBefore(start)) return start;
    if (at.isAfter(end)) return end;

    return at;
  }

  /*
    "Today" / "Yesterday" / "Aug 23, 2026" — for list headers, where a
    relative label reads faster than a date the user has to decode.
    Compares calendar days, not elapsed hours, so 11pm and 1am are
    correctly "yesterday" and "today" rather than "2 hours ago".
  */
  static String relative(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final thatDay = DateTime(date.year, date.month, date.day);
    final thisDay = DateTime(today.year, today.month, today.day);
    final difference = thisDay.difference(thatDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference > 1 && difference < 7) return '$difference days ago';

    return medium(date);
  }
}
