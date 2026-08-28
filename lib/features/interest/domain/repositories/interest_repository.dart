import 'package:utanglista_mobileapp/core/constants/sort_options.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/features/interest/data/datasource/interest_local_data_source.dart';
import 'package:utanglista_mobileapp/features/interest/domain/entities/interest_preview.dart';
import 'package:utanglista_mobileapp/features/interest/domain/entities/interest_record_entity.dart';

abstract class InterestRepository {
  Future<InterestPreview> buildPreview({
    required int storeId,
    required String periodKey,
    required InterestRate rate,
  });

  Future<InterestApplicationResult> applyInterest({
    required int storeId,
    required String periodKey,
    required InterestRate rate,
  });

  Future<List<InterestRecordEntity>> fetchRecords(
    int storeId, {
    int? customerId,
    String? periodKey,
    String? search,
    InterestSort sort,
  });
}

class InterestRepositoryImplementation implements InterestRepository {
  final InterestLocalDataSource localDataSource;

  InterestRepositoryImplementation(this.localDataSource);

  // ========================================================
  // ** INTEREST METHODS **
  // ========================================================
  @override
  Future<InterestPreview> buildPreview({
    required int storeId,
    required String periodKey,
    required InterestRate rate,
  }) async {
    final failure = _validate(rate, periodKey);
    if (failure != null) throw failure;

    return repositoryGuard(
      () => localDataSource.buildPreview(
        storeId: storeId,
        periodKey: periodKey,
        rate: rate,
      ),
      failureMessage: "Could not work out this month's interest.",
    );
  }

  /*
    `async` for the same reason as createTransaction: a synchronous
    throw before the Future is returned never reaches the caller's
    .catchError.
  */
  @override
  Future<InterestApplicationResult> applyInterest({
    required int storeId,
    required String periodKey,
    required InterestRate rate,
  }) async {
    final failure = _validate(rate, periodKey);
    if (failure != null) throw failure;

    return repositoryGuard(
      () => localDataSource.applyInterest(
        storeId: storeId,
        periodKey: periodKey,
        rate: rate,
      ),
      failureMessage: "Could not apply this month's interest.",
    );
  }

  @override
  Future<List<InterestRecordEntity>> fetchRecords(
    int storeId, {
    int? customerId,
    String? periodKey,
    String? search,
    InterestSort sort = InterestSort.newestPeriod,
  }) {
    return repositoryGuard(
      () => localDataSource.fetchRecords(
        storeId,
        customerId: customerId,
        periodKey: periodKey,
        search: search,
        sort: sort,
      ),
      failureMessage: "Could not load interest history.",
    );
  }

  // ========================================================

  AppFailure? _validate(InterestRate rate, String periodKey) {
    /*
      §19: 0%-5%. Checked here as well as in the store form because a
      rate that slipped through would be written onto every interest
      record it produced — and §21 makes those permanent.
    */
    if (!rate.isValid) {
      return AppFailure(
        code: 'INVALID_INTEREST_RATE',
        message:
            'Monthly interest must be between 0% and '
            '${InterestRate.maximum.formatPercent()}.',
      );
    }

    // A zero rate charges nothing; applying it would write nothing and
    // report success, which reads as a failure to the seller.
    if (rate.isZero) {
      return AppFailure(
        code: 'ZERO_INTEREST_RATE',
        message:
            'This store\'s interest rate is 0%, so there is nothing to '
            'charge. Set a rate in the store settings first.',
      );
    }

    // §22's guard is the period key. A malformed one would let the
    // unique index be sidestepped and interest applied twice.
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(periodKey)) {
      return AppFailure(
        code: 'INVALID_PERIOD',
        message: 'That month is not valid.',
      );
    }

    return null;
  }
}
