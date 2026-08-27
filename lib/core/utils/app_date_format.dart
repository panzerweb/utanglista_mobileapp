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
    final parts = periodKey.split('-');
    if (parts.length != 2) return periodKey;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return periodKey;

    return monthYear(DateTime(year, month));
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
