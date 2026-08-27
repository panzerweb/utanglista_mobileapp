# CLAUDE.md

Guidance for Claude Code when working in this repository.

---

## 1. What this project is

**UtangLista** — a fully offline Flutter mobile app for small sellers to track customer
credit ("utang"). One local SQLite database is the only source of truth. No auth, no
network, no sync.

The app answers four questions about every debt:
**what** product, **who** owes it, **when** it happened, **how much** — plus optional
monthly interest.

**Read [`docs/transaction_logic.md`](docs/transaction_logic.md) before touching anything
financial.** It is a business requirements document, not a suggestion. The accounting
invariants in §38 are non-negotiable.

**Read [`docs/design_plan.md`](docs/design_plan.md)** for the phased build order, screen
inventory, and open decisions.

### Store categories are labels, not modes

`StoreCategory` has `personal`, `retail`, `street`. A "store" means *any medium a seller
has*:

- **retail** — a fixed stall, walk-in buyers (sari-sari store).
- **street** — street vendors; non-barcoded goods (street food), customers still utang.
- **personal** — the general bucket, including people who sell online.

`personal` covering online sellers is a **categorisation label only**. It never implies
network features. The app stays 100% offline in every category.

### The doc says one store; the app has many

`transaction_logic.md` §3 says "one local store profile per instance". That line is
**stale**. The product requirement is **multi-store**: the Stores screen lists every store
the user created, and each store owns its own customers, products, transactions, payments
and settings. Every table already carries `storeId` — keep it that way. All other rules in
that document stand.

---

## 2. Commands

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter run
```

`app_database.g.dart` is generated and **committed**. Never hand-edit it. Any change to
`lib/core/config/tables/app_tables.dart` requires re-running build_runner and bumping
`schemaVersion` in `app_database.dart`.

---

## 3. Architecture

Feature-first Clean Architecture. Each feature is a self-contained vertical slice:

```text
lib/
├── core/
│   ├── config/          AppDatabase + tables/app_tables.dart (all Drift tables)
│   ├── constants/       enum.dart — shared enums
│   ├── error/           AppFailure
│   ├── extensions/      AppButtonSize and friends
│   ├── helper/          repositoryGuard, requireRowChanged
│   ├── routes/          go_router config (StatefulShellRoute)
│   ├── services/        service_locator.dart (get_it)
│   ├── shared/          reusable widgets: app_view, main_app_bar, buttons/, textfield/, dropdown/
│   └── styles/          AppPalette, AppTextStyles
└── features/<feature>/
    ├── data/
    │   ├── datasource/   <feature>_local_data_source.dart   ← raw Drift only
    │   └── model/        <feature>_model.dart, <feature>_payload_model.dart
    ├── domain/
    │   ├── entities/     <feature>_entity.dart
    │   └── repositories/ <feature>_repository.dart          ← abstract + implementation
    └── presentation/
        ├── bloc/         <feature>_cubit.dart, <feature>_state.dart
        ├── screens/      full-page widgets
        └── widgets/      feature-local widgets
```

### Layer rules

| Layer | May depend on | Must never |
|---|---|---|
| **Datasource** | Drift, `AppDatabase`, models | Contain business rules; know about entities |
| **Repository** | Datasource, models, entities, guards | Touch Drift query builders directly |
| **Cubit** | Repository, entities, payload models | Import `AppDatabase` or Drift |
| **Screen/Widget** | Cubit, entities, core/shared, core/styles | Import repositories, datasources, or Drift |

> Business rules live in the domain/application layer, **never inside UI widgets**
> (`transaction_logic.md` §37.13).

**Note on an existing quirk:** repository *implementations* currently sit in
`domain/repositories/` rather than `data/repositories/`. That is this codebase's
convention — follow it for consistency rather than mixing two styles. If it is ever moved,
move all features at once.

---

## 4. Established patterns — follow these exactly

### 4.1 Model / Payload / Entity triad

- **`XModel`** — data layer. `factory XModel.fromTable(XTableData row)` and
  `XEntity toEntity()`. Never leaves the repository.
- **`XPayloadModel`** — create input. Plain fields + typed enums, with a
  `String? get categoryString => category?.value` style getter for enum → column.
- **`UpdateXPayloadModel`** — update input. Every field nullable, plus
  `XTableCompanion toCompanion()` that maps `null → const Value.absent()` so partial
  updates never blank a column.
- **`XEntity`** — the only shape the presentation layer sees. Immutable, `final` fields.

### 4.2 Datasource

Abstract class + `XLocalDataSourceImplementation`. Constructor takes `AppDatabase`.
Table handles hoisted as `late final xTable = database.xTable;` under a
`** CONSTANTS FOR TABLE **` banner. Methods return row counts (`int`) for mutations and
`XModel` / `List<XModel>` for reads. Wrap in `try / catch (e) { rethrow; }` — error
translation is the repository's job, not the datasource's.

### 4.3 Repository — always guard

Never write a bare try/catch in a repository. Use the two helpers in
`lib/core/helper/repository_guard.dart`:

```dart
@override
Future<List<StoreEntity>> fetchStores(String? category) {
  return repositoryGuard(() async {
    final models = await localDataSource.fetchStores(category);
    return models.map((m) => m.toEntity()).toList();
  }, failureMessage: "Could not fetch stores.");
}

@override
Future<int> updateStore(UpdateStorePayloadModel payload) {
  return requireRowChanged(
    () => localDataSource.updateStore(payload),
    failureMessage: "Could not update this store.",
    notFoundMessage: "This store no longer exists.",
  );
}
```

`failureMessage` is shown to the user verbatim — write it in plain user language, and make
it describe the operation that actually failed.

Error codes a cubit may branch on: `DRIFT_ERROR`, `UNEXPECTED_ERROR`, `NOT_FOUND`, plus
domain codes thrown deliberately (`INVALID_FORMAT`, `OVERPAYMENT`, …). An `AppFailure`
thrown from deeper is rethrown untouched, so a specific code is never downgraded.

### 4.4 Cubits — two shapes, chosen by job

**List / read cubits → single state class with a status enum.** Holds filters and data
together so a filter change does not wipe the list shape.

```dart
enum StoreListStateStatus { initial, loading, success, failure }

class StoreListState {
  final List<StoreEntity> stores;
  final StoreListStateStatus status;
  final String? category;
  final AppFailure? error;
  // const constructor with defaults + copyWith
}
```

**Form / mutation cubits → `sealed class` hierarchy.** One state per outcome, so
`BlocListener` can pattern-match and fire snackbars/navigation exactly once.

```dart
sealed class StoreFormState {}
class StoreFormInitial    extends StoreFormState {}
class StoreFormSubmitting extends StoreFormState {}
class StoreFormSuccess    extends StoreFormState { final int storeId; ... }
class StoreFormFailure    extends StoreFormState { final AppFailure error; ... }
```

Every cubit method follows: `emit(loading)` → `try` → `emit(success)` →
`on AppFailure catch` → `catch (e)` fallback with code `UNKNOWN_ERROR`.

Validation failures must `emit(...)` **and `return`** — never fall through into the try
block.

### 4.5 copyWith and nullable fields

`field ?? this.field` **cannot clear a value**. Where a state field must be resettable
(`error`, the `category` filter), use an explicit sentinel or a `clearX` flag:

```dart
StoreListState copyWith({
  Object? error = _sentinel,   // or: bool clearError = false
  ...
});
```

This matters: `state.copyWith(error: null, ...)` in the current `loadAllStores` is a no-op,
so a stale error survives an otherwise successful reload.

### 4.6 Dependency injection

`get_it` via `lib/core/services/service_locator.dart`. Register per feature:

```dart
locator.registerLazySingleton<StoreLocalDataSource>(
  () => StoreLocalDataSourceImplementation(locator<AppDatabase>()),
);
locator.registerLazySingleton<StoreRepository>(
  () => StoreRepositoryImplementation(locator<StoreLocalDataSource>()),
);
// Cubits are registerFactory — a fresh instance per screen.
locator.registerFactory(() => StoreListCubit(locator<StoreRepository>()));
```

Screens obtain cubits with `BlocProvider(create: (_) => locator<XCubit>())`.
`AppDatabase` is the only long-lived singleton.

### 4.7 Navigation

**All navigation goes through `go_router`.** Use `context.push` / `context.go` /
`context.pop`. Never call `Navigator.push` directly — a second navigation system means two
places to look when a back button misbehaves, and routes that cannot be deep-linked.

Return values work the same way `Navigator` does:

```dart
final barcode = await context.push<String>(AppRoutes.scan);
// ...and inside the pushed screen:
context.pop(barcode);
```

**The one exception is dialogs and bottom sheets.** `showDialog` and
`showModalBottomSheet` are Flutter's APIs for transient overlays, not routes go_router
owns. `AppConfirmDialog` and `ManualBarcodeEntryDialog` correctly use them.

Paths live as constants on `AppRoutes` in `core/routes/routes.dart` — never a string
literal at a call site, where a typo is a runtime failure nobody sees until a button is
tapped.

Structure: a `StatefulShellRoute.indexedStack` with three branches —
**Dashboard / Stores / Settings**. `AppView` renders the bottom `NavigationBar`.

**The bottom bar stays at three destinations.** New screens are *pushed on top of* a
branch, never added as a fourth tab. Where a route goes:

| Placement | Effect | Use for |
|---|---|---|
| Nested in a shell branch | Bottom bar stays visible | Browsing screens — store detail |
| `parentNavigatorKey: _routerKey` | Full screen, covers the bar | Focused tasks — forms, the scanner |

Declare literal sub-paths *before* parameterised ones (`'new'` before `':storeId'`), or
`/stores/new` parses as a store whose id is the word "new".

### 4.8 UI conventions

- Colors only from `AppPalette`. Text only from `AppTextStyles` + `.copyWith(color:)`.
- Reuse `core/shared/`: `AppFilledButton`, `AppElevatedButton`, `AppIconButton`,
  `GlobalTextField`, `GlobalGenericDropdown<T>`, `MainAppBar`.
  Promote a widget to `core/shared/` when two or more features use it; otherwise it lives
  in the feature's `presentation/widgets/`.
- **Money is always a `Money`, never a raw number.** Every monetary column is an `int` of
  centavos; `Money` owns the arithmetic, parsing and `₱1,250.75` formatting. No widget ever
  does `toStringAsFixed`, and no layer does math on the bare `int`.
- Section banners in code follow the existing style: `// ====…` headers and `/* … */`
  intent blocks. Comments explain **why**, not what.

---

## 5. Financial invariants — the short list

Full detail in `docs/transaction_logic.md`. The rules that break the app if ignored:

1. **Balance is derived, never stored as truth:**
   `balance = Σ transactions + Σ interest − Σ payments`.
2. **Payments never modify transactions.** No `remaining_amount` on a transaction.
3. **`transaction_items.unitPrice` is a price snapshot.** Changing a product must never
   change history.
4. **A transaction and its items are written in one Drift `transaction { }` block.** A
   transaction with zero items must be impossible.
5. **Interest is a recorded event**, not a display-time recalculation, and must not be
   applied twice for the same month.
6. Interest rate is clamped to **0%–5%**.
7. **V1 rejects overpayment.** A payment may not exceed the outstanding balance.
8. Quantity > 0, transaction total > 0, no negative money anywhere.
9. **Deactivate, don't delete** customers and products that have history. Financial
   records are retained.

Every one of these belongs in the repository/domain layer with a single authoritative
implementation. Never derive a balance in two places.

---

## 6. Build phases

Detail and checklists live in `docs/design_plan.md`. Order matters — each phase depends on
the one before it.

| Phase | Focus | Exit criteria |
|---|---|---|
| **0** | **Schema & foundation fixes** — money representation, index-name collisions, FK actions on history tables, length constraints, `createdAt` defaults, interest period key, DI wiring, `copyWith` sentinels, cubit fall-through bug | `flutter analyze` clean; DB creates; store CRUD works end-to-end |
| **1** | **Stores** — list, filter by category, create/edit/delete forms, empty & error states. Completes the slice already begun | Stores tab fully usable; store detail shell renders its tabs |
| **2** | **Store Detail + Customers** — tabbed detail screen (Customers / Products / Transactions / Settings); customer CRUD, deactivation, per-customer balance | Customer list shows live derived balances |
| **3** | **Products + barcode** — product CRUD, `mobile_scanner` for add-by-scan and search-by-scan, deactivation | Scanning a barcode finds or pre-fills a product |
| **4** | **Transactions** — cart-style builder, scan-to-add, atomic write of transaction + items, transaction history, item detail | Ledger math matches `transaction_logic.md` §36 worked example |
| **5** | **Payments + Ledger** — record payment with overpayment guard, chronological customer ledger with running balance | §36 scenario reproduces exactly |
| **6** | **Interest** — store settings (enable/disable, 0–5% rate), period-guarded application, interest history | Re-running application in the same month creates no duplicate record |
| **7** | **Dashboard** — total receivables, top debtors, recent activity, per-store rollups | Dashboard reads only from the shared derived-balance path |
| **8** | **Polish** — search, sorting, confirmation dialogs, empty/loading/error states everywhere, backup/export | — |

---

## 7. Status

**Phases 0-7 are complete.** `flutter analyze` is clean and 255 tests pass. The
`transaction_logic.md` §36 worked example runs end to end — utang, payment, interest, and
the ledger's running-balance column — alongside pure-arithmetic and raw-SQL versions.

- **Phase 0** — schema corrections, `Money`, `CustomerBalance`, shared views, the scanner.
- **Phase 1** — Stores tab, store form with optional interest, store detail tab shell.
- **Phase 2** — Customers tab, customer detail with the §15 breakdown, deactivate rules.
- **Phase 3** — Products tab, scan-to-find and scan-to-add, `MoneyTextField`.
- **Phase 4** — Transaction builder, atomic write, history and read-only detail.
- **Phase 5** — Payments with the §23 guard, and the §17 ledger.
- **Phase 6** — Interest preview, idempotent application, and history.
- **Phase 7** — Dashboard: receivables, top debtors, recent activity, interest nudge.

Rules established along the way that later phases must not relitigate:

- **`CustomerBalance` is the only balance formula** — with TWO deliberate exceptions, both
  documented at their sites: the payment guard and the interest application recompute it
  inside their own transactions, because a balance read outside the write's transaction
  goes stale and §23/§21 would then be unenforceable. Nothing else may copy this.
- **`Money` for every peso amount, `MoneyTextField` for every peso input.**
- **`InterestRate`** owns the §19 0%-5% range as basis points. Validate via `isValid`.
- **Multi-record financial writes go in one `database.transaction { }`**, with the
  referential, balance and total checks INSIDE it (§10, §23, §33). A BATCH across many
  customers is many transactions, not one — a partial batch is correct when the failure is
  §22's guard firing.
- **Order by `(createdAt, id)`, never `createdAt` alone**; the ledger additionally orders
  by kind (utang → interest → payment) so a same-second pair cannot show a negative
  running balance.
- **A repository method that validates before awaiting must be `async`**, or the failure
  throws synchronously and never reaches the caller's `.catchError`.
- **Deactivate, never delete, anything with financial history** (§28, §29, §30). A
  deactivated customer can still *pay* — §29 stops new utang, not repayment — and is
  currently skipped by interest (see design_plan Phase 6; a documented judgment call).
- **An update that changes no column of its own table must not report NOT_FOUND.**
- **Any list with a search field needs a sequence guard**, not just a debounce.
- **A scanned barcode has three outcomes, not two:** found-active, found-inactive,
  not-found.
- **Snapshot what a record was computed from.** `transaction_items.unitPrice` (§7) and
  `interest_records.rateBasisPoints` / `baseAmount` (§21) are both snapshots — repricing a
  product or changing a store's rate must never rewrite a committed record.
- **Interest is charged on the balance carried INTO the month**, not the balance now: every
  event strictly before the period start. A debt taken on 20 August is first charged in
  September. Charging a past month must use that month's numbers.
- **An interest charge is dated to the period it covers**, not the wall clock
  (`AppDateFormat.interestEffectiveDate`). Both compounding and the §17 ledger's chronology
  depend on it — a charge dated by wall clock falls outside the next month's cutoff and the
  compounding silently stops.
- **Financial records are never edited or deleted** (§14, §30, §31). The absent actions are
  the rule; the detail screens say so rather than just omitting a button.

**Next: Phase 8 (Polish).** Search and sort on remaining lists, a formatting audit, and
local backup/restore — still fully offline. Nothing structural is left.

**The app is functionally complete for V1.** Every section of `transaction_logic.md` that
describes behaviour is implemented and tested.

### Carried into later phases

- **`StoreEntity.createdAt` is a preformatted `String`.** Fine while it is display-only,
  but the ledger and dashboard sort chronologically. When transactions arrive in Phase 4,
  entities that participate in the ledger must carry a real `DateTime` and format at the
  widget layer.
- **State classes have no value equality**, so every `emit` rebuilds even when nothing
  changed. Harmless now; worth revisiting if a list gets long enough to feel it.
- **The migration is destructive through v5.** From the first release onward, `onUpgrade`
  needs a real stepwise branch — see the comment in `app_database.dart`.

---

## 8. Working agreement

- **Ask before writing or modifying code.** Present the plan, get a yes, then implement.
- Prefer extending the existing store slice over inventing a parallel structure.
- When a business rule and existing code disagree, `transaction_logic.md` wins — raise it
  rather than quietly coding around it.
- Do not add packages without asking. Current stack: `drift`, `drift_flutter`,
  `flutter_bloc`, `get_it`, `go_router`, `google_fonts`, `intl`, `mobile_scanner`,
  `path_provider`.
- No network calls, no auth, no cloud. Ever.
