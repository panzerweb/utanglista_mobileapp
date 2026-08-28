/*
  ------------------------------------------------------------------
  How each list may be ordered.
  ------------------------------------------------------------------

  One enum per list, in the same shape as StoreCategory: a stable
  [value] that could be persisted later, a [label] the menu shows, and
  a null-safe [fromValue] so an option removed in a future version
  falls back to the default rather than crashing the screen.

  These live in core/ because they cross layers deliberately — the
  presentation layer picks one, the DATASOURCE turns it into an
  OrderingTerm. Sorting is a query concern, not a widget concern; no
  screen in this app calls .sort() on a list it was handed.

  TWO RULES every option below obeys:

  1. **Deactivated rows sort last, always.** Whatever the user picked,
     an inactive customer or product belongs at the bottom (§28, §29).
     The chosen key is the SECOND ordering term, never the first.

  2. **Every option ends with an id tiebreaker.** Drift stores DateTime
     as unix SECONDS, and two products can share a name or a price, so
     without it rows tie and reshuffle between loads.
*/

/*
  CUSTOMERS: browsed by recency by default — the person you added last
  is usually the person you are about to record an utang for.
*/
enum CustomerSort {
  recent(value: 'recent', label: 'Recently added'),
  name(value: 'name', label: 'Name (A–Z)'),

  /*
    Sorted by what each person owes, biggest first — the "who do I
    need to chase" order.

    This is the one option the DATABASE cannot serve. A customer's
    balance is not a column on customers_table; it comes from the
    batched aggregate over three financial tables (§15), which the
    cubit loads separately. So the datasource treats this as [name]
    ordering to get a deterministic base, and CustomerListCubit
    re-sorts the loaded page by outstanding. That is not a widget
    sorting its own data — the cubit is the layer that holds both
    halves.
  */
  balance(value: 'balance', label: 'Balance (highest)');

  final String value;
  final String label;

  const CustomerSort({required this.value, required this.label});

  static CustomerSort fromValue(String? value) {
    if (value == null || value.isEmpty) return CustomerSort.recent;

    for (final sort in CustomerSort.values) {
      if (sort.value == value) return sort;
    }

    return CustomerSort.recent;
  }
}

/*
  STORES: newest first, so the store someone just created is the one
  they see without scrolling.
*/
enum StoreSort {
  recent(value: 'recent', label: 'Recently added'),
  name(value: 'name', label: 'Name (A–Z)'),

  /*
    Same situation as CustomerSort.balance, one level up: a store's
    receivable is the §15 aggregate across its customers, not a column
    on stores_table. StoreListCubit already loads those totals in one
    batched query, so it re-sorts there and the datasource gives this
    option a deterministic [name] base.
  */
  receivable(value: 'receivable', label: 'Receivable (highest)');

  final String value;
  final String label;

  const StoreSort({required this.value, required this.label});

  static StoreSort fromValue(String? value) {
    if (value == null || value.isEmpty) return StoreSort.recent;

    for (final sort in StoreSort.values) {
      if (sort.value == value) return sort;
    }

    return StoreSort.recent;
  }
}

/*
  ------------------------------------------------------------------
  The financial histories: transactions, payments, interest.
  ------------------------------------------------------------------

  All three default to newest first — a history is opened to see what
  just happened. They keep separate enums rather than sharing one
  because their columns differ (a period key is not a timestamp), and
  a shared enum would have to carry options that do not apply to every
  list.

  NOTE: no sort option here changes what a record MEANS. These lists
  show completed, immutable events (§30, §31); reordering them is a
  reading convenience. The customer LEDGER is deliberately excluded
  from all of this — its running balance is only correct in one order,
  and sorting or filtering it would produce numbers that are simply
  wrong. See ledger_tab.dart.
*/
enum TransactionSort {
  recent(value: 'recent', label: 'Newest first'),
  oldest(value: 'oldest', label: 'Oldest first'),
  amountHighLow(value: 'amount_desc', label: 'Largest amount');

  final String value;
  final String label;

  const TransactionSort({required this.value, required this.label});

  static TransactionSort fromValue(String? value) {
    if (value == null || value.isEmpty) return TransactionSort.recent;

    for (final sort in TransactionSort.values) {
      if (sort.value == value) return sort;
    }

    return TransactionSort.recent;
  }
}

enum PaymentSort {
  recent(value: 'recent', label: 'Newest first'),
  oldest(value: 'oldest', label: 'Oldest first'),
  amountHighLow(value: 'amount_desc', label: 'Largest amount');

  final String value;
  final String label;

  const PaymentSort({required this.value, required this.label});

  static PaymentSort fromValue(String? value) {
    if (value == null || value.isEmpty) return PaymentSort.recent;

    for (final sort in PaymentSort.values) {
      if (sort.value == value) return sort;
    }

    return PaymentSort.recent;
  }
}

/*
  INTEREST: ordered by the period a charge COVERS, not by when it was
  written. §21 dates a charge to its period deliberately — see
  AppDateFormat.interestEffectiveDate — and periodKey is zero-padded
  'YYYY-MM', so it sorts chronologically as text.
*/
enum InterestSort {
  newestPeriod(value: 'period_desc', label: 'Newest month'),
  oldestPeriod(value: 'period_asc', label: 'Oldest month'),
  amountHighLow(value: 'amount_desc', label: 'Largest charge');

  final String value;
  final String label;

  const InterestSort({required this.value, required this.label});

  static InterestSort fromValue(String? value) {
    if (value == null || value.isEmpty) return InterestSort.newestPeriod;

    for (final sort in InterestSort.values) {
      if (sort.value == value) return sort;
    }

    return InterestSort.newestPeriod;
  }
}

/*
  PRODUCTS: browsed alphabetically by default. A catalogue is looked
  up by name — unlike the customer list, which is looked up by who was
  here recently.
*/
enum ProductSort {
  name(value: 'name', label: 'Name (A–Z)'),
  priceHighLow(value: 'price_desc', label: 'Price (highest)'),
  priceLowHigh(value: 'price_asc', label: 'Price (lowest)'),
  recent(value: 'recent', label: 'Recently added');

  final String value;
  final String label;

  const ProductSort({required this.value, required this.label});

  static ProductSort fromValue(String? value) {
    if (value == null || value.isEmpty) return ProductSort.name;

    for (final sort in ProductSort.values) {
      if (sort.value == value) return sort;
    }

    return ProductSort.name;
  }
}
