import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';

/*
  Creating a store also creates its settings row (§3.8 of the design
  plan), so both live on one payload and the form submits once. The
  datasource writes them inside a single DB transaction — a store
  without settings would be a state nothing else in the app expects.
*/
class StorePayloadModel {
  final String name;
  final String? description;
  final StoreCategory? category;

  /// §19: optional, off by default.
  final bool monthlyInterestEnabled;
  final InterestRate monthlyInterestRate;

  StorePayloadModel({
    required this.name,
    this.description,
    this.category,
    this.monthlyInterestEnabled = false,
    this.monthlyInterestRate = InterestRate.zero,
  });

  // This getter safely returns the string or null
  // Use payload.categoryString when saving to the database.
  String? get categoryString => category?.value;
}

class UpdateStorePayloadModel {
  final int storeId;
  final String? name;
  final String? description;
  final StoreCategory? category;

  /*
    Null means "leave this setting alone", matching how the other fields
    behave. Both are supplied together by the settings form, but an edit
    that only renames the store must not silently switch interest off.
  */
  final bool? monthlyInterestEnabled;
  final InterestRate? monthlyInterestRate;

  UpdateStorePayloadModel({
    required this.storeId,
    this.name,
    this.description,
    this.category,
    this.monthlyInterestEnabled,
    this.monthlyInterestRate,
  });

  // This getter safely returns the string or null
  // Use payload.categoryString when saving to the database.
  String? get categoryString => category?.value;

  /// True when this payload touches the settings row at all.
  bool get hasSettingsChanges =>
      monthlyInterestEnabled != null || monthlyInterestRate != null;

  /*
    True when this payload touches the STORES row.

    An interest-only edit changes no store column, so `toCompanion()`
    would be entirely absent and the UPDATE would match zero rows —
    which requireRowChanged reads as "this store no longer exists".
    The datasource checks this to tell "nothing to write" apart from
    "nothing to write it to".
  */
  bool get hasStoreChanges =>
      name != null || description != null || category != null;

  StoresTableCompanion toCompanion() {
    return StoresTableCompanion(
      name: name == null ? const Value.absent() : Value(name!),
      description: description == null
          ? const Value.absent()
          : Value(description!),
      category: categoryString == null
          ? const Value.absent()
          : Value(categoryString!),
    );
  }

  StoreSettingsTableCompanion toSettingsCompanion() {
    return StoreSettingsTableCompanion(
      monthlyInterestEnabled: monthlyInterestEnabled == null
          ? const Value.absent()
          : Value(monthlyInterestEnabled!),
      monthlyInterestRateBasisPoints: monthlyInterestRate == null
          ? const Value.absent()
          : Value(monthlyInterestRate!.basisPoints),
    );
  }
}
