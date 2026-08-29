import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_balance_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/datasource/customer_local_data_source.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_repository.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:utanglista_mobileapp/features/stores/data/datasource/store_local_data_source.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';
import 'package:utanglista_mobileapp/features/stores/domain/repositories/store_repository.dart';

void main() {
  group('CustomerEntity', () {
    CustomerEntity customer({String name = 'Juan Dela Cruz', String? contact}) {
      return CustomerEntity(
        id: 1,
        storeId: 1,
        name: name,
        contactNumber: contact,
        isActive: true,
        createdAt: DateTime(2026, 8, 23),
      );
    }

    test('initials take the first and last name', () {
      expect(customer(name: 'Juan Dela Cruz').initials, 'JC');
      expect(customer(name: 'Maria Santos').initials, 'MS');
    });

    test('a single name gives one initial', () {
      expect(customer(name: 'Juan').initials, 'J');
    });

    test('extra whitespace does not produce a blank initial', () {
      expect(customer(name: '  Juan   Santos  ').initials, 'JS');
    });

    test('an empty name falls back rather than throwing', () {
      // A list row must render even for data that should not exist.
      expect(customer(name: '   ').initials, '?');
    });

    test('contact is optional (§4)', () {
      expect(customer().hasContactNumber, isFalse);
      expect(customer(contact: '09171234567').hasContactNumber, isTrue);
      // Whitespace is not a contact number.
      expect(customer(contact: '   ').hasContactNumber, isFalse);
    });
  });

  group('customer repository', () {
    late AppDatabase db;
    late CustomerRepository repository;
    late StoreRepository storeRepository;
    late int storeId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = CustomerRepositoryImplementation(
        CustomerLocalDataSourceImplementation(db),
      );
      storeRepository = StoreRepositoryImplementation(
        StoreLocalDataSourceImplementation(db),
      );
      storeId = await storeRepository.createStore(
        StorePayloadModel(name: 'Aling Nena Store'),
      );
    });

    tearDown(() async => db.close());

    Future<int> addCustomer(String name, {String? contact}) =>
        repository.createCustomer(
          CustomerPayloadModel(
            storeId: storeId,
            name: name,
            contactNumber: contact,
          ),
        );

    Future<void> addTransaction(int customerId, Money amount) => db
        .into(db.transactionsTable)
        .insert(
          TransactionsTableCompanion.insert(
            storeId: storeId,
            customerId: customerId,
            totalAmount: amount.centavos,
          ),
        );

    // ====================================================
    test('creates a customer, active by default', () async {
      final id = await addCustomer('Juan');

      final customer = await repository.fetchCustomerById(id);
      expect(customer!.name, 'Juan');
      expect(customer.isActive, isTrue);
      expect(customer.contactNumber, isNull);
    });

    test('blank contact is stored as null, not an empty string', () async {
      // "Not recorded" must have exactly one representation.
      final id = await addCustomer('Juan', contact: '   ');

      final customer = await repository.fetchCustomerById(id);
      expect(customer!.contactNumber, isNull);
    });

    test('customers are scoped to their store', () async {
      final otherStoreId = await storeRepository.createStore(
        StorePayloadModel(name: 'Fishball Cart'),
      );

      await addCustomer('Juan');
      await repository.createCustomer(
        CustomerPayloadModel(storeId: otherStoreId, name: 'Pedro'),
      );

      final ourCustomers = await repository.fetchCustomers(storeId);
      expect(ourCustomers.map((c) => c.name), ['Juan']);
    });

    // ====================================================
    group('search', () {
      test('matches part of a name, case-insensitively', () async {
        await addCustomer('Juan Dela Cruz');
        await addCustomer('Maria Santos');

        expect(
          (await repository.fetchCustomers(storeId, search: 'juan')).single.name,
          'Juan Dela Cruz',
        );
        expect(
          (await repository.fetchCustomers(storeId, search: 'DELA')).single.name,
          'Juan Dela Cruz',
        );
        expect(
          (await repository.fetchCustomers(storeId, search: 'santos'))
              .single
              .name,
          'Maria Santos',
        );
      });

      test('matches the contact number too', () async {
        await addCustomer('Juan', contact: '09171234567');
        await addCustomer('Maria', contact: '09981112222');

        final results = await repository.fetchCustomers(
          storeId,
          search: '0917',
        );
        expect(results.single.name, 'Juan');
      });

      test('an accented name is found by its accented spelling', () async {
        // SQLite's LIKE is only case-insensitive for ASCII, which is why
        // both sides of the comparison are lowered explicitly.
        await addCustomer('José Rizal');

        expect(
          (await repository.fetchCustomers(storeId, search: 'josé')).single.name,
          'José Rizal',
        );
      });

      test('a blank search returns everyone', () async {
        await addCustomer('Juan');
        await addCustomer('Maria');

        expect(await repository.fetchCustomers(storeId, search: ''), hasLength(2));
        expect(
          await repository.fetchCustomers(storeId, search: '   '),
          hasLength(2),
        );
      });

      test('no match returns empty, not everyone', () async {
        await addCustomer('Juan');

        expect(
          await repository.fetchCustomers(storeId, search: 'zzz'),
          isEmpty,
        );
      });
    });

    // ====================================================
    group('deactivation (§29)', () {
      test('deactivating hides a customer from the default list', () async {
        final id = await addCustomer('Juan');

        await repository.setActive(id, isActive: false);

        expect(
          await repository.fetchCustomers(storeId, includeInactive: false),
          isEmpty,
        );
        expect(
          await repository.fetchCustomers(storeId, includeInactive: true),
          hasLength(1),
        );
      });

      test('a deactivated customer keeps their balance and history',
          () async {
        final id = await addCustomer('Juan');
        await addTransaction(id, Money.fromPesos(500));

        await repository.setActive(id, isActive: false);

        // §29: inactive means "no new utang", never "records removed".
        final customer = await repository.fetchCustomerById(id);
        expect(customer!.isActive, isFalse);
        expect(await repository.hasFinancialHistory(id), isTrue);
      });

      test('reactivating restores them to the active list', () async {
        final id = await addCustomer('Juan');
        await repository.setActive(id, isActive: false);
        await repository.setActive(id, isActive: true);

        expect(
          await repository.fetchCustomers(storeId, includeInactive: false),
          hasLength(1),
        );
      });

      test('active customers sort above inactive ones', () async {
        final juan = await addCustomer('Juan');
        await addCustomer('Maria');
        await repository.setActive(juan, isActive: false);

        final customers = await repository.fetchCustomers(
          storeId,
          includeInactive: true,
        );
        expect(customers.first.name, 'Maria');
        expect(customers.last.name, 'Juan');
      });
    });

    // ====================================================
    group('deletion (§29, §30)', () {
      test('a customer with no history can be deleted', () async {
        // Someone added by mistake, before any utang was recorded.
        final id = await addCustomer('Mistake');

        expect(await repository.deleteCustomer(id), 1);
        expect(await repository.fetchCustomerById(id), isNull);
      });

      test('a customer with a transaction cannot be deleted', () async {
        final id = await addCustomer('Juan');
        await addTransaction(id, Money.fromPesos(500));

        await expectLater(
          repository.deleteCustomer(id),
          throwsA(
            isA<AppFailure>().having(
              (f) => f.code,
              'code',
              'HAS_FINANCIAL_HISTORY',
            ),
          ),
        );

        // Still there, untouched.
        expect(await repository.fetchCustomerById(id), isNotNull);
      });

      test('a customer who paid in full still cannot be deleted', () async {
        // Balance is zero, but the records exist and §30 keeps them.
        final id = await addCustomer('Juan');
        await addTransaction(id, Money.fromPesos(500));
        await db
            .into(db.paymentsTable)
            .insert(
              PaymentsTableCompanion.insert(
                storeId: storeId,
                customerId: id,
                amount: Money.fromPesos(500).centavos,
              ),
            );

        await expectLater(
          repository.deleteCustomer(id),
          throwsA(isA<AppFailure>()),
        );
      });

      test('deleting twice reports NOT_FOUND', () async {
        final id = await addCustomer('Mistake');
        await repository.deleteCustomer(id);

        await expectLater(
          repository.deleteCustomer(id),
          throwsA(
            isA<AppFailure>().having((f) => f.code, 'code', 'NOT_FOUND'),
          ),
        );
      });
    });

    // ====================================================
    group('updating', () {
      test('a partial update leaves untouched fields alone', () async {
        final id = await addCustomer('Juan', contact: '09171234567');

        await repository.updateCustomer(
          UpdateCustomerPayloadModel(customerId: id, name: 'Juan Dela Cruz'),
        );

        final customer = await repository.fetchCustomerById(id);
        expect(customer!.name, 'Juan Dela Cruz');
        expect(customer.contactNumber, '09171234567');
      });

      test("an empty contact clears it — '' means clear, null means keep",
          () async {
        final id = await addCustomer('Juan', contact: '09171234567');

        await repository.updateCustomer(
          UpdateCustomerPayloadModel(customerId: id, contactNumber: ''),
        );

        final customer = await repository.fetchCustomerById(id);
        expect(customer!.contactNumber, isNull);
        expect(customer.name, 'Juan');
      });

      test('renaming does not deactivate', () async {
        final id = await addCustomer('Juan');

        await repository.updateCustomer(
          UpdateCustomerPayloadModel(customerId: id, name: 'Juan Dela Cruz'),
        );

        expect((await repository.fetchCustomerById(id))!.isActive, isTrue);
      });

      test('an update with nothing to change is not NOT_FOUND', () async {
        // An empty companion would match zero rows, which
        // requireRowChanged reads as "this customer is gone".
        final id = await addCustomer('Juan');

        expect(
          await repository.updateCustomer(
            UpdateCustomerPayloadModel(customerId: id),
          ),
          1,
        );
      });

      test('updating a missing customer does report NOT_FOUND', () async {
        await expectLater(
          repository.updateCustomer(
            UpdateCustomerPayloadModel(customerId: 999, name: 'Ghost'),
          ),
          throwsA(
            isA<AppFailure>().having((f) => f.code, 'code', 'NOT_FOUND'),
          ),
        );
      });
    });

    // ====================================================
    test('hasFinancialHistory sees each kind of record', () async {
      final withTransaction = await addCustomer('Has Transaction');
      final withPayment = await addCustomer('Has Payment');
      final withInterest = await addCustomer('Has Interest');
      final withNothing = await addCustomer('Has Nothing');

      await addTransaction(withTransaction, Money.fromPesos(100));

      await db
          .into(db.paymentsTable)
          .insert(
            PaymentsTableCompanion.insert(
              storeId: storeId,
              customerId: withPayment,
              amount: Money.fromPesos(50).centavos,
            ),
          );

      await db
          .into(db.interestRecordsTable)
          .insert(
            InterestRecordsTableCompanion.insert(
              storeId: storeId,
              customerId: withInterest,
              rateBasisPoints: 200,
              baseAmount: 10000,
              interestAmount: 200,
              periodKey: '2026-08',
            ),
          );

      expect(await repository.hasFinancialHistory(withTransaction), isTrue);
      expect(await repository.hasFinancialHistory(withPayment), isTrue);
      expect(await repository.hasFinancialHistory(withInterest), isTrue);
      expect(await repository.hasFinancialHistory(withNothing), isFalse);
    });

    /*
      Two of the three customer sorts are an ORDER BY in the
      datasource. The third — by balance — cannot be, and is tested
      separately below through the cubit, because the balance lives in
      a different query.
    */
    group('sorting', () {
      Future<List<String>> namesSortedBy(
        CustomerSort sort, {
        bool includeInactive = false,
      }) async {
        final customers = await repository.fetchCustomers(
          storeId,
          sort: sort,
          includeInactive: includeInactive,
        );

        return customers.map((c) => c.name).toList();
      }

      /*
        Newest-first with everything created in the same unix second,
        so this is really a test of the id tiebreaker. Without it the
        customer list reshuffles between loads — the Phase 1 bug, in
        the feature that came after it.
      */
      test('defaults to newest first', () async {
        await addCustomer('Juan');
        await addCustomer('Maria');
        await addCustomer('Pedro');

        final customers = await repository.fetchCustomers(storeId);

        expect(customers.map((c) => c.name), ['Pedro', 'Maria', 'Juan']);
      });

      test('by name, A–Z', () async {
        await addCustomer('Pedro');
        await addCustomer('Juan');
        await addCustomer('Maria');

        expect(await namesSortedBy(CustomerSort.name), [
          'Juan',
          'Maria',
          'Pedro',
        ]);
      });

      /// §29: a deactivated customer is still listed when asked for,
      /// but never above someone the seller is actively dealing with.
      test('deactivated customers sort last, whatever the sort', () async {
        final juan = await addCustomer('Juan');
        await addCustomer('Maria');
        await addCustomer('Pedro');

        await repository.setActive(juan, isActive: false);

        expect(
          await namesSortedBy(CustomerSort.name, includeInactive: true),
          ['Maria', 'Pedro', 'Juan'],
        );
      });

      /*
        CustomerSort.balance has no column to sort on, so the datasource
        gives it a deterministic base order and the CUBIT re-sorts once
        the batched balances arrive. That seam is the thing worth
        testing: the screen must receive a list already in its final
        order.
      */
      group('by balance (ordered in the cubit, not in SQL)', () {
        late CustomerBalanceRepository balanceRepository;

        setUp(() {
          balanceRepository = CustomerBalanceRepositoryImplementation(
            CustomerBalanceLocalDataSourceImplementation(db),
          );
        });

        Future<List<String>> loadSortedByBalance() async {
          final cubit = CustomerListCubit(
            repository,
            balanceRepository,
            storeId: storeId,
          );

          await cubit.setSort(CustomerSort.balance);
          final names = cubit.state.customers.map((c) => c.name).toList();

          await cubit.close();
          return names;
        }

        test('biggest debtor first', () async {
          final juan = await addCustomer('Juan');
          final maria = await addCustomer('Maria');
          final pedro = await addCustomer('Pedro');

          await addTransaction(juan, Money.fromPesos(500));
          await addTransaction(maria, Money.fromPesos(1200));
          await addTransaction(pedro, Money.fromPesos(80));

          expect(await loadSortedByBalance(), ['Maria', 'Juan', 'Pedro']);
        });

        test('a customer who owes nothing sorts last', () async {
          final juan = await addCustomer('Juan');
          await addCustomer('Maria');

          await addTransaction(juan, Money.fromPesos(500));

          // Maria has no financial records at all, so she has no row
          // in the batched balance map — she must read as ₱0.00, not
          // as an absent value that throws or sorts first.
          expect(await loadSortedByBalance(), ['Juan', 'Maria']);
        });

        test('two customers owing the same keep a stable order', () async {
          final juan = await addCustomer('Juan');
          final maria = await addCustomer('Maria');

          await addTransaction(juan, Money.fromPesos(300));
          await addTransaction(maria, Money.fromPesos(300));

          expect(await loadSortedByBalance(), ['Juan', 'Maria']);
          expect(await loadSortedByBalance(), ['Juan', 'Maria']);
        });
      });
    });

    test('deleting a store removes its customers', () async {
      await addCustomer('Juan');

      // storeId cascades — a deliberate "remove this whole business".
      await storeRepository.deleteStore(storeId);

      expect(await db.select(db.customersTable).get(), isEmpty);
    });
  });
}
