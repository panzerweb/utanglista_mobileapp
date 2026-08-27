import 'package:drift/drift.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';

class CustomerPayloadModel {
  final int storeId;
  final String name;

  /// §4: optional. Empty or null both mean "not recorded".
  final String? contactNumber;

  CustomerPayloadModel({
    required this.storeId,
    required this.name,
    this.contactNumber,
  });

  /// Blank input is stored as NULL rather than '', so "no contact" has
  /// exactly one representation in the database.
  String? get normalisedContactNumber {
    final trimmed = contactNumber?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

/*
  ------------------------------------------------------------------
  Partial updates: absent, and cleared, are different things.
  ------------------------------------------------------------------

  Every field is nullable and null means "leave this alone" — the same
  convention as UpdateStorePayloadModel.

  That leaves no way to say "remove the contact number", because the
  clearing value IS null. So for contactNumber only:

      null   ->  leave whatever is stored
      ''     ->  clear it (writes NULL)
      '0917' ->  set it

  The form passes '' when the user empties the field, which is the one
  case that would otherwise silently do nothing.
*/
class UpdateCustomerPayloadModel {
  final int customerId;
  final String? name;
  final String? contactNumber;
  final bool? isActive;

  UpdateCustomerPayloadModel({
    required this.customerId,
    this.name,
    this.contactNumber,
    this.isActive,
  });

  CustomersTableCompanion toCompanion() {
    return CustomersTableCompanion(
      name: name == null ? const Value.absent() : Value(name!),
      contactNumber: contactNumber == null
          ? const Value.absent()
          // '' is a deliberate clear — see the note above.
          : Value(contactNumber!.trim().isEmpty ? null : contactNumber!.trim()),
      isActive: isActive == null ? const Value.absent() : Value(isActive!),
    );
  }

  /// False when there is nothing to write, so the datasource can tell
  /// "no changes" apart from "no such customer".
  bool get hasChanges =>
      name != null || contactNumber != null || isActive != null;
}
