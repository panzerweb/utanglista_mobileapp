/*
  A person who may owe money to a store.

  Customers are STORE-SCOPED. If Juan buys from two of your stores he is
  two customer rows, each with its own ledger. That keeps every balance
  query answerable from one store's records and matches how a seller
  actually thinks about two separate businesses.

  Note what is NOT here: no balance field. §16 is explicit that the
  balance is derived from financial events and never stored on the
  customer. Read it through CustomerBalanceRepository instead.
*/
class CustomerEntity {
  final int id;
  final int storeId;
  final String name;

  /// §4: optional. null means the seller did not record one.
  final String? contactNumber;

  /*
    §29: a customer with history is deactivated, never deleted. An
    inactive customer keeps their whole financial record and stays
    visible in it, but cannot take on new utang.
  */
  final bool isActive;

  final DateTime createdAt;

  const CustomerEntity({
    required this.id,
    required this.storeId,
    required this.name,
    required this.contactNumber,
    required this.isActive,
    required this.createdAt,
  });

  bool get hasContactNumber =>
      contactNumber != null && contactNumber!.trim().isNotEmpty;

  /// The initials shown in the list avatar. Falls back to '?' rather
  /// than throwing on a name that is somehow empty.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((part) => part.isEmpty);

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  CustomerEntity copyWith({
    int? id,
    int? storeId,
    String? name,
    String? contactNumber,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      contactNumber: contactNumber ?? this.contactNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
