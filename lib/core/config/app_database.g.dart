// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StoresTableTable extends StoresTable
    with TableInfo<$StoresTableTable, StoresTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoresTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    category,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stores_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoresTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoresTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoresTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $StoresTableTable createAlias(String alias) {
    return $StoresTableTable(attachedDatabase, alias);
  }
}

class StoresTableData extends DataClass implements Insertable<StoresTableData> {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final DateTime? createdAt;
  const StoresTableData({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  StoresTableCompanion toCompanion(bool nullToAbsent) {
    return StoresTableCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory StoresTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoresTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String?>(json['category']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String?>(category),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  StoresTableData copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => StoresTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    category: category.present ? category.value : this.category,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  StoresTableData copyWithCompanion(StoresTableCompanion data) {
    return StoresTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoresTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, category, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoresTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.createdAt == this.createdAt);
}

class StoresTableCompanion extends UpdateCompanion<StoresTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> category;
  final Value<DateTime?> createdAt;
  const StoresTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StoresTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<StoresTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StoresTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? category,
    Value<DateTime?>? createdAt,
  }) {
    return StoresTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoresTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CustomersTableTable extends CustomersTable
    with TableInfo<$CustomersTableTable, CustomersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<int> storeId = GeneratedColumn<int>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactNumberMeta = const VerificationMeta(
    'contactNumber',
  );
  @override
  late final GeneratedColumn<String> contactNumber = GeneratedColumn<String>(
    'contact_number',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 12),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    name,
    contactNumber,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('contact_number')) {
      context.handle(
        _contactNumberMeta,
        contactNumber.isAcceptableOrUnknown(
          data['contact_number']!,
          _contactNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactNumberMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}store_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      contactNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_number'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $CustomersTableTable createAlias(String alias) {
    return $CustomersTableTable(attachedDatabase, alias);
  }
}

class CustomersTableData extends DataClass
    implements Insertable<CustomersTableData> {
  final int id;
  final int storeId;
  final String name;
  final String contactNumber;
  final bool isActive;
  final DateTime? createdAt;
  const CustomersTableData({
    required this.id,
    required this.storeId,
    required this.name,
    required this.contactNumber,
    required this.isActive,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<int>(storeId);
    map['name'] = Variable<String>(name);
    map['contact_number'] = Variable<String>(contactNumber);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  CustomersTableCompanion toCompanion(bool nullToAbsent) {
    return CustomersTableCompanion(
      id: Value(id),
      storeId: Value(storeId),
      name: Value(name),
      contactNumber: Value(contactNumber),
      isActive: Value(isActive),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory CustomersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomersTableData(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<int>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      contactNumber: serializer.fromJson<String>(json['contactNumber']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storeId': serializer.toJson<int>(storeId),
      'name': serializer.toJson<String>(name),
      'contactNumber': serializer.toJson<String>(contactNumber),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  CustomersTableData copyWith({
    int? id,
    int? storeId,
    String? name,
    String? contactNumber,
    bool? isActive,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => CustomersTableData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    name: name ?? this.name,
    contactNumber: contactNumber ?? this.contactNumber,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  CustomersTableData copyWithCompanion(CustomersTableCompanion data) {
    return CustomersTableData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      contactNumber: data.contactNumber.present
          ? data.contactNumber.value
          : this.contactNumber,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storeId, name, contactNumber, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomersTableData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.contactNumber == this.contactNumber &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class CustomersTableCompanion extends UpdateCompanion<CustomersTableData> {
  final Value<int> id;
  final Value<int> storeId;
  final Value<String> name;
  final Value<String> contactNumber;
  final Value<bool> isActive;
  final Value<DateTime?> createdAt;
  const CustomersTableCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.contactNumber = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomersTableCompanion.insert({
    this.id = const Value.absent(),
    required int storeId,
    required String name,
    required String contactNumber,
    required bool isActive,
    this.createdAt = const Value.absent(),
  }) : storeId = Value(storeId),
       name = Value(name),
       contactNumber = Value(contactNumber),
       isActive = Value(isActive);
  static Insertable<CustomersTableData> custom({
    Expression<int>? id,
    Expression<int>? storeId,
    Expression<String>? name,
    Expression<String>? contactNumber,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomersTableCompanion copyWith({
    Value<int>? id,
    Value<int>? storeId,
    Value<String>? name,
    Value<String>? contactNumber,
    Value<bool>? isActive,
    Value<DateTime?>? createdAt,
  }) {
    return CustomersTableCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      contactNumber: contactNumber ?? this.contactNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<int>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contactNumber.present) {
      map['contact_number'] = Variable<String>(contactNumber.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersTableCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<int> storeId = GeneratedColumn<int>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    name,
    description,
    price,
    unit,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}store_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductsTableData extends DataClass
    implements Insertable<ProductsTableData> {
  final int id;
  final int storeId;
  final String name;
  final String? description;
  final double price;
  final String unit;
  final bool isActive;
  final DateTime? createdAt;
  const ProductsTableData({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    required this.price,
    required this.unit,
    required this.isActive,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<int>(storeId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['price'] = Variable<double>(price);
    map['unit'] = Variable<String>(unit);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      storeId: Value(storeId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      price: Value(price),
      unit: Value(unit),
      isActive: Value(isActive),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory ProductsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsTableData(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<int>(json['storeId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      price: serializer.fromJson<double>(json['price']),
      unit: serializer.fromJson<String>(json['unit']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storeId': serializer.toJson<int>(storeId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'price': serializer.toJson<double>(price),
      'unit': serializer.toJson<String>(unit),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  ProductsTableData copyWith({
    int? id,
    int? storeId,
    String? name,
    Value<String?> description = const Value.absent(),
    double? price,
    String? unit,
    bool? isActive,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => ProductsTableData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    price: price ?? this.price,
    unit: unit ?? this.unit,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  ProductsTableData copyWithCompanion(ProductsTableCompanion data) {
    return ProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      price: data.price.present ? data.price.value : this.price,
      unit: data.unit.present ? data.unit.value : this.unit,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('unit: $unit, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    name,
    description,
    price,
    unit,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsTableData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.unit == this.unit &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class ProductsTableCompanion extends UpdateCompanion<ProductsTableData> {
  final Value<int> id;
  final Value<int> storeId;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> price;
  final Value<String> unit;
  final Value<bool> isActive;
  final Value<DateTime?> createdAt;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.unit = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    this.id = const Value.absent(),
    required int storeId,
    required String name,
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    required String unit,
    required bool isActive,
    this.createdAt = const Value.absent(),
  }) : storeId = Value(storeId),
       name = Value(name),
       unit = Value(unit),
       isActive = Value(isActive);
  static Insertable<ProductsTableData> custom({
    Expression<int>? id,
    Expression<int>? storeId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? price,
    Expression<String>? unit,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (unit != null) 'unit': unit,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProductsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? storeId,
    Value<String>? name,
    Value<String?>? description,
    Value<double>? price,
    Value<String>? unit,
    Value<bool>? isActive,
    Value<DateTime?>? createdAt,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<int>(storeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('unit: $unit, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTableTable extends TransactionsTable
    with TableInfo<$TransactionsTableTable, TransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<int> storeId = GeneratedColumn<int>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    customerId,
    totalAmount,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}store_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}customer_id'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $TransactionsTableTable createAlias(String alias) {
    return $TransactionsTableTable(attachedDatabase, alias);
  }
}

class TransactionsTableData extends DataClass
    implements Insertable<TransactionsTableData> {
  final int id;
  final int storeId;
  final int customerId;
  final double totalAmount;
  final String? note;
  final DateTime? createdAt;
  const TransactionsTableData({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.totalAmount,
    this.note,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<int>(storeId);
    map['customer_id'] = Variable<int>(customerId);
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  TransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsTableCompanion(
      id: Value(id),
      storeId: Value(storeId),
      customerId: Value(customerId),
      totalAmount: Value(totalAmount),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory TransactionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsTableData(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<int>(json['storeId']),
      customerId: serializer.fromJson<int>(json['customerId']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storeId': serializer.toJson<int>(storeId),
      'customerId': serializer.toJson<int>(customerId),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  TransactionsTableData copyWith({
    int? id,
    int? storeId,
    int? customerId,
    double? totalAmount,
    Value<String?> note = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => TransactionsTableData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    customerId: customerId ?? this.customerId,
    totalAmount: totalAmount ?? this.totalAmount,
    note: note.present ? note.value : this.note,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  TransactionsTableData copyWithCompanion(TransactionsTableCompanion data) {
    return TransactionsTableData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('customerId: $customerId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storeId, customerId, totalAmount, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsTableData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.customerId == this.customerId &&
          other.totalAmount == this.totalAmount &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class TransactionsTableCompanion
    extends UpdateCompanion<TransactionsTableData> {
  final Value<int> id;
  final Value<int> storeId;
  final Value<int> customerId;
  final Value<double> totalAmount;
  final Value<String?> note;
  final Value<DateTime?> createdAt;
  const TransactionsTableCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransactionsTableCompanion.insert({
    this.id = const Value.absent(),
    required int storeId,
    required int customerId,
    this.totalAmount = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : storeId = Value(storeId),
       customerId = Value(customerId);
  static Insertable<TransactionsTableData> custom({
    Expression<int>? id,
    Expression<int>? storeId,
    Expression<int>? customerId,
    Expression<double>? totalAmount,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (customerId != null) 'customer_id': customerId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransactionsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? storeId,
    Value<int>? customerId,
    Value<double>? totalAmount,
    Value<String?>? note,
    Value<DateTime?>? createdAt,
  }) {
    return TransactionsTableCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      customerId: customerId ?? this.customerId,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<int>(storeId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('customerId: $customerId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsItemTableTable extends TransactionsItemTable
    with TableInfo<$TransactionsItemTableTable, TransactionsItemTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsItemTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _subTotalMeta = const VerificationMeta(
    'subTotal',
  );
  @override
  late final GeneratedColumn<double> subTotal = GeneratedColumn<double>(
    'sub_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    productId,
    quantity,
    unitPrice,
    subTotal,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions_item_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionsItemTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('sub_total')) {
      context.handle(
        _subTotalMeta,
        subTotal.isAcceptableOrUnknown(data['sub_total']!, _subTotalMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsItemTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionsItemTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      subTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sub_total'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $TransactionsItemTableTable createAlias(String alias) {
    return $TransactionsItemTableTable(attachedDatabase, alias);
  }
}

class TransactionsItemTableData extends DataClass
    implements Insertable<TransactionsItemTableData> {
  final int id;
  final int transactionId;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double subTotal;
  final DateTime? createdAt;
  const TransactionsItemTableData({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subTotal,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_id'] = Variable<int>(transactionId);
    map['product_id'] = Variable<int>(productId);
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['sub_total'] = Variable<double>(subTotal);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  TransactionsItemTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsItemTableCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      productId: Value(productId),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      subTotal: Value(subTotal),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory TransactionsItemTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsItemTableData(
      id: serializer.fromJson<int>(json['id']),
      transactionId: serializer.fromJson<int>(json['transactionId']),
      productId: serializer.fromJson<int>(json['productId']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      subTotal: serializer.fromJson<double>(json['subTotal']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionId': serializer.toJson<int>(transactionId),
      'productId': serializer.toJson<int>(productId),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'subTotal': serializer.toJson<double>(subTotal),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  TransactionsItemTableData copyWith({
    int? id,
    int? transactionId,
    int? productId,
    double? quantity,
    double? unitPrice,
    double? subTotal,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => TransactionsItemTableData(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    subTotal: subTotal ?? this.subTotal,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  TransactionsItemTableData copyWithCompanion(
    TransactionsItemTableCompanion data,
  ) {
    return TransactionsItemTableData(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      subTotal: data.subTotal.present ? data.subTotal.value : this.subTotal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsItemTableData(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('subTotal: $subTotal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    productId,
    quantity,
    unitPrice,
    subTotal,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsItemTableData &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.subTotal == this.subTotal &&
          other.createdAt == this.createdAt);
}

class TransactionsItemTableCompanion
    extends UpdateCompanion<TransactionsItemTableData> {
  final Value<int> id;
  final Value<int> transactionId;
  final Value<int> productId;
  final Value<double> quantity;
  final Value<double> unitPrice;
  final Value<double> subTotal;
  final Value<DateTime?> createdAt;
  const TransactionsItemTableCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.subTotal = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransactionsItemTableCompanion.insert({
    this.id = const Value.absent(),
    required int transactionId,
    required int productId,
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.subTotal = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : transactionId = Value(transactionId),
       productId = Value(productId);
  static Insertable<TransactionsItemTableData> custom({
    Expression<int>? id,
    Expression<int>? transactionId,
    Expression<int>? productId,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? subTotal,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (subTotal != null) 'sub_total': subTotal,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransactionsItemTableCompanion copyWith({
    Value<int>? id,
    Value<int>? transactionId,
    Value<int>? productId,
    Value<double>? quantity,
    Value<double>? unitPrice,
    Value<double>? subTotal,
    Value<DateTime?>? createdAt,
  }) {
    return TransactionsItemTableCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subTotal: subTotal ?? this.subTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (subTotal.present) {
      map['sub_total'] = Variable<double>(subTotal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsItemTableCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('subTotal: $subTotal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTableTable extends PaymentsTable
    with TableInfo<$PaymentsTableTable, PaymentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<int> storeId = GeneratedColumn<int>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    customerId,
    amount,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}store_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}customer_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $PaymentsTableTable createAlias(String alias) {
    return $PaymentsTableTable(attachedDatabase, alias);
  }
}

class PaymentsTableData extends DataClass
    implements Insertable<PaymentsTableData> {
  final int id;
  final int storeId;
  final int customerId;
  final double amount;
  final String? note;
  final DateTime? createdAt;
  const PaymentsTableData({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.amount,
    this.note,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<int>(storeId);
    map['customer_id'] = Variable<int>(customerId);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  PaymentsTableCompanion toCompanion(bool nullToAbsent) {
    return PaymentsTableCompanion(
      id: Value(id),
      storeId: Value(storeId),
      customerId: Value(customerId),
      amount: Value(amount),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory PaymentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentsTableData(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<int>(json['storeId']),
      customerId: serializer.fromJson<int>(json['customerId']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storeId': serializer.toJson<int>(storeId),
      'customerId': serializer.toJson<int>(customerId),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  PaymentsTableData copyWith({
    int? id,
    int? storeId,
    int? customerId,
    double? amount,
    Value<String?> note = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => PaymentsTableData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    customerId: customerId ?? this.customerId,
    amount: amount ?? this.amount,
    note: note.present ? note.value : this.note,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  PaymentsTableData copyWithCompanion(PaymentsTableCompanion data) {
    return PaymentsTableData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsTableData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('customerId: $customerId, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storeId, customerId, amount, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentsTableData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.customerId == this.customerId &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class PaymentsTableCompanion extends UpdateCompanion<PaymentsTableData> {
  final Value<int> id;
  final Value<int> storeId;
  final Value<int> customerId;
  final Value<double> amount;
  final Value<String?> note;
  final Value<DateTime?> createdAt;
  const PaymentsTableCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PaymentsTableCompanion.insert({
    this.id = const Value.absent(),
    required int storeId,
    required int customerId,
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : storeId = Value(storeId),
       customerId = Value(customerId);
  static Insertable<PaymentsTableData> custom({
    Expression<int>? id,
    Expression<int>? storeId,
    Expression<int>? customerId,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (customerId != null) 'customer_id': customerId,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PaymentsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? storeId,
    Value<int>? customerId,
    Value<double>? amount,
    Value<String?>? note,
    Value<DateTime?>? createdAt,
  }) {
    return PaymentsTableCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<int>(storeId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsTableCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('customerId: $customerId, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StoreSettingsTableTable extends StoreSettingsTable
    with TableInfo<$StoreSettingsTableTable, StoreSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<int> storeId = GeneratedColumn<int>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _monthlyInterestEnabledMeta =
      const VerificationMeta('monthlyInterestEnabled');
  @override
  late final GeneratedColumn<bool> monthlyInterestEnabled =
      GeneratedColumn<bool>(
        'monthly_interest_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("monthly_interest_enabled" IN (0, 1))',
        ),
        clientDefault: () => false,
      );
  static const VerificationMeta _monthlyInterestRateMeta =
      const VerificationMeta('monthlyInterestRate');
  @override
  late final GeneratedColumn<double> monthlyInterestRate =
      GeneratedColumn<double>(
        'monthly_interest_rate',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        clientDefault: () => 0.0,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    monthlyInterestEnabled,
    monthlyInterestRate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoreSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('monthly_interest_enabled')) {
      context.handle(
        _monthlyInterestEnabledMeta,
        monthlyInterestEnabled.isAcceptableOrUnknown(
          data['monthly_interest_enabled']!,
          _monthlyInterestEnabledMeta,
        ),
      );
    }
    if (data.containsKey('monthly_interest_rate')) {
      context.handle(
        _monthlyInterestRateMeta,
        monthlyInterestRate.isAcceptableOrUnknown(
          data['monthly_interest_rate']!,
          _monthlyInterestRateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoreSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}store_id'],
      )!,
      monthlyInterestEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}monthly_interest_enabled'],
      )!,
      monthlyInterestRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_interest_rate'],
      )!,
    );
  }

  @override
  $StoreSettingsTableTable createAlias(String alias) {
    return $StoreSettingsTableTable(attachedDatabase, alias);
  }
}

class StoreSettingsTableData extends DataClass
    implements Insertable<StoreSettingsTableData> {
  final int id;
  final int storeId;
  final bool monthlyInterestEnabled;
  final double monthlyInterestRate;
  const StoreSettingsTableData({
    required this.id,
    required this.storeId,
    required this.monthlyInterestEnabled,
    required this.monthlyInterestRate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<int>(storeId);
    map['monthly_interest_enabled'] = Variable<bool>(monthlyInterestEnabled);
    map['monthly_interest_rate'] = Variable<double>(monthlyInterestRate);
    return map;
  }

  StoreSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return StoreSettingsTableCompanion(
      id: Value(id),
      storeId: Value(storeId),
      monthlyInterestEnabled: Value(monthlyInterestEnabled),
      monthlyInterestRate: Value(monthlyInterestRate),
    );
  }

  factory StoreSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<int>(json['storeId']),
      monthlyInterestEnabled: serializer.fromJson<bool>(
        json['monthlyInterestEnabled'],
      ),
      monthlyInterestRate: serializer.fromJson<double>(
        json['monthlyInterestRate'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storeId': serializer.toJson<int>(storeId),
      'monthlyInterestEnabled': serializer.toJson<bool>(monthlyInterestEnabled),
      'monthlyInterestRate': serializer.toJson<double>(monthlyInterestRate),
    };
  }

  StoreSettingsTableData copyWith({
    int? id,
    int? storeId,
    bool? monthlyInterestEnabled,
    double? monthlyInterestRate,
  }) => StoreSettingsTableData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    monthlyInterestEnabled:
        monthlyInterestEnabled ?? this.monthlyInterestEnabled,
    monthlyInterestRate: monthlyInterestRate ?? this.monthlyInterestRate,
  );
  StoreSettingsTableData copyWithCompanion(StoreSettingsTableCompanion data) {
    return StoreSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      monthlyInterestEnabled: data.monthlyInterestEnabled.present
          ? data.monthlyInterestEnabled.value
          : this.monthlyInterestEnabled,
      monthlyInterestRate: data.monthlyInterestRate.present
          ? data.monthlyInterestRate.value
          : this.monthlyInterestRate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreSettingsTableData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('monthlyInterestEnabled: $monthlyInterestEnabled, ')
          ..write('monthlyInterestRate: $monthlyInterestRate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storeId, monthlyInterestEnabled, monthlyInterestRate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreSettingsTableData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.monthlyInterestEnabled == this.monthlyInterestEnabled &&
          other.monthlyInterestRate == this.monthlyInterestRate);
}

class StoreSettingsTableCompanion
    extends UpdateCompanion<StoreSettingsTableData> {
  final Value<int> id;
  final Value<int> storeId;
  final Value<bool> monthlyInterestEnabled;
  final Value<double> monthlyInterestRate;
  const StoreSettingsTableCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.monthlyInterestEnabled = const Value.absent(),
    this.monthlyInterestRate = const Value.absent(),
  });
  StoreSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required int storeId,
    this.monthlyInterestEnabled = const Value.absent(),
    this.monthlyInterestRate = const Value.absent(),
  }) : storeId = Value(storeId);
  static Insertable<StoreSettingsTableData> custom({
    Expression<int>? id,
    Expression<int>? storeId,
    Expression<bool>? monthlyInterestEnabled,
    Expression<double>? monthlyInterestRate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (monthlyInterestEnabled != null)
        'monthly_interest_enabled': monthlyInterestEnabled,
      if (monthlyInterestRate != null)
        'monthly_interest_rate': monthlyInterestRate,
    });
  }

  StoreSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? storeId,
    Value<bool>? monthlyInterestEnabled,
    Value<double>? monthlyInterestRate,
  }) {
    return StoreSettingsTableCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      monthlyInterestEnabled:
          monthlyInterestEnabled ?? this.monthlyInterestEnabled,
      monthlyInterestRate: monthlyInterestRate ?? this.monthlyInterestRate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<int>(storeId.value);
    }
    if (monthlyInterestEnabled.present) {
      map['monthly_interest_enabled'] = Variable<bool>(
        monthlyInterestEnabled.value,
      );
    }
    if (monthlyInterestRate.present) {
      map['monthly_interest_rate'] = Variable<double>(
        monthlyInterestRate.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('monthlyInterestEnabled: $monthlyInterestEnabled, ')
          ..write('monthlyInterestRate: $monthlyInterestRate')
          ..write(')'))
        .toString();
  }
}

class $InterestRecordsTableTable extends InterestRecordsTable
    with TableInfo<$InterestRecordsTableTable, InterestRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InterestRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<int> storeId = GeneratedColumn<int>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES customers_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _baseAmountMeta = const VerificationMeta(
    'baseAmount',
  );
  @override
  late final GeneratedColumn<double> baseAmount = GeneratedColumn<double>(
    'base_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _interestAmountMeta = const VerificationMeta(
    'interestAmount',
  );
  @override
  late final GeneratedColumn<double> interestAmount = GeneratedColumn<double>(
    'interest_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    clientDefault: () => 0.0,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    customerId,
    rate,
    baseAmount,
    interestAmount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'interest_records_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<InterestRecordsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    }
    if (data.containsKey('base_amount')) {
      context.handle(
        _baseAmountMeta,
        baseAmount.isAcceptableOrUnknown(data['base_amount']!, _baseAmountMeta),
      );
    }
    if (data.containsKey('interest_amount')) {
      context.handle(
        _interestAmountMeta,
        interestAmount.isAcceptableOrUnknown(
          data['interest_amount']!,
          _interestAmountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InterestRecordsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InterestRecordsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}store_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}customer_id'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate'],
      )!,
      baseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_amount'],
      )!,
      interestAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_amount'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $InterestRecordsTableTable createAlias(String alias) {
    return $InterestRecordsTableTable(attachedDatabase, alias);
  }
}

class InterestRecordsTableData extends DataClass
    implements Insertable<InterestRecordsTableData> {
  final int id;
  final int storeId;
  final int customerId;
  final double rate;
  final double baseAmount;
  final double interestAmount;
  final DateTime? createdAt;
  const InterestRecordsTableData({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.rate,
    required this.baseAmount,
    required this.interestAmount,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<int>(storeId);
    map['customer_id'] = Variable<int>(customerId);
    map['rate'] = Variable<double>(rate);
    map['base_amount'] = Variable<double>(baseAmount);
    map['interest_amount'] = Variable<double>(interestAmount);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  InterestRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return InterestRecordsTableCompanion(
      id: Value(id),
      storeId: Value(storeId),
      customerId: Value(customerId),
      rate: Value(rate),
      baseAmount: Value(baseAmount),
      interestAmount: Value(interestAmount),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory InterestRecordsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InterestRecordsTableData(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<int>(json['storeId']),
      customerId: serializer.fromJson<int>(json['customerId']),
      rate: serializer.fromJson<double>(json['rate']),
      baseAmount: serializer.fromJson<double>(json['baseAmount']),
      interestAmount: serializer.fromJson<double>(json['interestAmount']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storeId': serializer.toJson<int>(storeId),
      'customerId': serializer.toJson<int>(customerId),
      'rate': serializer.toJson<double>(rate),
      'baseAmount': serializer.toJson<double>(baseAmount),
      'interestAmount': serializer.toJson<double>(interestAmount),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  InterestRecordsTableData copyWith({
    int? id,
    int? storeId,
    int? customerId,
    double? rate,
    double? baseAmount,
    double? interestAmount,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => InterestRecordsTableData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    customerId: customerId ?? this.customerId,
    rate: rate ?? this.rate,
    baseAmount: baseAmount ?? this.baseAmount,
    interestAmount: interestAmount ?? this.interestAmount,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  InterestRecordsTableData copyWithCompanion(
    InterestRecordsTableCompanion data,
  ) {
    return InterestRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      rate: data.rate.present ? data.rate.value : this.rate,
      baseAmount: data.baseAmount.present
          ? data.baseAmount.value
          : this.baseAmount,
      interestAmount: data.interestAmount.present
          ? data.interestAmount.value
          : this.interestAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InterestRecordsTableData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('customerId: $customerId, ')
          ..write('rate: $rate, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('interestAmount: $interestAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    customerId,
    rate,
    baseAmount,
    interestAmount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InterestRecordsTableData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.customerId == this.customerId &&
          other.rate == this.rate &&
          other.baseAmount == this.baseAmount &&
          other.interestAmount == this.interestAmount &&
          other.createdAt == this.createdAt);
}

class InterestRecordsTableCompanion
    extends UpdateCompanion<InterestRecordsTableData> {
  final Value<int> id;
  final Value<int> storeId;
  final Value<int> customerId;
  final Value<double> rate;
  final Value<double> baseAmount;
  final Value<double> interestAmount;
  final Value<DateTime?> createdAt;
  const InterestRecordsTableCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.rate = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.interestAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InterestRecordsTableCompanion.insert({
    this.id = const Value.absent(),
    required int storeId,
    required int customerId,
    this.rate = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.interestAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : storeId = Value(storeId),
       customerId = Value(customerId);
  static Insertable<InterestRecordsTableData> custom({
    Expression<int>? id,
    Expression<int>? storeId,
    Expression<int>? customerId,
    Expression<double>? rate,
    Expression<double>? baseAmount,
    Expression<double>? interestAmount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (customerId != null) 'customer_id': customerId,
      if (rate != null) 'rate': rate,
      if (baseAmount != null) 'base_amount': baseAmount,
      if (interestAmount != null) 'interest_amount': interestAmount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InterestRecordsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? storeId,
    Value<int>? customerId,
    Value<double>? rate,
    Value<double>? baseAmount,
    Value<double>? interestAmount,
    Value<DateTime?>? createdAt,
  }) {
    return InterestRecordsTableCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      customerId: customerId ?? this.customerId,
      rate: rate ?? this.rate,
      baseAmount: baseAmount ?? this.baseAmount,
      interestAmount: interestAmount ?? this.interestAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<int>(storeId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (baseAmount.present) {
      map['base_amount'] = Variable<double>(baseAmount.value);
    }
    if (interestAmount.present) {
      map['interest_amount'] = Variable<double>(interestAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InterestRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('customerId: $customerId, ')
          ..write('rate: $rate, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('interestAmount: $interestAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StoresTableTable storesTable = $StoresTableTable(this);
  late final $CustomersTableTable customersTable = $CustomersTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $TransactionsItemTableTable transactionsItemTable =
      $TransactionsItemTableTable(this);
  late final $PaymentsTableTable paymentsTable = $PaymentsTableTable(this);
  late final $StoreSettingsTableTable storeSettingsTable =
      $StoreSettingsTableTable(this);
  late final $InterestRecordsTableTable interestRecordsTable =
      $InterestRecordsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    storesTable,
    customersTable,
    productsTable,
    transactionsTable,
    transactionsItemTable,
    paymentsTable,
    storeSettingsTable,
    interestRecordsTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stores_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('customers_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stores_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('products_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stores_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'customers_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions_item_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions_item_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stores_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payments_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'customers_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payments_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stores_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('store_settings_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stores_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('interest_records_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'customers_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('interest_records_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$StoresTableTableCreateCompanionBuilder =
    StoresTableCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<String?> category,
      Value<DateTime?> createdAt,
    });
typedef $$StoresTableTableUpdateCompanionBuilder =
    StoresTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> category,
      Value<DateTime?> createdAt,
    });

final class $$StoresTableTableReferences
    extends BaseReferences<_$AppDatabase, $StoresTableTable, StoresTableData> {
  $$StoresTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CustomersTableTable, List<CustomersTableData>>
  _customersTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customersTable,
    aliasName: 'stores_table__id__customers_table__store_id',
  );

  $$CustomersTableTableProcessedTableManager get customersTableRefs {
    final manager = $$CustomersTableTableTableManager(
      $_db,
      $_db.customersTable,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_customersTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProductsTableTable, List<ProductsTableData>>
  _productsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productsTable,
    aliasName: 'stores_table__id__products_table__store_id',
  );

  $$ProductsTableTableProcessedTableManager get productsTableRefs {
    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TransactionsTableTable,
    List<TransactionsTableData>
  >
  _transactionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionsTable,
        aliasName: 'stores_table__id__transactions_table__store_id',
      );

  $$TransactionsTableTableProcessedTableManager get transactionsTableRefs {
    final manager = $$TransactionsTableTableTableManager(
      $_db,
      $_db.transactionsTable,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentsTableTable, List<PaymentsTableData>>
  _paymentsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.paymentsTable,
    aliasName: 'stores_table__id__payments_table__store_id',
  );

  $$PaymentsTableTableProcessedTableManager get paymentsTableRefs {
    final manager = $$PaymentsTableTableTableManager(
      $_db,
      $_db.paymentsTable,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $StoreSettingsTableTable,
    List<StoreSettingsTableData>
  >
  _storeSettingsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.storeSettingsTable,
        aliasName: 'stores_table__id__store_settings_table__store_id',
      );

  $$StoreSettingsTableTableProcessedTableManager get storeSettingsTableRefs {
    final manager = $$StoreSettingsTableTableTableManager(
      $_db,
      $_db.storeSettingsTable,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _storeSettingsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $InterestRecordsTableTable,
    List<InterestRecordsTableData>
  >
  _interestRecordsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.interestRecordsTable,
        aliasName: 'stores_table__id__interest_records_table__store_id',
      );

  $$InterestRecordsTableTableProcessedTableManager
  get interestRecordsTableRefs {
    final manager = $$InterestRecordsTableTableTableManager(
      $_db,
      $_db.interestRecordsTable,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _interestRecordsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoresTableTableFilterComposer
    extends Composer<_$AppDatabase, $StoresTableTable> {
  $$StoresTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> customersTableRefs(
    Expression<bool> Function($$CustomersTableTableFilterComposer f) f,
  ) {
    final $$CustomersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableFilterComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> productsTableRefs(
    Expression<bool> Function($$ProductsTableTableFilterComposer f) f,
  ) {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsTableRefs(
    Expression<bool> Function($$TransactionsTableTableFilterComposer f) f,
  ) {
    final $$TransactionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionsTable,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableTableFilterComposer(
            $db: $db,
            $table: $db.transactionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentsTableRefs(
    Expression<bool> Function($$PaymentsTableTableFilterComposer f) f,
  ) {
    final $$PaymentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paymentsTable,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableTableFilterComposer(
            $db: $db,
            $table: $db.paymentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storeSettingsTableRefs(
    Expression<bool> Function($$StoreSettingsTableTableFilterComposer f) f,
  ) {
    final $$StoreSettingsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storeSettingsTable,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoreSettingsTableTableFilterComposer(
            $db: $db,
            $table: $db.storeSettingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> interestRecordsTableRefs(
    Expression<bool> Function($$InterestRecordsTableTableFilterComposer f) f,
  ) {
    final $$InterestRecordsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.interestRecordsTable,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InterestRecordsTableTableFilterComposer(
            $db: $db,
            $table: $db.interestRecordsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoresTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StoresTableTable> {
  $$StoresTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoresTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoresTableTable> {
  $$StoresTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> customersTableRefs<T extends Object>(
    Expression<T> Function($$CustomersTableTableAnnotationComposer a) f,
  ) {
    final $$CustomersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> productsTableRefs<T extends Object>(
    Expression<T> Function($$ProductsTableTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsTableRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionsTable,
          getReferencedColumn: (t) => t.storeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> paymentsTableRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paymentsTable,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storeSettingsTableRefs<T extends Object>(
    Expression<T> Function($$StoreSettingsTableTableAnnotationComposer a) f,
  ) {
    final $$StoreSettingsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.storeSettingsTable,
          getReferencedColumn: (t) => t.storeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StoreSettingsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.storeSettingsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> interestRecordsTableRefs<T extends Object>(
    Expression<T> Function($$InterestRecordsTableTableAnnotationComposer a) f,
  ) {
    final $$InterestRecordsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.interestRecordsTable,
          getReferencedColumn: (t) => t.storeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InterestRecordsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.interestRecordsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StoresTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoresTableTable,
          StoresTableData,
          $$StoresTableTableFilterComposer,
          $$StoresTableTableOrderingComposer,
          $$StoresTableTableAnnotationComposer,
          $$StoresTableTableCreateCompanionBuilder,
          $$StoresTableTableUpdateCompanionBuilder,
          (StoresTableData, $$StoresTableTableReferences),
          StoresTableData,
          PrefetchHooks Function({
            bool customersTableRefs,
            bool productsTableRefs,
            bool transactionsTableRefs,
            bool paymentsTableRefs,
            bool storeSettingsTableRefs,
            bool interestRecordsTableRefs,
          })
        > {
  $$StoresTableTableTableManager(_$AppDatabase db, $StoresTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoresTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoresTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoresTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => StoresTableCompanion(
                id: id,
                name: name,
                description: description,
                category: category,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => StoresTableCompanion.insert(
                id: id,
                name: name,
                description: description,
                category: category,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoresTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                customersTableRefs = false,
                productsTableRefs = false,
                transactionsTableRefs = false,
                paymentsTableRefs = false,
                storeSettingsTableRefs = false,
                interestRecordsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (customersTableRefs) db.customersTable,
                    if (productsTableRefs) db.productsTable,
                    if (transactionsTableRefs) db.transactionsTable,
                    if (paymentsTableRefs) db.paymentsTable,
                    if (storeSettingsTableRefs) db.storeSettingsTable,
                    if (interestRecordsTableRefs) db.interestRecordsTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (customersTableRefs)
                        await $_getPrefetchedData<
                          StoresTableData,
                          $StoresTableTable,
                          CustomersTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StoresTableTableReferences
                              ._customersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoresTableTableReferences(
                                db,
                                table,
                                p0,
                              ).customersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (productsTableRefs)
                        await $_getPrefetchedData<
                          StoresTableData,
                          $StoresTableTable,
                          ProductsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StoresTableTableReferences
                              ._productsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoresTableTableReferences(
                                db,
                                table,
                                p0,
                              ).productsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsTableRefs)
                        await $_getPrefetchedData<
                          StoresTableData,
                          $StoresTableTable,
                          TransactionsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StoresTableTableReferences
                              ._transactionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoresTableTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (paymentsTableRefs)
                        await $_getPrefetchedData<
                          StoresTableData,
                          $StoresTableTable,
                          PaymentsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StoresTableTableReferences
                              ._paymentsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoresTableTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storeSettingsTableRefs)
                        await $_getPrefetchedData<
                          StoresTableData,
                          $StoresTableTable,
                          StoreSettingsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StoresTableTableReferences
                              ._storeSettingsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoresTableTableReferences(
                                db,
                                table,
                                p0,
                              ).storeSettingsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (interestRecordsTableRefs)
                        await $_getPrefetchedData<
                          StoresTableData,
                          $StoresTableTable,
                          InterestRecordsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StoresTableTableReferences
                              ._interestRecordsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoresTableTableReferences(
                                db,
                                table,
                                p0,
                              ).interestRecordsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StoresTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoresTableTable,
      StoresTableData,
      $$StoresTableTableFilterComposer,
      $$StoresTableTableOrderingComposer,
      $$StoresTableTableAnnotationComposer,
      $$StoresTableTableCreateCompanionBuilder,
      $$StoresTableTableUpdateCompanionBuilder,
      (StoresTableData, $$StoresTableTableReferences),
      StoresTableData,
      PrefetchHooks Function({
        bool customersTableRefs,
        bool productsTableRefs,
        bool transactionsTableRefs,
        bool paymentsTableRefs,
        bool storeSettingsTableRefs,
        bool interestRecordsTableRefs,
      })
    >;
typedef $$CustomersTableTableCreateCompanionBuilder =
    CustomersTableCompanion Function({
      Value<int> id,
      required int storeId,
      required String name,
      required String contactNumber,
      required bool isActive,
      Value<DateTime?> createdAt,
    });
typedef $$CustomersTableTableUpdateCompanionBuilder =
    CustomersTableCompanion Function({
      Value<int> id,
      Value<int> storeId,
      Value<String> name,
      Value<String> contactNumber,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
    });

final class $$CustomersTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomersTableTable,
          CustomersTableData
        > {
  $$CustomersTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoresTableTable _storeIdTable(_$AppDatabase db) =>
      db.storesTable.createAlias('customers_table__store_id__stores_table__id');

  $$StoresTableTableProcessedTableManager get storeId {
    final $_column = $_itemColumn<int>('store_id')!;

    final manager = $$StoresTableTableTableManager(
      $_db,
      $_db.storesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TransactionsTableTable,
    List<TransactionsTableData>
  >
  _transactionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionsTable,
        aliasName: 'customers_table__id__transactions_table__customer_id',
      );

  $$TransactionsTableTableProcessedTableManager get transactionsTableRefs {
    final manager = $$TransactionsTableTableTableManager(
      $_db,
      $_db.transactionsTable,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentsTableTable, List<PaymentsTableData>>
  _paymentsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.paymentsTable,
    aliasName: 'customers_table__id__payments_table__customer_id',
  );

  $$PaymentsTableTableProcessedTableManager get paymentsTableRefs {
    final manager = $$PaymentsTableTableTableManager(
      $_db,
      $_db.paymentsTable,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $InterestRecordsTableTable,
    List<InterestRecordsTableData>
  >
  _interestRecordsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.interestRecordsTable,
        aliasName: 'customers_table__id__interest_records_table__customer_id',
      );

  $$InterestRecordsTableTableProcessedTableManager
  get interestRecordsTableRefs {
    final manager = $$InterestRecordsTableTableTableManager(
      $_db,
      $_db.interestRecordsTable,
    ).filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _interestRecordsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomersTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoresTableTableFilterComposer get storeId {
    final $$StoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableFilterComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsTableRefs(
    Expression<bool> Function($$TransactionsTableTableFilterComposer f) f,
  ) {
    final $$TransactionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionsTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableTableFilterComposer(
            $db: $db,
            $table: $db.transactionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentsTableRefs(
    Expression<bool> Function($$PaymentsTableTableFilterComposer f) f,
  ) {
    final $$PaymentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paymentsTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableTableFilterComposer(
            $db: $db,
            $table: $db.paymentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> interestRecordsTableRefs(
    Expression<bool> Function($$InterestRecordsTableTableFilterComposer f) f,
  ) {
    final $$InterestRecordsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.interestRecordsTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InterestRecordsTableTableFilterComposer(
            $db: $db,
            $table: $db.interestRecordsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoresTableTableOrderingComposer get storeId {
    final $$StoresTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableOrderingComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTableTable> {
  $$CustomersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$StoresTableTableAnnotationComposer get storeId {
    final $$StoresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsTableRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionsTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> paymentsTableRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paymentsTable,
      getReferencedColumn: (t) => t.customerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> interestRecordsTableRefs<T extends Object>(
    Expression<T> Function($$InterestRecordsTableTableAnnotationComposer a) f,
  ) {
    final $$InterestRecordsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.interestRecordsTable,
          getReferencedColumn: (t) => t.customerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InterestRecordsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.interestRecordsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CustomersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTableTable,
          CustomersTableData,
          $$CustomersTableTableFilterComposer,
          $$CustomersTableTableOrderingComposer,
          $$CustomersTableTableAnnotationComposer,
          $$CustomersTableTableCreateCompanionBuilder,
          $$CustomersTableTableUpdateCompanionBuilder,
          (CustomersTableData, $$CustomersTableTableReferences),
          CustomersTableData,
          PrefetchHooks Function({
            bool storeId,
            bool transactionsTableRefs,
            bool paymentsTableRefs,
            bool interestRecordsTableRefs,
          })
        > {
  $$CustomersTableTableTableManager(
    _$AppDatabase db,
    $CustomersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> contactNumber = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => CustomersTableCompanion(
                id: id,
                storeId: storeId,
                name: name,
                contactNumber: contactNumber,
                isActive: isActive,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storeId,
                required String name,
                required String contactNumber,
                required bool isActive,
                Value<DateTime?> createdAt = const Value.absent(),
              }) => CustomersTableCompanion.insert(
                id: id,
                storeId: storeId,
                name: name,
                contactNumber: contactNumber,
                isActive: isActive,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                storeId = false,
                transactionsTableRefs = false,
                paymentsTableRefs = false,
                interestRecordsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsTableRefs) db.transactionsTable,
                    if (paymentsTableRefs) db.paymentsTable,
                    if (interestRecordsTableRefs) db.interestRecordsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (storeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.storeId,
                                    referencedTable:
                                        $$CustomersTableTableReferences
                                            ._storeIdTable(db),
                                    referencedColumn:
                                        $$CustomersTableTableReferences
                                            ._storeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsTableRefs)
                        await $_getPrefetchedData<
                          CustomersTableData,
                          $CustomersTableTable,
                          TransactionsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomersTableTableReferences
                              ._transactionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (paymentsTableRefs)
                        await $_getPrefetchedData<
                          CustomersTableData,
                          $CustomersTableTable,
                          PaymentsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomersTableTableReferences
                              ._paymentsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (interestRecordsTableRefs)
                        await $_getPrefetchedData<
                          CustomersTableData,
                          $CustomersTableTable,
                          InterestRecordsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CustomersTableTableReferences
                              ._interestRecordsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).interestRecordsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CustomersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTableTable,
      CustomersTableData,
      $$CustomersTableTableFilterComposer,
      $$CustomersTableTableOrderingComposer,
      $$CustomersTableTableAnnotationComposer,
      $$CustomersTableTableCreateCompanionBuilder,
      $$CustomersTableTableUpdateCompanionBuilder,
      (CustomersTableData, $$CustomersTableTableReferences),
      CustomersTableData,
      PrefetchHooks Function({
        bool storeId,
        bool transactionsTableRefs,
        bool paymentsTableRefs,
        bool interestRecordsTableRefs,
      })
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<int> id,
      required int storeId,
      required String name,
      Value<String?> description,
      Value<double> price,
      required String unit,
      required bool isActive,
      Value<DateTime?> createdAt,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<int> id,
      Value<int> storeId,
      Value<String> name,
      Value<String?> description,
      Value<double> price,
      Value<String> unit,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
    });

final class $$ProductsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData> {
  $$ProductsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoresTableTable _storeIdTable(_$AppDatabase db) =>
      db.storesTable.createAlias('products_table__store_id__stores_table__id');

  $$StoresTableTableProcessedTableManager get storeId {
    final $_column = $_itemColumn<int>('store_id')!;

    final manager = $$StoresTableTableTableManager(
      $_db,
      $_db.storesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TransactionsItemTableTable,
    List<TransactionsItemTableData>
  >
  _transactionsItemTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionsItemTable,
        aliasName: 'products_table__id__transactions_item_table__product_id',
      );

  $$TransactionsItemTableTableProcessedTableManager
  get transactionsItemTableRefs {
    final manager = $$TransactionsItemTableTableTableManager(
      $_db,
      $_db.transactionsItemTable,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionsItemTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoresTableTableFilterComposer get storeId {
    final $$StoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableFilterComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsItemTableRefs(
    Expression<bool> Function($$TransactionsItemTableTableFilterComposer f) f,
  ) {
    final $$TransactionsItemTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionsItemTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsItemTableTableFilterComposer(
                $db: $db,
                $table: $db.transactionsItemTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoresTableTableOrderingComposer get storeId {
    final $$StoresTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableOrderingComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$StoresTableTableAnnotationComposer get storeId {
    final $$StoresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsItemTableRefs<T extends Object>(
    Expression<T> Function($$TransactionsItemTableTableAnnotationComposer a) f,
  ) {
    final $$TransactionsItemTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionsItemTable,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsItemTableTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionsItemTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductsTableData,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (ProductsTableData, $$ProductsTableTableReferences),
          ProductsTableData,
          PrefetchHooks Function({bool storeId, bool transactionsItemTableRefs})
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> storeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                storeId: storeId,
                name: name,
                description: description,
                price: price,
                unit: unit,
                isActive: isActive,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storeId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<double> price = const Value.absent(),
                required String unit,
                required bool isActive,
                Value<DateTime?> createdAt = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                storeId: storeId,
                name: name,
                description: description,
                price: price,
                unit: unit,
                isActive: isActive,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({storeId = false, transactionsItemTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsItemTableRefs) db.transactionsItemTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (storeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.storeId,
                                    referencedTable:
                                        $$ProductsTableTableReferences
                                            ._storeIdTable(db),
                                    referencedColumn:
                                        $$ProductsTableTableReferences
                                            ._storeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsItemTableRefs)
                        await $_getPrefetchedData<
                          ProductsTableData,
                          $ProductsTableTable,
                          TransactionsItemTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableTableReferences
                              ._transactionsItemTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsItemTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductsTableData,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (ProductsTableData, $$ProductsTableTableReferences),
      ProductsTableData,
      PrefetchHooks Function({bool storeId, bool transactionsItemTableRefs})
    >;
typedef $$TransactionsTableTableCreateCompanionBuilder =
    TransactionsTableCompanion Function({
      Value<int> id,
      required int storeId,
      required int customerId,
      Value<double> totalAmount,
      Value<String?> note,
      Value<DateTime?> createdAt,
    });
typedef $$TransactionsTableTableUpdateCompanionBuilder =
    TransactionsTableCompanion Function({
      Value<int> id,
      Value<int> storeId,
      Value<int> customerId,
      Value<double> totalAmount,
      Value<String?> note,
      Value<DateTime?> createdAt,
    });

final class $$TransactionsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionsTableData
        > {
  $$TransactionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoresTableTable _storeIdTable(_$AppDatabase db) => db.storesTable
      .createAlias('transactions_table__store_id__stores_table__id');

  $$StoresTableTableProcessedTableManager get storeId {
    final $_column = $_itemColumn<int>('store_id')!;

    final manager = $$StoresTableTableTableManager(
      $_db,
      $_db.storesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomersTableTable _customerIdTable(_$AppDatabase db) => db
      .customersTable
      .createAlias('transactions_table__customer_id__customers_table__id');

  $$CustomersTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<int>('customer_id')!;

    final manager = $$CustomersTableTableTableManager(
      $_db,
      $_db.customersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TransactionsItemTableTable,
    List<TransactionsItemTableData>
  >
  _transactionsItemTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionsItemTable,
        aliasName:
            'transactions_table__id__transactions_item_table__transaction_id',
      );

  $$TransactionsItemTableTableProcessedTableManager
  get transactionsItemTableRefs {
    final manager = $$TransactionsItemTableTableTableManager(
      $_db,
      $_db.transactionsItemTable,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionsItemTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoresTableTableFilterComposer get storeId {
    final $$StoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableFilterComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableFilterComposer get customerId {
    final $$CustomersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableFilterComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsItemTableRefs(
    Expression<bool> Function($$TransactionsItemTableTableFilterComposer f) f,
  ) {
    final $$TransactionsItemTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionsItemTable,
          getReferencedColumn: (t) => t.transactionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsItemTableTableFilterComposer(
                $db: $db,
                $table: $db.transactionsItemTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoresTableTableOrderingComposer get storeId {
    final $$StoresTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableOrderingComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableOrderingComposer get customerId {
    final $$CustomersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableOrderingComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$StoresTableTableAnnotationComposer get storeId {
    final $$StoresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableAnnotationComposer get customerId {
    final $$CustomersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsItemTableRefs<T extends Object>(
    Expression<T> Function($$TransactionsItemTableTableAnnotationComposer a) f,
  ) {
    final $$TransactionsItemTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionsItemTable,
          getReferencedColumn: (t) => t.transactionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsItemTableTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionsItemTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TransactionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionsTableData,
          $$TransactionsTableTableFilterComposer,
          $$TransactionsTableTableOrderingComposer,
          $$TransactionsTableTableAnnotationComposer,
          $$TransactionsTableTableCreateCompanionBuilder,
          $$TransactionsTableTableUpdateCompanionBuilder,
          (TransactionsTableData, $$TransactionsTableTableReferences),
          TransactionsTableData,
          PrefetchHooks Function({
            bool storeId,
            bool customerId,
            bool transactionsItemTableRefs,
          })
        > {
  $$TransactionsTableTableTableManager(
    _$AppDatabase db,
    $TransactionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> storeId = const Value.absent(),
                Value<int> customerId = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TransactionsTableCompanion(
                id: id,
                storeId: storeId,
                customerId: customerId,
                totalAmount: totalAmount,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storeId,
                required int customerId,
                Value<double> totalAmount = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TransactionsTableCompanion.insert(
                id: id,
                storeId: storeId,
                customerId: customerId,
                totalAmount: totalAmount,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                storeId = false,
                customerId = false,
                transactionsItemTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsItemTableRefs) db.transactionsItemTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (storeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.storeId,
                                    referencedTable:
                                        $$TransactionsTableTableReferences
                                            ._storeIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableTableReferences
                                            ._storeIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (customerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.customerId,
                                    referencedTable:
                                        $$TransactionsTableTableReferences
                                            ._customerIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableTableReferences
                                            ._customerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsItemTableRefs)
                        await $_getPrefetchedData<
                          TransactionsTableData,
                          $TransactionsTableTable,
                          TransactionsItemTableData
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionsTableTableReferences
                              ._transactionsItemTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsItemTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTableTable,
      TransactionsTableData,
      $$TransactionsTableTableFilterComposer,
      $$TransactionsTableTableOrderingComposer,
      $$TransactionsTableTableAnnotationComposer,
      $$TransactionsTableTableCreateCompanionBuilder,
      $$TransactionsTableTableUpdateCompanionBuilder,
      (TransactionsTableData, $$TransactionsTableTableReferences),
      TransactionsTableData,
      PrefetchHooks Function({
        bool storeId,
        bool customerId,
        bool transactionsItemTableRefs,
      })
    >;
typedef $$TransactionsItemTableTableCreateCompanionBuilder =
    TransactionsItemTableCompanion Function({
      Value<int> id,
      required int transactionId,
      required int productId,
      Value<double> quantity,
      Value<double> unitPrice,
      Value<double> subTotal,
      Value<DateTime?> createdAt,
    });
typedef $$TransactionsItemTableTableUpdateCompanionBuilder =
    TransactionsItemTableCompanion Function({
      Value<int> id,
      Value<int> transactionId,
      Value<int> productId,
      Value<double> quantity,
      Value<double> unitPrice,
      Value<double> subTotal,
      Value<DateTime?> createdAt,
    });

final class $$TransactionsItemTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionsItemTableTable,
          TransactionsItemTableData
        > {
  $$TransactionsItemTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionsTableTable _transactionIdTable(_$AppDatabase db) =>
      db.transactionsTable.createAlias(
        'transactions_item_table__transaction_id__transactions_table__id',
      );

  $$TransactionsTableTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<int>('transaction_id')!;

    final manager = $$TransactionsTableTableTableManager(
      $_db,
      $_db.transactionsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTableTable _productIdTable(_$AppDatabase db) => db
      .productsTable
      .createAlias('transactions_item_table__product_id__products_table__id');

  $$ProductsTableTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableTableManager(
      $_db,
      $_db.productsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsItemTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsItemTableTable> {
  $$TransactionsItemTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subTotal => $composableBuilder(
    column: $table.subTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableTableFilterComposer get transactionId {
    final $$TransactionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactionsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableTableFilterComposer(
            $db: $db,
            $table: $db.transactionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableFilterComposer get productId {
    final $$ProductsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableFilterComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsItemTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsItemTableTable> {
  $$TransactionsItemTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subTotal => $composableBuilder(
    column: $table.subTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableTableOrderingComposer get transactionId {
    final $$TransactionsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactionsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableTableOrderingComposer(
            $db: $db,
            $table: $db.transactionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableTableOrderingComposer get productId {
    final $$ProductsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableOrderingComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsItemTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsItemTableTable> {
  $$TransactionsItemTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get subTotal =>
      $composableBuilder(column: $table.subTotal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TransactionsTableTableAnnotationComposer get transactionId {
    final $$TransactionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.transactionId,
          referencedTable: $db.transactionsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ProductsTableTableAnnotationComposer get productId {
    final $$ProductsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.productsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.productsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsItemTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsItemTableTable,
          TransactionsItemTableData,
          $$TransactionsItemTableTableFilterComposer,
          $$TransactionsItemTableTableOrderingComposer,
          $$TransactionsItemTableTableAnnotationComposer,
          $$TransactionsItemTableTableCreateCompanionBuilder,
          $$TransactionsItemTableTableUpdateCompanionBuilder,
          (TransactionsItemTableData, $$TransactionsItemTableTableReferences),
          TransactionsItemTableData,
          PrefetchHooks Function({bool transactionId, bool productId})
        > {
  $$TransactionsItemTableTableTableManager(
    _$AppDatabase db,
    $TransactionsItemTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsItemTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TransactionsItemTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionsItemTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> transactionId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> subTotal = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TransactionsItemTableCompanion(
                id: id,
                transactionId: transactionId,
                productId: productId,
                quantity: quantity,
                unitPrice: unitPrice,
                subTotal: subTotal,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int transactionId,
                required int productId,
                Value<double> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> subTotal = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TransactionsItemTableCompanion.insert(
                id: id,
                transactionId: transactionId,
                productId: productId,
                quantity: quantity,
                unitPrice: unitPrice,
                subTotal: subTotal,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsItemTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.transactionId,
                                referencedTable:
                                    $$TransactionsItemTableTableReferences
                                        ._transactionIdTable(db),
                                referencedColumn:
                                    $$TransactionsItemTableTableReferences
                                        ._transactionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$TransactionsItemTableTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$TransactionsItemTableTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsItemTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsItemTableTable,
      TransactionsItemTableData,
      $$TransactionsItemTableTableFilterComposer,
      $$TransactionsItemTableTableOrderingComposer,
      $$TransactionsItemTableTableAnnotationComposer,
      $$TransactionsItemTableTableCreateCompanionBuilder,
      $$TransactionsItemTableTableUpdateCompanionBuilder,
      (TransactionsItemTableData, $$TransactionsItemTableTableReferences),
      TransactionsItemTableData,
      PrefetchHooks Function({bool transactionId, bool productId})
    >;
typedef $$PaymentsTableTableCreateCompanionBuilder =
    PaymentsTableCompanion Function({
      Value<int> id,
      required int storeId,
      required int customerId,
      Value<double> amount,
      Value<String?> note,
      Value<DateTime?> createdAt,
    });
typedef $$PaymentsTableTableUpdateCompanionBuilder =
    PaymentsTableCompanion Function({
      Value<int> id,
      Value<int> storeId,
      Value<int> customerId,
      Value<double> amount,
      Value<String?> note,
      Value<DateTime?> createdAt,
    });

final class $$PaymentsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $PaymentsTableTable, PaymentsTableData> {
  $$PaymentsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoresTableTable _storeIdTable(_$AppDatabase db) =>
      db.storesTable.createAlias('payments_table__store_id__stores_table__id');

  $$StoresTableTableProcessedTableManager get storeId {
    final $_column = $_itemColumn<int>('store_id')!;

    final manager = $$StoresTableTableTableManager(
      $_db,
      $_db.storesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomersTableTable _customerIdTable(_$AppDatabase db) => db
      .customersTable
      .createAlias('payments_table__customer_id__customers_table__id');

  $$CustomersTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<int>('customer_id')!;

    final manager = $$CustomersTableTableTableManager(
      $_db,
      $_db.customersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTableTable> {
  $$PaymentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoresTableTableFilterComposer get storeId {
    final $$StoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableFilterComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableFilterComposer get customerId {
    final $$CustomersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableFilterComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTableTable> {
  $$PaymentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoresTableTableOrderingComposer get storeId {
    final $$StoresTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableOrderingComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableOrderingComposer get customerId {
    final $$CustomersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableOrderingComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTableTable> {
  $$PaymentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$StoresTableTableAnnotationComposer get storeId {
    final $$StoresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableAnnotationComposer get customerId {
    final $$CustomersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTableTable,
          PaymentsTableData,
          $$PaymentsTableTableFilterComposer,
          $$PaymentsTableTableOrderingComposer,
          $$PaymentsTableTableAnnotationComposer,
          $$PaymentsTableTableCreateCompanionBuilder,
          $$PaymentsTableTableUpdateCompanionBuilder,
          (PaymentsTableData, $$PaymentsTableTableReferences),
          PaymentsTableData,
          PrefetchHooks Function({bool storeId, bool customerId})
        > {
  $$PaymentsTableTableTableManager(_$AppDatabase db, $PaymentsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> storeId = const Value.absent(),
                Value<int> customerId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => PaymentsTableCompanion(
                id: id,
                storeId: storeId,
                customerId: customerId,
                amount: amount,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storeId,
                required int customerId,
                Value<double> amount = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => PaymentsTableCompanion.insert(
                id: id,
                storeId: storeId,
                customerId: customerId,
                amount: amount,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PaymentsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({storeId = false, customerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (storeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.storeId,
                                referencedTable: $$PaymentsTableTableReferences
                                    ._storeIdTable(db),
                                referencedColumn: $$PaymentsTableTableReferences
                                    ._storeIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (customerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customerId,
                                referencedTable: $$PaymentsTableTableReferences
                                    ._customerIdTable(db),
                                referencedColumn: $$PaymentsTableTableReferences
                                    ._customerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PaymentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTableTable,
      PaymentsTableData,
      $$PaymentsTableTableFilterComposer,
      $$PaymentsTableTableOrderingComposer,
      $$PaymentsTableTableAnnotationComposer,
      $$PaymentsTableTableCreateCompanionBuilder,
      $$PaymentsTableTableUpdateCompanionBuilder,
      (PaymentsTableData, $$PaymentsTableTableReferences),
      PaymentsTableData,
      PrefetchHooks Function({bool storeId, bool customerId})
    >;
typedef $$StoreSettingsTableTableCreateCompanionBuilder =
    StoreSettingsTableCompanion Function({
      Value<int> id,
      required int storeId,
      Value<bool> monthlyInterestEnabled,
      Value<double> monthlyInterestRate,
    });
typedef $$StoreSettingsTableTableUpdateCompanionBuilder =
    StoreSettingsTableCompanion Function({
      Value<int> id,
      Value<int> storeId,
      Value<bool> monthlyInterestEnabled,
      Value<double> monthlyInterestRate,
    });

final class $$StoreSettingsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $StoreSettingsTableTable,
          StoreSettingsTableData
        > {
  $$StoreSettingsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoresTableTable _storeIdTable(_$AppDatabase db) => db.storesTable
      .createAlias('store_settings_table__store_id__stores_table__id');

  $$StoresTableTableProcessedTableManager get storeId {
    final $_column = $_itemColumn<int>('store_id')!;

    final manager = $$StoresTableTableTableManager(
      $_db,
      $_db.storesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoreSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StoreSettingsTableTable> {
  $$StoreSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get monthlyInterestEnabled => $composableBuilder(
    column: $table.monthlyInterestEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyInterestRate => $composableBuilder(
    column: $table.monthlyInterestRate,
    builder: (column) => ColumnFilters(column),
  );

  $$StoresTableTableFilterComposer get storeId {
    final $$StoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableFilterComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoreSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StoreSettingsTableTable> {
  $$StoreSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get monthlyInterestEnabled => $composableBuilder(
    column: $table.monthlyInterestEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyInterestRate => $composableBuilder(
    column: $table.monthlyInterestRate,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoresTableTableOrderingComposer get storeId {
    final $$StoresTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableOrderingComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoreSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoreSettingsTableTable> {
  $$StoreSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get monthlyInterestEnabled => $composableBuilder(
    column: $table.monthlyInterestEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<double> get monthlyInterestRate => $composableBuilder(
    column: $table.monthlyInterestRate,
    builder: (column) => column,
  );

  $$StoresTableTableAnnotationComposer get storeId {
    final $$StoresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoreSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoreSettingsTableTable,
          StoreSettingsTableData,
          $$StoreSettingsTableTableFilterComposer,
          $$StoreSettingsTableTableOrderingComposer,
          $$StoreSettingsTableTableAnnotationComposer,
          $$StoreSettingsTableTableCreateCompanionBuilder,
          $$StoreSettingsTableTableUpdateCompanionBuilder,
          (StoreSettingsTableData, $$StoreSettingsTableTableReferences),
          StoreSettingsTableData,
          PrefetchHooks Function({bool storeId})
        > {
  $$StoreSettingsTableTableTableManager(
    _$AppDatabase db,
    $StoreSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoreSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoreSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoreSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> storeId = const Value.absent(),
                Value<bool> monthlyInterestEnabled = const Value.absent(),
                Value<double> monthlyInterestRate = const Value.absent(),
              }) => StoreSettingsTableCompanion(
                id: id,
                storeId: storeId,
                monthlyInterestEnabled: monthlyInterestEnabled,
                monthlyInterestRate: monthlyInterestRate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storeId,
                Value<bool> monthlyInterestEnabled = const Value.absent(),
                Value<double> monthlyInterestRate = const Value.absent(),
              }) => StoreSettingsTableCompanion.insert(
                id: id,
                storeId: storeId,
                monthlyInterestEnabled: monthlyInterestEnabled,
                monthlyInterestRate: monthlyInterestRate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoreSettingsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({storeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (storeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.storeId,
                                referencedTable:
                                    $$StoreSettingsTableTableReferences
                                        ._storeIdTable(db),
                                referencedColumn:
                                    $$StoreSettingsTableTableReferences
                                        ._storeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StoreSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoreSettingsTableTable,
      StoreSettingsTableData,
      $$StoreSettingsTableTableFilterComposer,
      $$StoreSettingsTableTableOrderingComposer,
      $$StoreSettingsTableTableAnnotationComposer,
      $$StoreSettingsTableTableCreateCompanionBuilder,
      $$StoreSettingsTableTableUpdateCompanionBuilder,
      (StoreSettingsTableData, $$StoreSettingsTableTableReferences),
      StoreSettingsTableData,
      PrefetchHooks Function({bool storeId})
    >;
typedef $$InterestRecordsTableTableCreateCompanionBuilder =
    InterestRecordsTableCompanion Function({
      Value<int> id,
      required int storeId,
      required int customerId,
      Value<double> rate,
      Value<double> baseAmount,
      Value<double> interestAmount,
      Value<DateTime?> createdAt,
    });
typedef $$InterestRecordsTableTableUpdateCompanionBuilder =
    InterestRecordsTableCompanion Function({
      Value<int> id,
      Value<int> storeId,
      Value<int> customerId,
      Value<double> rate,
      Value<double> baseAmount,
      Value<double> interestAmount,
      Value<DateTime?> createdAt,
    });

final class $$InterestRecordsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InterestRecordsTableTable,
          InterestRecordsTableData
        > {
  $$InterestRecordsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoresTableTable _storeIdTable(_$AppDatabase db) => db.storesTable
      .createAlias('interest_records_table__store_id__stores_table__id');

  $$StoresTableTableProcessedTableManager get storeId {
    final $_column = $_itemColumn<int>('store_id')!;

    final manager = $$StoresTableTableTableManager(
      $_db,
      $_db.storesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomersTableTable _customerIdTable(_$AppDatabase db) => db
      .customersTable
      .createAlias('interest_records_table__customer_id__customers_table__id');

  $$CustomersTableTableProcessedTableManager get customerId {
    final $_column = $_itemColumn<int>('customer_id')!;

    final manager = $$CustomersTableTableTableManager(
      $_db,
      $_db.customersTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InterestRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $InterestRecordsTableTable> {
  $$InterestRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestAmount => $composableBuilder(
    column: $table.interestAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoresTableTableFilterComposer get storeId {
    final $$StoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableFilterComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableFilterComposer get customerId {
    final $$CustomersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableFilterComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InterestRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InterestRecordsTableTable> {
  $$InterestRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestAmount => $composableBuilder(
    column: $table.interestAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoresTableTableOrderingComposer get storeId {
    final $$StoresTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableOrderingComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableOrderingComposer get customerId {
    final $$CustomersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableOrderingComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InterestRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InterestRecordsTableTable> {
  $$InterestRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<double> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get interestAmount => $composableBuilder(
    column: $table.interestAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$StoresTableTableAnnotationComposer get storeId {
    final $$StoresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.storesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.storesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomersTableTableAnnotationComposer get customerId {
    final $$CustomersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customerId,
      referencedTable: $db.customersTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.customersTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InterestRecordsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InterestRecordsTableTable,
          InterestRecordsTableData,
          $$InterestRecordsTableTableFilterComposer,
          $$InterestRecordsTableTableOrderingComposer,
          $$InterestRecordsTableTableAnnotationComposer,
          $$InterestRecordsTableTableCreateCompanionBuilder,
          $$InterestRecordsTableTableUpdateCompanionBuilder,
          (InterestRecordsTableData, $$InterestRecordsTableTableReferences),
          InterestRecordsTableData,
          PrefetchHooks Function({bool storeId, bool customerId})
        > {
  $$InterestRecordsTableTableTableManager(
    _$AppDatabase db,
    $InterestRecordsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InterestRecordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InterestRecordsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InterestRecordsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> storeId = const Value.absent(),
                Value<int> customerId = const Value.absent(),
                Value<double> rate = const Value.absent(),
                Value<double> baseAmount = const Value.absent(),
                Value<double> interestAmount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => InterestRecordsTableCompanion(
                id: id,
                storeId: storeId,
                customerId: customerId,
                rate: rate,
                baseAmount: baseAmount,
                interestAmount: interestAmount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storeId,
                required int customerId,
                Value<double> rate = const Value.absent(),
                Value<double> baseAmount = const Value.absent(),
                Value<double> interestAmount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => InterestRecordsTableCompanion.insert(
                id: id,
                storeId: storeId,
                customerId: customerId,
                rate: rate,
                baseAmount: baseAmount,
                interestAmount: interestAmount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InterestRecordsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({storeId = false, customerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (storeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.storeId,
                                referencedTable:
                                    $$InterestRecordsTableTableReferences
                                        ._storeIdTable(db),
                                referencedColumn:
                                    $$InterestRecordsTableTableReferences
                                        ._storeIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (customerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customerId,
                                referencedTable:
                                    $$InterestRecordsTableTableReferences
                                        ._customerIdTable(db),
                                referencedColumn:
                                    $$InterestRecordsTableTableReferences
                                        ._customerIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InterestRecordsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InterestRecordsTableTable,
      InterestRecordsTableData,
      $$InterestRecordsTableTableFilterComposer,
      $$InterestRecordsTableTableOrderingComposer,
      $$InterestRecordsTableTableAnnotationComposer,
      $$InterestRecordsTableTableCreateCompanionBuilder,
      $$InterestRecordsTableTableUpdateCompanionBuilder,
      (InterestRecordsTableData, $$InterestRecordsTableTableReferences),
      InterestRecordsTableData,
      PrefetchHooks Function({bool storeId, bool customerId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StoresTableTableTableManager get storesTable =>
      $$StoresTableTableTableManager(_db, _db.storesTable);
  $$CustomersTableTableTableManager get customersTable =>
      $$CustomersTableTableTableManager(_db, _db.customersTable);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$TransactionsTableTableTableManager get transactionsTable =>
      $$TransactionsTableTableTableManager(_db, _db.transactionsTable);
  $$TransactionsItemTableTableTableManager get transactionsItemTable =>
      $$TransactionsItemTableTableTableManager(_db, _db.transactionsItemTable);
  $$PaymentsTableTableTableManager get paymentsTable =>
      $$PaymentsTableTableTableManager(_db, _db.paymentsTable);
  $$StoreSettingsTableTableTableManager get storeSettingsTable =>
      $$StoreSettingsTableTableTableManager(_db, _db.storeSettingsTable);
  $$InterestRecordsTableTableTableManager get interestRecordsTable =>
      $$InterestRecordsTableTableTableManager(_db, _db.interestRecordsTable);
}
