import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/features/ledger/data/datasource/ledger_local_data_source.dart';
import 'package:utanglista_mobileapp/features/ledger/domain/entities/ledger_entry.dart';

/*
  The ledger is a READ MODEL. It writes nothing and owns no table —
  §17 builds it from the three event tables that already exist.

  It sits in its own feature rather than under customers because it
  spans transactions, payments and interest; putting it in any one of
  them would make that slice depend on the other two.
*/
abstract class LedgerRepository {
  /// Chronological, oldest first, with the running balance folded in.
  Future<List<LedgerRow>> fetchLedgerForCustomer(int customerId);
}

class LedgerRepositoryImplementation implements LedgerRepository {
  final LedgerLocalDataSource localDataSource;

  LedgerRepositoryImplementation(this.localDataSource);

  @override
  Future<List<LedgerRow>> fetchLedgerForCustomer(int customerId) {
    return repositoryGuard(() async {
      final entries = await localDataSource.fetchEntriesForCustomer(
        customerId,
      );

      // Ordering and the running balance are domain logic — Ledger.build
      // owns both, so the SQL never has to encode the sign convention.
      return Ledger.build(entries);
    }, failureMessage: "Could not build this customer's ledger.");
  }
}
