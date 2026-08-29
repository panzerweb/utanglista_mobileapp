import 'package:utanglista_mobileapp/core/money/money.dart';

/*
  ------------------------------------------------------------------
  The customer ledger (§17) — assembled, never stored.
  ------------------------------------------------------------------

  §17 is explicit that no ledger table is needed: the chronology is
  built from the three financial event tables that already exist.

      Date     Type      Description          Amount
      -----------------------------------------------
      Aug 20   UTANG     5 × Rice             +₱500
      Aug 22   PAYMENT   Partial payment      −₱200
      Aug 23   INTEREST  Monthly interest       +₱9

  A ledger row is one of exactly three things, so it is a sealed
  hierarchy rather than a struct with nullable fields — the UI switches
  on the kind and the compiler checks it covered all three.

  `signedAmount` is what makes the running balance a plain fold:
  utang and interest add, payments subtract. That sign convention IS
  the §15 formula, expressed per-event.
*/
enum LedgerEntryKind { utang, payment, interest }

sealed class LedgerEntry {
  /// The id of the underlying row, within its own table.
  final int sourceId;
  final DateTime occurredAt;

  const LedgerEntry({required this.sourceId, required this.occurredAt});

  LedgerEntryKind get kind;

  /// Positive adds to the debt, negative reduces it (§15).
  Money get signedAmount;

  /// The magnitude, for display beside an explicit sign.
  Money get amount => signedAmount.absolute;
}

/// Money owed because the customer took goods on credit (§6).
class LedgerUtangEntry extends LedgerEntry {
  final Money total;

  /// Item count rather than the item list. Loading every line of every
  /// transaction to render a scrollable ledger would be a query per
  /// row; tapping through to the transaction shows the full breakdown.
  final int itemCount;

  final String note;

  const LedgerUtangEntry({
    required super.sourceId,
    required super.occurredAt,
    required this.total,
    required this.itemCount,
    required this.note,
  });

  @override
  LedgerEntryKind get kind => LedgerEntryKind.utang;

  @override
  Money get signedAmount => total;

  String get description =>
      '$itemCount ${itemCount == 1 ? 'item' : 'items'}';
}

/// Money received, reducing the account balance (§11).
class LedgerPaymentEntry extends LedgerEntry {
  final Money paid;
  final String note;

  const LedgerPaymentEntry({
    required super.sourceId,
    required super.occurredAt,
    required this.paid,
    required this.note,
  });

  @override
  LedgerEntryKind get kind => LedgerEntryKind.payment;

  @override
  Money get signedAmount => -paid;

  String get description => note.trim().isEmpty ? 'Payment' : note;
}

/// A monthly interest charge, recorded as an event (§20, §21).
class LedgerInterestEntry extends LedgerEntry {
  final Money charged;
  final int rateBasisPoints;
  final String periodKey;

  const LedgerInterestEntry({
    required super.sourceId,
    required super.occurredAt,
    required this.charged,
    required this.rateBasisPoints,
    required this.periodKey,
  });

  @override
  LedgerEntryKind get kind => LedgerEntryKind.interest;

  @override
  Money get signedAmount => charged;
}

/*
  A ledger row with the balance AS OF that event.

  Computed oldest-first, because a running balance only means anything
  read forwards. The UI then renders newest-first — so the top row's
  balance is the customer's balance right now, which is the number the
  seller opened the screen for.
*/
class LedgerRow {
  final LedgerEntry entry;
  final Money balanceAfter;

  const LedgerRow({required this.entry, required this.balanceAfter});
}

abstract final class Ledger {
  /*
    Orders the events and folds the running balance over them.

    ------------------------------------------------------------------
    Why the sort has three keys.
    ------------------------------------------------------------------

    Drift stores DateTime as unix SECONDS, so an utang and the payment
    settling it can carry the identical timestamp — a customer paying
    at the counter for what they just took is not a rare case.

    Ordering by time alone leaves those tied, and SQLite may return
    them either way, so the running balance would flicker between
    loads. Worse, if the payment sorted first the ledger would show a
    momentarily NEGATIVE balance for a customer who never owed one.

    So within the same second: utang, then interest, then payments —
    debts are added before anything reduces them. The `sourceId`
    breaks any remaining tie so the order is fully deterministic.
  */
  static List<LedgerRow> build(List<LedgerEntry> entries) {
    final ordered = [...entries]..sort(_compare);

    var running = Money.zero;

    return ordered.map((entry) {
      running = running + entry.signedAmount;
      return LedgerRow(entry: entry, balanceAfter: running);
    }).toList();
  }

  /// Oldest first — the order the running balance is folded in.
  static int _compare(LedgerEntry a, LedgerEntry b) {
    final byTime = a.occurredAt.compareTo(b.occurredAt);
    if (byTime != 0) return byTime;

    final byKind = _kindOrder(a.kind).compareTo(_kindOrder(b.kind));
    if (byKind != 0) return byKind;

    return a.sourceId.compareTo(b.sourceId);
  }

  static int _kindOrder(LedgerEntryKind kind) {
    switch (kind) {
      case LedgerEntryKind.utang:
        return 0;
      case LedgerEntryKind.interest:
        return 1;
      case LedgerEntryKind.payment:
        return 2;
    }
  }
}
