import 'package:drift/drift.dart';

// ============================================================
// STORES TABLE
// ============================================================
class StoresTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 6, max: 32)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

// ============================================================
// CUSTOMERS TABLE
// ============================================================
class CustomersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 6, max: 32)();
  TextColumn get contactNumber => text().withLength(max: 12)();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

// ============================================================
// PRODUCTS TABLE
// ============================================================
class ProductsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 6, max: 32)();
  TextColumn get description => text().nullable()();
  RealColumn get price => real().clientDefault(() => 0.0)();
  TextColumn get unit => text()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

// ============================================================
// TRANSACTIONS TABLE
// ============================================================
/*
  transactions

  id:           1001
  customer_id:  5
  total_amount: 500.00
  created_at:   2026-08-23
*/
class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get customerId =>
      integer().references(CustomersTable, #id, onDelete: KeyAction.cascade)();
  RealColumn get totalAmount => real().clientDefault(() => 0.0)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

// ============================================================
// TRANSACTIONS ITEMS TABLE
// ============================================================
/*
  transaction_items

  transaction_id: 1001

  Rice
  quantity:       5
  unit_price:     ₱100
  subtotal:       ₱500
*/
class TransactionsItemTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(
    TransactionsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get productId =>
      integer().references(ProductsTable, #id, onDelete: KeyAction.cascade)();
  RealColumn get quantity => real().clientDefault(() => 0.0)();
  RealColumn get unitPrice => real().clientDefault(() => 0.0)();
  RealColumn get subTotal => real().clientDefault(() => 0.0)();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

// ============================================================
// PAYMENTS TABLE
// ============================================================
/*
  payments

  customer_id: 5
  amount:      ₱100
  created_at:  2026-08-23
  note:        "Partial payment"
*/
class PaymentsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get customerId =>
      integer().references(CustomersTable, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real().clientDefault(() => 0.0)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

// ============================================================
// STORE SETTINGS TABLE
// ============================================================
/*
  store_settings

  store_id:                  1
  monthly_interest_enabled:  true
  monthly_interest_rate:     2.00
*/
class StoreSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  BoolColumn get monthlyInterestEnabled =>
      boolean().clientDefault(() => false)();
  RealColumn get monthlyInterestRate => real().clientDefault(() => 0.0)();
}

// ============================================================
// INTEREST RECORDS TABLE
// ============================================================
/*
  Customer balance: ₱1,000

  Monthly interest: 2%

  base_amount:      ₱1,000
  rate:             2%
  interest_amount:  ₱20
*/
class InterestRecordsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId =>
      integer().references(StoresTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get customerId =>
      integer().references(CustomersTable, #id, onDelete: KeyAction.cascade)();

  RealColumn get rate => real().clientDefault(() => 0.0)();
  RealColumn get baseAmount => real().clientDefault(() => 0.0)();
  RealColumn get interestAmount => real().clientDefault(() => 0.0)();
  DateTimeColumn get createdAt => dateTime().nullable()();
}
