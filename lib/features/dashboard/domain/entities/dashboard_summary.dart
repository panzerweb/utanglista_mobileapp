import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';

/*
  ------------------------------------------------------------------
  The dashboard is a READ MODEL. It owns no table and no new maths.
  ------------------------------------------------------------------

  Every figure here is the §15 balance, arrived at through the same
  formula CustomerBalance uses — just aggregated differently. The
  dashboard must never introduce a second definition of what a customer
  owes; if a number here disagrees with the store screen, one of them
  is lying and the seller cannot tell which.
*/
class StoreSummary {
  final int storeId;
  final String storeName;
  final StoreCategory? category;

  final int customerCount;

  /// How many of them actually owe something — more useful at a glance
  /// than the raw customer count.
  final int debtorCount;

  final CustomerBalance balance;

  /*
    True when this store charges interest, has something chargeable
    this month, and has not been charged yet.

    Computed by running the real interest preview rather than a
    lookalike check, so the nudge cannot disagree with what the
    interest screen would actually do.
  */
  final bool interestDue;

  const StoreSummary({
    required this.storeId,
    required this.storeName,
    required this.category,
    required this.customerCount,
    required this.debtorCount,
    required this.balance,
    this.interestDue = false,
  });

  StoreSummary copyWith({bool? interestDue}) {
    return StoreSummary(
      storeId: storeId,
      storeName: storeName,
      category: category,
      customerCount: customerCount,
      debtorCount: debtorCount,
      balance: balance,
      interestDue: interestDue ?? this.interestDue,
    );
  }
}

/// A customer who owes money, with the store they owe it to — the
/// dashboard spans stores, so the store name is never redundant here.
class TopDebtor {
  final int customerId;
  final int storeId;
  final String customerName;
  final String storeName;
  final CustomerBalance balance;

  const TopDebtor({
    required this.customerId,
    required this.storeId,
    required this.customerName,
    required this.storeName,
    required this.balance,
  });
}

enum ActivityKind { utang, payment }

/// One recent financial event, across every store.
class RecentActivity {
  final ActivityKind kind;
  final int sourceId;
  final int storeId;
  final int customerId;
  final String customerName;
  final String storeName;
  final Money amount;
  final DateTime occurredAt;

  const RecentActivity({
    required this.kind,
    required this.sourceId,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    required this.storeName,
    required this.amount,
    required this.occurredAt,
  });

  /// Utang adds, payments reduce — the §15 sign convention, per event.
  bool get isCredit => kind == ActivityKind.payment;
}

class DashboardSummary {
  /// Every store combined. §23 means no customer can be overpaid, so
  /// this equals the sum of the per-store figures.
  final CustomerBalance overall;

  final List<StoreSummary> stores;
  final List<TopDebtor> topDebtors;
  final List<RecentActivity> recentActivity;

  const DashboardSummary({
    this.overall = CustomerBalance.zero,
    this.stores = const [],
    this.topDebtors = const [],
    this.recentActivity = const [],
  });

  bool get hasStores => stores.isNotEmpty;

  Money get totalReceivable => overall.outstanding;

  int get totalCustomers =>
      stores.fold(0, (sum, store) => sum + store.customerCount);

  int get totalDebtors =>
      stores.fold(0, (sum, store) => sum + store.debtorCount);

  /// Stores that need this month's interest run.
  List<StoreSummary> get storesNeedingInterest =>
      stores.where((store) => store.interestDue).toList();
}
