import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/products/data/datasource/product_local_data_source.dart';
import 'package:utanglista_mobileapp/features/products/data/model/product_payload_model.dart';
import 'package:utanglista_mobileapp/features/products/domain/entities/product_entity.dart';
import 'package:utanglista_mobileapp/features/products/domain/repositories/product_repository.dart';
import 'package:utanglista_mobileapp/features/stores/data/datasource/store_local_data_source.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';
import 'package:utanglista_mobileapp/features/stores/domain/repositories/store_repository.dart';

void main() {
  group('ProductEntity', () {
    ProductEntity product({
      String? barcode,
      Money price = const Money.fromCentavos(10000),
      bool isActive = true,
    }) {
      return ProductEntity(
        id: 1,
        storeId: 1,
        name: 'Rice',
        description: '',
        barcode: barcode,
        price: price,
        unit: 'kg',
        isActive: isActive,
        createdAt: DateTime(2026, 8, 23),
      );
    }

    test('barcode is optional', () {
      expect(product().hasBarcode, isFalse);
      expect(product(barcode: '4801234567890').hasBarcode, isTrue);
      // Whitespace is not a barcode.
      expect(product(barcode: '   ').hasBarcode, isFalse);
    });

    test('price reads with its unit', () {
      expect(product().priceWithUnit, '₱100.00 / kg');
    });

    test('an inactive product is not sellable (§28)', () {
      expect(product(isActive: false).isSellable, isFalse);
    });

    test('a zero-priced product is not sellable (§24)', () {
      // §24 requires a transaction total above zero, so a free item
      // would have to be a deliberate feature, not an accident.
      expect(product(price: Money.zero).isSellable, isFalse);
      expect(product().isSellable, isTrue);
    });
  });

  group('product repository', () {
    late AppDatabase db;
    late ProductRepository repository;
    late StoreRepository storeRepository;
    late int storeId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = ProductRepositoryImplementation(
        ProductLocalDataSourceImplementation(db),
      );
      storeRepository = StoreRepositoryImplementation(
        StoreLocalDataSourceImplementation(db),
      );
      storeId = await storeRepository.createStore(
        StorePayloadModel(name: 'Aling Nena Store'),
      );
    });

    tearDown(() async => db.close());

    Future<int> addProduct(
      String name, {
      String? barcode,
      Money? price,
      String unit = 'pc',
      int? inStore,
    }) {
      return repository.createProduct(
        ProductPayloadModel(
          storeId: inStore ?? storeId,
          name: name,
          price: price ?? Money.fromPesos(100),
          unit: unit,
          barcode: barcode,
        ),
      );
    }

    /// Puts the product into a transaction, which is what makes it
    /// undeletable under §28.
    Future<void> sellProduct(int productId, {required Money at}) async {
      final customerId = await db
          .into(db.customersTable)
          .insert(
            CustomersTableCompanion.insert(storeId: storeId, name: 'Juan'),
          );
      final transactionId = await db
          .into(db.transactionsTable)
          .insert(
            TransactionsTableCompanion.insert(
              storeId: storeId,
              customerId: customerId,
              totalAmount: at.centavos,
            ),
          );
      await db
          .into(db.transactionsItemTable)
          .insert(
            TransactionsItemTableCompanion.insert(
              transactionId: transactionId,
              productId: productId,
              quantity: 1,
              unitPrice: at.centavos,
              subTotal: at.centavos,
            ),
          );
    }

    // ====================================================
    test('creates a product, active by default', () async {
      final id = await addProduct('Rice', price: Money.fromPesos(52.50));

      final product = await repository.fetchProductById(id);
      expect(product!.name, 'Rice');
      expect(product.isActive, isTrue);
      expect(product.price, Money.fromPesos(52.50));
      expect(product.price.format(), '₱52.50');
    });

    test('a blank barcode is stored as null, not an empty string', () async {
      // Many NULLs coexist under the unique index; many '' would not.
      final id = await addProduct('Fishball', barcode: '   ');

      expect((await repository.fetchProductById(id))!.barcode, isNull);
    });

    test('products are scoped to their store', () async {
      final otherStoreId = await storeRepository.createStore(
        StorePayloadModel(name: 'Fishball Cart'),
      );

      await addProduct('Rice');
      await addProduct('Fishball', inStore: otherStoreId);

      final ours = await repository.fetchProducts(storeId);
      expect(ours.map((p) => p.name), ['Rice']);
    });

    test('lists alphabetically, active first', () async {
      final coffee = await addProduct('Coffee');
      await addProduct('Sardines');
      await addProduct('Rice');
      await repository.setActive(coffee, isActive: false);

      final products = await repository.fetchProducts(
        storeId,
        includeInactive: true,
      );

      // A catalogue is browsed by name, unlike the customer list.
      expect(products.map((p) => p.name), ['Rice', 'Sardines', 'Coffee']);
    });

    // ====================================================
    group('barcodes', () {
      test('finds a product by exact barcode', () async {
        final id = await addProduct('Rice', barcode: '4801234567890');
        await addProduct('Coffee', barcode: '4809999999999');

        final found = await repository.findByBarcode(
          storeId,
          '4801234567890',
        );
        expect(found!.id, id);
        expect(found.name, 'Rice');
      });

      test('an unknown barcode returns null, not an error', () async {
        // Scan-to-find turns this into "add it as a new product".
        expect(await repository.findByBarcode(storeId, '0000000'), isNull);
      });

      test('finds an INACTIVE product too', () async {
        // Reporting "not found" would push the seller into creating a
        // duplicate that the unique index then rejects.
        final id = await addProduct('Rice', barcode: '4801234567890');
        await repository.setActive(id, isActive: false);

        final found = await repository.findByBarcode(
          storeId,
          '4801234567890',
        );
        expect(found, isNotNull);
        expect(found!.isActive, isFalse);
      });

      test('a duplicate barcode is refused, and names the culprit', () async {
        await addProduct('Rice', barcode: '4801234567890');

        await expectLater(
          addProduct('Coffee', barcode: '4801234567890'),
          throwsA(
            isA<AppFailure>()
                .having((f) => f.code, 'code', 'DUPLICATE_BARCODE')
                // The seller needs to know WHICH product has it.
                .having((f) => f.message, 'message', contains('Rice')),
          ),
        );
      });

      test('the same barcode is fine in a different store', () async {
        final otherStoreId = await storeRepository.createStore(
          StorePayloadModel(name: 'Second Store'),
        );

        await addProduct('Rice', barcode: '4801234567890');
        await addProduct(
          'Rice',
          barcode: '4801234567890',
          inStore: otherStoreId,
        );

        expect(await db.select(db.productsTable).get(), hasLength(2));
      });

      test('many unbarcoded products coexist', () async {
        // The whole reason barcode is nullable — street food has none.
        await addProduct('Fishball');
        await addProduct('Kwek Kwek');
        await addProduct('Kikiam');

        expect(await repository.fetchProducts(storeId), hasLength(3));
      });

      test('keeping its own barcode on edit is not a conflict', () async {
        final id = await addProduct('Rice', barcode: '4801234567890');

        await repository.updateProduct(
          UpdateProductPayloadModel(
            productId: id,
            name: 'Rice (Sinandomeng)',
            barcode: '4801234567890',
          ),
        );

        expect(
          (await repository.fetchProductById(id))!.name,
          'Rice (Sinandomeng)',
        );
      });

      test('taking another product\'s barcode on edit is refused', () async {
        await addProduct('Rice', barcode: '4801234567890');
        final coffee = await addProduct('Coffee');

        await expectLater(
          repository.updateProduct(
            UpdateProductPayloadModel(
              productId: coffee,
              barcode: '4801234567890',
            ),
          ),
          throwsA(
            isA<AppFailure>().having(
              (f) => f.code,
              'code',
              'DUPLICATE_BARCODE',
            ),
          ),
        );
      });

      test("an empty barcode clears it — '' means clear", () async {
        final id = await addProduct('Rice', barcode: '4801234567890');

        await repository.updateProduct(
          UpdateProductPayloadModel(productId: id, barcode: ''),
        );

        expect((await repository.fetchProductById(id))!.barcode, isNull);
      });

      test('search matches a barcode as well as a name', () async {
        await addProduct('Rice', barcode: '4801234567890');
        await addProduct('Coffee', barcode: '4809999999999');

        expect(
          (await repository.fetchProducts(storeId, search: '48012'))
              .single
              .name,
          'Rice',
        );
        expect(
          (await repository.fetchProducts(storeId, search: 'cof')).single.name,
          'Coffee',
        );
      });
    });

    // ====================================================
    group('price history (§7, §27)', () {
      test('repricing a product does not change what it already sold for',
          () async {
        final id = await addProduct('Rice', price: Money.fromPesos(100));

        // 5 × ₱100 = ₱500, the §7 worked example.
        await sellProduct(id, at: Money.fromPesos(100));

        await repository.updateProduct(
          UpdateProductPayloadModel(
            productId: id,
            price: Money.fromPesos(110),
          ),
        );

        // Current price moved...
        expect(
          (await repository.fetchProductById(id))!.price,
          Money.fromPesos(110),
        );

        // ...but the historical line did not. This is the invariant the
        // whole snapshot design exists to protect.
        final item = await db.select(db.transactionsItemTable).getSingle();
        expect(Money.fromCentavos(item.unitPrice), Money.fromPesos(100));
        expect(Money.fromCentavos(item.subTotal), Money.fromPesos(100));
      });

      test('deactivating a product does not change its history', () async {
        final id = await addProduct('Rice', price: Money.fromPesos(100));
        await sellProduct(id, at: Money.fromPesos(100));

        await repository.setActive(id, isActive: false);

        final item = await db.select(db.transactionsItemTable).getSingle();
        expect(Money.fromCentavos(item.unitPrice), Money.fromPesos(100));
      });
    });

    // ====================================================
    group('deactivation and deletion (§28)', () {
      test('deactivating hides a product from the default list', () async {
        final id = await addProduct('Rice');

        await repository.setActive(id, isActive: false);

        expect(
          await repository.fetchProducts(storeId, includeInactive: false),
          isEmpty,
        );
        expect(
          await repository.fetchProducts(storeId, includeInactive: true),
          hasLength(1),
        );
      });

      test('an unsold product can be deleted', () async {
        final id = await addProduct('Typo');

        expect(await repository.deleteProduct(id), 1);
        expect(await repository.fetchProductById(id), isNull);
      });

      test('a sold product cannot be deleted', () async {
        final id = await addProduct('Rice');
        await sellProduct(id, at: Money.fromPesos(100));

        await expectLater(
          repository.deleteProduct(id),
          throwsA(
            isA<AppFailure>().having(
              (f) => f.code,
              'code',
              'HAS_TRANSACTION_HISTORY',
            ),
          ),
        );

        // Still there, and so is the line item that references it.
        expect(await repository.fetchProductById(id), isNotNull);
        expect(await db.select(db.transactionsItemTable).get(), hasLength(1));
      });

      test('hasTransactionHistory answers correctly', () async {
        final sold = await addProduct('Rice');
        final unsold = await addProduct('Coffee');
        await sellProduct(sold, at: Money.fromPesos(100));

        expect(await repository.hasTransactionHistory(sold), isTrue);
        expect(await repository.hasTransactionHistory(unsold), isFalse);
      });
    });

    // ====================================================
    group('updating', () {
      test('a partial update leaves untouched fields alone', () async {
        final id = await addProduct(
          'Rice',
          price: Money.fromPesos(100),
          unit: 'kg',
          barcode: '4801234567890',
        );

        await repository.updateProduct(
          UpdateProductPayloadModel(
            productId: id,
            price: Money.fromPesos(110),
          ),
        );

        final product = await repository.fetchProductById(id);
        expect(product!.price, Money.fromPesos(110));
        expect(product.name, 'Rice');
        expect(product.unit, 'kg');
        expect(product.barcode, '4801234567890');
      });

      test('an update with nothing to change is not NOT_FOUND', () async {
        final id = await addProduct('Rice');

        expect(
          await repository.updateProduct(
            UpdateProductPayloadModel(productId: id),
          ),
          1,
        );
      });

      test('updating a missing product does report NOT_FOUND', () async {
        await expectLater(
          repository.updateProduct(
            UpdateProductPayloadModel(productId: 999, name: 'Ghost'),
          ),
          throwsA(
            isA<AppFailure>().having((f) => f.code, 'code', 'NOT_FOUND'),
          ),
        );
      });
    });

    /*
      Sorting is a QUERY concern — every option below is an ORDER BY in
      the datasource, never a .sort() in a widget. These tests exist
      because two of them are easy to get wrong: the active-first rule
      has to survive whatever the user picked, and every option needs
      an id tiebreaker or rows reshuffle between identical values.
    */
    group('sorting', () {
      Future<List<String>> namesSortedBy(
        ProductSort sort, {
        bool includeInactive = false,
      }) async {
        final products = await repository.fetchProducts(
          storeId,
          sort: sort,
          includeInactive: includeInactive,
        );

        return products.map((p) => p.name).toList();
      }

      test('defaults to name A–Z', () async {
        await addProduct('Sardines');
        await addProduct('Bigas');
        await addProduct('Mantika');

        // The default on the repository signature, not just the enum.
        final products = await repository.fetchProducts(storeId);

        expect(products.map((p) => p.name), ['Bigas', 'Mantika', 'Sardines']);
      });

      test('by price, both directions', () async {
        await addProduct('Bigas', price: Money.fromPesos(52.50));
        await addProduct('Sardines', price: Money.fromPesos(28));
        await addProduct('Mantika', price: Money.fromPesos(85));

        expect(await namesSortedBy(ProductSort.priceHighLow), [
          'Mantika',
          'Bigas',
          'Sardines',
        ]);
        expect(await namesSortedBy(ProductSort.priceLowHigh), [
          'Sardines',
          'Bigas',
          'Mantika',
        ]);
      });

      /*
        Drift stores createdAt as unix SECONDS, so three products added
        in one test share a timestamp. Newest-first therefore rests
        entirely on the id tiebreaker — which is the point: without it
        this order would be undefined.
      */
      test('by recency, with the id breaking a same-second tie', () async {
        await addProduct('Bigas');
        await addProduct('Sardines');
        await addProduct('Mantika');

        expect(await namesSortedBy(ProductSort.recent), [
          'Mantika',
          'Sardines',
          'Bigas',
        ]);
      });

      test('two products at the same price keep a stable order', () async {
        await addProduct('Bigas', price: Money.fromPesos(50));
        await addProduct('Sardines', price: Money.fromPesos(50));

        // Same price, so only the id separates them — and it must give
        // the same answer every time the list loads.
        expect(await namesSortedBy(ProductSort.priceHighLow), [
          'Bigas',
          'Sardines',
        ]);
        expect(await namesSortedBy(ProductSort.priceHighLow), [
          'Bigas',
          'Sardines',
        ]);
      });

      /*
        §28: a deactivated product belongs at the bottom of the list
        whatever the sort — otherwise the cheapest item in the store
        turns out to be one that can no longer be sold.
      */
      test('deactivated products sort last, whatever the sort', () async {
        final cheap = await addProduct('Bigas', price: Money.fromPesos(10));
        await addProduct('Sardines', price: Money.fromPesos(28));
        await addProduct('Mantika', price: Money.fromPesos(85));

        await repository.setActive(cheap, isActive: false);

        expect(
          await namesSortedBy(
            ProductSort.priceLowHigh,
            includeInactive: true,
          ),
          ['Sardines', 'Mantika', 'Bigas'],
        );

        expect(
          await namesSortedBy(ProductSort.name, includeInactive: true),
          ['Mantika', 'Sardines', 'Bigas'],
        );
      });

      test('sorting still respects the search filter', () async {
        await addProduct('Bigas Sinandomeng', price: Money.fromPesos(52));
        await addProduct('Bigas Dinorado', price: Money.fromPesos(60));
        await addProduct('Sardines', price: Money.fromPesos(28));

        final products = await repository.fetchProducts(
          storeId,
          search: 'bigas',
          sort: ProductSort.priceHighLow,
        );

        expect(products.map((p) => p.name), [
          'Bigas Dinorado',
          'Bigas Sinandomeng',
        ]);
      });
    });

    test('deleting a store removes its products', () async {
      await addProduct('Rice');

      await storeRepository.deleteStore(storeId);

      expect(await db.select(db.productsTable).get(), isEmpty);
    });
  });
}
