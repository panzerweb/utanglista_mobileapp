import 'package:drift/drift.dart';

/*
  ------------------------------------------------------------------
  MONEY IS STORED AS INTEGER CENTAVOS.
  ------------------------------------------------------------------

  transaction_logic.md §26 forbids floating point for exact financial
  values. Every monetary column below is therefore an IntColumn holding
  centavos, never a RealColumn holding pesos:

    ₱1,250.75  ->  125075

  Addition, subtraction and equality are then exact, which matters most
  for the one comparison the whole app leans on: "balance == 0" meaning
  fully paid. With doubles that check is unreliable.

  Read and write these columns through the Money value object in
  core/money/money.dart. No layer should do arithmetic on the bare int.

  Interest rates are stored the same way, as BASIS POINTS:

    2%  ->  200      5% (the cap) ->  500

  so the 0%-5% range check in §19 is an exact integer comparison.

  QUANTITY is the deliberate exception: it stays a RealColumn because
  street vendors sell by weight (1.5 kg). Quantity is not money, and the
  single multiplication that turns it into money rounds exactly once,
  inside Money.

  ------------------------------------------------------------------
  INDEX NAMES ARE GLOBAL IN SQLITE.
  ------------------------------------------------------------------

  Two tables cannot share an index name. When they do, the generator
  silently emits only the first one and the other table ends up with no
  index at all. Every index below is therefore prefixed idx_ and named
  after its own table.
*/

// ============================================================
// STORES TABLE
// ============================================================
@TableIndex(name: 'idx_store_name_category', columns: {#name, #category})
class StoresTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 60)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();

  // Non-null: list ordering and the dashboard's "recent activity" both
  // sort on this, and a null sorts unpredictably.
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

// ============================================================
// CUSTOMERS TABLE
// ============================================================
@TableIndex(name: 'idx_customer_store_name', columns: {#storeId, #name})
class CustomersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 2, max: 60)();

  // Optional per §4. 20 chars fits "+63 917 123 4567" with separators.
  TextColumn get contactNumber =>
      text().withLength(max: 20).nullable()();

  // §29: deactivate rather than delete a customer who has history.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

// ============================================================
// PRODUCTS TABLE
// ============================================================
/*
  Barcode is nullable on purpose: street-vendor stores sell unbarcoded
  goods. When a barcode IS present it must be unique within the store,
  or scan-to-find becomes ambiguous. SQLite allows many NULLs in a
  unique index, so the two rules coexist.
*/
@TableIndex(name: 'idx_product_store_name', columns: {#storeId, #name})
@TableIndex(
  name: 'idx_product_store_barcode',
  columns: {#storeId, #barcode},
  unique: true,
)
class ProductsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text().withLength(min: 2, max: 60)();
  TextColumn get description => text().nullable()();

  // Centavos. Required — a product without a stated price is a bug, not
  // a free item, so there is deliberately no default.
  IntColumn get price => integer()();

  TextColumn get unit => text()();

  // §28: deactivate rather than delete a product with history.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

// ============================================================
// TRANSACTIONS TABLE
// ============================================================
/*
  transactions

  id:           1001
  customer_id:  5
  total_amount: 50000      // ₱500.00 in centavos
  created_at:   2026-08-23

  totalAmount is a snapshot of SUM(items.subTotal) (§8). The repository
  asserts the two agree inside the same DB transaction that writes them.

  customerId does NOT cascade: deleting a customer must never erase the
  debt they owed (§29, §30).
*/
@TableIndex(name: 'idx_txn_customer_created', columns: {#customerId, #createdAt})
@TableIndex(name: 'idx_txn_store_created', columns: {#storeId, #createdAt})
class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get customerId =>
      integer().references(CustomersTable, #id, onDelete: KeyAction.noAction)();

  // Centavos.
  IntColumn get totalAmount => integer()();

  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

// ============================================================
// TRANSACTIONS ITEMS TABLE
// ============================================================
/*
  transaction_items

  transaction_id: 1001

  Rice
  quantity:       5
  unit_price:     10000     // ₱100.00 in centavos
  subtotal:       50000     // ₱500.00 in centavos

  unitPrice is a HISTORICAL SNAPSHOT (§7). Repricing the product later
  must never change what this line cost. That is why the price lives
  here and is not read back through productId.

  productId does NOT cascade, for the same reason: deleting a product
  cannot be allowed to erase the line items that reference it.
*/
@TableIndex(name: 'idx_txn_item_transaction', columns: {#transactionId})
@TableIndex(name: 'idx_txn_item_product', columns: {#productId})
class TransactionsItemTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(
    TransactionsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get productId =>
      integer().references(ProductsTable, #id, onDelete: KeyAction.noAction)();

  // Not money — sold by weight as well as by piece. See the header note.
  RealColumn get quantity => real()();

  // Centavos.
  IntColumn get unitPrice => integer()();
  IntColumn get subTotal => integer()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

// ============================================================
// PAYMENTS TABLE
// ============================================================
/*
  payments

  customer_id: 5
  amount:      10000        // ₱100.00 in centavos
  created_at:  2026-08-23
  note:        "Partial payment"

  A payment belongs to the CUSTOMER's account, never to a transaction or
  a product (§11). There is deliberately no transaction_id here.
*/
@TableIndex(
  name: 'idx_payment_customer_created',
  columns: {#customerId, #createdAt},
)
@TableIndex(name: 'idx_payment_store_created', columns: {#storeId, #createdAt})
class PaymentsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get customerId =>
      integer().references(CustomersTable, #id, onDelete: KeyAction.noAction)();

  // Centavos.
  IntColumn get amount => integer()();

  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

// ============================================================
// STORE SETTINGS TABLE
// ============================================================
/*
  store_settings

  store_id:                          1
  monthly_interest_enabled:          true
  monthly_interest_rate_basis_points: 200    // 2%

  Exactly one row per store. The unique index enforces it; the store
  repository creates this row inside the same DB transaction as the
  store itself, so a store can never exist without settings.
*/
@TableIndex(name: 'idx_store_settings_store', columns: {#storeId}, unique: true)
class StoreSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();

  // §19: monthly interest is OPTIONAL. Off unless the owner turns it on.
  BoolColumn get monthlyInterestEnabled =>
      boolean().withDefault(const Constant(false))();

  // Basis points, 0-500 == 0%-5% (§19). Enforced in the domain layer as
  // well, so an out-of-range rate can never reach the database.
  IntColumn get monthlyInterestRateBasisPoints =>
      integer().withDefault(const Constant(0))();
}

// ============================================================
// INTEREST RECORDS TABLE
// ============================================================
/*
  Customer balance: ₱1,000

  Monthly interest: 2%

  base_amount:       100000     // ₱1,000.00 in centavos
  rate_basis_points: 200        // 2%
  interest_amount:   2000       // ₱20.00 in centavos
  period_key:        '2026-08'

  §22 requires that interest for a period is never applied twice. The
  unique (customer_id, period_key) index makes that a database
  guarantee rather than a check the caller has to remember: a second
  attempt for the same month fails on the constraint instead of
  quietly compounding.
*/
@TableIndex(
  name: 'idx_interest_customer_period',
  columns: {#customerId, #periodKey},
  unique: true,
)
@TableIndex(
  name: 'idx_interest_customer_created',
  columns: {#customerId, #createdAt},
)
@TableIndex(name: 'idx_interest_store_created', columns: {#storeId, #createdAt})
class InterestRecordsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get customerId =>
      integer().references(CustomersTable, #id, onDelete: KeyAction.noAction)();

  // Basis points, snapshotted at the time interest was applied — the
  // store's rate may change later, this record must not.
  IntColumn get rateBasisPoints => integer()();

  // Centavos.
  IntColumn get baseAmount => integer()();
  IntColumn get interestAmount => integer()();

  // 'YYYY-MM', e.g. '2026-08'. The period this charge covers.
  TextColumn get periodKey => text().withLength(min: 7, max: 7)();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}
