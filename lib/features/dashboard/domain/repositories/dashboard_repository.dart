import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/dashboard/data/datasource/dashboard_local_data_source.dart';
import 'package:utanglista_mobileapp/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utanglista_mobileapp/features/interest/domain/repositories/interest_repository.dart';
import 'package:utanglista_mobileapp/features/stores/domain/repositories/store_repository.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> fetchSummary();
}

/*
  ------------------------------------------------------------------
  Composes the dashboard from what already exists.
  ------------------------------------------------------------------

  The headline figure comes from CustomerBalanceRepository, not from a
  fourth SUM written here — CLAUDE.md's rule that there is one
  authoritative balance path applies to the dashboard most of all,
  because it is the screen where a disagreement would be visible.

  The interest nudge runs the REAL preview per store rather than a
  lookalike check, so what the dashboard promises and what the interest
  screen would do cannot drift apart.
*/
class DashboardRepositoryImplementation implements DashboardRepository {
  final DashboardLocalDataSource localDataSource;
  final CustomerBalanceRepository balanceRepository;
  final StoreRepository storeRepository;
  final InterestRepository interestRepository;

  DashboardRepositoryImplementation(
    this.localDataSource,
    this.balanceRepository,
    this.storeRepository,
    this.interestRepository,
  );

  @override
  Future<DashboardSummary> fetchSummary() {
    return repositoryGuard(() async {
      final overall = await balanceRepository.fetchTotalForAllStores();

      final summaries = await localDataSource.fetchStoreSummaries();
      final topDebtors = await localDataSource.fetchTopDebtors();
      final recentActivity = await localDataSource.fetchRecentActivity();

      return DashboardSummary(
        overall: overall,
        stores: await _withInterestNudges(summaries),
        topDebtors: topDebtors,
        recentActivity: recentActivity,
      );
    }, failureMessage: "Could not load your dashboard.");
  }

  /*
    Flags stores that still owe this month's interest run.

    One preview per store WITH interest enabled — which for a seller
    running two or three businesses is two or three queries, and for a
    seller who never turned interest on is none.

    A failure here is swallowed: an interest hint that cannot be
    computed should not take the whole dashboard down with it.
  */
  Future<List<StoreSummary>> _withInterestNudges(
    List<StoreSummary> summaries,
  ) async {
    final periodKey = AppDateFormat.periodKey(DateTime.now());
    final result = <StoreSummary>[];

    for (final summary in summaries) {
      final store = await storeRepository.fetchStoreById(summary.storeId);

      // §19: interest is optional, and enabled-at-0% charges nothing.
      if (store == null || !store.chargesInterest) {
        result.add(summary);
        continue;
      }

      try {
        final preview = await interestRepository.buildPreview(
          storeId: summary.storeId,
          periodKey: periodKey,
          rate: store.monthlyInterestRate,
        );

        result.add(summary.copyWith(interestDue: preview.hasAnythingToApply));
      } catch (_) {
        result.add(summary);
      }
    }

    return result;
  }
}
