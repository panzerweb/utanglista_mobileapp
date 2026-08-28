# UtangLista — Design & Implementation Plan

Companion to [`transaction_logic.md`](transaction_logic.md) (business rules) and
[`../CLAUDE.md`](../CLAUDE.md) (conventions). This document is the **game plan**: what gets
built, in what order, and which decisions are still open.

---

## 1. Where the codebase stands today

*Updated at the end of Phase 8.*

| Area | Status |
|---|---|
| Drift schema (8 tables) | ✅ `schemaVersion: 5`, covered by 23 tests |
| `Money` / `InterestRate` / `MoneyTextField` | ✅ |
| `AppDateFormat` (+ `periodKey`, interest period helpers) | ✅ |
| `AppFailure` + `repositoryGuard` / `requireRowChanged` | ✅ |
| Shared state views, snackbar, confirm dialog, scanner | ✅ |
| `CustomerBalance` + balance repository | ✅ The §15 formula and its queries |
| Stores slice + screens | ✅ Phase 1 |
| Customers slice + screens | ✅ Phase 2 |
| Products slice + screens + barcode flows | ✅ Phase 3 |
| Transactions slice, builder, history, detail | ✅ Phase 4 |
| Payments slice + §23 guard | ✅ Phase 5 |
| Ledger read model (§17) | ✅ Phase 5 |
| Interest preview / application / history | ✅ Phase 6 |
| Dashboard read model + screen | ✅ Phase 7 |
| Routing (all screens on go_router) | ✅ |
| DI registrations | ✅ All slices wired |
| Search + sort on every list | ✅ Phase 8 |
| Stepwise migrations (destructive `onUpgrade` gone) | ✅ Phase 8 |
| Backup / restore (versioned JSON) | ✅ Phase 8 |

**The store slice is the reference implementation.** Every other feature is built by
copying its shape.

---

## 2. Navigation map

The bottom bar stays at **three** destinations. Everything else is pushed on top of a
branch.

```text
/                                     Splash / landing (existing HomeScreen)
│
└── StatefulShellRoute (AppView, bottom NavigationBar)
    │
    ├── [0] /dashboard                Dashboard
    │
    ├── [1] /stores                   Store list  ← every store the user created
    │        ├── /stores/new          Create store (full-page form)
    │        └── /stores/:storeId     STORE DETAIL — TabBar shell
    │             ├── tab: Customers
    │             │    └── /stores/:storeId/customers/:customerId
    │             │         ├── tab: Ledger      (running balance)
    │             │         ├── tab: Utang       (transactions)
    │             │         └── tab: Payments
    │             ├── tab: Products
    │             │    ├── /stores/:storeId/products/new   (+ scan)
    │             │    └── /stores/:storeId/products/:productId
    │             ├── tab: Transactions          (store-wide history)
    │             │    └── /stores/:storeId/transactions/:transactionId
    │             └── tab: Settings              (interest on/off + rate, edit, delete)
    │
    │        /stores/:storeId/transactions/new   Transaction builder (pushed full-screen)
    │        /stores/:storeId/payments/new       Record payment (modal sheet or page)
    │        /scan                               Barcode scanner (pushed, returns a String)
    │
    └── [2] /settings                 App-level settings
```

**Store detail is a `TabBar` inside a single route**, not four routes. The tab index is a
query param (`/stores/3?tab=products`) so back-navigation and deep links behave.

The tab list is deliberately extensible — "and more…" lands here (e.g. Reports, Ledger
export) without touching the bottom bar.

---

## 3. Schema decisions to settle before Phase 1

These are the corrections referenced in `CLAUDE.md` §7, with the reasoning behind each.

### 3.1 Money representation — **DECIDED: integer centavos**

`transaction_logic.md` §26 explicitly forbids floating point for exact financial values.
The current schema uses `RealColumn` (Dart `double`) for `price`, `unitPrice`, `subTotal`,
`totalAmount`, `amount`, `baseAmount`, `interestAmount`, `rate`. All of these become
`IntColumn`.

```dart
IntColumn get totalAmount     => integer().withDefault(const Constant(0))();  // centavos
IntColumn get rateBasisPoints => integer().withDefault(const Constant(0))();  // 0–500 = 0–5%
```

- ₱1,250.75 → `125075`. Exact addition, exact comparison, exact equality.
- Only division (interest) rounds, and it rounds once, deliberately:
  `interest = (balance * rateBasisPoints / 10000).round()`.
- Rate stored as basis points (`IntColumn`, 0–500 for 0%–5%) so the 5% cap is an exact
  integer check.
- A `Money` value object in `core/` wraps the int and owns parsing, arithmetic and the
  `₱#,##0.00` formatter, so no widget ever does raw math.

*Rejected: keeping `double`.* `0.1 + 0.2 != 0.3` means balances drift by centavos over long
ledgers, and equality checks (`balance == 0` → "fully paid") become unreliable — exactly
the hazard §26 warns about.

**Naming:** columns keep their existing names (`price`, `unitPrice`, `totalAmount`, …)
rather than gaining a `Centavos` suffix. The unit is enforced by the type system — every
one of these is read and written through `Money`, never as a bare `int` — and the suffix
would be noise on a dozen columns. `rate` is the exception: it becomes
`rateBasisPoints` because "rate" reads ambiguously as either `0.02` or `2`.

### 3.2 Index names must be globally unique

`customer_created_at` is declared three times. The generator emits only one
`CREATE INDEX`, so **`payments_table` has no index and `interest_records_table` lost its
customer index.** Rename per table:

```text
idx_txn_customer_created
idx_payment_customer_created
idx_interest_customer_created
idx_interest_store_created
idx_customer_store_name
idx_product_store_barcode
```

### 3.3 History must survive product/customer changes

`TransactionsItemTable.productId` currently cascades on delete. Change to
`KeyAction.restrict` (or no action) so a product with history simply cannot be deleted —
the UI offers **deactivate** instead (§28). Same reasoning for
`TransactionsTable.customerId` and `PaymentsTable.customerId`.

`storeId` cascades are fine: deleting a store is a deliberate "remove this business and all
its records" action, and the UI will confirm it explicitly.

### 3.4 Realistic length constraints

`min: 6` on `name` rejects "Rice", "Juan", "Egg". Change to `min: 2, max: 60` for stores,
customers and products. Update `StoreFormCubit`'s matching validation message.

### 3.5 Optional / defaulted columns

- `CustomersTable.contactNumber` → `.nullable()` (§4 says optional).
- `createdAt` everywhere → `.clientDefault(() => DateTime.now())`, non-nullable. The
  ledger sorts on it.
- `isActive` → `.withDefault(const Constant(true))`.
- `StoresTable.category` → keep nullable, but the create form requires it.

### 3.6 Interest period guard

Add to `InterestRecordsTable`:

```dart
TextColumn get periodKey => text()();   // 'YYYY-MM', e.g. '2026-08'
```

plus a **unique** index on `(customerId, periodKey)`. §22's "must not compound
accidentally" then becomes a database guarantee, not a hopeful check.

### 3.7 Barcode uniqueness

Unique index on `(storeId, barcode)` where barcode is non-null — two products in the same
store must not share a barcode, or scan-to-find is ambiguous. Barcode stays nullable
because street vendors sell unbarcoded goods.

### 3.8 Store settings row

Every store needs exactly one `store_settings` row. Create it **inside the same Drift
transaction** as the store insert so a store can never exist without settings.

### 3.9 `StoreFormCubit.insertStore` missing `return`

The validation branch emits `StoreFormFailure` and then falls through into the insert, so
an invalid name still writes a row *and* the UI sees two conflicting states.

### 3.10 `StoreListState.copyWith` cannot clear

`error ?? this.error` means `copyWith(error: null)` keeps the old error, and the category
filter can never return to "All". Fix with a sentinel (see `CLAUDE.md` §4.5).

### 3.11 Migration — **DECIDED: destructive**

Confirmed there is no real data on the device yet, so Phase 0 bumps `schemaVersion` to `4`
and uses a destructive `onUpgrade` that drops every table and recreates the schema. This is
the last version where that is acceptable — from Phase 1 onward, migrations are stepwise.

Once real data exists, drift's `schema dump` / migration test tooling should be adopted so
upgrades are verified rather than hoped for.

---

## 4. Cross-cutting building blocks (Phase 0)

Built once, used by every later phase.

| Component | Location | Purpose | Status |
|---|---|---|---|
| `Money` value object | `core/money/money.dart` | Centavo arithmetic + `₱#,##0.00` formatting | ✅ |
| `AppDateFormat` | `core/utils/` | Dates, plus the `periodKey` §22 depends on | ✅ |
| `CustomerBalance` | `features/customers/domain/entities/` | The **single** authoritative `Σtxn + Σinterest − Σpayment`, and the payment/interest rules that hang off it | ✅ |
| `CustomerBalanceRepository` | `features/customers/domain/repositories/` | The queries behind it — per customer, per store (one query, not N), and store/global totals | ✅ |
| `AppSnackBar` | `core/shared/` | Renders an `AppFailure` consistently | ✅ |
| `AppConfirmDialog` | `core/shared/` | Destructive-action confirmation (§30) | ✅ |
| `EmptyStateView` | `core/shared/views/` | Icon + message + optional CTA | ✅ |
| `AppLoadingView` / `AppErrorView` | `core/shared/views/` | The other two of the three list states | ✅ |
| `BarcodeScannerScreen` | `core/shared/scanner/` | Wraps `mobile_scanner`, pops a `String?` | ✅ |
| `ManualBarcodeEntryDialog` | `core/shared/scanner/` | The fallback every scanner failure path ends at | ✅ |

**On the balance:** it landed as an entity + repository pair rather than a standalone
`BalanceCalculator` class. The formula lives on `CustomerBalance` (pure, no database), and
the repository supplies the three sums that feed it. One formula, two ways to load its
inputs — a single-customer query and a batched per-store query — so a list of 200 customers
is one round trip, not 200, and both paths reach the same arithmetic.

**`BalanceCalculator` is the most important item here.** Every screen that shows a balance
— customer row, customer header, dashboard total, payment validation, interest base — calls
it. It is a single SQL aggregate per customer, not three round trips:

```sql
SELECT
  (SELECT COALESCE(SUM(total_amount), 0)    FROM transactions_table   WHERE customer_id = ?)
+ (SELECT COALESCE(SUM(interest_amount), 0) FROM interest_records_table WHERE customer_id = ?)
- (SELECT COALESCE(SUM(amount), 0)          FROM payments_table       WHERE customer_id = ?)
```

For the customer *list*, the same shape runs as one grouped query over the whole store —
never N+1 per row.

---

## 5. Phases

### Phase 0 — Foundation ✅ COMPLETE

**Goal:** the schema is correct and the store slice is wired end-to-end.

- [x] Apply schema decisions §3.1–§3.8; regenerate; `schemaVersion` → 5
- [x] `Money` value object + formatter + 28 unit tests
- [x] `AppDateFormat`, including the `periodKey` definition §22 depends on
- [x] Fix `StoreFormCubit` validation bounds; `StoreListState.copyWith` sentinel;
      `setFilter(String?)` and `loadAllStores({force})`
- [x] Register store datasource / repository / cubits in `service_locator.dart`
- [x] Shared `EmptyStateView`, `AppLoadingView`, `AppErrorView`, `AppSnackBar`,
      `AppConfirmDialog`
- [x] `print` → `debugPrint`; unused imports and catch bindings removed
- [x] 23 schema tests asserting the constraints the business rules lean on
- [x] `CustomerBalance` + balance datasource/repository — the §15 formula and its queries
- [x] `BarcodeScannerScreen` + `ManualBarcodeEntryDialog`; `NSCameraUsageDescription`
      added to the iOS `Info.plist`

**Done:** `flutter analyze` clean, 73/73 tests pass, debug APK builds. Verified by test
rather than by inspection: every index exists, foreign keys are enforced at runtime, a
product or customer with history cannot be deleted, interest cannot be applied twice for
one period, money round-trips through SQLite as exact centavos, and the balance queries do
not fan out.

**What Phase 0 did NOT do:** no UI beyond the scanner. `stores_screen.dart` is still a
placeholder, and the scanner has not been run on a physical device — only its build and
API compatibility are verified.

---

### Phase 1 — Stores ✅ COMPLETE

**Goal:** the Stores tab is fully usable.

- [x] `StoresScreen` — category filter chips (All/Retail/Street/Personal), store cards,
      pull-to-refresh, FAB, and the three non-success states
- [x] Live **total receivable** per store and across the list, respecting the active filter
- [x] `StoreFormScreen` — create and edit in one screen, with the optional interest setting
- [x] `InterestRate` value object owning the §19 0%–5% range as basis points
- [x] Store + `store_settings` created atomically; settings upserted on update
- [x] `StoreDetailScreen` — tab shell (Customers / Products / Transactions / Settings)
- [x] Delete behind `AppConfirmDialog`, spelling out the cascade
- [x] Routes: `/stores/new`, `/stores/:storeId`, `/stores/:storeId/edit`, `/scan`
- [x] Scanner moved onto go_router; navigation convention documented in CLAUDE.md §4.7

**Done:** `flutter analyze` clean, 93/93 tests pass, debug APK builds.

**Two bugs the tests caught, both worth knowing about:**

1. An **interest-only edit** writes no store column, so the `UPDATE` matched zero rows and
   `requireRowChanged` reported NOT_FOUND for a store that plainly existed. The datasource
   now checks existence when there is nothing to write.
2. **Ordering by `createdAt` alone is not deterministic.** Drift stores `DateTime` as unix
   seconds, so stores created in the same second tied and reshuffled between loads. Fixed
   with an `id` tiebreaker — the Phase 5 ledger merges three tables by date and needs the
   same treatment.

**Deviation from the plan:** the store card shows a real receivable total rather than the
placeholder this document originally called for. `fetchTotalForStore` was already built and
tested in Phase 0, so a real ₱0.00 was less work than a fake one — and it exercises the
balance path before Phase 4 depends on it.

**Not verified:** no Android device or emulator was available, so no screen has actually
been rendered. Layout, scrolling and the scanner's camera behaviour are unconfirmed.

### Phase 2 — Store Detail + Customers ✅ COMPLETE

**Goal:** the Customers tab, with real derived balances.

- [x] Customers feature slice (datasource → repository → cubits) mirroring stores
- [x] `CustomerListCubit` scoped to `storeId`, with debounced search over name and
      contact number, and an active/inactive filter
- [x] Customer card: initials avatar, contact, **outstanding balance**, inactive badge
- [x] `CustomerFormScreen` — name required (2–60), contact optional
- [x] `CustomerDetailScreen` — balance header showing the §15 breakdown
      (utang + interest − paid), tabs Ledger / Utang / Payments for Phases 4–5
- [x] Deactivate/reactivate; delete offered **only** for a customer with zero financial
      records, behind `AppConfirmDialog` (§29, §30)
- [x] Routes: `/stores/:storeId/customers/new`, `/customers/:customerId`,
      `/customers/:customerId/edit`

**Done:** `flutter analyze` clean, 121/121 tests pass, debug APK builds.

**The balance query finally earns its design.** The customer list calls
`fetchBalancesForStore` once per load — one batched aggregate over three financial tables,
not one query per row. This is what the Phase 0 fan-out work was for.

**Three decisions worth recording:**

1. **Delete is hidden, not disabled, for a customer with history.** A greyed-out Delete
   invites the user to hunt for a way to enable it, when the real answer is that the record
   must be kept (§30) and Deactivate is the action they want. The repository refuses it
   with `HAS_FINANCIAL_HISTORY` regardless, and the foreign keys refuse it after that —
   three layers, because deleting a ledger is unrecoverable.
2. **Search has a sequence guard, not just a debounce.** Typing "juan" starts overlapping
   reads and nothing orders their completion; a slow query for "ju" landing after "juan"
   would leave the list showing results for a search the user had moved past. Each load
   claims a ticket and only the newest may emit.
3. **Contact number: `null` means "leave alone", `''` means "clear".** The usual
   null-is-absent convention has no way to express removal when the removal value *is*
   null, so the form passes `''` when the user empties the field.

**Not verified:** no widget tests — screens are covered by build and logic tests only.

### Phase 3 — Products + barcode ✅ COMPLETE

**Goal:** the Products tab plus the scanner Phase 4 leans on.

- [x] Products feature slice, scoped to `storeId`
- [x] `ProductFormScreen` — name, price (`MoneyTextField`), unit, barcode, description
- [x] **Scan to add:** scan button beside the barcode field fills it in
- [x] **Scan to find:** scanner in the product search bar; a hit opens the product, a
      miss offers to create it with the barcode pre-filled
- [x] Duplicate barcodes refused with a message naming the product that already owns it
- [x] Text search over name and barcode
- [x] Deactivate rather than delete once a product appears in any transaction item (§28)
- [x] `MoneyTextField` in `core/shared/textfield/` — the only way a peso amount is typed

**Done:** `flutter analyze` clean, 149/149 tests pass, debug APK builds.

**Scan-to-find has three endings, not two.** The obvious design is found/not-found, but a
scanned barcode belonging to a *deactivated* product is a third case. Reporting it as "not
found" would push the seller into creating a duplicate that the unique `(storeId, barcode)`
index then rejects — a dead end they cannot reason their way out of. So a hit on an
inactive product offers to reactivate it instead.

**Three decisions worth recording:**

1. **No separate product detail route.** `design_plan` §2 listed
   `/stores/:storeId/products/:productId` as a read-only detail screen, but a product has
   no sub-content — no ledger, no history page of its own. A detail screen would show
   exactly the fields the form shows, one tap further from editing them. The form doubles
   as the detail screen, with deactivate/delete in its overflow menu. Customers kept
   theirs because it hosts the ledger tabs.
2. **Unit is free text with quick-pick chips, not a dropdown.** A closed enum would stop a
   seller describing "1/4 kilo" or "3 sticks", and being unable to name what you sell is
   worse than typing it. The chips cover the common cases so most people never type.
3. **`MoneyTextField` owns peso entry**, including the §25 non-negative rule and an input
   formatter that blocks impossible amounts as they are typed. Phase 4's transaction lines
   and Phase 5's payment field both use it, so the parsing lives in one place.

**Not verified:** the scanner still has not been exercised on a physical device — only its
build and API compatibility. Phase 3's scan paths are the first real use of it.

### Phase 4 — Transactions ✅ COMPLETE

**Goal:** record an utang. The heart of the app.

- [x] `TransactionDraft` / `TransactionDraftLine` — the cart, owning every §24/§38 rule
- [x] `TransactionBuilderScreen` — customer picker, item picker (search / scan / quick add),
      quantity steppers with fractional entry, running total, note
- [x] **Atomic write** (§10, §33): one Drift transaction inserts the transaction and all of
      its items, with referential checks and the §8 total check inside it
- [x] Store-wide and per-customer history, grouped by day with per-day subtotals
- [x] `TransactionDetailScreen` — every line at the price it sold for, read-only (§31)
- [x] Customer detail's Utang tab and a "New utang" FAB scoped to that customer

**Done:** `flutter analyze` clean, 177/177 tests pass, debug APK builds.

**Four checks live INSIDE the database transaction**, not before it. Anything checked
outside is checked against a database that can change before the write lands:

1. the customer exists and belongs to this store
2. the customer is active (§29 — no new utang)
3. every product exists and belongs to this store
4. the persisted total equals the sum of the subtotals **read back from the rows that were
   actually written** (§8) — not the payload, which is what the total was computed from in
   the first place

**A real bug the tests caught.** `createTransaction` validated §24/§38 and threw
*synchronously* despite returning a `Future`. A caller using `.catchError` would never see
the failure and the app would take an uncaught exception instead of a failure state.
Marking the method `async` makes every failure arrive as a rejected Future, the same way
`repositoryGuard`'s do.

**Three decisions worth recording:**

1. **Quick add genuinely creates a product.** `transaction_items.product_id` is a required
   foreign key, so there is no such thing as a free-text line — and §35 puts products at
   the top of the source-of-truth hierarchy deliberately, because that is what later lets a
   seller ask "how much fishball have I sold on credit?". Quick add asks only for name,
   price and unit, then creates the product and adds it.
2. **A scan miss inside the builder does not open the product form.** Mid-transaction is
   the wrong moment to ask a seller to fill in a form while someone waits at the stall, so
   it points at Quick add instead.
3. **The price snapshot is taken when the line is ADDED**, not at submit. The seller can
   edit a product's price with a half-built cart open; whatever price was shown when they
   added the line is what the customer agreed to.

**Not verified:** no widget tests — the builder's interaction flow is covered by logic
tests and a build only.

### Phase 5 — Payments + Ledger ✅ COMPLETE

**Goal:** money comes back in, and the ledger tells the whole story.

- [x] Payments slice — recorded and read, never edited or deleted (§30)
- [x] `RecordPaymentScreen` with a "Pay full balance" shortcut
- [x] **§23 overpayment guard inside the same DB transaction as the insert**
- [x] Payment history per store and per customer
- [x] **Customer Ledger tab** — transactions, payments and interest merged into one
      chronological list with a running balance (§17), built from one `UNION ALL`
- [x] Customer detail gains a "Record payment" action, shown only when something is owed

**Done:** `flutter analyze` clean, 199/199 tests pass, debug APK builds.

**The overpayment race, and why the guard is in the datasource.** The obvious
implementation reads the balance, compares, then inserts — and two taps both read ₱500,
both pass, and the balance lands at −₱500, a state §23 says is impossible. So the balance
is read and the payment inserted inside one `database.transaction { }`. Two tests fire
concurrent payments without awaiting: two × ₱500 against ₱500 → exactly one succeeds;
five × ₱200 against ₱500 → exactly two succeed, balance ₱100, never negative.

This is the one place in the app where the §15 formula is written twice — once in
`CustomerBalance`, once inside the payment transaction. That duplication is accepted
because the alternative is a race on the app's most sensitive write; the datasource says
so in a comment.

**The ledger sorts on three keys, not one.** Drift stores `DateTime` as unix seconds, so
an utang and the payment settling it at the counter carry the identical timestamp.
Ordering by time alone leaves them tied — and if the payment sorted first, the ledger
would show a momentarily *negative* balance for a customer who never owed one. Within the
same second: utang, then interest, then payments. `sourceId` breaks any remaining tie.

**A test that was wrong, not the code.** The first §36 run asserted the day-by-day running
balance while inserting all five events in the same second, so the same-second rule
reordered them. The ledger was right; the test now dates the records across the four days
§36 describes, which is what multi-day ordering is actually for. The same-second case has
its own test.

**Rendered newest-first, computed oldest-first.** A running balance only means anything
read forwards, but the seller opened the screen to see what is owed *now* — so the fold
runs oldest-first and the list is reversed, putting the current balance on the top row.

**Not verified:** no widget tests. The concurrency guard is proven at the repository level,
not through the UI.

### Phase 6 — Interest ✅ COMPLETE

**Goal:** optional monthly interest, correct and idempotent.

- [x] Interest slice — preview, apply, history
- [x] `ApplyInterestScreen` — month stepper, per-customer preview, confirmation naming
      the exact figures, result reporting
- [x] Every customer listed with a STATUS, charged or skipped, and why
- [x] §22 idempotency: a second run for the same month charges nothing
- [x] §21: base amount and rate recorded WITH each charge, so a later rate change cannot
      rewrite what was already applied
- [x] `InterestHistoryScreen` — per store and per customer, grouped by month
- [x] Store Settings tab gains "Charge N% monthly interest" and "Interest history",
      shown only when interest is actually configured

**Done:** `flutter analyze` clean, 228/228 tests pass, debug APK builds.

**One transaction per customer, not one for the batch.** §33 describes applying interest
as its own BEGIN/COMMIT, and that is per customer for a reason: wrapping fifty customers in
one transaction means the fiftieth failing undoes the other forty-nine — and the most
likely failure is §22's unique index firing because that customer was already charged. A
partial batch is the *correct* outcome there. The run reports what it charged and what it
could not, rather than throwing.

---

#### ⚠ Corrected after review: WHEN interest starts

The first implementation charged 2% of the balance **right now**, which had two problems:

1. **A real bug.** The month stepper lets you charge a past month, but the base ignored
   dates entirely — stepping back to charge August while in September computed 2% of the
   *September* balance and labelled it August.
2. **A debt taken on 20 August was charged for August**, as though it had been outstanding
   all month.

**Decided:** the base is the balance the customer carried **into** the month — every
financial event strictly before the period start. A debt taken on 20 August is therefore
first charged in **September**, roughly a month after it was created.

*Why not true per-debt accrual?* Charging each transaction from its own date requires
knowing how much of each one is still unpaid, and §11/§13 explicitly forbid allocating
payments to transactions. Per-debt interest would need FIFO allocation and a rewrite of two
sections of `transaction_logic.md`. Period-start basing gets the same practical behaviour
without touching the payment model.

**Decided:** interest **compounds** — a month's base includes prior interest charges.

That decision forced a second one. A charge is **dated to the period it covers**, not to
the wall clock (`AppDateFormat.interestEffectiveDate`, clamped so the current month is
never future-dated). Without it, running August's charge on 1 September would date it
September, and it would fall outside September's own cutoff — the compounding the store
expects would silently not happen. It also keeps §17's ledger chronology honest: an August
charge surfacing in late September reads as a double charge.

---

**Three skip reasons the seller sees**, rather than customers silently vanishing from the
list: already charged this month, owed nothing entering the month (which covers both a
settled account *and* a debt taken during the month), and interest rounds to ₱0.00.

**The base is recomputed inside each transaction, not taken from the preview.** The preview
may be minutes old by the time the seller confirms, and §21 requires the recorded base to be
the balance the charge was actually computed from.

**Manual, not automatic — a deliberate choice.** The `(customerId, periodKey)` unique index
makes an automatic trigger *safe*; it is manual anyway because §21 makes each charge
permanent and V1 has no reversal.

**⚠ A judgment call, not a spec rule: deactivated customers are SKIPPED.** §29 says an
inactive customer "cannot normally receive new transactions" and "retains their financial
history" — interest is neither exactly. This implementation skips them, on the reasoning
that deactivating someone is the seller's signal to stop the relationship growing. It is the
reversible choice: reactivate the customer to charge them. **If the business rule is the
opposite, `InterestPreviewStatus.inactive` in `interest_local_data_source.dart` is the one
place to change it.**

**Not verified:** no widget tests. The month stepper and confirmation flow are covered by
logic tests and a build only.

### Phase 7 — Dashboard ✅ COMPLETE

**Goal:** the at-a-glance screen.

- [x] **Total receivable** across all stores, with the §15 breakdown beneath it
- [x] **Store rows** — customer count, how many owe, outstanding, tap → store detail
- [x] **Top debtors** across every store, ranked by outstanding, tap → customer detail
- [x] **Recent activity** — latest utang and payments across stores, tap → the record
- [x] **Interest nudge** when a store has this month's interest still to charge
- [x] Empty state that offers to create the first store

**Done:** `flutter analyze` clean, 255/255 tests pass, debug APK builds.

Ordered by what a seller opens the app to find out: how much am I owed → is there anything
I need to do → who owes the most → what happened recently → which store is which.

**The dashboard adds no arithmetic of its own.** The headline comes from
`CustomerBalanceRepository.fetchTotalForAllStores()`, not a fourth SUM — this is the screen
where a disagreement would actually be visible, and the seller would have no way to tell
which number was lying. A test asserts the headline equals both the sum of the per-store
figures and what `CustomerBalanceRepository` reports directly.

**The interest nudge runs the real preview**, per store, rather than a lookalike "has this
month got records?" check. Two reasons: it cannot drift from what the interest screen would
actually do, and after Phase 6's correction it correctly stays *off* when the only debt was
taken this month — tapping through would otherwise show "nothing to charge". One query per
store with interest enabled, none for a seller who never turned it on. A failure there is
swallowed: a hint that cannot be computed should not take the dashboard down.

**Three queries, all fan-out-safe.** Store summaries, top debtors and recent activity each
pre-aggregate before joining, the same shape the balance query uses. A test puts two
transactions and three payments on one customer and asserts nothing multiplies.

**Interest is left out of recent activity** on purpose — it arrives as a monthly batch that
would swamp the feed, and it is already visible on the store that charged it.

**Not verified:** no widget tests.

### Phase 8 — Polish ✅ COMPLETE

**Goal:** the parts that make a finished app rather than a working one.

- [x] Search and sort on every list that should have them
- [x] Confirmation on the two permanent writes that had none
- [x] Empty / loading / error states audited across all 11 list surfaces
- [x] Currency and date formatting audit
- [x] **Stepwise migrations** — the destructive `onUpgrade` is gone
- [x] Local backup / restore as a versioned JSON file — still fully offline

**Done:** `flutter analyze` clean, 325/325 tests pass, debug APK builds.

Two dependencies added, both platform plugins and neither of them networked:
`share_plus` ^13.3.0 (the OS share sheet) and `file_picker` ^12.1.1 (the OS
file picker).

#### Sorting is a query concern

`core/constants/sort_options.dart` holds one rich enum per list, in the same
shape as `StoreCategory`. The chosen option is threaded
datasource → repository → cubit and becomes an `OrderingTerm`; no widget sorts
a list it was handed.

Two options cannot be SQL, and both are documented at all three of their sites:
a customer's balance and a store's receivable are the §15 aggregate over three
financial tables, not a column. Those are ordered in the CUBIT — the layer that
holds the rows and the totals — over a deterministic base order the datasource
supplies.

Every option keeps two rules: deactivated rows sort last whatever the user
picked (§28, §29), and every ordering ends with an id tiebreaker. The
tiebreaker follows the DIRECTION of the sort — an oldest-first list breaking
ties by descending id hands back same-second rows reversed.

#### Three things worth recording

1. **The Stores cubit had an in-flight guard, not a sequence guard.** It
   skipped a load while another ran, with a `force` flag for filter changes.
   That is fine until a search field exists: most keystrokes get dropped and
   the survivors can still finish out of order. Replaced with the ticket
   pattern the other lists use, and `force` is gone from all four call sites.
2. **Sorting by amount breaks grouping.** Transaction history groups under day
   headings and interest history under month headings; ordered by size, those
   headings repeat and jump backwards. Both lists render FLAT when sorted by
   amount, and interest rows then carry their own period label because the
   heading that used to say so is gone. Day headings also follow the sort
   direction now.
3. **`AppSearchField` was promoted to `core/shared/`** once a third list needed
   one. Customers and Products were refactored onto it, which let both of their
   search bars drop their controller lifecycle and become stateless.

#### The Ledger deliberately has neither

Every other list gained search and sort. The §17 ledger did not, and the reason
is written into `ledger_tab.dart` rather than left as an unexplained omission:
a running balance is a fold over the rows before it. Filter the list and every
balance below a hidden row is wrong by that row's amount. Sort it by size and
"balance after this event" stops meaning anything at all.

A seller looking for one utang has the Utang tab; one payment, the Payments
tab. Both are searchable, because neither carries a running total.

#### Confirmation on the two permanent writes

Recording a payment and committing an utang both went straight through. Both
are permanent under §30/§31 and V1 has no reversal, so a payment against the
wrong customer cannot be corrected — only offset by a second record that makes
the ledger harder to read.

Both now confirm, naming the figures a mis-tap actually gets wrong: the amount
and the payer, or the customer and the total. The cart is already on screen, so
the utang dialog does not re-list it.

#### The formatting audit found nothing, which is the point

Zero `toStringAsFixed` outside `core/money`, zero raw `DateFormat` outside
`AppDateFormat`, zero `₱` literals outside `MoneyTextField` and comments. The
`Money`-everywhere rule held on its own for seven phases.

`StoreEntity.createdAt` was already a real `DateTime` — the note carried
forward from Phase 1 was stale.

---

#### ⚠ Migrations: the destructive upgrade is gone

`onUpgrade` dropped every table and recreated the schema. Acceptable exactly
once — v5 converted the money columns from REAL pesos to INTEGER centavos while
no real data existed. Shipping it would mean the first post-release schema
change silently erasing every ledger on every device.

`core/config/migrations.dart` replaces it. **v5 is the released baseline**, each
later version registers one step keyed by the version it produces, and anything
unaccounted for THROWS rather than guesses: a missing step, a downgrade, a
pre-release schema. A database that refuses to open keeps its rows.

The tempting fallback — "no step registered, just `createAll`" — is the
destructive behaviour returning through the side door at the exact moment a
developer forgot something, and on a user's device rather than in development.
Hence the throw.

**The proof is a test, not an assertion:** a real v5 file on disk holding a
ledger, opened by a subclass whose `schemaVersion` is 6 with no step registered.
It throws, and the ledger is still there and readable by the correct build
afterwards.

**drift's own schema tooling could not be adopted.** `drift_dev` is held at
2.34.0 by the Flutter SDK's pinned analyzer, and 2.34.0's `schema dump` is
broken against drift 2.34.3 — it resolves the drift3-preview
`GeneratedDatabase`, which has no `allSchemaEntities`. The exact commands to run
once an SDK bump unblocks drift_dev 2.34.5+ are in the header of
`migrations.dart`. Adopt them then; they verify migrations between real
historical schemas, which the hand-written tests cannot.

---

#### Backup and restore

A JSON file, not a copy of the `.db`. It is self-describing, readable by a
human deciding whether a file is worth restoring, and survives a schema change
in a way an opaque binary does not.

```json
{ "app": "utanglista", "formatVersion": 1, "schemaVersion": 5,
  "exportedAt": "...", "tables": { "stores_table": [ ... ], ... } }
```

**Two version numbers, moving independently.** `formatVersion` is the
envelope's own shape; `schemaVersion` is the schema the rows came from. Adding
a column bumps one and not the other.

**Money is exported as raw centavos.** Never `52.5`, never `"₱52.50"` — §26
forbids the float, and a formatted string would have to be parsed back through
a locale-dependent currency format. Dates go out as the unix seconds drift
stores. A backup carries what the DATABASE had, so a restore is a copy rather
than a re-interpretation.

**The datasource is generic SQL, deliberately.** `SELECT *` per table, written
back from whatever column names came out. The obvious alternative — a
serialiser per table — rots the moment someone adds a column: it is simply
missing from every backup afterwards, nothing fails, and the bug surfaces
months later on a restore as a column of nulls. A guard checks the write-order
list against the real schema so a new TABLE cannot be forgotten either.

**The whole restore is one `database.transaction { }`.** Deletes in reverse
dependency order, inserts forward, foreign keys live throughout — SQLite
ignores `PRAGMA foreign_keys` changes inside a transaction, so the ordering is
load-bearing rather than tidy. A file that turns out to be damaged halfway
through cannot leave a half-restored ledger, which would be worse than either
outcome: numbers that look plausible and are wrong.

**Ids are preserved.** Every foreign key in the file refers to them, and
remapping eight tables' worth of references is the one operation here with a
real chance of silently attaching a payment to the wrong customer.

**Restore is two steps with the confirmation between them.** Read and describe,
then apply. A single call would have to confirm before knowing the file is any
good — asking someone to approve replacing their ledger with a file that turns
out to be a photo — or confirm after writing, which is not a confirmation. The
dialog names when the backup was made and what is in it: "3 stores, 41
customers, 260 utang records".

**Four decisions worth recording:**

1. **Replace, never merge.** Two databases of the same shape both using
   autoincrement ids cannot be merged without rewriting every foreign key, and
   a merge that guessed wrong would corrupt a ledger rather than replace one.
   The screen says so before the button is pressed, not only in the dialog.
2. **An empty backup is refused.** Restoring one would delete everything and
   put nothing back. If that is genuinely wanted, deleting the stores says so
   out loud.
3. **A schema mismatch is refused in both directions**, with a message saying
   which way it runs. Migrating an older backup column by column is real work
   whose bugs cost people their ledgers, so it is not being guessed at; when
   the schema first moves past v5, `_requireCompatibleSchema` is where that
   path goes.
4. **A restore raises `DataResetNotifier`.** The Dashboard and Stores tabs live
   in the shell's `IndexedStack` and are not rebuilt by navigating to Settings,
   so without a signal they would keep showing a total receivable for
   transactions that no longer exist. Keying the navigation shell would be
   fewer lines but depends on how go_router treats a recreated element subtree,
   which this project has no device to verify; `goBranch(initialLocation: true)`
   only resets a branch's navigation stack and would not rebuild a branch
   already at its root. An explicit signal is more code and is obvious.

**Still fully offline.** Export writes to the app's cache directory and hands
the path to the OS share sheet; import reads what the OS file picker returns.
No socket is opened, and where the file goes is a choice the user makes in a
dialog this app cannot see the result of.

**Not verified:** no widget tests, and neither the share sheet nor the file
picker has been exercised on a physical device — only their build and API
compatibility. The 24 backup tests cover the repository and below, which is
where the data-loss risk lives.

---

## 6. Testing strategy

Business rules are worth testing even in a solo project, because the accounting invariants
are exactly the kind of thing that breaks silently.

| Level | What |
|---|---|
| Unit | `Money` arithmetic; `BalanceCalculator`; interest rounding and rate clamping; payload → companion mapping |
| Repository (in-memory Drift) | Transaction atomicity and rollback; overpayment rejection; interest idempotency for the same `periodKey`; restrict-on-delete for products with history |
| Golden scenario | `transaction_logic.md` §36, day by day, asserting ₱540.60 at the end |
| Widget | The three list states; form validation messages |

`AppDatabase` already accepts an injected `QueryExecutor`, so
`AppDatabase(NativeDatabase.memory())` works for tests with no extra plumbing.

---

## 7. Decisions log

| # | Question | Decision | Where |
|---|---|---|---|
| 1 | Money representation | **Integer centavos**, wrapped in a `Money` value object | §3.1 |
| 2 | Existing device data | **None** — Phase 0 uses a destructive migration | §3.11 |
| 3 | First build target | **Phase 0**, schema + foundation | §5 |

### Still open — not blocking Phase 0

4. **Interest trigger:** manual-only for V1 as planned in Phase 6, or automatic on app open
   once the period guard is in place? The unique `(customerId, periodKey)` index makes both
   safe; manual is easier to reason about first.
5. **Transaction list scope:** the plan builds both store-wide and per-customer history.
   Store-wide is more work but is what the "Transaction History" tab in your workflow
   implies. Confirm before Phase 4.
6. **One customer across two stores:** if Juan buys from two of your stores, is he one
   customer or two? The current schema says two — customers are store-scoped. Simpler, and
   probably right, but worth confirming before Phase 2 since it is painful to change after.
