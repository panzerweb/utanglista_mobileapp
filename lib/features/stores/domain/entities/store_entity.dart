import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';

/*
  The shape the presentation layer sees.

  Two things changed from the first version, both so widgets stop doing
  work that belongs further down:

    category   a StoreCategory, not a raw String. A badge should not be
               string-matching 'retail' to pick its label.

    createdAt  a DateTime, not a preformatted String. Lists sort on it
               and the dashboard groups by it; formatting is the
               widget's job, via AppDateFormat.

  Interest settings ride along because every store has exactly one
  settings row (§3) and the store screen always needs them — fetching
  them separately would mean two queries for one card.
*/
class StoreEntity {
  final int id;
  final String name;
  final String description;
  final StoreCategory? category;
  final DateTime createdAt;

  /// §19: monthly interest is optional, per store.
  final bool monthlyInterestEnabled;
  final InterestRate monthlyInterestRate;

  const StoreEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.monthlyInterestEnabled,
    required this.monthlyInterestRate,
  });

  /*
    Interest only actually applies when it is switched on AND the rate
    is above zero. A store with interest enabled at 0% charges nothing,
    so treating it as "has interest" would promise the user a feature
    that produces no records.
  */
  bool get chargesInterest =>
      monthlyInterestEnabled && !monthlyInterestRate.isZero;

  StoreEntity copyWith({
    int? id,
    String? name,
    String? description,
    StoreCategory? category,
    DateTime? createdAt,
    bool? monthlyInterestEnabled,
    InterestRate? monthlyInterestRate,
  }) {
    return StoreEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      monthlyInterestEnabled:
          monthlyInterestEnabled ?? this.monthlyInterestEnabled,
      monthlyInterestRate: monthlyInterestRate ?? this.monthlyInterestRate,
    );
  }
}
