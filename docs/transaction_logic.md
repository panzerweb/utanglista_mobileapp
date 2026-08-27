# UtangLista — Business Logic

## 1. Overview

UtangLista is a **local, offline-first mobile application** for small store owners to manage customer credit (utang), products, transactions, payments, and optional monthly interest.

The application has:

- No authentication
- No required internet connection
- Local persistent storage
- One local store profile per application instance
- Customers belonging to the store
- Products belonging to the store
- Credit transactions involving customers and products
- Payments made against a customer's outstanding account balance
- Optional monthly interest

The most important business principle is:

> **Transactions record what a customer took. Payments reduce the customer's overall outstanding balance. Payments are not assigned to individual products or transaction items.**

The customer's account balance is derived from financial events rather than manually maintained as a mutable field.

---

# 2. Core Business Concepts

UtangLista has four primary financial concepts:

1. **Transaction** — money owed because the customer received products without paying immediately.
2. **Transaction Item** — the individual products and quantities contained in a transaction.
3. **Payment** — money received from a customer that reduces their outstanding balance.
4. **Interest** — an optional financial charge added to the customer's outstanding balance.

These form the customer's account ledger.

Conceptually:

```text
Customer Account
│
├── Transactions      + debt
├── Interest          + debt
└── Payments          - debt
```

The current outstanding balance is derived from these events.

---

# 3. Store

A store represents the business using UtangLista.

A store contains:

- Store name
- Description
- Category
- Store settings

Store settings may include:

- Monthly interest enabled/disabled
- Monthly interest rate

The application is offline-first and does not require a user account or authentication.

---

# 4. Customers

A customer represents a person who may owe money to the store.

A customer has:

- Name
- Contact number (optional)
- Creation date
- Active/inactive state

A customer may have:

- Zero outstanding balance
- Positive outstanding balance
- Historical transactions
- Historical payments
- Historical interest charges

A customer should not directly store a manually maintained balance.

Do NOT treat the following as authoritative database fields:

```text
customer.total_utang
customer.total_paid
customer.balance
```

These values should be calculated from the underlying financial records.

---

# 5. Products

A product represents something sold by the store.

A product has:

- Name
- Description (optional)
- Barcode
- Current selling price
- Unit
- Active/inactive state
- Creation date

The product's current price is only the current selling price.

Historical transactions must never depend on the current product price.

---

# 6. Transactions

A transaction represents a customer receiving one or more products on credit.

Example:

```text
Customer: Juan Dela Cruz

Rice       5 × ₱100 = ₱500
Coffee     2 × ₱20  = ₱40

Transaction Total = ₱540
```

A transaction belongs to exactly one customer.

A transaction contains one or more transaction items.

A transaction records the amount that became part of the customer's debt.

---

# 7. Transaction Items

Each transaction item represents a product included in a transaction.

A transaction item contains:

- Product reference
- Quantity
- Unit price
- Subtotal

The transaction item must store the **unit price at the time of the transaction**.

For example:

```text
Current Product Price:
Rice = ₱100
```

Customer purchases:

```text
5 × ₱100 = ₱500
```

Later, the product price changes:

```text
Rice = ₱110
```

The historical transaction must remain:

```text
5 × ₱100 = ₱500
```

It must NOT become:

```text
5 × ₱110 = ₱550
```

Therefore:

> `transaction_items.unit_price` is a historical price snapshot.

---

# 8. Transaction Total

The total amount of a transaction is the sum of its transaction item subtotals.

For each item:

```text
subtotal = quantity × unit_price
```

For the transaction:

```text
transaction_total = SUM(transaction_item.subtotal)
```

Example:

```text
Rice       5 × ₱100 = ₱500
Coffee     2 × ₱20  = ₱40
Sardines   3 × ₱30  = ₱90

Total = ₱630
```

The transaction total should be persisted as a snapshot for efficient access and historical consistency, while transaction items remain the detailed source of what was purchased.

The application must ensure that the persisted total agrees with the calculated item total when creating or modifying a transaction.

---

# 9. Transaction Creation

When creating a transaction:

1. Select a customer.
2. Select one or more products.
3. Enter quantities.
4. Retrieve each product's current price.
5. Store that price as the transaction item's `unit_price`.
6. Calculate each item's subtotal.
7. Calculate the transaction total.
8. Persist the transaction and its items atomically.

Example:

```text
Customer: Juan

Rice
Quantity: 5
Current Price: ₱100
Subtotal: ₱500

Coffee
Quantity: 2
Current Price: ₱20
Subtotal: ₱40

Transaction Total: ₱540
```

Once committed, the transaction becomes part of the customer's outstanding debt.

---

# 10. Transaction Atomicity

Creating a transaction must be atomic.

A transaction must never exist without its required transaction items.

For example, this state is invalid:

```text
transactions
    Transaction #1001
    Total: ₱500

transaction_items
    No items
```

If any required transaction item fails to persist, the entire transaction creation must fail and roll back.

The database transaction should therefore be:

```text
BEGIN

Create transaction
Create transaction items

COMMIT
```

If anything fails:

```text
ROLLBACK
```

---

# 11. Payments

A payment represents money actually received from a customer.

A payment belongs to:

- Store
- Customer

A payment contains:

- Amount
- Date/time
- Optional note

A payment is **not tied to a specific transaction or product**.

This is intentional.

Example:

```text
Transaction #1 = ₱500
Transaction #2 = ₱300

Customer owes = ₱800

Customer pays = ₱450

Remaining balance = ₱350
```

The application does not need to determine which products were "paid for."

---

# 12. Partial Payments

Partial payments are fully supported.

Example:

```text
Customer debt = ₱500

Customer pays = ₱100

Remaining balance = ₱400
```

The original transaction remains unchanged:

```text
Transaction = ₱500
Payment     = ₱100
Balance     = ₱400
```

The application must never alter the original transaction total simply because a payment was made.

---

# 13. Payment Larger Than a Single Transaction

A payment may cover multiple previous transactions.

Example:

```text
Transaction #1 = ₱500
Transaction #2 = ₱300
Transaction #3 = ₱200

Total debt = ₱1,000

Payment = ₱700

Remaining balance = ₱300
```

The payment is applied to the customer's account as a whole.

Do not artificially distribute the payment across products unless a future feature explicitly requires allocation.

---

# 14. Payment Must Not Modify Historical Transactions

Given:

```text
Transaction #1
5 × Rice
₱500
```

and:

```text
Payment
₱100
```

Do NOT change:

```text
Transaction #1
amount = ₱400
```

Do NOT change:

```text
Transaction #1
remaining_amount = ₱400
```

Instead:

```text
Transaction #1 = +₱500
Payment        = -₱100

Outstanding = ₱400
```

Historical transactions are immutable financial records after they are committed, except through explicitly supported correction/deletion workflows.

---

# 15. Customer Balance

The customer's balance is derived from financial events.

Basic formula:

```text
Outstanding Balance =
    Total Transaction Amounts
    + Total Interest
    - Total Payments
```

Example:

```text
Transactions:
₱500
₱300
₱200

Total Transactions = ₱1,000

Payments:
₱100
₱200

Total Payments = ₱300

Interest:
₱20

Outstanding Balance:

₱1,000 + ₱20 - ₱300
= ₱720
```

Therefore:

```text
Outstanding Balance = ₱720
```

---

# 16. Balance Must Not Be the Source of Truth

Do not maintain the customer's balance as the primary accounting value.

Avoid logic such as:

```text
customer.balance += transaction.total
customer.balance -= payment.amount
```

as the only source of truth.

This creates risks such as:

- Incorrect balance after failed writes
- Balance corruption
- Difficult recovery
- Synchronization problems
- Difficulty auditing historical events

Instead, the financial records are authoritative:

```text
Transactions
Payments
Interest Records
```

The balance is derived from them.

For performance optimization, a cached balance may be introduced in the future, but it must remain a derived/cache value and must never replace the underlying ledger records.

---

# 17. Customer Ledger

A customer's financial activity can be represented as a chronological ledger.

Example:

```text
Date       Type        Description             Amount
-------------------------------------------------------
Aug 20     UTANG       5 × Rice               +₱500
Aug 21     UTANG       2 × Coffee             +₱100
Aug 22     PAYMENT     Partial payment         -₱200
Aug 23     UTANG       3 × Sardines           +₱150
Aug 23     INTEREST    Monthly interest        +₱9
```

The running balance becomes:

```text
Aug 20    ₱500
Aug 21    ₱600
Aug 22    ₱400
Aug 23    ₱550
Aug 23    ₱559
```

The ledger can be constructed from:

```text
transactions
payments
interest_records
```

There is no requirement for a separate ledger table in the initial implementation.

---

# 18. Transaction Status

Transaction status should not be used as the primary accounting mechanism.

Avoid relying on:

```text
PAID
PARTIALLY_PAID
UNPAID
```

to calculate the customer's balance.

The customer's account balance is determined by the account-level financial events.

A transaction may still have a UI status for display purposes if desired, but it must not replace the ledger model.

Example:

```text
Transaction:
₱500

Customer:
₱500 debt

Payment:
₱100

Customer balance:
₱400
```

The payment does not require changing the transaction's amount.

---

# 19. Monthly Interest

Monthly interest is optional.

Store owners may enable or disable monthly interest.

The store owner can configure the monthly interest rate.

The allowed rate is:

```text
0% to 5%
```

The application must reject rates below 0% or above 5%.

Example:

```text
Interest enabled: true
Rate: 2%
```

---

# 20. Interest Calculation

For the initial implementation, monthly interest should be calculated against the customer's applicable outstanding balance.

Example:

```text
Outstanding Balance = ₱1,000
Monthly Interest = 2%

Interest:
₱1,000 × 0.02 = ₱20

New Balance:
₱1,020
```

Interest should be represented as a financial event rather than simply recalculated every time the balance is displayed.

This allows the application to preserve historical accounting.

---

# 21. Interest Records

When interest is applied, create an interest record containing at minimum:

```text
customer_id
rate
base_amount
interest_amount
created_at
```

Example:

```text
Customer: Juan

Base Amount:      ₱1,000
Rate:             2%
Interest Amount:  ₱20
Date:             Aug 23
```

The customer's balance then becomes:

```text
Transactions
+₱1,000

Interest
+₱20

Payments
-₱0

Balance
₱1,020
```

---

# 22. Interest Must Not Compound Accidentally

The system must avoid accidentally applying monthly interest multiple times for the same period.

For example, if August interest has already been applied to Juan, opening the application multiple times must not create:

```text
Aug 23    Interest +₱20
Aug 23    Interest +₱20
Aug 23    Interest +₱20
```

unless the business rules explicitly allow multiple interest charges.

There should be a mechanism to determine whether interest for the applicable period has already been generated.

---

# 23. Negative Balance

The application should prevent ordinary payments from creating an unintended negative outstanding balance.

Example:

```text
Customer balance = ₱500
Payment entered  = ₱700
```

The default behavior should be to reject the payment or require explicit handling of the excess amount.

Do not silently create:

```text
Balance = -₱200
```

unless a future business rule explicitly introduces customer credits/overpayments.

For V1, payments should not exceed the customer's outstanding balance.

---

# 24. Zero-Value Transactions

Transactions should not normally allow:

```text
quantity = 0
```

or:

```text
transaction total = ₱0
```

unless there is a deliberate business reason to support free items.

For V1:

- Quantity must be greater than zero.
- Transaction must contain at least one item.
- Unit price must not be negative.
- Subtotal must not be negative.
- Transaction total must be greater than zero.

---

# 25. Negative Monetary Values

The following values must never be negative:

```text
product.price
transaction_item.unit_price
transaction_item.subtotal
transaction.total_amount
payment.amount
interest.interest_amount
```

Negative financial adjustments should be represented by an explicit business event rather than by allowing arbitrary negative values.

For example, a future refund feature should introduce a proper refund/adjustment concept rather than allowing:

```text
payment.amount = -100
```

---

# 26. Monetary Precision

Money must not be represented using floating-point arithmetic where exact financial calculations are required.

Prefer a decimal-safe representation appropriate for the chosen database and application layer.

For Philippine peso amounts:

```text
₱500.00
₱100.50
₱1,250.75
```

Calculations should preserve centavo precision.

Do not rely on binary floating-point equality for financial validation.

---

# 27. Historical Data

Historical financial records must remain stable.

Changing a product should not change:

- Existing transaction prices
- Existing transaction totals
- Existing payment amounts
- Existing interest records

Changing a customer name/contact information may update how the customer is displayed, but must not alter historical financial amounts.

---

# 28. Product Deactivation

Products should preferably be deactivated instead of permanently deleted when they have historical transactions.

Example:

```text
Product:
Rice

is_active = false
```

The product should no longer appear when creating new transactions.

However, existing transaction items must remain accessible because they represent historical records.

---

# 29. Customer Deactivation

Customers with historical transactions should preferably be deactivated rather than permanently deleted.

An inactive customer:

- Cannot normally receive new transactions
- Remains visible in historical records
- Retains their financial history

A customer with an outstanding balance should never be silently deleted.

---

# 30. Deletion Rules

Financial records require stricter deletion behavior than ordinary CRUD data.

The application should avoid unrestricted deletion of:

```text
transactions
payments
interest_records
```

because deleting financial records changes the accounting history.

If deletion is eventually supported, it should be treated as a deliberate correction operation with appropriate confirmation.

For V1, prefer:

```text
Products → deactivate
Customers → deactivate
Financial records → retain
```

---

# 31. Transaction Editing

Once a transaction has been committed, editing its financial values should be restricted.

Do not allow casual modification of:

```text
quantity
unit_price
subtotal
total_amount
customer
```

after payments or subsequent transactions exist.

If corrections are required in the future, consider introducing explicit adjustment/reversal transactions instead of silently mutating historical records.

---

# 32. Offline-First Requirement

All core business operations must work without an internet connection.

These operations must be available offline:

- Create store
- Edit store
- Create customer
- Edit customer
- Create product
- Edit product
- Create transaction
- Record payment
- View customer balance
- View transaction history
- View payment history
- Calculate applicable interest

The local database is the source of truth for the application.

---

# 33. Database Transactions

Operations involving multiple records must use database-level transactions.

Examples:

### Creating a transaction

```text
BEGIN

Insert transaction
Insert transaction items

COMMIT
```

### Recording a payment

```text
BEGIN

Validate customer balance
Insert payment

COMMIT
```

### Applying interest

```text
BEGIN

Calculate applicable balance
Create interest record

COMMIT
```

If any operation fails:

```text
ROLLBACK
```

The application must not leave partially completed financial operations.

---

# 34. Recommended Database Structure

The initial database should contain:

```text
stores
store_settings

customers
products

transactions
transaction_items

payments

interest_records
```

Relationships:

```text
stores
│
├── store_settings
├── customers
│   ├── transactions
│   │   └── transaction_items
│   ├── payments
│   └── interest_records
│
└── products
       └── transaction_items
```

---

# 35. Source of Truth

The following hierarchy should be respected:

```text
PRODUCT
Current product information
        │
        ▼
TRANSACTION ITEM
Historical purchased product + historical price
        │
        ▼
TRANSACTION
Historical amount of credit given
        │
        ├───────────────┐
        ▼               ▼
PAYMENT          INTEREST RECORD
Money received   Additional debt
        │               │
        └───────┬───────┘
                ▼
        CUSTOMER BALANCE
          Derived value
```

The balance is the result of the ledger, not the source of the ledger.

---

# 36. Example Complete Scenario

A customer named Juan starts with no debt.

## Day 1

Juan takes:

```text
5 × Rice @ ₱100
```

Transaction:

```text
+₱500
```

Balance:

```text
₱500
```

## Day 2

Juan takes:

```text
2 × Coffee @ ₱20
```

Transaction:

```text
+₱40
```

Balance:

```text
₱540
```

## Day 3

Juan pays:

```text
₱100
```

Payment:

```text
-₱100
```

Balance:

```text
₱440
```

The original transactions remain:

```text
Day 1: ₱500
Day 2: ₱40
```

They are not changed to reflect the payment.

## Day 4

Juan takes:

```text
3 × Sardines @ ₱30
```

Transaction:

```text
+₱90
```

Balance:

```text
₱530
```

## End of Month

Store has:

```text
Monthly interest: 2%
```

Applicable balance:

```text
₱530
```

Interest:

```text
₱530 × 0.02 = ₱10.60
```

New balance:

```text
₱540.60
```

Ledger:

```text
Day 1    UTANG       +₱500.00
Day 2    UTANG        +₱40.00
Day 3    PAYMENT     -₱100.00
Day 4    UTANG        +₱90.00
Month    INTEREST     +₱10.60
--------------------------------
Balance              ₱540.60
```

This is the canonical accounting behavior for UtangLista.

---

# 37. Implementation Principles for Claude Code

When implementing UtangLista:

1. Treat financial events as the source of truth.
2. Do not use customer balance as the authoritative stored value.
3. Do not assign payments to individual products.
4. Do not modify historical transaction amounts when payments are recorded.
5. Store historical product prices inside transaction items.
6. Use database transactions for multi-record financial operations.
7. Validate monetary values before persistence.
8. Prevent negative monetary values.
9. Prevent accidental overpayments in V1.
10. Preserve historical financial records.
11. Prefer deactivation over deletion for customers and products with history.
12. Keep the application fully functional offline.
13. Keep business rules in the domain/application layer rather than inside UI widgets.
14. Repositories should handle persistence; business logic should not be duplicated across screens.
15. Derived values such as balances should have a single authoritative calculation path.
16. Interest must be recorded as an explicit financial event.
17. Interest must not be generated repeatedly for the same period.
18. Financial operations must be atomic.
19. Never silently mutate historical financial records.
20. Favor correctness and auditability over premature optimization.

---

# 38. Core Invariants

The implementation must preserve these invariants:

```text
Transaction total >= 0
Transaction item quantity > 0
Transaction item unit price >= 0
Transaction item subtotal >= 0
Payment amount > 0
Interest amount >= 0
Interest rate >= 0
Interest rate <= 5%
```

And:

```text
Transaction total
=
SUM(transaction item subtotals)
```

And:

```text
Customer balance
=
SUM(transaction totals)
+
SUM(interest amounts)
-
SUM(payment amounts)
```

For V1, customer balance must not become negative through ordinary payment operations.

Most importantly:

```text
Payments do not modify transactions.
Transactions do not contain payment state.
Products do not determine historical transaction prices.
Customer balance is derived from financial events.
```

These rules define the accounting foundation of UtangLista and should be treated as business requirements rather than implementation suggestions.