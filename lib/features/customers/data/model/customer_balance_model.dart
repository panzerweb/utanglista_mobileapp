import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';

/*
  The raw shape the balance query returns: three centavo sums, straight
  out of SQLite as ints.

  Unlike the other models in this app there is no `fromTable` here,
  because a balance is not a row — it is an aggregate over three tables
  (§16: the balance is derived, never stored). The transformation this
  model performs is int -> Money, which is exactly the boundary the data
  layer is supposed to own.
*/
class CustomerBalanceModel {
  final int totalUtangCentavos;
  final int totalInterestCentavos;
  final int totalPaidCentavos;

  const CustomerBalanceModel({
    required this.totalUtangCentavos,
    required this.totalInterestCentavos,
    required this.totalPaidCentavos,
  });

  CustomerBalance toEntity() {
    return CustomerBalance(
      totalUtang: Money.fromCentavos(totalUtangCentavos),
      totalInterest: Money.fromCentavos(totalInterestCentavos),
      totalPaid: Money.fromCentavos(totalPaidCentavos),
    );
  }
}
