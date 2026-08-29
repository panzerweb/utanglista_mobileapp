import 'package:utanglista_mobileapp/core/config/app_database.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';

class CustomerModel {
  final int id;
  final int storeId;
  final String name;
  final String? contactNumber;
  final bool isActive;
  final DateTime createdAt;

  const CustomerModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.contactNumber,
    required this.isActive,
    required this.createdAt,
  });

  factory CustomerModel.fromTable(CustomersTableData customer) {
    return CustomerModel(
      id: customer.id,
      storeId: customer.storeId,
      name: customer.name,
      contactNumber: customer.contactNumber,
      isActive: customer.isActive,
      createdAt: customer.createdAt,
    );
  }

  CustomerEntity toEntity() {
    return CustomerEntity(
      id: id,
      storeId: storeId,
      name: name,
      // A contact stored as whitespace is the same as none recorded.
      contactNumber: (contactNumber?.trim().isEmpty ?? true)
          ? null
          : contactNumber!.trim(),
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
