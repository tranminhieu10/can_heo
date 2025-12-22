// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PartnersTable extends Partners with TableInfo<$PartnersTable, Partner> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PartnersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSupplierMeta =
      const VerificationMeta('isSupplier');
  @override
  late final GeneratedColumn<bool> isSupplier = GeneratedColumn<bool>(
      'is_supplier', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_supplier" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _currentDebtMeta =
      const VerificationMeta('currentDebt');
  @override
  late final GeneratedColumn<double> currentDebt = GeneratedColumn<double>(
      'current_debt', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, phone, address, code, isSupplier, currentDebt, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'partners';
  @override
  VerificationContext validateIntegrity(Insertable<Partner> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('is_supplier')) {
      context.handle(
          _isSupplierMeta,
          isSupplier.isAcceptableOrUnknown(
              data['is_supplier']!, _isSupplierMeta));
    }
    if (data.containsKey('current_debt')) {
      context.handle(
          _currentDebtMeta,
          currentDebt.isAcceptableOrUnknown(
              data['current_debt']!, _currentDebtMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Partner map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Partner(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code']),
      isSupplier: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_supplier'])!,
      currentDebt: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_debt'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $PartnersTable createAlias(String alias) {
    return $PartnersTable(attachedDatabase, alias);
  }
}

class Partner extends DataClass implements Insertable<Partner> {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? code;
  final bool isSupplier;
  final double currentDebt;
  final DateTime? lastUpdated;
  const Partner(
      {required this.id,
      required this.name,
      this.phone,
      this.address,
      this.code,
      required this.isSupplier,
      required this.currentDebt,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['is_supplier'] = Variable<bool>(isSupplier);
    map['current_debt'] = Variable<double>(currentDebt);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  PartnersCompanion toCompanion(bool nullToAbsent) {
    return PartnersCompanion(
      id: Value(id),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      isSupplier: Value(isSupplier),
      currentDebt: Value(currentDebt),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory Partner.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Partner(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      code: serializer.fromJson<String?>(json['code']),
      isSupplier: serializer.fromJson<bool>(json['isSupplier']),
      currentDebt: serializer.fromJson<double>(json['currentDebt']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'code': serializer.toJson<String?>(code),
      'isSupplier': serializer.toJson<bool>(isSupplier),
      'currentDebt': serializer.toJson<double>(currentDebt),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  Partner copyWith(
          {String? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> code = const Value.absent(),
          bool? isSupplier,
          double? currentDebt,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      Partner(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        address: address.present ? address.value : this.address,
        code: code.present ? code.value : this.code,
        isSupplier: isSupplier ?? this.isSupplier,
        currentDebt: currentDebt ?? this.currentDebt,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  Partner copyWithCompanion(PartnersCompanion data) {
    return Partner(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      code: data.code.present ? data.code.value : this.code,
      isSupplier:
          data.isSupplier.present ? data.isSupplier.value : this.isSupplier,
      currentDebt:
          data.currentDebt.present ? data.currentDebt.value : this.currentDebt,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Partner(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('code: $code, ')
          ..write('isSupplier: $isSupplier, ')
          ..write('currentDebt: $currentDebt, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, phone, address, code, isSupplier, currentDebt, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Partner &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.code == this.code &&
          other.isSupplier == this.isSupplier &&
          other.currentDebt == this.currentDebt &&
          other.lastUpdated == this.lastUpdated);
}

class PartnersCompanion extends UpdateCompanion<Partner> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String?> code;
  final Value<bool> isSupplier;
  final Value<double> currentDebt;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const PartnersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.code = const Value.absent(),
    this.isSupplier = const Value.absent(),
    this.currentDebt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PartnersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.code = const Value.absent(),
    this.isSupplier = const Value.absent(),
    this.currentDebt = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Partner> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? code,
    Expression<bool>? isSupplier,
    Expression<double>? currentDebt,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (code != null) 'code': code,
      if (isSupplier != null) 'is_supplier': isSupplier,
      if (currentDebt != null) 'current_debt': currentDebt,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PartnersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? phone,
      Value<String?>? address,
      Value<String?>? code,
      Value<bool>? isSupplier,
      Value<double>? currentDebt,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return PartnersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      code: code ?? this.code,
      isSupplier: isSupplier ?? this.isSupplier,
      currentDebt: currentDebt ?? this.currentDebt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (isSupplier.present) {
      map['is_supplier'] = Variable<bool>(isSupplier.value);
    }
    if (currentDebt.present) {
      map['current_debt'] = Variable<double>(currentDebt.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PartnersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('code: $code, ')
          ..write('isSupplier: $isSupplier, ')
          ..write('currentDebt: $currentDebt, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CagesTable extends Cages with TableInfo<$CagesTable, Cage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _capacityMeta =
      const VerificationMeta('capacity');
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
      'capacity', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, capacity, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cages';
  @override
  VerificationContext validateIntegrity(Insertable<Cage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('capacity')) {
      context.handle(_capacityMeta,
          capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      capacity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}capacity']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CagesTable createAlias(String alias) {
    return $CagesTable(attachedDatabase, alias);
  }
}

class Cage extends DataClass implements Insertable<Cage> {
  final String id;
  final String name;
  final int? capacity;
  final String? note;
  final DateTime createdAt;
  const Cage(
      {required this.id,
      required this.name,
      this.capacity,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || capacity != null) {
      map['capacity'] = Variable<int>(capacity);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CagesCompanion toCompanion(bool nullToAbsent) {
    return CagesCompanion(
      id: Value(id),
      name: Value(name),
      capacity: capacity == null && nullToAbsent
          ? const Value.absent()
          : Value(capacity),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Cage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cage(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      capacity: serializer.fromJson<int?>(json['capacity']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'capacity': serializer.toJson<int?>(capacity),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Cage copyWith(
          {String? id,
          String? name,
          Value<int?> capacity = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      Cage(
        id: id ?? this.id,
        name: name ?? this.name,
        capacity: capacity.present ? capacity.value : this.capacity,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  Cage copyWithCompanion(CagesCompanion data) {
    return Cage(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cage(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('capacity: $capacity, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, capacity, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cage &&
          other.id == this.id &&
          other.name == this.name &&
          other.capacity == this.capacity &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class CagesCompanion extends UpdateCompanion<Cage> {
  final Value<String> id;
  final Value<String> name;
  final Value<int?> capacity;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CagesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.capacity = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CagesCompanion.insert({
    required String id,
    required String name,
    this.capacity = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Cage> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? capacity,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (capacity != null) 'capacity': capacity,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int?>? capacity,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return CagesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CagesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('capacity: $capacity, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices with TableInfo<$InvoicesTable, Invoice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _invoiceCodeMeta =
      const VerificationMeta('invoiceCode');
  @override
  late final GeneratedColumn<String> invoiceCode = GeneratedColumn<String>(
      'invoice_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _partnerIdMeta =
      const VerificationMeta('partnerId');
  @override
  late final GeneratedColumn<String> partnerId = GeneratedColumn<String>(
      'partner_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES partners (id)'));
  static const VerificationMeta _cageIdMeta = const VerificationMeta('cageId');
  @override
  late final GeneratedColumn<String> cageId = GeneratedColumn<String>(
      'cage_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cages (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
      'type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdDateMeta =
      const VerificationMeta('createdDate');
  @override
  late final GeneratedColumn<DateTime> createdDate = GeneratedColumn<DateTime>(
      'created_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _totalWeightMeta =
      const VerificationMeta('totalWeight');
  @override
  late final GeneratedColumn<double> totalWeight = GeneratedColumn<double>(
      'total_weight', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _totalQuantityMeta =
      const VerificationMeta('totalQuantity');
  @override
  late final GeneratedColumn<int> totalQuantity = GeneratedColumn<int>(
      'total_quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _pricePerKgMeta =
      const VerificationMeta('pricePerKg');
  @override
  late final GeneratedColumn<double> pricePerKg = GeneratedColumn<double>(
      'price_per_kg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _truckCostMeta =
      const VerificationMeta('truckCost');
  @override
  late final GeneratedColumn<double> truckCost = GeneratedColumn<double>(
      'truck_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _finalAmountMeta =
      const VerificationMeta('finalAmount');
  @override
  late final GeneratedColumn<double> finalAmount = GeneratedColumn<double>(
      'final_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _paidAmountMeta =
      const VerificationMeta('paidAmount');
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
      'paid_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        invoiceCode,
        partnerId,
        cageId,
        type,
        createdDate,
        totalWeight,
        totalQuantity,
        pricePerKg,
        truckCost,
        discount,
        finalAmount,
        paidAmount,
        note
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(Insertable<Invoice> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_code')) {
      context.handle(
          _invoiceCodeMeta,
          invoiceCode.isAcceptableOrUnknown(
              data['invoice_code']!, _invoiceCodeMeta));
    }
    if (data.containsKey('partner_id')) {
      context.handle(_partnerIdMeta,
          partnerId.isAcceptableOrUnknown(data['partner_id']!, _partnerIdMeta));
    }
    if (data.containsKey('cage_id')) {
      context.handle(_cageIdMeta,
          cageId.isAcceptableOrUnknown(data['cage_id']!, _cageIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_date')) {
      context.handle(
          _createdDateMeta,
          createdDate.isAcceptableOrUnknown(
              data['created_date']!, _createdDateMeta));
    } else if (isInserting) {
      context.missing(_createdDateMeta);
    }
    if (data.containsKey('total_weight')) {
      context.handle(
          _totalWeightMeta,
          totalWeight.isAcceptableOrUnknown(
              data['total_weight']!, _totalWeightMeta));
    }
    if (data.containsKey('total_quantity')) {
      context.handle(
          _totalQuantityMeta,
          totalQuantity.isAcceptableOrUnknown(
              data['total_quantity']!, _totalQuantityMeta));
    }
    if (data.containsKey('price_per_kg')) {
      context.handle(
          _pricePerKgMeta,
          pricePerKg.isAcceptableOrUnknown(
              data['price_per_kg']!, _pricePerKgMeta));
    }
    if (data.containsKey('truck_cost')) {
      context.handle(_truckCostMeta,
          truckCost.isAcceptableOrUnknown(data['truck_cost']!, _truckCostMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('final_amount')) {
      context.handle(
          _finalAmountMeta,
          finalAmount.isAcceptableOrUnknown(
              data['final_amount']!, _finalAmountMeta));
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
          _paidAmountMeta,
          paidAmount.isAcceptableOrUnknown(
              data['paid_amount']!, _paidAmountMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invoice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invoice(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      invoiceCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_code']),
      partnerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}partner_id']),
      cageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cage_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!,
      createdDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_date'])!,
      totalWeight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_weight'])!,
      totalQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_quantity'])!,
      pricePerKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_per_kg'])!,
      truckCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}truck_cost'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      finalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}final_amount'])!,
      paidAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}paid_amount'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class Invoice extends DataClass implements Insertable<Invoice> {
  final String id;
  final String? invoiceCode;
  final String? partnerId;
  final String? cageId;
  final int type;
  final DateTime createdDate;
  final double totalWeight;
  final int totalQuantity;
  final double pricePerKg;
  final double truckCost;
  final double discount;
  final double finalAmount;
  final double paidAmount;
  final String? note;
  const Invoice(
      {required this.id,
      this.invoiceCode,
      this.partnerId,
      this.cageId,
      required this.type,
      required this.createdDate,
      required this.totalWeight,
      required this.totalQuantity,
      required this.pricePerKg,
      required this.truckCost,
      required this.discount,
      required this.finalAmount,
      required this.paidAmount,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || invoiceCode != null) {
      map['invoice_code'] = Variable<String>(invoiceCode);
    }
    if (!nullToAbsent || partnerId != null) {
      map['partner_id'] = Variable<String>(partnerId);
    }
    if (!nullToAbsent || cageId != null) {
      map['cage_id'] = Variable<String>(cageId);
    }
    map['type'] = Variable<int>(type);
    map['created_date'] = Variable<DateTime>(createdDate);
    map['total_weight'] = Variable<double>(totalWeight);
    map['total_quantity'] = Variable<int>(totalQuantity);
    map['price_per_kg'] = Variable<double>(pricePerKg);
    map['truck_cost'] = Variable<double>(truckCost);
    map['discount'] = Variable<double>(discount);
    map['final_amount'] = Variable<double>(finalAmount);
    map['paid_amount'] = Variable<double>(paidAmount);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      invoiceCode: invoiceCode == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceCode),
      partnerId: partnerId == null && nullToAbsent
          ? const Value.absent()
          : Value(partnerId),
      cageId:
          cageId == null && nullToAbsent ? const Value.absent() : Value(cageId),
      type: Value(type),
      createdDate: Value(createdDate),
      totalWeight: Value(totalWeight),
      totalQuantity: Value(totalQuantity),
      pricePerKg: Value(pricePerKg),
      truckCost: Value(truckCost),
      discount: Value(discount),
      finalAmount: Value(finalAmount),
      paidAmount: Value(paidAmount),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invoice(
      id: serializer.fromJson<String>(json['id']),
      invoiceCode: serializer.fromJson<String?>(json['invoiceCode']),
      partnerId: serializer.fromJson<String?>(json['partnerId']),
      cageId: serializer.fromJson<String?>(json['cageId']),
      type: serializer.fromJson<int>(json['type']),
      createdDate: serializer.fromJson<DateTime>(json['createdDate']),
      totalWeight: serializer.fromJson<double>(json['totalWeight']),
      totalQuantity: serializer.fromJson<int>(json['totalQuantity']),
      pricePerKg: serializer.fromJson<double>(json['pricePerKg']),
      truckCost: serializer.fromJson<double>(json['truckCost']),
      discount: serializer.fromJson<double>(json['discount']),
      finalAmount: serializer.fromJson<double>(json['finalAmount']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceCode': serializer.toJson<String?>(invoiceCode),
      'partnerId': serializer.toJson<String?>(partnerId),
      'cageId': serializer.toJson<String?>(cageId),
      'type': serializer.toJson<int>(type),
      'createdDate': serializer.toJson<DateTime>(createdDate),
      'totalWeight': serializer.toJson<double>(totalWeight),
      'totalQuantity': serializer.toJson<int>(totalQuantity),
      'pricePerKg': serializer.toJson<double>(pricePerKg),
      'truckCost': serializer.toJson<double>(truckCost),
      'discount': serializer.toJson<double>(discount),
      'finalAmount': serializer.toJson<double>(finalAmount),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'note': serializer.toJson<String?>(note),
    };
  }

  Invoice copyWith(
          {String? id,
          Value<String?> invoiceCode = const Value.absent(),
          Value<String?> partnerId = const Value.absent(),
          Value<String?> cageId = const Value.absent(),
          int? type,
          DateTime? createdDate,
          double? totalWeight,
          int? totalQuantity,
          double? pricePerKg,
          double? truckCost,
          double? discount,
          double? finalAmount,
          double? paidAmount,
          Value<String?> note = const Value.absent()}) =>
      Invoice(
        id: id ?? this.id,
        invoiceCode: invoiceCode.present ? invoiceCode.value : this.invoiceCode,
        partnerId: partnerId.present ? partnerId.value : this.partnerId,
        cageId: cageId.present ? cageId.value : this.cageId,
        type: type ?? this.type,
        createdDate: createdDate ?? this.createdDate,
        totalWeight: totalWeight ?? this.totalWeight,
        totalQuantity: totalQuantity ?? this.totalQuantity,
        pricePerKg: pricePerKg ?? this.pricePerKg,
        truckCost: truckCost ?? this.truckCost,
        discount: discount ?? this.discount,
        finalAmount: finalAmount ?? this.finalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        note: note.present ? note.value : this.note,
      );
  Invoice copyWithCompanion(InvoicesCompanion data) {
    return Invoice(
      id: data.id.present ? data.id.value : this.id,
      invoiceCode:
          data.invoiceCode.present ? data.invoiceCode.value : this.invoiceCode,
      partnerId: data.partnerId.present ? data.partnerId.value : this.partnerId,
      cageId: data.cageId.present ? data.cageId.value : this.cageId,
      type: data.type.present ? data.type.value : this.type,
      createdDate:
          data.createdDate.present ? data.createdDate.value : this.createdDate,
      totalWeight:
          data.totalWeight.present ? data.totalWeight.value : this.totalWeight,
      totalQuantity: data.totalQuantity.present
          ? data.totalQuantity.value
          : this.totalQuantity,
      pricePerKg:
          data.pricePerKg.present ? data.pricePerKg.value : this.pricePerKg,
      truckCost: data.truckCost.present ? data.truckCost.value : this.truckCost,
      discount: data.discount.present ? data.discount.value : this.discount,
      finalAmount:
          data.finalAmount.present ? data.finalAmount.value : this.finalAmount,
      paidAmount:
          data.paidAmount.present ? data.paidAmount.value : this.paidAmount,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invoice(')
          ..write('id: $id, ')
          ..write('invoiceCode: $invoiceCode, ')
          ..write('partnerId: $partnerId, ')
          ..write('cageId: $cageId, ')
          ..write('type: $type, ')
          ..write('createdDate: $createdDate, ')
          ..write('totalWeight: $totalWeight, ')
          ..write('totalQuantity: $totalQuantity, ')
          ..write('pricePerKg: $pricePerKg, ')
          ..write('truckCost: $truckCost, ')
          ..write('discount: $discount, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      invoiceCode,
      partnerId,
      cageId,
      type,
      createdDate,
      totalWeight,
      totalQuantity,
      pricePerKg,
      truckCost,
      discount,
      finalAmount,
      paidAmount,
      note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invoice &&
          other.id == this.id &&
          other.invoiceCode == this.invoiceCode &&
          other.partnerId == this.partnerId &&
          other.cageId == this.cageId &&
          other.type == this.type &&
          other.createdDate == this.createdDate &&
          other.totalWeight == this.totalWeight &&
          other.totalQuantity == this.totalQuantity &&
          other.pricePerKg == this.pricePerKg &&
          other.truckCost == this.truckCost &&
          other.discount == this.discount &&
          other.finalAmount == this.finalAmount &&
          other.paidAmount == this.paidAmount &&
          other.note == this.note);
}

class InvoicesCompanion extends UpdateCompanion<Invoice> {
  final Value<String> id;
  final Value<String?> invoiceCode;
  final Value<String?> partnerId;
  final Value<String?> cageId;
  final Value<int> type;
  final Value<DateTime> createdDate;
  final Value<double> totalWeight;
  final Value<int> totalQuantity;
  final Value<double> pricePerKg;
  final Value<double> truckCost;
  final Value<double> discount;
  final Value<double> finalAmount;
  final Value<double> paidAmount;
  final Value<String?> note;
  final Value<int> rowid;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.invoiceCode = const Value.absent(),
    this.partnerId = const Value.absent(),
    this.cageId = const Value.absent(),
    this.type = const Value.absent(),
    this.createdDate = const Value.absent(),
    this.totalWeight = const Value.absent(),
    this.totalQuantity = const Value.absent(),
    this.pricePerKg = const Value.absent(),
    this.truckCost = const Value.absent(),
    this.discount = const Value.absent(),
    this.finalAmount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesCompanion.insert({
    required String id,
    this.invoiceCode = const Value.absent(),
    this.partnerId = const Value.absent(),
    this.cageId = const Value.absent(),
    required int type,
    required DateTime createdDate,
    this.totalWeight = const Value.absent(),
    this.totalQuantity = const Value.absent(),
    this.pricePerKg = const Value.absent(),
    this.truckCost = const Value.absent(),
    this.discount = const Value.absent(),
    this.finalAmount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        createdDate = Value(createdDate);
  static Insertable<Invoice> custom({
    Expression<String>? id,
    Expression<String>? invoiceCode,
    Expression<String>? partnerId,
    Expression<String>? cageId,
    Expression<int>? type,
    Expression<DateTime>? createdDate,
    Expression<double>? totalWeight,
    Expression<int>? totalQuantity,
    Expression<double>? pricePerKg,
    Expression<double>? truckCost,
    Expression<double>? discount,
    Expression<double>? finalAmount,
    Expression<double>? paidAmount,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceCode != null) 'invoice_code': invoiceCode,
      if (partnerId != null) 'partner_id': partnerId,
      if (cageId != null) 'cage_id': cageId,
      if (type != null) 'type': type,
      if (createdDate != null) 'created_date': createdDate,
      if (totalWeight != null) 'total_weight': totalWeight,
      if (totalQuantity != null) 'total_quantity': totalQuantity,
      if (pricePerKg != null) 'price_per_kg': pricePerKg,
      if (truckCost != null) 'truck_cost': truckCost,
      if (discount != null) 'discount': discount,
      if (finalAmount != null) 'final_amount': finalAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? invoiceCode,
      Value<String?>? partnerId,
      Value<String?>? cageId,
      Value<int>? type,
      Value<DateTime>? createdDate,
      Value<double>? totalWeight,
      Value<int>? totalQuantity,
      Value<double>? pricePerKg,
      Value<double>? truckCost,
      Value<double>? discount,
      Value<double>? finalAmount,
      Value<double>? paidAmount,
      Value<String?>? note,
      Value<int>? rowid}) {
    return InvoicesCompanion(
      id: id ?? this.id,
      invoiceCode: invoiceCode ?? this.invoiceCode,
      partnerId: partnerId ?? this.partnerId,
      cageId: cageId ?? this.cageId,
      type: type ?? this.type,
      createdDate: createdDate ?? this.createdDate,
      totalWeight: totalWeight ?? this.totalWeight,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      truckCost: truckCost ?? this.truckCost,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invoiceCode.present) {
      map['invoice_code'] = Variable<String>(invoiceCode.value);
    }
    if (partnerId.present) {
      map['partner_id'] = Variable<String>(partnerId.value);
    }
    if (cageId.present) {
      map['cage_id'] = Variable<String>(cageId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (createdDate.present) {
      map['created_date'] = Variable<DateTime>(createdDate.value);
    }
    if (totalWeight.present) {
      map['total_weight'] = Variable<double>(totalWeight.value);
    }
    if (totalQuantity.present) {
      map['total_quantity'] = Variable<int>(totalQuantity.value);
    }
    if (pricePerKg.present) {
      map['price_per_kg'] = Variable<double>(pricePerKg.value);
    }
    if (truckCost.present) {
      map['truck_cost'] = Variable<double>(truckCost.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (finalAmount.present) {
      map['final_amount'] = Variable<double>(finalAmount.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('invoiceCode: $invoiceCode, ')
          ..write('partnerId: $partnerId, ')
          ..write('cageId: $cageId, ')
          ..write('type: $type, ')
          ..write('createdDate: $createdDate, ')
          ..write('totalWeight: $totalWeight, ')
          ..write('totalQuantity: $totalQuantity, ')
          ..write('pricePerKg: $pricePerKg, ')
          ..write('truckCost: $truckCost, ')
          ..write('discount: $discount, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeighingDetailsTable extends WeighingDetails
    with TableInfo<$WeighingDetailsTable, WeighingDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeighingDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
      'invoice_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES invoices (id) ON DELETE CASCADE'));
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _weighingTimeMeta =
      const VerificationMeta('weighingTime');
  @override
  late final GeneratedColumn<DateTime> weighingTime = GeneratedColumn<DateTime>(
      'weighing_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _batchNumberMeta =
      const VerificationMeta('batchNumber');
  @override
  late final GeneratedColumn<String> batchNumber = GeneratedColumn<String>(
      'batch_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pigTypeMeta =
      const VerificationMeta('pigType');
  @override
  late final GeneratedColumn<String> pigType = GeneratedColumn<String>(
      'pig_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        invoiceId,
        sequence,
        weight,
        quantity,
        weighingTime,
        batchNumber,
        pigType,
        note
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weighing_details';
  @override
  VerificationContext validateIntegrity(Insertable<WeighingDetail> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('weighing_time')) {
      context.handle(
          _weighingTimeMeta,
          weighingTime.isAcceptableOrUnknown(
              data['weighing_time']!, _weighingTimeMeta));
    } else if (isInserting) {
      context.missing(_weighingTimeMeta);
    }
    if (data.containsKey('batch_number')) {
      context.handle(
          _batchNumberMeta,
          batchNumber.isAcceptableOrUnknown(
              data['batch_number']!, _batchNumberMeta));
    }
    if (data.containsKey('pig_type')) {
      context.handle(_pigTypeMeta,
          pigType.isAcceptableOrUnknown(data['pig_type']!, _pigTypeMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeighingDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeighingDetail(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_id'])!,
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      weighingTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}weighing_time'])!,
      batchNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_number']),
      pigType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pig_type']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $WeighingDetailsTable createAlias(String alias) {
    return $WeighingDetailsTable(attachedDatabase, alias);
  }
}

class WeighingDetail extends DataClass implements Insertable<WeighingDetail> {
  final String id;
  final String invoiceId;
  final int sequence;
  final double weight;
  final int quantity;
  final DateTime weighingTime;
  final String? batchNumber;
  final String? pigType;
  final String? note;
  const WeighingDetail(
      {required this.id,
      required this.invoiceId,
      required this.sequence,
      required this.weight,
      required this.quantity,
      required this.weighingTime,
      this.batchNumber,
      this.pigType,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['sequence'] = Variable<int>(sequence);
    map['weight'] = Variable<double>(weight);
    map['quantity'] = Variable<int>(quantity);
    map['weighing_time'] = Variable<DateTime>(weighingTime);
    if (!nullToAbsent || batchNumber != null) {
      map['batch_number'] = Variable<String>(batchNumber);
    }
    if (!nullToAbsent || pigType != null) {
      map['pig_type'] = Variable<String>(pigType);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  WeighingDetailsCompanion toCompanion(bool nullToAbsent) {
    return WeighingDetailsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      sequence: Value(sequence),
      weight: Value(weight),
      quantity: Value(quantity),
      weighingTime: Value(weighingTime),
      batchNumber: batchNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(batchNumber),
      pigType: pigType == null && nullToAbsent
          ? const Value.absent()
          : Value(pigType),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory WeighingDetail.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeighingDetail(
      id: serializer.fromJson<String>(json['id']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      weight: serializer.fromJson<double>(json['weight']),
      quantity: serializer.fromJson<int>(json['quantity']),
      weighingTime: serializer.fromJson<DateTime>(json['weighingTime']),
      batchNumber: serializer.fromJson<String?>(json['batchNumber']),
      pigType: serializer.fromJson<String?>(json['pigType']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'sequence': serializer.toJson<int>(sequence),
      'weight': serializer.toJson<double>(weight),
      'quantity': serializer.toJson<int>(quantity),
      'weighingTime': serializer.toJson<DateTime>(weighingTime),
      'batchNumber': serializer.toJson<String?>(batchNumber),
      'pigType': serializer.toJson<String?>(pigType),
      'note': serializer.toJson<String?>(note),
    };
  }

  WeighingDetail copyWith(
          {String? id,
          String? invoiceId,
          int? sequence,
          double? weight,
          int? quantity,
          DateTime? weighingTime,
          Value<String?> batchNumber = const Value.absent(),
          Value<String?> pigType = const Value.absent(),
          Value<String?> note = const Value.absent()}) =>
      WeighingDetail(
        id: id ?? this.id,
        invoiceId: invoiceId ?? this.invoiceId,
        sequence: sequence ?? this.sequence,
        weight: weight ?? this.weight,
        quantity: quantity ?? this.quantity,
        weighingTime: weighingTime ?? this.weighingTime,
        batchNumber: batchNumber.present ? batchNumber.value : this.batchNumber,
        pigType: pigType.present ? pigType.value : this.pigType,
        note: note.present ? note.value : this.note,
      );
  WeighingDetail copyWithCompanion(WeighingDetailsCompanion data) {
    return WeighingDetail(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      weight: data.weight.present ? data.weight.value : this.weight,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      weighingTime: data.weighingTime.present
          ? data.weighingTime.value
          : this.weighingTime,
      batchNumber:
          data.batchNumber.present ? data.batchNumber.value : this.batchNumber,
      pigType: data.pigType.present ? data.pigType.value : this.pigType,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeighingDetail(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('sequence: $sequence, ')
          ..write('weight: $weight, ')
          ..write('quantity: $quantity, ')
          ..write('weighingTime: $weighingTime, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('pigType: $pigType, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, invoiceId, sequence, weight, quantity,
      weighingTime, batchNumber, pigType, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeighingDetail &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.sequence == this.sequence &&
          other.weight == this.weight &&
          other.quantity == this.quantity &&
          other.weighingTime == this.weighingTime &&
          other.batchNumber == this.batchNumber &&
          other.pigType == this.pigType &&
          other.note == this.note);
}

class WeighingDetailsCompanion extends UpdateCompanion<WeighingDetail> {
  final Value<String> id;
  final Value<String> invoiceId;
  final Value<int> sequence;
  final Value<double> weight;
  final Value<int> quantity;
  final Value<DateTime> weighingTime;
  final Value<String?> batchNumber;
  final Value<String?> pigType;
  final Value<String?> note;
  final Value<int> rowid;
  const WeighingDetailsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.weight = const Value.absent(),
    this.quantity = const Value.absent(),
    this.weighingTime = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.pigType = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeighingDetailsCompanion.insert({
    required String id,
    required String invoiceId,
    required int sequence,
    required double weight,
    this.quantity = const Value.absent(),
    required DateTime weighingTime,
    this.batchNumber = const Value.absent(),
    this.pigType = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        invoiceId = Value(invoiceId),
        sequence = Value(sequence),
        weight = Value(weight),
        weighingTime = Value(weighingTime);
  static Insertable<WeighingDetail> custom({
    Expression<String>? id,
    Expression<String>? invoiceId,
    Expression<int>? sequence,
    Expression<double>? weight,
    Expression<int>? quantity,
    Expression<DateTime>? weighingTime,
    Expression<String>? batchNumber,
    Expression<String>? pigType,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (sequence != null) 'sequence': sequence,
      if (weight != null) 'weight': weight,
      if (quantity != null) 'quantity': quantity,
      if (weighingTime != null) 'weighing_time': weighingTime,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (pigType != null) 'pig_type': pigType,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeighingDetailsCompanion copyWith(
      {Value<String>? id,
      Value<String>? invoiceId,
      Value<int>? sequence,
      Value<double>? weight,
      Value<int>? quantity,
      Value<DateTime>? weighingTime,
      Value<String?>? batchNumber,
      Value<String?>? pigType,
      Value<String?>? note,
      Value<int>? rowid}) {
    return WeighingDetailsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      sequence: sequence ?? this.sequence,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      weighingTime: weighingTime ?? this.weighingTime,
      batchNumber: batchNumber ?? this.batchNumber,
      pigType: pigType ?? this.pigType,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (weighingTime.present) {
      map['weighing_time'] = Variable<DateTime>(weighingTime.value);
    }
    if (batchNumber.present) {
      map['batch_number'] = Variable<String>(batchNumber.value);
    }
    if (pigType.present) {
      map['pig_type'] = Variable<String>(pigType.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeighingDetailsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('sequence: $sequence, ')
          ..write('weight: $weight, ')
          ..write('quantity: $quantity, ')
          ..write('weighingTime: $weighingTime, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('pigType: $pigType, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _partnerIdMeta =
      const VerificationMeta('partnerId');
  @override
  late final GeneratedColumn<String> partnerId = GeneratedColumn<String>(
      'partner_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES partners (id)'));
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
      'invoice_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES invoices (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
      'type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<int> paymentMethod = GeneratedColumn<int>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _transactionDateMeta =
      const VerificationMeta('transactionDate');
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>('transaction_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        partnerId,
        invoiceId,
        amount,
        type,
        paymentMethod,
        transactionDate,
        note
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('partner_id')) {
      context.handle(_partnerIdMeta,
          partnerId.isAcceptableOrUnknown(data['partner_id']!, _partnerIdMeta));
    } else if (isInserting) {
      context.missing(_partnerIdMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
          _transactionDateMeta,
          transactionDate.isAcceptableOrUnknown(
              data['transaction_date']!, _transactionDateMeta));
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      partnerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}partner_id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payment_method'])!,
      transactionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}transaction_date'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String partnerId;
  final String? invoiceId;
  final double amount;
  final int type;
  final int paymentMethod;
  final DateTime transactionDate;
  final String? note;
  const Transaction(
      {required this.id,
      required this.partnerId,
      this.invoiceId,
      required this.amount,
      required this.type,
      required this.paymentMethod,
      required this.transactionDate,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['partner_id'] = Variable<String>(partnerId);
    if (!nullToAbsent || invoiceId != null) {
      map['invoice_id'] = Variable<String>(invoiceId);
    }
    map['amount'] = Variable<double>(amount);
    map['type'] = Variable<int>(type);
    map['payment_method'] = Variable<int>(paymentMethod);
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      partnerId: Value(partnerId),
      invoiceId: invoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceId),
      amount: Value(amount),
      type: Value(type),
      paymentMethod: Value(paymentMethod),
      transactionDate: Value(transactionDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      partnerId: serializer.fromJson<String>(json['partnerId']),
      invoiceId: serializer.fromJson<String?>(json['invoiceId']),
      amount: serializer.fromJson<double>(json['amount']),
      type: serializer.fromJson<int>(json['type']),
      paymentMethod: serializer.fromJson<int>(json['paymentMethod']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'partnerId': serializer.toJson<String>(partnerId),
      'invoiceId': serializer.toJson<String?>(invoiceId),
      'amount': serializer.toJson<double>(amount),
      'type': serializer.toJson<int>(type),
      'paymentMethod': serializer.toJson<int>(paymentMethod),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'note': serializer.toJson<String?>(note),
    };
  }

  Transaction copyWith(
          {String? id,
          String? partnerId,
          Value<String?> invoiceId = const Value.absent(),
          double? amount,
          int? type,
          int? paymentMethod,
          DateTime? transactionDate,
          Value<String?> note = const Value.absent()}) =>
      Transaction(
        id: id ?? this.id,
        partnerId: partnerId ?? this.partnerId,
        invoiceId: invoiceId.present ? invoiceId.value : this.invoiceId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        transactionDate: transactionDate ?? this.transactionDate,
        note: note.present ? note.value : this.note,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      partnerId: data.partnerId.present ? data.partnerId.value : this.partnerId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('partnerId: $partnerId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, partnerId, invoiceId, amount, type,
      paymentMethod, transactionDate, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.partnerId == this.partnerId &&
          other.invoiceId == this.invoiceId &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.paymentMethod == this.paymentMethod &&
          other.transactionDate == this.transactionDate &&
          other.note == this.note);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> partnerId;
  final Value<String?> invoiceId;
  final Value<double> amount;
  final Value<int> type;
  final Value<int> paymentMethod;
  final Value<DateTime> transactionDate;
  final Value<String?> note;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.partnerId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String partnerId,
    this.invoiceId = const Value.absent(),
    required double amount,
    required int type,
    this.paymentMethod = const Value.absent(),
    required DateTime transactionDate,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        partnerId = Value(partnerId),
        amount = Value(amount),
        type = Value(type),
        transactionDate = Value(transactionDate);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? partnerId,
    Expression<String>? invoiceId,
    Expression<double>? amount,
    Expression<int>? type,
    Expression<int>? paymentMethod,
    Expression<DateTime>? transactionDate,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partnerId != null) 'partner_id': partnerId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? partnerId,
      Value<String?>? invoiceId,
      Value<double>? amount,
      Value<int>? type,
      Value<int>? paymentMethod,
      Value<DateTime>? transactionDate,
      Value<String?>? note,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (partnerId.present) {
      map['partner_id'] = Variable<String>(partnerId.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<int>(paymentMethod.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('partnerId: $partnerId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PigTypesTable extends PigTypes with TableInfo<$PigTypesTable, PigType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PigTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, description, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pig_types';
  @override
  VerificationContext validateIntegrity(Insertable<PigType> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PigType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PigType(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $PigTypesTable createAlias(String alias) {
    return $PigTypesTable(attachedDatabase, alias);
  }
}

class PigType extends DataClass implements Insertable<PigType> {
  final String id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  const PigType(
      {required this.id, required this.name, this.description, this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  PigTypesCompanion toCompanion(bool nullToAbsent) {
    return PigTypesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory PigType.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PigType(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  PigType copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      PigType(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  PigType copyWithCompanion(PigTypesCompanion data) {
    return PigType(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PigType(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PigType &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class PigTypesCompanion extends UpdateCompanion<PigType> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const PigTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PigTypesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<PigType> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PigTypesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return PigTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PigTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FarmsTable extends Farms with TableInfo<$FarmsTable, Farm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FarmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _partnerIdMeta =
      const VerificationMeta('partnerId');
  @override
  late final GeneratedColumn<String> partnerId = GeneratedColumn<String>(
      'partner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, partnerId, address, phone, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'farms';
  @override
  VerificationContext validateIntegrity(Insertable<Farm> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('partner_id')) {
      context.handle(_partnerIdMeta,
          partnerId.isAcceptableOrUnknown(data['partner_id']!, _partnerIdMeta));
    } else if (isInserting) {
      context.missing(_partnerIdMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Farm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Farm(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      partnerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}partner_id'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FarmsTable createAlias(String alias) {
    return $FarmsTable(attachedDatabase, alias);
  }
}

class Farm extends DataClass implements Insertable<Farm> {
  final String id;
  final String name;
  final String partnerId;
  final String? address;
  final String? phone;
  final String? note;
  final DateTime createdAt;
  const Farm(
      {required this.id,
      required this.name,
      required this.partnerId,
      this.address,
      this.phone,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['partner_id'] = Variable<String>(partnerId);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FarmsCompanion toCompanion(bool nullToAbsent) {
    return FarmsCompanion(
      id: Value(id),
      name: Value(name),
      partnerId: Value(partnerId),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Farm.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Farm(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      partnerId: serializer.fromJson<String>(json['partnerId']),
      address: serializer.fromJson<String?>(json['address']),
      phone: serializer.fromJson<String?>(json['phone']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'partnerId': serializer.toJson<String>(partnerId),
      'address': serializer.toJson<String?>(address),
      'phone': serializer.toJson<String?>(phone),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Farm copyWith(
          {String? id,
          String? name,
          String? partnerId,
          Value<String?> address = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      Farm(
        id: id ?? this.id,
        name: name ?? this.name,
        partnerId: partnerId ?? this.partnerId,
        address: address.present ? address.value : this.address,
        phone: phone.present ? phone.value : this.phone,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  Farm copyWithCompanion(FarmsCompanion data) {
    return Farm(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      partnerId: data.partnerId.present ? data.partnerId.value : this.partnerId,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Farm(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('partnerId: $partnerId, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, partnerId, address, phone, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Farm &&
          other.id == this.id &&
          other.name == this.name &&
          other.partnerId == this.partnerId &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class FarmsCompanion extends UpdateCompanion<Farm> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> partnerId;
  final Value<String?> address;
  final Value<String?> phone;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FarmsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.partnerId = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FarmsCompanion.insert({
    required String id,
    required String name,
    required String partnerId,
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        partnerId = Value(partnerId);
  static Insertable<Farm> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? partnerId,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (partnerId != null) 'partner_id': partnerId,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FarmsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? partnerId,
      Value<String?>? address,
      Value<String?>? phone,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return FarmsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      partnerId: partnerId ?? this.partnerId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (partnerId.present) {
      map['partner_id'] = Variable<String>(partnerId.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FarmsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('partnerId: $partnerId, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isAdminMeta =
      const VerificationMeta('isAdmin');
  @override
  late final GeneratedColumn<bool> isAdmin = GeneratedColumn<bool>(
      'is_admin', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_admin" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastLoginMeta =
      const VerificationMeta('lastLogin');
  @override
  late final GeneratedColumn<DateTime> lastLogin = GeneratedColumn<DateTime>(
      'last_login', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        username,
        password,
        displayName,
        isAdmin,
        isActive,
        createdAt,
        lastLogin
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('is_admin')) {
      context.handle(_isAdminMeta,
          isAdmin.isAcceptableOrUnknown(data['is_admin']!, _isAdminMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_login')) {
      context.handle(_lastLoginMeta,
          lastLogin.isAcceptableOrUnknown(data['last_login']!, _lastLoginMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      isAdmin: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_admin'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastLogin: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_login']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String username;
  final String password;
  final String? displayName;
  final bool isAdmin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  const User(
      {required this.id,
      required this.username,
      required this.password,
      this.displayName,
      required this.isAdmin,
      required this.isActive,
      required this.createdAt,
      this.lastLogin});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['is_admin'] = Variable<bool>(isAdmin);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastLogin != null) {
      map['last_login'] = Variable<DateTime>(lastLogin);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      password: Value(password),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      isAdmin: Value(isAdmin),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      lastLogin: lastLogin == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLogin),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      isAdmin: serializer.fromJson<bool>(json['isAdmin']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastLogin: serializer.fromJson<DateTime?>(json['lastLogin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'displayName': serializer.toJson<String?>(displayName),
      'isAdmin': serializer.toJson<bool>(isAdmin),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastLogin': serializer.toJson<DateTime?>(lastLogin),
    };
  }

  User copyWith(
          {String? id,
          String? username,
          String? password,
          Value<String?> displayName = const Value.absent(),
          bool? isAdmin,
          bool? isActive,
          DateTime? createdAt,
          Value<DateTime?> lastLogin = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        displayName: displayName.present ? displayName.value : this.displayName,
        isAdmin: isAdmin ?? this.isAdmin,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        lastLogin: lastLogin.present ? lastLogin.value : this.lastLogin,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      isAdmin: data.isAdmin.present ? data.isAdmin.value : this.isAdmin,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastLogin: data.lastLogin.present ? data.lastLogin.value : this.lastLogin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('displayName: $displayName, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLogin: $lastLogin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, username, password, displayName, isAdmin,
      isActive, createdAt, lastLogin);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.password == this.password &&
          other.displayName == this.displayName &&
          other.isAdmin == this.isAdmin &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.lastLogin == this.lastLogin);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> username;
  final Value<String> password;
  final Value<String?> displayName;
  final Value<bool> isAdmin;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastLogin;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isAdmin = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLogin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String username,
    required String password,
    this.displayName = const Value.absent(),
    this.isAdmin = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    this.lastLogin = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        username = Value(username),
        password = Value(password),
        createdAt = Value(createdAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? displayName,
    Expression<bool>? isAdmin,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastLogin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (displayName != null) 'display_name': displayName,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (lastLogin != null) 'last_login': lastLogin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? username,
      Value<String>? password,
      Value<String?>? displayName,
      Value<bool>? isAdmin,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastLogin,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isAdmin.present) {
      map['is_admin'] = Variable<bool>(isAdmin.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastLogin.present) {
      map['last_login'] = Variable<DateTime>(lastLogin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('displayName: $displayName, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLogin: $lastLogin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PartnersTable partners = $PartnersTable(this);
  late final $CagesTable cages = $CagesTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $WeighingDetailsTable weighingDetails =
      $WeighingDetailsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $PigTypesTable pigTypes = $PigTypesTable(this);
  late final $FarmsTable farms = $FarmsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final PartnersDao partnersDao = PartnersDao(this as AppDatabase);
  late final InvoicesDao invoicesDao = InvoicesDao(this as AppDatabase);
  late final WeighingDetailsDao weighingDetailsDao =
      WeighingDetailsDao(this as AppDatabase);
  late final TransactionsDao transactionsDao =
      TransactionsDao(this as AppDatabase);
  late final PigTypesDao pigTypesDao = PigTypesDao(this as AppDatabase);
  late final FarmsDao farmsDao = FarmsDao(this as AppDatabase);
  late final CagesDao cagesDao = CagesDao(this as AppDatabase);
  late final UsersDao usersDao = UsersDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        partners,
        cages,
        invoices,
        weighingDetails,
        transactions,
        pigTypes,
        farms,
        users
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('invoices',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('weighing_details', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$PartnersTableCreateCompanionBuilder = PartnersCompanion Function({
  required String id,
  required String name,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> code,
  Value<bool> isSupplier,
  Value<double> currentDebt,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$PartnersTableUpdateCompanionBuilder = PartnersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> code,
  Value<bool> isSupplier,
  Value<double> currentDebt,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

final class $$PartnersTableReferences
    extends BaseReferences<_$AppDatabase, $PartnersTable, Partner> {
  $$PartnersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoicesTable, List<Invoice>> _invoicesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.invoices,
          aliasName:
              $_aliasNameGenerator(db.partners.id, db.invoices.partnerId));

  $$InvoicesTableProcessedTableManager get invoicesRefs {
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.partnerId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_invoicesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.transactions,
          aliasName:
              $_aliasNameGenerator(db.partners.id, db.transactions.partnerId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.partnerId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PartnersTableFilterComposer
    extends Composer<_$AppDatabase, $PartnersTable> {
  $$PartnersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSupplier => $composableBuilder(
      column: $table.isSupplier, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentDebt => $composableBuilder(
      column: $table.currentDebt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));

  Expression<bool> invoicesRefs(
      Expression<bool> Function($$InvoicesTableFilterComposer f) f) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.partnerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.partnerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PartnersTableOrderingComposer
    extends Composer<_$AppDatabase, $PartnersTable> {
  $$PartnersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSupplier => $composableBuilder(
      column: $table.isSupplier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentDebt => $composableBuilder(
      column: $table.currentDebt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$PartnersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PartnersTable> {
  $$PartnersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<bool> get isSupplier => $composableBuilder(
      column: $table.isSupplier, builder: (column) => column);

  GeneratedColumn<double> get currentDebt => $composableBuilder(
      column: $table.currentDebt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);

  Expression<T> invoicesRefs<T extends Object>(
      Expression<T> Function($$InvoicesTableAnnotationComposer a) f) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.partnerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.partnerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PartnersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PartnersTable,
    Partner,
    $$PartnersTableFilterComposer,
    $$PartnersTableOrderingComposer,
    $$PartnersTableAnnotationComposer,
    $$PartnersTableCreateCompanionBuilder,
    $$PartnersTableUpdateCompanionBuilder,
    (Partner, $$PartnersTableReferences),
    Partner,
    PrefetchHooks Function({bool invoicesRefs, bool transactionsRefs})> {
  $$PartnersTableTableManager(_$AppDatabase db, $PartnersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PartnersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PartnersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PartnersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> code = const Value.absent(),
            Value<bool> isSupplier = const Value.absent(),
            Value<double> currentDebt = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PartnersCompanion(
            id: id,
            name: name,
            phone: phone,
            address: address,
            code: code,
            isSupplier: isSupplier,
            currentDebt: currentDebt,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> code = const Value.absent(),
            Value<bool> isSupplier = const Value.absent(),
            Value<double> currentDebt = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PartnersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            address: address,
            code: code,
            isSupplier: isSupplier,
            currentDebt: currentDebt,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PartnersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {invoicesRefs = false, transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (invoicesRefs) db.invoices,
                if (transactionsRefs) db.transactions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoicesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PartnersTableReferences._invoicesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PartnersTableReferences(db, table, p0)
                                .invoicesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.partnerId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$PartnersTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PartnersTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.partnerId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PartnersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PartnersTable,
    Partner,
    $$PartnersTableFilterComposer,
    $$PartnersTableOrderingComposer,
    $$PartnersTableAnnotationComposer,
    $$PartnersTableCreateCompanionBuilder,
    $$PartnersTableUpdateCompanionBuilder,
    (Partner, $$PartnersTableReferences),
    Partner,
    PrefetchHooks Function({bool invoicesRefs, bool transactionsRefs})>;
typedef $$CagesTableCreateCompanionBuilder = CagesCompanion Function({
  required String id,
  required String name,
  Value<int?> capacity,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$CagesTableUpdateCompanionBuilder = CagesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int?> capacity,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$CagesTableReferences
    extends BaseReferences<_$AppDatabase, $CagesTable, Cage> {
  $$CagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoicesTable, List<Invoice>> _invoicesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.invoices,
          aliasName: $_aliasNameGenerator(db.cages.id, db.invoices.cageId));

  $$InvoicesTableProcessedTableManager get invoicesRefs {
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.cageId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_invoicesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CagesTableFilterComposer extends Composer<_$AppDatabase, $CagesTable> {
  $$CagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get capacity => $composableBuilder(
      column: $table.capacity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> invoicesRefs(
      Expression<bool> Function($$InvoicesTableFilterComposer f) f) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.cageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CagesTable> {
  $$CagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capacity => $composableBuilder(
      column: $table.capacity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CagesTable> {
  $$CagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> invoicesRefs<T extends Object>(
      Expression<T> Function($$InvoicesTableAnnotationComposer a) f) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.cageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CagesTable,
    Cage,
    $$CagesTableFilterComposer,
    $$CagesTableOrderingComposer,
    $$CagesTableAnnotationComposer,
    $$CagesTableCreateCompanionBuilder,
    $$CagesTableUpdateCompanionBuilder,
    (Cage, $$CagesTableReferences),
    Cage,
    PrefetchHooks Function({bool invoicesRefs})> {
  $$CagesTableTableManager(_$AppDatabase db, $CagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> capacity = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CagesCompanion(
            id: id,
            name: name,
            capacity: capacity,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int?> capacity = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CagesCompanion.insert(
            id: id,
            name: name,
            capacity: capacity,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$CagesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({invoicesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (invoicesRefs) db.invoices],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoicesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$CagesTableReferences._invoicesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CagesTableReferences(db, table, p0).invoicesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cageId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CagesTable,
    Cage,
    $$CagesTableFilterComposer,
    $$CagesTableOrderingComposer,
    $$CagesTableAnnotationComposer,
    $$CagesTableCreateCompanionBuilder,
    $$CagesTableUpdateCompanionBuilder,
    (Cage, $$CagesTableReferences),
    Cage,
    PrefetchHooks Function({bool invoicesRefs})>;
typedef $$InvoicesTableCreateCompanionBuilder = InvoicesCompanion Function({
  required String id,
  Value<String?> invoiceCode,
  Value<String?> partnerId,
  Value<String?> cageId,
  required int type,
  required DateTime createdDate,
  Value<double> totalWeight,
  Value<int> totalQuantity,
  Value<double> pricePerKg,
  Value<double> truckCost,
  Value<double> discount,
  Value<double> finalAmount,
  Value<double> paidAmount,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$InvoicesTableUpdateCompanionBuilder = InvoicesCompanion Function({
  Value<String> id,
  Value<String?> invoiceCode,
  Value<String?> partnerId,
  Value<String?> cageId,
  Value<int> type,
  Value<DateTime> createdDate,
  Value<double> totalWeight,
  Value<int> totalQuantity,
  Value<double> pricePerKg,
  Value<double> truckCost,
  Value<double> discount,
  Value<double> finalAmount,
  Value<double> paidAmount,
  Value<String?> note,
  Value<int> rowid,
});

final class $$InvoicesTableReferences
    extends BaseReferences<_$AppDatabase, $InvoicesTable, Invoice> {
  $$InvoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PartnersTable _partnerIdTable(_$AppDatabase db) => db.partners
      .createAlias($_aliasNameGenerator(db.invoices.partnerId, db.partners.id));

  $$PartnersTableProcessedTableManager? get partnerId {
    if ($_item.partnerId == null) return null;
    final manager = $$PartnersTableTableManager($_db, $_db.partners)
        .filter((f) => f.id($_item.partnerId!));
    final item = $_typedResult.readTableOrNull(_partnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CagesTable _cageIdTable(_$AppDatabase db) => db.cages
      .createAlias($_aliasNameGenerator(db.invoices.cageId, db.cages.id));

  $$CagesTableProcessedTableManager? get cageId {
    if ($_item.cageId == null) return null;
    final manager = $$CagesTableTableManager($_db, $_db.cages)
        .filter((f) => f.id($_item.cageId!));
    final item = $_typedResult.readTableOrNull(_cageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$WeighingDetailsTable, List<WeighingDetail>>
      _weighingDetailsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.weighingDetails,
              aliasName: $_aliasNameGenerator(
                  db.invoices.id, db.weighingDetails.invoiceId));

  $$WeighingDetailsTableProcessedTableManager get weighingDetailsRefs {
    final manager =
        $$WeighingDetailsTableTableManager($_db, $_db.weighingDetails)
            .filter((f) => f.invoiceId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_weighingDetailsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.transactions,
          aliasName:
              $_aliasNameGenerator(db.invoices.id, db.transactions.invoiceId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.invoiceId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$InvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceCode => $composableBuilder(
      column: $table.invoiceCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdDate => $composableBuilder(
      column: $table.createdDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalWeight => $composableBuilder(
      column: $table.totalWeight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalQuantity => $composableBuilder(
      column: $table.totalQuantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pricePerKg => $composableBuilder(
      column: $table.pricePerKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get truckCost => $composableBuilder(
      column: $table.truckCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get finalAmount => $composableBuilder(
      column: $table.finalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$PartnersTableFilterComposer get partnerId {
    final $$PartnersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partnerId,
        referencedTable: $db.partners,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartnersTableFilterComposer(
              $db: $db,
              $table: $db.partners,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CagesTableFilterComposer get cageId {
    final $$CagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cageId,
        referencedTable: $db.cages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CagesTableFilterComposer(
              $db: $db,
              $table: $db.cages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> weighingDetailsRefs(
      Expression<bool> Function($$WeighingDetailsTableFilterComposer f) f) {
    final $$WeighingDetailsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.weighingDetails,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WeighingDetailsTableFilterComposer(
              $db: $db,
              $table: $db.weighingDetails,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceCode => $composableBuilder(
      column: $table.invoiceCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdDate => $composableBuilder(
      column: $table.createdDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalWeight => $composableBuilder(
      column: $table.totalWeight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalQuantity => $composableBuilder(
      column: $table.totalQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pricePerKg => $composableBuilder(
      column: $table.pricePerKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get truckCost => $composableBuilder(
      column: $table.truckCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get finalAmount => $composableBuilder(
      column: $table.finalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$PartnersTableOrderingComposer get partnerId {
    final $$PartnersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partnerId,
        referencedTable: $db.partners,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartnersTableOrderingComposer(
              $db: $db,
              $table: $db.partners,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CagesTableOrderingComposer get cageId {
    final $$CagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cageId,
        referencedTable: $db.cages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CagesTableOrderingComposer(
              $db: $db,
              $table: $db.cages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceCode => $composableBuilder(
      column: $table.invoiceCode, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdDate => $composableBuilder(
      column: $table.createdDate, builder: (column) => column);

  GeneratedColumn<double> get totalWeight => $composableBuilder(
      column: $table.totalWeight, builder: (column) => column);

  GeneratedColumn<int> get totalQuantity => $composableBuilder(
      column: $table.totalQuantity, builder: (column) => column);

  GeneratedColumn<double> get pricePerKg => $composableBuilder(
      column: $table.pricePerKg, builder: (column) => column);

  GeneratedColumn<double> get truckCost =>
      $composableBuilder(column: $table.truckCost, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<double> get finalAmount => $composableBuilder(
      column: $table.finalAmount, builder: (column) => column);

  GeneratedColumn<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$PartnersTableAnnotationComposer get partnerId {
    final $$PartnersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partnerId,
        referencedTable: $db.partners,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartnersTableAnnotationComposer(
              $db: $db,
              $table: $db.partners,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CagesTableAnnotationComposer get cageId {
    final $$CagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cageId,
        referencedTable: $db.cages,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CagesTableAnnotationComposer(
              $db: $db,
              $table: $db.cages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> weighingDetailsRefs<T extends Object>(
      Expression<T> Function($$WeighingDetailsTableAnnotationComposer a) f) {
    final $$WeighingDetailsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.weighingDetails,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WeighingDetailsTableAnnotationComposer(
              $db: $db,
              $table: $db.weighingDetails,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InvoicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InvoicesTable,
    Invoice,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (Invoice, $$InvoicesTableReferences),
    Invoice,
    PrefetchHooks Function(
        {bool partnerId,
        bool cageId,
        bool weighingDetailsRefs,
        bool transactionsRefs})> {
  $$InvoicesTableTableManager(_$AppDatabase db, $InvoicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> invoiceCode = const Value.absent(),
            Value<String?> partnerId = const Value.absent(),
            Value<String?> cageId = const Value.absent(),
            Value<int> type = const Value.absent(),
            Value<DateTime> createdDate = const Value.absent(),
            Value<double> totalWeight = const Value.absent(),
            Value<int> totalQuantity = const Value.absent(),
            Value<double> pricePerKg = const Value.absent(),
            Value<double> truckCost = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> finalAmount = const Value.absent(),
            Value<double> paidAmount = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoicesCompanion(
            id: id,
            invoiceCode: invoiceCode,
            partnerId: partnerId,
            cageId: cageId,
            type: type,
            createdDate: createdDate,
            totalWeight: totalWeight,
            totalQuantity: totalQuantity,
            pricePerKg: pricePerKg,
            truckCost: truckCost,
            discount: discount,
            finalAmount: finalAmount,
            paidAmount: paidAmount,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> invoiceCode = const Value.absent(),
            Value<String?> partnerId = const Value.absent(),
            Value<String?> cageId = const Value.absent(),
            required int type,
            required DateTime createdDate,
            Value<double> totalWeight = const Value.absent(),
            Value<int> totalQuantity = const Value.absent(),
            Value<double> pricePerKg = const Value.absent(),
            Value<double> truckCost = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> finalAmount = const Value.absent(),
            Value<double> paidAmount = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoicesCompanion.insert(
            id: id,
            invoiceCode: invoiceCode,
            partnerId: partnerId,
            cageId: cageId,
            type: type,
            createdDate: createdDate,
            totalWeight: totalWeight,
            totalQuantity: totalQuantity,
            pricePerKg: pricePerKg,
            truckCost: truckCost,
            discount: discount,
            finalAmount: finalAmount,
            paidAmount: paidAmount,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$InvoicesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {partnerId = false,
              cageId = false,
              weighingDetailsRefs = false,
              transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (weighingDetailsRefs) db.weighingDetails,
                if (transactionsRefs) db.transactions
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (partnerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.partnerId,
                    referencedTable:
                        $$InvoicesTableReferences._partnerIdTable(db),
                    referencedColumn:
                        $$InvoicesTableReferences._partnerIdTable(db).id,
                  ) as T;
                }
                if (cageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cageId,
                    referencedTable: $$InvoicesTableReferences._cageIdTable(db),
                    referencedColumn:
                        $$InvoicesTableReferences._cageIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (weighingDetailsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$InvoicesTableReferences
                            ._weighingDetailsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InvoicesTableReferences(db, table, p0)
                                .weighingDetailsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.invoiceId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$InvoicesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InvoicesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.invoiceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$InvoicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InvoicesTable,
    Invoice,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (Invoice, $$InvoicesTableReferences),
    Invoice,
    PrefetchHooks Function(
        {bool partnerId,
        bool cageId,
        bool weighingDetailsRefs,
        bool transactionsRefs})>;
typedef $$WeighingDetailsTableCreateCompanionBuilder = WeighingDetailsCompanion
    Function({
  required String id,
  required String invoiceId,
  required int sequence,
  required double weight,
  Value<int> quantity,
  required DateTime weighingTime,
  Value<String?> batchNumber,
  Value<String?> pigType,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$WeighingDetailsTableUpdateCompanionBuilder = WeighingDetailsCompanion
    Function({
  Value<String> id,
  Value<String> invoiceId,
  Value<int> sequence,
  Value<double> weight,
  Value<int> quantity,
  Value<DateTime> weighingTime,
  Value<String?> batchNumber,
  Value<String?> pigType,
  Value<String?> note,
  Value<int> rowid,
});

final class $$WeighingDetailsTableReferences extends BaseReferences<
    _$AppDatabase, $WeighingDetailsTable, WeighingDetail> {
  $$WeighingDetailsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias(
          $_aliasNameGenerator(db.weighingDetails.invoiceId, db.invoices.id));

  $$InvoicesTableProcessedTableManager? get invoiceId {
    if ($_item.invoiceId == null) return null;
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.id($_item.invoiceId!));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WeighingDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $WeighingDetailsTable> {
  $$WeighingDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get weighingTime => $composableBuilder(
      column: $table.weighingTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get batchNumber => $composableBuilder(
      column: $table.batchNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pigType => $composableBuilder(
      column: $table.pigType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WeighingDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeighingDetailsTable> {
  $$WeighingDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get weighingTime => $composableBuilder(
      column: $table.weighingTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get batchNumber => $composableBuilder(
      column: $table.batchNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pigType => $composableBuilder(
      column: $table.pigType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableOrderingComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WeighingDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeighingDetailsTable> {
  $$WeighingDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<DateTime> get weighingTime => $composableBuilder(
      column: $table.weighingTime, builder: (column) => column);

  GeneratedColumn<String> get batchNumber => $composableBuilder(
      column: $table.batchNumber, builder: (column) => column);

  GeneratedColumn<String> get pigType =>
      $composableBuilder(column: $table.pigType, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WeighingDetailsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeighingDetailsTable,
    WeighingDetail,
    $$WeighingDetailsTableFilterComposer,
    $$WeighingDetailsTableOrderingComposer,
    $$WeighingDetailsTableAnnotationComposer,
    $$WeighingDetailsTableCreateCompanionBuilder,
    $$WeighingDetailsTableUpdateCompanionBuilder,
    (WeighingDetail, $$WeighingDetailsTableReferences),
    WeighingDetail,
    PrefetchHooks Function({bool invoiceId})> {
  $$WeighingDetailsTableTableManager(
      _$AppDatabase db, $WeighingDetailsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeighingDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeighingDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeighingDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> invoiceId = const Value.absent(),
            Value<int> sequence = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<DateTime> weighingTime = const Value.absent(),
            Value<String?> batchNumber = const Value.absent(),
            Value<String?> pigType = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WeighingDetailsCompanion(
            id: id,
            invoiceId: invoiceId,
            sequence: sequence,
            weight: weight,
            quantity: quantity,
            weighingTime: weighingTime,
            batchNumber: batchNumber,
            pigType: pigType,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String invoiceId,
            required int sequence,
            required double weight,
            Value<int> quantity = const Value.absent(),
            required DateTime weighingTime,
            Value<String?> batchNumber = const Value.absent(),
            Value<String?> pigType = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WeighingDetailsCompanion.insert(
            id: id,
            invoiceId: invoiceId,
            sequence: sequence,
            weight: weight,
            quantity: quantity,
            weighingTime: weighingTime,
            batchNumber: batchNumber,
            pigType: pigType,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WeighingDetailsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (invoiceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.invoiceId,
                    referencedTable:
                        $$WeighingDetailsTableReferences._invoiceIdTable(db),
                    referencedColumn:
                        $$WeighingDetailsTableReferences._invoiceIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WeighingDetailsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WeighingDetailsTable,
    WeighingDetail,
    $$WeighingDetailsTableFilterComposer,
    $$WeighingDetailsTableOrderingComposer,
    $$WeighingDetailsTableAnnotationComposer,
    $$WeighingDetailsTableCreateCompanionBuilder,
    $$WeighingDetailsTableUpdateCompanionBuilder,
    (WeighingDetail, $$WeighingDetailsTableReferences),
    WeighingDetail,
    PrefetchHooks Function({bool invoiceId})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  required String id,
  required String partnerId,
  Value<String?> invoiceId,
  required double amount,
  required int type,
  Value<int> paymentMethod,
  required DateTime transactionDate,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  Value<String> partnerId,
  Value<String?> invoiceId,
  Value<double> amount,
  Value<int> type,
  Value<int> paymentMethod,
  Value<DateTime> transactionDate,
  Value<String?> note,
  Value<int> rowid,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PartnersTable _partnerIdTable(_$AppDatabase db) =>
      db.partners.createAlias(
          $_aliasNameGenerator(db.transactions.partnerId, db.partners.id));

  $$PartnersTableProcessedTableManager? get partnerId {
    if ($_item.partnerId == null) return null;
    final manager = $$PartnersTableTableManager($_db, $_db.partners)
        .filter((f) => f.id($_item.partnerId!));
    final item = $_typedResult.readTableOrNull(_partnerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $InvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.invoices.createAlias(
          $_aliasNameGenerator(db.transactions.invoiceId, db.invoices.id));

  $$InvoicesTableProcessedTableManager? get invoiceId {
    if ($_item.invoiceId == null) return null;
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.id($_item.invoiceId!));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$PartnersTableFilterComposer get partnerId {
    final $$PartnersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partnerId,
        referencedTable: $db.partners,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartnersTableFilterComposer(
              $db: $db,
              $table: $db.partners,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$PartnersTableOrderingComposer get partnerId {
    final $$PartnersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partnerId,
        referencedTable: $db.partners,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartnersTableOrderingComposer(
              $db: $db,
              $table: $db.partners,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableOrderingComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$PartnersTableAnnotationComposer get partnerId {
    final $$PartnersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.partnerId,
        referencedTable: $db.partners,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PartnersTableAnnotationComposer(
              $db: $db,
              $table: $db.partners,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function({bool partnerId, bool invoiceId})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> partnerId = const Value.absent(),
            Value<String?> invoiceId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<int> type = const Value.absent(),
            Value<int> paymentMethod = const Value.absent(),
            Value<DateTime> transactionDate = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            partnerId: partnerId,
            invoiceId: invoiceId,
            amount: amount,
            type: type,
            paymentMethod: paymentMethod,
            transactionDate: transactionDate,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String partnerId,
            Value<String?> invoiceId = const Value.absent(),
            required double amount,
            required int type,
            Value<int> paymentMethod = const Value.absent(),
            required DateTime transactionDate,
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            partnerId: partnerId,
            invoiceId: invoiceId,
            amount: amount,
            type: type,
            paymentMethod: paymentMethod,
            transactionDate: transactionDate,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({partnerId = false, invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (partnerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.partnerId,
                    referencedTable:
                        $$TransactionsTableReferences._partnerIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._partnerIdTable(db).id,
                  ) as T;
                }
                if (invoiceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.invoiceId,
                    referencedTable:
                        $$TransactionsTableReferences._invoiceIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._invoiceIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function({bool partnerId, bool invoiceId})>;
typedef $$PigTypesTableCreateCompanionBuilder = PigTypesCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$PigTypesTableUpdateCompanionBuilder = PigTypesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$PigTypesTableFilterComposer
    extends Composer<_$AppDatabase, $PigTypesTable> {
  $$PigTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PigTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $PigTypesTable> {
  $$PigTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PigTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PigTypesTable> {
  $$PigTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PigTypesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PigTypesTable,
    PigType,
    $$PigTypesTableFilterComposer,
    $$PigTypesTableOrderingComposer,
    $$PigTypesTableAnnotationComposer,
    $$PigTypesTableCreateCompanionBuilder,
    $$PigTypesTableUpdateCompanionBuilder,
    (PigType, BaseReferences<_$AppDatabase, $PigTypesTable, PigType>),
    PigType,
    PrefetchHooks Function()> {
  $$PigTypesTableTableManager(_$AppDatabase db, $PigTypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PigTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PigTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PigTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PigTypesCompanion(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PigTypesCompanion.insert(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PigTypesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PigTypesTable,
    PigType,
    $$PigTypesTableFilterComposer,
    $$PigTypesTableOrderingComposer,
    $$PigTypesTableAnnotationComposer,
    $$PigTypesTableCreateCompanionBuilder,
    $$PigTypesTableUpdateCompanionBuilder,
    (PigType, BaseReferences<_$AppDatabase, $PigTypesTable, PigType>),
    PigType,
    PrefetchHooks Function()>;
typedef $$FarmsTableCreateCompanionBuilder = FarmsCompanion Function({
  required String id,
  required String name,
  required String partnerId,
  Value<String?> address,
  Value<String?> phone,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$FarmsTableUpdateCompanionBuilder = FarmsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> partnerId,
  Value<String?> address,
  Value<String?> phone,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$FarmsTableFilterComposer extends Composer<_$AppDatabase, $FarmsTable> {
  $$FarmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partnerId => $composableBuilder(
      column: $table.partnerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$FarmsTableOrderingComposer
    extends Composer<_$AppDatabase, $FarmsTable> {
  $$FarmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partnerId => $composableBuilder(
      column: $table.partnerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$FarmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FarmsTable> {
  $$FarmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get partnerId =>
      $composableBuilder(column: $table.partnerId, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FarmsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FarmsTable,
    Farm,
    $$FarmsTableFilterComposer,
    $$FarmsTableOrderingComposer,
    $$FarmsTableAnnotationComposer,
    $$FarmsTableCreateCompanionBuilder,
    $$FarmsTableUpdateCompanionBuilder,
    (Farm, BaseReferences<_$AppDatabase, $FarmsTable, Farm>),
    Farm,
    PrefetchHooks Function()> {
  $$FarmsTableTableManager(_$AppDatabase db, $FarmsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FarmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FarmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FarmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> partnerId = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FarmsCompanion(
            id: id,
            name: name,
            partnerId: partnerId,
            address: address,
            phone: phone,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String partnerId,
            Value<String?> address = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FarmsCompanion.insert(
            id: id,
            name: name,
            partnerId: partnerId,
            address: address,
            phone: phone,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FarmsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FarmsTable,
    Farm,
    $$FarmsTableFilterComposer,
    $$FarmsTableOrderingComposer,
    $$FarmsTableAnnotationComposer,
    $$FarmsTableCreateCompanionBuilder,
    $$FarmsTableUpdateCompanionBuilder,
    (Farm, BaseReferences<_$AppDatabase, $FarmsTable, Farm>),
    Farm,
    PrefetchHooks Function()>;
typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String username,
  required String password,
  Value<String?> displayName,
  Value<bool> isAdmin,
  Value<bool> isActive,
  required DateTime createdAt,
  Value<DateTime?> lastLogin,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> username,
  Value<String> password,
  Value<String?> displayName,
  Value<bool> isAdmin,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime?> lastLogin,
  Value<int> rowid,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAdmin => $composableBuilder(
      column: $table.isAdmin, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastLogin => $composableBuilder(
      column: $table.lastLogin, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAdmin => $composableBuilder(
      column: $table.isAdmin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastLogin => $composableBuilder(
      column: $table.lastLogin, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<bool> get isAdmin =>
      $composableBuilder(column: $table.isAdmin, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLogin =>
      $composableBuilder(column: $table.lastLogin, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> password = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<bool> isAdmin = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastLogin = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            username: username,
            password: password,
            displayName: displayName,
            isAdmin: isAdmin,
            isActive: isActive,
            createdAt: createdAt,
            lastLogin: lastLogin,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String username,
            required String password,
            Value<String?> displayName = const Value.absent(),
            Value<bool> isAdmin = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> lastLogin = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            username: username,
            password: password,
            displayName: displayName,
            isAdmin: isAdmin,
            isActive: isActive,
            createdAt: createdAt,
            lastLogin: lastLogin,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PartnersTableTableManager get partners =>
      $$PartnersTableTableManager(_db, _db.partners);
  $$CagesTableTableManager get cages =>
      $$CagesTableTableManager(_db, _db.cages);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$WeighingDetailsTableTableManager get weighingDetails =>
      $$WeighingDetailsTableTableManager(_db, _db.weighingDetails);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$PigTypesTableTableManager get pigTypes =>
      $$PigTypesTableTableManager(_db, _db.pigTypes);
  $$FarmsTableTableManager get farms =>
      $$FarmsTableTableManager(_db, _db.farms);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
}
