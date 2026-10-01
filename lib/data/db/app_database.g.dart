// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects
    with TableInfo<$SubjectsTable, SubjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SubjectsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($SubjectsTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SubjectsTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String>
  pendingDeleteUntil = GeneratedColumn<String>(
    'pending_delete_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($SubjectsTable.$converterpendingDeleteUntil);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    pendingDeleteUntil,
    name,
    colorIndex,
    sortOrder,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $SubjectsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $SubjectsTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $SubjectsTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      pendingDeleteUntil: $SubjectsTable.$converterpendingDeleteUntil.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pending_delete_until'],
        ),
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      ),
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?>
  $converterpendingDeleteUntil = const NullableUtcDateTimeConverter();
}

class SubjectRow extends DataClass implements Insertable<SubjectRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;
  final DateTime? pendingDeleteUntil;
  final String? name;
  final int? colorIndex;
  final int? sortOrder;
  final bool? isDefault;
  const SubjectRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    this.pendingDeleteUntil,
    this.name,
    this.colorIndex,
    this.sortOrder,
    this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $SubjectsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $SubjectsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $SubjectsTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    if (!nullToAbsent || pendingDeleteUntil != null) {
      map['pending_delete_until'] = Variable<String>(
        $SubjectsTable.$converterpendingDeleteUntil.toSql(pendingDeleteUntil),
      );
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || colorIndex != null) {
      map['color_index'] = Variable<int>(colorIndex);
    }
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    if (!nullToAbsent || isDefault != null) {
      map['is_default'] = Variable<bool>(isDefault);
    }
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      pendingDeleteUntil: pendingDeleteUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingDeleteUntil),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      colorIndex: colorIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorIndex),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
      isDefault: isDefault == null && nullToAbsent
          ? const Value.absent()
          : Value(isDefault),
    );
  }

  factory SubjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $SubjectsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $SubjectsTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $SubjectsTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      pendingDeleteUntil: $SubjectsTable.$converterpendingDeleteUntil.fromJson(
        serializer.fromJson<String?>(json['pending_delete_until']),
      ),
      name: serializer.fromJson<String?>(json['name']),
      colorIndex: serializer.fromJson<int?>(json['color_index']),
      sortOrder: serializer.fromJson<int?>(json['sort_order']),
      isDefault: serializer.fromJson<bool?>(json['is_default']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $SubjectsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $SubjectsTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $SubjectsTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'pending_delete_until': serializer.toJson<String?>(
        $SubjectsTable.$converterpendingDeleteUntil.toJson(pendingDeleteUntil),
      ),
      'name': serializer.toJson<String?>(name),
      'color_index': serializer.toJson<int?>(colorIndex),
      'sort_order': serializer.toJson<int?>(sortOrder),
      'is_default': serializer.toJson<bool?>(isDefault),
    };
  }

  SubjectRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    Value<DateTime?> pendingDeleteUntil = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<int?> colorIndex = const Value.absent(),
    Value<int?> sortOrder = const Value.absent(),
    Value<bool?> isDefault = const Value.absent(),
  }) => SubjectRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    pendingDeleteUntil: pendingDeleteUntil.present
        ? pendingDeleteUntil.value
        : this.pendingDeleteUntil,
    name: name.present ? name.value : this.name,
    colorIndex: colorIndex.present ? colorIndex.value : this.colorIndex,
    sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
    isDefault: isDefault.present ? isDefault.value : this.isDefault,
  );
  SubjectRow copyWithCompanion(SubjectsCompanion data) {
    return SubjectRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      pendingDeleteUntil: data.pendingDeleteUntil.present
          ? data.pendingDeleteUntil.value
          : this.pendingDeleteUntil,
      name: data.name.present ? data.name.value : this.name,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('pendingDeleteUntil: $pendingDeleteUntil, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    pendingDeleteUntil,
    name,
    colorIndex,
    sortOrder,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.pendingDeleteUntil == this.pendingDeleteUntil &&
          other.name == this.name &&
          other.colorIndex == this.colorIndex &&
          other.sortOrder == this.sortOrder &&
          other.isDefault == this.isDefault);
}

class SubjectsCompanion extends UpdateCompanion<SubjectRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<DateTime?> pendingDeleteUntil;
  final Value<String?> name;
  final Value<int?> colorIndex;
  final Value<int?> sortOrder;
  final Value<bool?> isDefault;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.pendingDeleteUntil = const Value.absent(),
    this.name = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.pendingDeleteUntil = const Value.absent(),
    this.name = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId);
  static Insertable<SubjectRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? pendingDeleteUntil,
    Expression<String>? name,
    Expression<int>? colorIndex,
    Expression<int>? sortOrder,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (pendingDeleteUntil != null)
        'pending_delete_until': pendingDeleteUntil,
      if (name != null) 'name': name,
      if (colorIndex != null) 'color_index': colorIndex,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<DateTime?>? pendingDeleteUntil,
    Value<String?>? name,
    Value<int?>? colorIndex,
    Value<int?>? sortOrder,
    Value<bool?>? isDefault,
    Value<int>? rowid,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      pendingDeleteUntil: pendingDeleteUntil ?? this.pendingDeleteUntil,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $SubjectsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $SubjectsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $SubjectsTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (pendingDeleteUntil.present) {
      map['pending_delete_until'] = Variable<String>(
        $SubjectsTable.$converterpendingDeleteUntil.toSql(
          pendingDeleteUntil.value,
        ),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('pendingDeleteUntil: $pendingDeleteUntil, ')
          ..write('name: $name, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SessionsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($SessionsTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SessionsTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String>
  pendingDeleteUntil = GeneratedColumn<String>(
    'pending_delete_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($SessionsTable.$converterpendingDeleteUntil);
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannerItemIdMeta = const VerificationMeta(
    'plannerItemId',
  );
  @override
  late final GeneratedColumn<String> plannerItemId = GeneratedColumn<String>(
    'planner_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionKind?, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SessionKind?>($SessionsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<SessionMode?, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SessionMode?>($SessionsTable.$convertermode);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> startedAt =
      GeneratedColumn<String>(
        'started_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SessionsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> endedAt =
      GeneratedColumn<String>(
        'ended_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SessionsTable.$converterendedAt);
  @override
  late final GeneratedColumnWithTypeConverter<SessionStatus?, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SessionStatus?>($SessionsTable.$converterstatus);
  static const VerificationMeta _seatedSecondsMeta = const VerificationMeta(
    'seatedSeconds',
  );
  @override
  late final GeneratedColumn<int> seatedSeconds = GeneratedColumn<int>(
    'seated_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensitivityLevelMeta = const VerificationMeta(
    'sensitivityLevel',
  );
  @override
  late final GeneratedColumn<int> sensitivityLevel = GeneratedColumn<int>(
    'sensitivity_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    pendingDeleteUntil,
    subjectId,
    plannerItemId,
    kind,
    mode,
    startedAt,
    endedAt,
    status,
    seatedSeconds,
    sensitivityLevel,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('planner_item_id')) {
      context.handle(
        _plannerItemIdMeta,
        plannerItemId.isAcceptableOrUnknown(
          data['planner_item_id']!,
          _plannerItemIdMeta,
        ),
      );
    }
    if (data.containsKey('seated_seconds')) {
      context.handle(
        _seatedSecondsMeta,
        seatedSeconds.isAcceptableOrUnknown(
          data['seated_seconds']!,
          _seatedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('sensitivity_level')) {
      context.handle(
        _sensitivityLevelMeta,
        sensitivityLevel.isAcceptableOrUnknown(
          data['sensitivity_level']!,
          _sensitivityLevelMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $SessionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $SessionsTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $SessionsTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      pendingDeleteUntil: $SessionsTable.$converterpendingDeleteUntil.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pending_delete_until'],
        ),
      ),
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      plannerItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planner_item_id'],
      ),
      kind: $SessionsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        ),
      ),
      mode: $SessionsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        ),
      ),
      startedAt: $SessionsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}started_at'],
        ),
      ),
      endedAt: $SessionsTable.$converterendedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ended_at'],
        ),
      ),
      status: $SessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        ),
      ),
      seatedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seated_seconds'],
      ),
      sensitivityLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sensitivity_level'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?>
  $converterpendingDeleteUntil = const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<SessionKind?, String?, String?> $converterkind =
      const NullableWireEnumConverter(SessionKind.values);
  static JsonTypeConverter2<SessionMode?, String?, String?> $convertermode =
      const NullableWireEnumConverter(SessionMode.values);
  static JsonTypeConverter2<DateTime?, String?, String?> $converterstartedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterendedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<SessionStatus?, String?, String?> $converterstatus =
      const NullableWireEnumConverter(SessionStatus.values);
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;
  final DateTime? pendingDeleteUntil;
  final String? subjectId;
  final String? plannerItemId;
  final SessionKind? kind;
  final SessionMode? mode;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final SessionStatus? status;
  final int? seatedSeconds;
  final int? sensitivityLevel;
  final String? note;
  const SessionRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    this.pendingDeleteUntil,
    this.subjectId,
    this.plannerItemId,
    this.kind,
    this.mode,
    this.startedAt,
    this.endedAt,
    this.status,
    this.seatedSeconds,
    this.sensitivityLevel,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $SessionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $SessionsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $SessionsTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    if (!nullToAbsent || pendingDeleteUntil != null) {
      map['pending_delete_until'] = Variable<String>(
        $SessionsTable.$converterpendingDeleteUntil.toSql(pendingDeleteUntil),
      );
    }
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || plannerItemId != null) {
      map['planner_item_id'] = Variable<String>(plannerItemId);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>($SessionsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || mode != null) {
      map['mode'] = Variable<String>($SessionsTable.$convertermode.toSql(mode));
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<String>(
        $SessionsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<String>(
        $SessionsTable.$converterendedAt.toSql(endedAt),
      );
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(
        $SessionsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || seatedSeconds != null) {
      map['seated_seconds'] = Variable<int>(seatedSeconds);
    }
    if (!nullToAbsent || sensitivityLevel != null) {
      map['sensitivity_level'] = Variable<int>(sensitivityLevel);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      pendingDeleteUntil: pendingDeleteUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingDeleteUntil),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      plannerItemId: plannerItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannerItemId),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      mode: mode == null && nullToAbsent ? const Value.absent() : Value(mode),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      seatedSeconds: seatedSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(seatedSeconds),
      sensitivityLevel: sensitivityLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(sensitivityLevel),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $SessionsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $SessionsTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $SessionsTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      pendingDeleteUntil: $SessionsTable.$converterpendingDeleteUntil.fromJson(
        serializer.fromJson<String?>(json['pending_delete_until']),
      ),
      subjectId: serializer.fromJson<String?>(json['subject_id']),
      plannerItemId: serializer.fromJson<String?>(json['planner_item_id']),
      kind: $SessionsTable.$converterkind.fromJson(
        serializer.fromJson<String?>(json['kind']),
      ),
      mode: $SessionsTable.$convertermode.fromJson(
        serializer.fromJson<String?>(json['mode']),
      ),
      startedAt: $SessionsTable.$converterstartedAt.fromJson(
        serializer.fromJson<String?>(json['started_at']),
      ),
      endedAt: $SessionsTable.$converterendedAt.fromJson(
        serializer.fromJson<String?>(json['ended_at']),
      ),
      status: $SessionsTable.$converterstatus.fromJson(
        serializer.fromJson<String?>(json['status']),
      ),
      seatedSeconds: serializer.fromJson<int?>(json['seated_seconds']),
      sensitivityLevel: serializer.fromJson<int?>(json['sensitivity_level']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $SessionsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $SessionsTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $SessionsTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'pending_delete_until': serializer.toJson<String?>(
        $SessionsTable.$converterpendingDeleteUntil.toJson(pendingDeleteUntil),
      ),
      'subject_id': serializer.toJson<String?>(subjectId),
      'planner_item_id': serializer.toJson<String?>(plannerItemId),
      'kind': serializer.toJson<String?>(
        $SessionsTable.$converterkind.toJson(kind),
      ),
      'mode': serializer.toJson<String?>(
        $SessionsTable.$convertermode.toJson(mode),
      ),
      'started_at': serializer.toJson<String?>(
        $SessionsTable.$converterstartedAt.toJson(startedAt),
      ),
      'ended_at': serializer.toJson<String?>(
        $SessionsTable.$converterendedAt.toJson(endedAt),
      ),
      'status': serializer.toJson<String?>(
        $SessionsTable.$converterstatus.toJson(status),
      ),
      'seated_seconds': serializer.toJson<int?>(seatedSeconds),
      'sensitivity_level': serializer.toJson<int?>(sensitivityLevel),
      'note': serializer.toJson<String?>(note),
    };
  }

  SessionRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    Value<DateTime?> pendingDeleteUntil = const Value.absent(),
    Value<String?> subjectId = const Value.absent(),
    Value<String?> plannerItemId = const Value.absent(),
    Value<SessionKind?> kind = const Value.absent(),
    Value<SessionMode?> mode = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    Value<SessionStatus?> status = const Value.absent(),
    Value<int?> seatedSeconds = const Value.absent(),
    Value<int?> sensitivityLevel = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => SessionRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    pendingDeleteUntil: pendingDeleteUntil.present
        ? pendingDeleteUntil.value
        : this.pendingDeleteUntil,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    plannerItemId: plannerItemId.present
        ? plannerItemId.value
        : this.plannerItemId,
    kind: kind.present ? kind.value : this.kind,
    mode: mode.present ? mode.value : this.mode,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    status: status.present ? status.value : this.status,
    seatedSeconds: seatedSeconds.present
        ? seatedSeconds.value
        : this.seatedSeconds,
    sensitivityLevel: sensitivityLevel.present
        ? sensitivityLevel.value
        : this.sensitivityLevel,
    note: note.present ? note.value : this.note,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      pendingDeleteUntil: data.pendingDeleteUntil.present
          ? data.pendingDeleteUntil.value
          : this.pendingDeleteUntil,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      plannerItemId: data.plannerItemId.present
          ? data.plannerItemId.value
          : this.plannerItemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      mode: data.mode.present ? data.mode.value : this.mode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      status: data.status.present ? data.status.value : this.status,
      seatedSeconds: data.seatedSeconds.present
          ? data.seatedSeconds.value
          : this.seatedSeconds,
      sensitivityLevel: data.sensitivityLevel.present
          ? data.sensitivityLevel.value
          : this.sensitivityLevel,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('pendingDeleteUntil: $pendingDeleteUntil, ')
          ..write('subjectId: $subjectId, ')
          ..write('plannerItemId: $plannerItemId, ')
          ..write('kind: $kind, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('seatedSeconds: $seatedSeconds, ')
          ..write('sensitivityLevel: $sensitivityLevel, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    pendingDeleteUntil,
    subjectId,
    plannerItemId,
    kind,
    mode,
    startedAt,
    endedAt,
    status,
    seatedSeconds,
    sensitivityLevel,
    note,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.pendingDeleteUntil == this.pendingDeleteUntil &&
          other.subjectId == this.subjectId &&
          other.plannerItemId == this.plannerItemId &&
          other.kind == this.kind &&
          other.mode == this.mode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.status == this.status &&
          other.seatedSeconds == this.seatedSeconds &&
          other.sensitivityLevel == this.sensitivityLevel &&
          other.note == this.note);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<DateTime?> pendingDeleteUntil;
  final Value<String?> subjectId;
  final Value<String?> plannerItemId;
  final Value<SessionKind?> kind;
  final Value<SessionMode?> mode;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endedAt;
  final Value<SessionStatus?> status;
  final Value<int?> seatedSeconds;
  final Value<int?> sensitivityLevel;
  final Value<String?> note;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.pendingDeleteUntil = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.plannerItemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.seatedSeconds = const Value.absent(),
    this.sensitivityLevel = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.pendingDeleteUntil = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.plannerItemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.seatedSeconds = const Value.absent(),
    this.sensitivityLevel = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId);
  static Insertable<SessionRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? pendingDeleteUntil,
    Expression<String>? subjectId,
    Expression<String>? plannerItemId,
    Expression<String>? kind,
    Expression<String>? mode,
    Expression<String>? startedAt,
    Expression<String>? endedAt,
    Expression<String>? status,
    Expression<int>? seatedSeconds,
    Expression<int>? sensitivityLevel,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (pendingDeleteUntil != null)
        'pending_delete_until': pendingDeleteUntil,
      if (subjectId != null) 'subject_id': subjectId,
      if (plannerItemId != null) 'planner_item_id': plannerItemId,
      if (kind != null) 'kind': kind,
      if (mode != null) 'mode': mode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      if (seatedSeconds != null) 'seated_seconds': seatedSeconds,
      if (sensitivityLevel != null) 'sensitivity_level': sensitivityLevel,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<DateTime?>? pendingDeleteUntil,
    Value<String?>? subjectId,
    Value<String?>? plannerItemId,
    Value<SessionKind?>? kind,
    Value<SessionMode?>? mode,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<SessionStatus?>? status,
    Value<int?>? seatedSeconds,
    Value<int?>? sensitivityLevel,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      pendingDeleteUntil: pendingDeleteUntil ?? this.pendingDeleteUntil,
      subjectId: subjectId ?? this.subjectId,
      plannerItemId: plannerItemId ?? this.plannerItemId,
      kind: kind ?? this.kind,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      seatedSeconds: seatedSeconds ?? this.seatedSeconds,
      sensitivityLevel: sensitivityLevel ?? this.sensitivityLevel,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $SessionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $SessionsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $SessionsTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (pendingDeleteUntil.present) {
      map['pending_delete_until'] = Variable<String>(
        $SessionsTable.$converterpendingDeleteUntil.toSql(
          pendingDeleteUntil.value,
        ),
      );
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (plannerItemId.present) {
      map['planner_item_id'] = Variable<String>(plannerItemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SessionsTable.$converterkind.toSql(kind.value),
      );
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $SessionsTable.$convertermode.toSql(mode.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(
        $SessionsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<String>(
        $SessionsTable.$converterendedAt.toSql(endedAt.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (seatedSeconds.present) {
      map['seated_seconds'] = Variable<int>(seatedSeconds.value);
    }
    if (sensitivityLevel.present) {
      map['sensitivity_level'] = Variable<int>(sensitivityLevel.value);
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
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('pendingDeleteUntil: $pendingDeleteUntil, ')
          ..write('subjectId: $subjectId, ')
          ..write('plannerItemId: $plannerItemId, ')
          ..write('kind: $kind, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('seatedSeconds: $seatedSeconds, ')
          ..write('sensitivityLevel: $sensitivityLevel, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionSegmentsTable extends SessionSegments
    with TableInfo<$SessionSegmentsTable, SessionSegmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SessionSegmentsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($SessionSegmentsTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SessionSegmentsTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SegmentKind?, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SegmentKind?>($SessionSegmentsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> startAt =
      GeneratedColumn<String>(
        'start_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SessionSegmentsTable.$converterstartAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> endAt =
      GeneratedColumn<String>(
        'end_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SessionSegmentsTable.$converterendAt);
  static const VerificationMeta _correctedMeta = const VerificationMeta(
    'corrected',
  );
  @override
  late final GeneratedColumn<bool> corrected = GeneratedColumn<bool>(
    'corrected',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("corrected" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    sessionId,
    kind,
    startAt,
    endAt,
    corrected,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionSegmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('corrected')) {
      context.handle(
        _correctedMeta,
        corrected.isAcceptableOrUnknown(data['corrected']!, _correctedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionSegmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionSegmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $SessionSegmentsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $SessionSegmentsTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $SessionSegmentsTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      kind: $SessionSegmentsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        ),
      ),
      startAt: $SessionSegmentsTable.$converterstartAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_at'],
        ),
      ),
      endAt: $SessionSegmentsTable.$converterendAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}end_at'],
        ),
      ),
      corrected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}corrected'],
      ),
    );
  }

  @override
  $SessionSegmentsTable createAlias(String alias) {
    return $SessionSegmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<SegmentKind?, String?, String?> $converterkind =
      const NullableWireEnumConverter(SegmentKind.values);
  static JsonTypeConverter2<DateTime?, String?, String?> $converterstartAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterendAt =
      const NullableUtcDateTimeConverter();
}

class SessionSegmentRow extends DataClass
    implements Insertable<SessionSegmentRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;

  /// Keep key.
  final String sessionId;
  final SegmentKind? kind;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool? corrected;
  const SessionSegmentRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    required this.sessionId,
    this.kind,
    this.startAt,
    this.endAt,
    this.corrected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $SessionSegmentsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $SessionSegmentsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $SessionSegmentsTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(
        $SessionSegmentsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<String>(
        $SessionSegmentsTable.$converterstartAt.toSql(startAt),
      );
    }
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<String>(
        $SessionSegmentsTable.$converterendAt.toSql(endAt),
      );
    }
    if (!nullToAbsent || corrected != null) {
      map['corrected'] = Variable<bool>(corrected);
    }
    return map;
  }

  SessionSegmentsCompanion toCompanion(bool nullToAbsent) {
    return SessionSegmentsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      sessionId: Value(sessionId),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      corrected: corrected == null && nullToAbsent
          ? const Value.absent()
          : Value(corrected),
    );
  }

  factory SessionSegmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionSegmentRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $SessionSegmentsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $SessionSegmentsTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $SessionSegmentsTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      kind: $SessionSegmentsTable.$converterkind.fromJson(
        serializer.fromJson<String?>(json['kind']),
      ),
      startAt: $SessionSegmentsTable.$converterstartAt.fromJson(
        serializer.fromJson<String?>(json['start_at']),
      ),
      endAt: $SessionSegmentsTable.$converterendAt.fromJson(
        serializer.fromJson<String?>(json['end_at']),
      ),
      corrected: serializer.fromJson<bool?>(json['corrected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $SessionSegmentsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $SessionSegmentsTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $SessionSegmentsTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'session_id': serializer.toJson<String>(sessionId),
      'kind': serializer.toJson<String?>(
        $SessionSegmentsTable.$converterkind.toJson(kind),
      ),
      'start_at': serializer.toJson<String?>(
        $SessionSegmentsTable.$converterstartAt.toJson(startAt),
      ),
      'end_at': serializer.toJson<String?>(
        $SessionSegmentsTable.$converterendAt.toJson(endAt),
      ),
      'corrected': serializer.toJson<bool?>(corrected),
    };
  }

  SessionSegmentRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    String? sessionId,
    Value<SegmentKind?> kind = const Value.absent(),
    Value<DateTime?> startAt = const Value.absent(),
    Value<DateTime?> endAt = const Value.absent(),
    Value<bool?> corrected = const Value.absent(),
  }) => SessionSegmentRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    sessionId: sessionId ?? this.sessionId,
    kind: kind.present ? kind.value : this.kind,
    startAt: startAt.present ? startAt.value : this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    corrected: corrected.present ? corrected.value : this.corrected,
  );
  SessionSegmentRow copyWithCompanion(SessionSegmentsCompanion data) {
    return SessionSegmentRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      corrected: data.corrected.present ? data.corrected.value : this.corrected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionSegmentRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('corrected: $corrected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    sessionId,
    kind,
    startAt,
    endAt,
    corrected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionSegmentRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.sessionId == this.sessionId &&
          other.kind == this.kind &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.corrected == this.corrected);
}

class SessionSegmentsCompanion extends UpdateCompanion<SessionSegmentRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<String> sessionId;
  final Value<SegmentKind?> kind;
  final Value<DateTime?> startAt;
  final Value<DateTime?> endAt;
  final Value<bool?> corrected;
  final Value<int> rowid;
  const SessionSegmentsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.corrected = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionSegmentsCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    required String sessionId,
    this.kind = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.corrected = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId),
       sessionId = Value(sessionId);
  static Insertable<SessionSegmentRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? sessionId,
    Expression<String>? kind,
    Expression<String>? startAt,
    Expression<String>? endAt,
    Expression<bool>? corrected,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (sessionId != null) 'session_id': sessionId,
      if (kind != null) 'kind': kind,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (corrected != null) 'corrected': corrected,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionSegmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<String>? sessionId,
    Value<SegmentKind?>? kind,
    Value<DateTime?>? startAt,
    Value<DateTime?>? endAt,
    Value<bool?>? corrected,
    Value<int>? rowid,
  }) {
    return SessionSegmentsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      sessionId: sessionId ?? this.sessionId,
      kind: kind ?? this.kind,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      corrected: corrected ?? this.corrected,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $SessionSegmentsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $SessionSegmentsTable.$converterclientUpdatedAt.toSql(
          clientUpdatedAt.value,
        ),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $SessionSegmentsTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SessionSegmentsTable.$converterkind.toSql(kind.value),
      );
    }
    if (startAt.present) {
      map['start_at'] = Variable<String>(
        $SessionSegmentsTable.$converterstartAt.toSql(startAt.value),
      );
    }
    if (endAt.present) {
      map['end_at'] = Variable<String>(
        $SessionSegmentsTable.$converterendAt.toSql(endAt.value),
      );
    }
    if (corrected.present) {
      map['corrected'] = Variable<bool>(corrected.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('corrected: $corrected, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CorrectionsTable extends Corrections
    with TableInfo<$CorrectionsTable, CorrectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CorrectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CorrectionsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($CorrectionsTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CorrectionsTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  @override
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
    'segment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SegmentKind?, String> fromKind =
      GeneratedColumn<String>(
        'from_kind',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SegmentKind?>($CorrectionsTable.$converterfromKind);
  @override
  late final GeneratedColumnWithTypeConverter<SegmentKind?, String> toKind =
      GeneratedColumn<String>(
        'to_kind',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SegmentKind?>($CorrectionsTable.$convertertoKind);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> at =
      GeneratedColumn<String>(
        'at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CorrectionsTable.$converterat);
  static const VerificationMeta _sensitivityBeforeMeta = const VerificationMeta(
    'sensitivityBefore',
  );
  @override
  late final GeneratedColumn<int> sensitivityBefore = GeneratedColumn<int>(
    'sensitivity_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensitivityAfterMeta = const VerificationMeta(
    'sensitivityAfter',
  );
  @override
  late final GeneratedColumn<int> sensitivityAfter = GeneratedColumn<int>(
    'sensitivity_after',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    sessionId,
    segmentId,
    fromKind,
    toKind,
    at,
    sensitivityBefore,
    sensitivityAfter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'corrections';
  @override
  VerificationContext validateIntegrity(
    Insertable<CorrectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    }
    if (data.containsKey('sensitivity_before')) {
      context.handle(
        _sensitivityBeforeMeta,
        sensitivityBefore.isAcceptableOrUnknown(
          data['sensitivity_before']!,
          _sensitivityBeforeMeta,
        ),
      );
    }
    if (data.containsKey('sensitivity_after')) {
      context.handle(
        _sensitivityAfterMeta,
        sensitivityAfter.isAcceptableOrUnknown(
          data['sensitivity_after']!,
          _sensitivityAfterMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CorrectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CorrectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $CorrectionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $CorrectionsTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $CorrectionsTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_id'],
      ),
      fromKind: $CorrectionsTable.$converterfromKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}from_kind'],
        ),
      ),
      toKind: $CorrectionsTable.$convertertoKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}to_kind'],
        ),
      ),
      at: $CorrectionsTable.$converterat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}at'],
        ),
      ),
      sensitivityBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sensitivity_before'],
      ),
      sensitivityAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sensitivity_after'],
      ),
    );
  }

  @override
  $CorrectionsTable createAlias(String alias) {
    return $CorrectionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<SegmentKind?, String?, String?> $converterfromKind =
      const NullableWireEnumConverter(SegmentKind.values);
  static JsonTypeConverter2<SegmentKind?, String?, String?> $convertertoKind =
      const NullableWireEnumConverter(SegmentKind.values);
  static JsonTypeConverter2<DateTime?, String?, String?> $converterat =
      const NullableUtcDateTimeConverter();
}

class CorrectionRow extends DataClass implements Insertable<CorrectionRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;

  /// Keep key.
  final String sessionId;
  final String? segmentId;
  final SegmentKind? fromKind;
  final SegmentKind? toKind;
  final DateTime? at;
  final int? sensitivityBefore;
  final int? sensitivityAfter;
  const CorrectionRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    required this.sessionId,
    this.segmentId,
    this.fromKind,
    this.toKind,
    this.at,
    this.sensitivityBefore,
    this.sensitivityAfter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $CorrectionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $CorrectionsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $CorrectionsTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || segmentId != null) {
      map['segment_id'] = Variable<String>(segmentId);
    }
    if (!nullToAbsent || fromKind != null) {
      map['from_kind'] = Variable<String>(
        $CorrectionsTable.$converterfromKind.toSql(fromKind),
      );
    }
    if (!nullToAbsent || toKind != null) {
      map['to_kind'] = Variable<String>(
        $CorrectionsTable.$convertertoKind.toSql(toKind),
      );
    }
    if (!nullToAbsent || at != null) {
      map['at'] = Variable<String>($CorrectionsTable.$converterat.toSql(at));
    }
    if (!nullToAbsent || sensitivityBefore != null) {
      map['sensitivity_before'] = Variable<int>(sensitivityBefore);
    }
    if (!nullToAbsent || sensitivityAfter != null) {
      map['sensitivity_after'] = Variable<int>(sensitivityAfter);
    }
    return map;
  }

  CorrectionsCompanion toCompanion(bool nullToAbsent) {
    return CorrectionsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      sessionId: Value(sessionId),
      segmentId: segmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(segmentId),
      fromKind: fromKind == null && nullToAbsent
          ? const Value.absent()
          : Value(fromKind),
      toKind: toKind == null && nullToAbsent
          ? const Value.absent()
          : Value(toKind),
      at: at == null && nullToAbsent ? const Value.absent() : Value(at),
      sensitivityBefore: sensitivityBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(sensitivityBefore),
      sensitivityAfter: sensitivityAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(sensitivityAfter),
    );
  }

  factory CorrectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CorrectionRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $CorrectionsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $CorrectionsTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $CorrectionsTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      segmentId: serializer.fromJson<String?>(json['segment_id']),
      fromKind: $CorrectionsTable.$converterfromKind.fromJson(
        serializer.fromJson<String?>(json['from_kind']),
      ),
      toKind: $CorrectionsTable.$convertertoKind.fromJson(
        serializer.fromJson<String?>(json['to_kind']),
      ),
      at: $CorrectionsTable.$converterat.fromJson(
        serializer.fromJson<String?>(json['at']),
      ),
      sensitivityBefore: serializer.fromJson<int?>(json['sensitivity_before']),
      sensitivityAfter: serializer.fromJson<int?>(json['sensitivity_after']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $CorrectionsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $CorrectionsTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $CorrectionsTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'session_id': serializer.toJson<String>(sessionId),
      'segment_id': serializer.toJson<String?>(segmentId),
      'from_kind': serializer.toJson<String?>(
        $CorrectionsTable.$converterfromKind.toJson(fromKind),
      ),
      'to_kind': serializer.toJson<String?>(
        $CorrectionsTable.$convertertoKind.toJson(toKind),
      ),
      'at': serializer.toJson<String?>(
        $CorrectionsTable.$converterat.toJson(at),
      ),
      'sensitivity_before': serializer.toJson<int?>(sensitivityBefore),
      'sensitivity_after': serializer.toJson<int?>(sensitivityAfter),
    };
  }

  CorrectionRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    String? sessionId,
    Value<String?> segmentId = const Value.absent(),
    Value<SegmentKind?> fromKind = const Value.absent(),
    Value<SegmentKind?> toKind = const Value.absent(),
    Value<DateTime?> at = const Value.absent(),
    Value<int?> sensitivityBefore = const Value.absent(),
    Value<int?> sensitivityAfter = const Value.absent(),
  }) => CorrectionRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    sessionId: sessionId ?? this.sessionId,
    segmentId: segmentId.present ? segmentId.value : this.segmentId,
    fromKind: fromKind.present ? fromKind.value : this.fromKind,
    toKind: toKind.present ? toKind.value : this.toKind,
    at: at.present ? at.value : this.at,
    sensitivityBefore: sensitivityBefore.present
        ? sensitivityBefore.value
        : this.sensitivityBefore,
    sensitivityAfter: sensitivityAfter.present
        ? sensitivityAfter.value
        : this.sensitivityAfter,
  );
  CorrectionRow copyWithCompanion(CorrectionsCompanion data) {
    return CorrectionRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      fromKind: data.fromKind.present ? data.fromKind.value : this.fromKind,
      toKind: data.toKind.present ? data.toKind.value : this.toKind,
      at: data.at.present ? data.at.value : this.at,
      sensitivityBefore: data.sensitivityBefore.present
          ? data.sensitivityBefore.value
          : this.sensitivityBefore,
      sensitivityAfter: data.sensitivityAfter.present
          ? data.sensitivityAfter.value
          : this.sensitivityAfter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CorrectionRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('sessionId: $sessionId, ')
          ..write('segmentId: $segmentId, ')
          ..write('fromKind: $fromKind, ')
          ..write('toKind: $toKind, ')
          ..write('at: $at, ')
          ..write('sensitivityBefore: $sensitivityBefore, ')
          ..write('sensitivityAfter: $sensitivityAfter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    sessionId,
    segmentId,
    fromKind,
    toKind,
    at,
    sensitivityBefore,
    sensitivityAfter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CorrectionRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.sessionId == this.sessionId &&
          other.segmentId == this.segmentId &&
          other.fromKind == this.fromKind &&
          other.toKind == this.toKind &&
          other.at == this.at &&
          other.sensitivityBefore == this.sensitivityBefore &&
          other.sensitivityAfter == this.sensitivityAfter);
}

class CorrectionsCompanion extends UpdateCompanion<CorrectionRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<String> sessionId;
  final Value<String?> segmentId;
  final Value<SegmentKind?> fromKind;
  final Value<SegmentKind?> toKind;
  final Value<DateTime?> at;
  final Value<int?> sensitivityBefore;
  final Value<int?> sensitivityAfter;
  final Value<int> rowid;
  const CorrectionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.segmentId = const Value.absent(),
    this.fromKind = const Value.absent(),
    this.toKind = const Value.absent(),
    this.at = const Value.absent(),
    this.sensitivityBefore = const Value.absent(),
    this.sensitivityAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CorrectionsCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    required String sessionId,
    this.segmentId = const Value.absent(),
    this.fromKind = const Value.absent(),
    this.toKind = const Value.absent(),
    this.at = const Value.absent(),
    this.sensitivityBefore = const Value.absent(),
    this.sensitivityAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId),
       sessionId = Value(sessionId);
  static Insertable<CorrectionRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? sessionId,
    Expression<String>? segmentId,
    Expression<String>? fromKind,
    Expression<String>? toKind,
    Expression<String>? at,
    Expression<int>? sensitivityBefore,
    Expression<int>? sensitivityAfter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (sessionId != null) 'session_id': sessionId,
      if (segmentId != null) 'segment_id': segmentId,
      if (fromKind != null) 'from_kind': fromKind,
      if (toKind != null) 'to_kind': toKind,
      if (at != null) 'at': at,
      if (sensitivityBefore != null) 'sensitivity_before': sensitivityBefore,
      if (sensitivityAfter != null) 'sensitivity_after': sensitivityAfter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CorrectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<String>? sessionId,
    Value<String?>? segmentId,
    Value<SegmentKind?>? fromKind,
    Value<SegmentKind?>? toKind,
    Value<DateTime?>? at,
    Value<int?>? sensitivityBefore,
    Value<int?>? sensitivityAfter,
    Value<int>? rowid,
  }) {
    return CorrectionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      sessionId: sessionId ?? this.sessionId,
      segmentId: segmentId ?? this.segmentId,
      fromKind: fromKind ?? this.fromKind,
      toKind: toKind ?? this.toKind,
      at: at ?? this.at,
      sensitivityBefore: sensitivityBefore ?? this.sensitivityBefore,
      sensitivityAfter: sensitivityAfter ?? this.sensitivityAfter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $CorrectionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $CorrectionsTable.$converterclientUpdatedAt.toSql(
          clientUpdatedAt.value,
        ),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $CorrectionsTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (fromKind.present) {
      map['from_kind'] = Variable<String>(
        $CorrectionsTable.$converterfromKind.toSql(fromKind.value),
      );
    }
    if (toKind.present) {
      map['to_kind'] = Variable<String>(
        $CorrectionsTable.$convertertoKind.toSql(toKind.value),
      );
    }
    if (at.present) {
      map['at'] = Variable<String>(
        $CorrectionsTable.$converterat.toSql(at.value),
      );
    }
    if (sensitivityBefore.present) {
      map['sensitivity_before'] = Variable<int>(sensitivityBefore.value);
    }
    if (sensitivityAfter.present) {
      map['sensitivity_after'] = Variable<int>(sensitivityAfter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CorrectionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('sessionId: $sessionId, ')
          ..write('segmentId: $segmentId, ')
          ..write('fromKind: $fromKind, ')
          ..write('toKind: $toKind, ')
          ..write('at: $at, ')
          ..write('sensitivityBefore: $sensitivityBefore, ')
          ..write('sensitivityAfter: $sensitivityAfter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannerItemsTable extends PlannerItems
    with TableInfo<$PlannerItemsTable, PlannerItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PlannerItemsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($PlannerItemsTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($PlannerItemsTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String>
  pendingDeleteUntil = GeneratedColumn<String>(
    'pending_delete_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($PlannerItemsTable.$converterpendingDeleteUntil);
  @override
  late final GeneratedColumnWithTypeConverter<PlannerKind?, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<PlannerKind?>($PlannerItemsTable.$converterkind);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rangeTextMeta = const VerificationMeta(
    'rangeText',
  );
  @override
  late final GeneratedColumn<String> rangeText = GeneratedColumn<String>(
    'range_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetMinutesMeta = const VerificationMeta(
    'targetMinutes',
  );
  @override
  late final GeneratedColumn<int> targetMinutes = GeneratedColumn<int>(
    'target_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> doneAt =
      GeneratedColumn<String>(
        'done_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($PlannerItemsTable.$converterdoneAt);
  static const VerificationMeta _recurrenceIdMeta = const VerificationMeta(
    'recurrenceId',
  );
  @override
  late final GeneratedColumn<String> recurrenceId = GeneratedColumn<String>(
    'recurrence_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bandStartMeta = const VerificationMeta(
    'bandStart',
  );
  @override
  late final GeneratedColumn<String> bandStart = GeneratedColumn<String>(
    'band_start',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bandEndMeta = const VerificationMeta(
    'bandEnd',
  );
  @override
  late final GeneratedColumn<String> bandEnd = GeneratedColumn<String>(
    'band_end',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    pendingDeleteUntil,
    kind,
    title,
    subjectId,
    rangeText,
    targetMinutes,
    date,
    startTime,
    endTime,
    isDone,
    doneAt,
    recurrenceId,
    bandStart,
    bandEnd,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('range_text')) {
      context.handle(
        _rangeTextMeta,
        rangeText.isAcceptableOrUnknown(data['range_text']!, _rangeTextMeta),
      );
    }
    if (data.containsKey('target_minutes')) {
      context.handle(
        _targetMinutesMeta,
        targetMinutes.isAcceptableOrUnknown(
          data['target_minutes']!,
          _targetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('recurrence_id')) {
      context.handle(
        _recurrenceIdMeta,
        recurrenceId.isAcceptableOrUnknown(
          data['recurrence_id']!,
          _recurrenceIdMeta,
        ),
      );
    }
    if (data.containsKey('band_start')) {
      context.handle(
        _bandStartMeta,
        bandStart.isAcceptableOrUnknown(data['band_start']!, _bandStartMeta),
      );
    }
    if (data.containsKey('band_end')) {
      context.handle(
        _bandEndMeta,
        bandEnd.isAcceptableOrUnknown(data['band_end']!, _bandEndMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannerItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $PlannerItemsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $PlannerItemsTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $PlannerItemsTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      pendingDeleteUntil: $PlannerItemsTable.$converterpendingDeleteUntil
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}pending_delete_until'],
            ),
          ),
      kind: $PlannerItemsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        ),
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      rangeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range_text'],
      ),
      targetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_minutes'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      ),
      doneAt: $PlannerItemsTable.$converterdoneAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}done_at'],
        ),
      ),
      recurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_id'],
      ),
      bandStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}band_start'],
      ),
      bandEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}band_end'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      ),
    );
  }

  @override
  $PlannerItemsTable createAlias(String alias) {
    return $PlannerItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?>
  $converterpendingDeleteUntil = const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<PlannerKind?, String?, String?> $converterkind =
      const NullableWireEnumConverter(PlannerKind.values);
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdoneAt =
      const NullableUtcDateTimeConverter();
}

class PlannerItemRow extends DataClass implements Insertable<PlannerItemRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;
  final DateTime? pendingDeleteUntil;
  final PlannerKind? kind;
  final String? title;
  final String? subjectId;
  final String? rangeText;
  final int? targetMinutes;

  /// Local `yyyy-MM-dd`.
  final String? date;
  final String? startTime;
  final String? endTime;
  final bool? isDone;
  final DateTime? doneAt;

  /// Keep key.
  final String? recurrenceId;
  final String? bandStart;
  final String? bandEnd;
  final int? sortOrder;
  const PlannerItemRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    this.pendingDeleteUntil,
    this.kind,
    this.title,
    this.subjectId,
    this.rangeText,
    this.targetMinutes,
    this.date,
    this.startTime,
    this.endTime,
    this.isDone,
    this.doneAt,
    this.recurrenceId,
    this.bandStart,
    this.bandEnd,
    this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $PlannerItemsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $PlannerItemsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $PlannerItemsTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    if (!nullToAbsent || pendingDeleteUntil != null) {
      map['pending_delete_until'] = Variable<String>(
        $PlannerItemsTable.$converterpendingDeleteUntil.toSql(
          pendingDeleteUntil,
        ),
      );
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(
        $PlannerItemsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || rangeText != null) {
      map['range_text'] = Variable<String>(rangeText);
    }
    if (!nullToAbsent || targetMinutes != null) {
      map['target_minutes'] = Variable<int>(targetMinutes);
    }
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<String>(date);
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    if (!nullToAbsent || isDone != null) {
      map['is_done'] = Variable<bool>(isDone);
    }
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<String>(
        $PlannerItemsTable.$converterdoneAt.toSql(doneAt),
      );
    }
    if (!nullToAbsent || recurrenceId != null) {
      map['recurrence_id'] = Variable<String>(recurrenceId);
    }
    if (!nullToAbsent || bandStart != null) {
      map['band_start'] = Variable<String>(bandStart);
    }
    if (!nullToAbsent || bandEnd != null) {
      map['band_end'] = Variable<String>(bandEnd);
    }
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    return map;
  }

  PlannerItemsCompanion toCompanion(bool nullToAbsent) {
    return PlannerItemsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      pendingDeleteUntil: pendingDeleteUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingDeleteUntil),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      rangeText: rangeText == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeText),
      targetMinutes: targetMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(targetMinutes),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      isDone: isDone == null && nullToAbsent
          ? const Value.absent()
          : Value(isDone),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
      recurrenceId: recurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceId),
      bandStart: bandStart == null && nullToAbsent
          ? const Value.absent()
          : Value(bandStart),
      bandEnd: bandEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(bandEnd),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
    );
  }

  factory PlannerItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerItemRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $PlannerItemsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $PlannerItemsTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $PlannerItemsTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      pendingDeleteUntil: $PlannerItemsTable.$converterpendingDeleteUntil
          .fromJson(serializer.fromJson<String?>(json['pending_delete_until'])),
      kind: $PlannerItemsTable.$converterkind.fromJson(
        serializer.fromJson<String?>(json['kind']),
      ),
      title: serializer.fromJson<String?>(json['title']),
      subjectId: serializer.fromJson<String?>(json['subject_id']),
      rangeText: serializer.fromJson<String?>(json['range_text']),
      targetMinutes: serializer.fromJson<int?>(json['target_minutes']),
      date: serializer.fromJson<String?>(json['date']),
      startTime: serializer.fromJson<String?>(json['start_time']),
      endTime: serializer.fromJson<String?>(json['end_time']),
      isDone: serializer.fromJson<bool?>(json['is_done']),
      doneAt: $PlannerItemsTable.$converterdoneAt.fromJson(
        serializer.fromJson<String?>(json['done_at']),
      ),
      recurrenceId: serializer.fromJson<String?>(json['recurrence_id']),
      bandStart: serializer.fromJson<String?>(json['band_start']),
      bandEnd: serializer.fromJson<String?>(json['band_end']),
      sortOrder: serializer.fromJson<int?>(json['sort_order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $PlannerItemsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $PlannerItemsTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $PlannerItemsTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'pending_delete_until': serializer.toJson<String?>(
        $PlannerItemsTable.$converterpendingDeleteUntil.toJson(
          pendingDeleteUntil,
        ),
      ),
      'kind': serializer.toJson<String?>(
        $PlannerItemsTable.$converterkind.toJson(kind),
      ),
      'title': serializer.toJson<String?>(title),
      'subject_id': serializer.toJson<String?>(subjectId),
      'range_text': serializer.toJson<String?>(rangeText),
      'target_minutes': serializer.toJson<int?>(targetMinutes),
      'date': serializer.toJson<String?>(date),
      'start_time': serializer.toJson<String?>(startTime),
      'end_time': serializer.toJson<String?>(endTime),
      'is_done': serializer.toJson<bool?>(isDone),
      'done_at': serializer.toJson<String?>(
        $PlannerItemsTable.$converterdoneAt.toJson(doneAt),
      ),
      'recurrence_id': serializer.toJson<String?>(recurrenceId),
      'band_start': serializer.toJson<String?>(bandStart),
      'band_end': serializer.toJson<String?>(bandEnd),
      'sort_order': serializer.toJson<int?>(sortOrder),
    };
  }

  PlannerItemRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    Value<DateTime?> pendingDeleteUntil = const Value.absent(),
    Value<PlannerKind?> kind = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> subjectId = const Value.absent(),
    Value<String?> rangeText = const Value.absent(),
    Value<int?> targetMinutes = const Value.absent(),
    Value<String?> date = const Value.absent(),
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    Value<bool?> isDone = const Value.absent(),
    Value<DateTime?> doneAt = const Value.absent(),
    Value<String?> recurrenceId = const Value.absent(),
    Value<String?> bandStart = const Value.absent(),
    Value<String?> bandEnd = const Value.absent(),
    Value<int?> sortOrder = const Value.absent(),
  }) => PlannerItemRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    pendingDeleteUntil: pendingDeleteUntil.present
        ? pendingDeleteUntil.value
        : this.pendingDeleteUntil,
    kind: kind.present ? kind.value : this.kind,
    title: title.present ? title.value : this.title,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    rangeText: rangeText.present ? rangeText.value : this.rangeText,
    targetMinutes: targetMinutes.present
        ? targetMinutes.value
        : this.targetMinutes,
    date: date.present ? date.value : this.date,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    isDone: isDone.present ? isDone.value : this.isDone,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    recurrenceId: recurrenceId.present ? recurrenceId.value : this.recurrenceId,
    bandStart: bandStart.present ? bandStart.value : this.bandStart,
    bandEnd: bandEnd.present ? bandEnd.value : this.bandEnd,
    sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
  );
  PlannerItemRow copyWithCompanion(PlannerItemsCompanion data) {
    return PlannerItemRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      pendingDeleteUntil: data.pendingDeleteUntil.present
          ? data.pendingDeleteUntil.value
          : this.pendingDeleteUntil,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      rangeText: data.rangeText.present ? data.rangeText.value : this.rangeText,
      targetMinutes: data.targetMinutes.present
          ? data.targetMinutes.value
          : this.targetMinutes,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      recurrenceId: data.recurrenceId.present
          ? data.recurrenceId.value
          : this.recurrenceId,
      bandStart: data.bandStart.present ? data.bandStart.value : this.bandStart,
      bandEnd: data.bandEnd.present ? data.bandEnd.value : this.bandEnd,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerItemRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('pendingDeleteUntil: $pendingDeleteUntil, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('rangeText: $rangeText, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isDone: $isDone, ')
          ..write('doneAt: $doneAt, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('bandStart: $bandStart, ')
          ..write('bandEnd: $bandEnd, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    pendingDeleteUntil,
    kind,
    title,
    subjectId,
    rangeText,
    targetMinutes,
    date,
    startTime,
    endTime,
    isDone,
    doneAt,
    recurrenceId,
    bandStart,
    bandEnd,
    sortOrder,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerItemRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.pendingDeleteUntil == this.pendingDeleteUntil &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.subjectId == this.subjectId &&
          other.rangeText == this.rangeText &&
          other.targetMinutes == this.targetMinutes &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.isDone == this.isDone &&
          other.doneAt == this.doneAt &&
          other.recurrenceId == this.recurrenceId &&
          other.bandStart == this.bandStart &&
          other.bandEnd == this.bandEnd &&
          other.sortOrder == this.sortOrder);
}

class PlannerItemsCompanion extends UpdateCompanion<PlannerItemRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<DateTime?> pendingDeleteUntil;
  final Value<PlannerKind?> kind;
  final Value<String?> title;
  final Value<String?> subjectId;
  final Value<String?> rangeText;
  final Value<int?> targetMinutes;
  final Value<String?> date;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<bool?> isDone;
  final Value<DateTime?> doneAt;
  final Value<String?> recurrenceId;
  final Value<String?> bandStart;
  final Value<String?> bandEnd;
  final Value<int?> sortOrder;
  final Value<int> rowid;
  const PlannerItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.pendingDeleteUntil = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.rangeText = const Value.absent(),
    this.targetMinutes = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isDone = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.bandStart = const Value.absent(),
    this.bandEnd = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannerItemsCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.pendingDeleteUntil = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.rangeText = const Value.absent(),
    this.targetMinutes = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isDone = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.bandStart = const Value.absent(),
    this.bandEnd = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId);
  static Insertable<PlannerItemRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? pendingDeleteUntil,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? subjectId,
    Expression<String>? rangeText,
    Expression<int>? targetMinutes,
    Expression<String>? date,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<bool>? isDone,
    Expression<String>? doneAt,
    Expression<String>? recurrenceId,
    Expression<String>? bandStart,
    Expression<String>? bandEnd,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (pendingDeleteUntil != null)
        'pending_delete_until': pendingDeleteUntil,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (subjectId != null) 'subject_id': subjectId,
      if (rangeText != null) 'range_text': rangeText,
      if (targetMinutes != null) 'target_minutes': targetMinutes,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (isDone != null) 'is_done': isDone,
      if (doneAt != null) 'done_at': doneAt,
      if (recurrenceId != null) 'recurrence_id': recurrenceId,
      if (bandStart != null) 'band_start': bandStart,
      if (bandEnd != null) 'band_end': bandEnd,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannerItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<DateTime?>? pendingDeleteUntil,
    Value<PlannerKind?>? kind,
    Value<String?>? title,
    Value<String?>? subjectId,
    Value<String?>? rangeText,
    Value<int?>? targetMinutes,
    Value<String?>? date,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<bool?>? isDone,
    Value<DateTime?>? doneAt,
    Value<String?>? recurrenceId,
    Value<String?>? bandStart,
    Value<String?>? bandEnd,
    Value<int?>? sortOrder,
    Value<int>? rowid,
  }) {
    return PlannerItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      pendingDeleteUntil: pendingDeleteUntil ?? this.pendingDeleteUntil,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      rangeText: rangeText ?? this.rangeText,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isDone: isDone ?? this.isDone,
      doneAt: doneAt ?? this.doneAt,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      bandStart: bandStart ?? this.bandStart,
      bandEnd: bandEnd ?? this.bandEnd,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $PlannerItemsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $PlannerItemsTable.$converterclientUpdatedAt.toSql(
          clientUpdatedAt.value,
        ),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $PlannerItemsTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (pendingDeleteUntil.present) {
      map['pending_delete_until'] = Variable<String>(
        $PlannerItemsTable.$converterpendingDeleteUntil.toSql(
          pendingDeleteUntil.value,
        ),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PlannerItemsTable.$converterkind.toSql(kind.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (rangeText.present) {
      map['range_text'] = Variable<String>(rangeText.value);
    }
    if (targetMinutes.present) {
      map['target_minutes'] = Variable<int>(targetMinutes.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<String>(
        $PlannerItemsTable.$converterdoneAt.toSql(doneAt.value),
      );
    }
    if (recurrenceId.present) {
      map['recurrence_id'] = Variable<String>(recurrenceId.value);
    }
    if (bandStart.present) {
      map['band_start'] = Variable<String>(bandStart.value);
    }
    if (bandEnd.present) {
      map['band_end'] = Variable<String>(bandEnd.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('pendingDeleteUntil: $pendingDeleteUntil, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('rangeText: $rangeText, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isDone: $isDone, ')
          ..write('doneAt: $doneAt, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('bandStart: $bandStart, ')
          ..write('bandEnd: $bandEnd, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurrencesTable extends Recurrences
    with TableInfo<$RecurrencesTable, RecurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RecurrencesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($RecurrencesTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($RecurrencesTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String>
  pendingDeleteUntil = GeneratedColumn<String>(
    'pending_delete_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($RecurrencesTable.$converterpendingDeleteUntil);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekdayMaskMeta = const VerificationMeta(
    'weekdayMask',
  );
  @override
  late final GeneratedColumn<int> weekdayMask = GeneratedColumn<int>(
    'weekday_mask',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsOnMeta = const VerificationMeta('endsOn');
  @override
  late final GeneratedColumn<String> endsOn = GeneratedColumn<String>(
    'ends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    pendingDeleteUntil,
    title,
    subjectId,
    weekdayMask,
    startTime,
    endTime,
    endsOn,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurrenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('weekday_mask')) {
      context.handle(
        _weekdayMaskMeta,
        weekdayMask.isAcceptableOrUnknown(
          data['weekday_mask']!,
          _weekdayMaskMeta,
        ),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('ends_on')) {
      context.handle(
        _endsOnMeta,
        endsOn.isAcceptableOrUnknown(data['ends_on']!, _endsOnMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurrenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $RecurrencesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $RecurrencesTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $RecurrencesTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      pendingDeleteUntil: $RecurrencesTable.$converterpendingDeleteUntil
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}pending_delete_until'],
            ),
          ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      weekdayMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday_mask'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      endsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ends_on'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      ),
    );
  }

  @override
  $RecurrencesTable createAlias(String alias) {
    return $RecurrencesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?>
  $converterpendingDeleteUntil = const NullableUtcDateTimeConverter();
}

class RecurrenceRow extends DataClass implements Insertable<RecurrenceRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;
  final DateTime? pendingDeleteUntil;
  final String? title;
  final String? subjectId;

  /// 7-bit mask, bit 0 = Monday … bit 6 = Sunday.
  final int? weekdayMask;
  final String? startTime;
  final String? endTime;

  /// Local `yyyy-MM-dd`, inclusive. null = open-ended.
  final String? endsOn;
  final bool? active;
  const RecurrenceRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    this.pendingDeleteUntil,
    this.title,
    this.subjectId,
    this.weekdayMask,
    this.startTime,
    this.endTime,
    this.endsOn,
    this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $RecurrencesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $RecurrencesTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $RecurrencesTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    if (!nullToAbsent || pendingDeleteUntil != null) {
      map['pending_delete_until'] = Variable<String>(
        $RecurrencesTable.$converterpendingDeleteUntil.toSql(
          pendingDeleteUntil,
        ),
      );
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || weekdayMask != null) {
      map['weekday_mask'] = Variable<int>(weekdayMask);
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    if (!nullToAbsent || endsOn != null) {
      map['ends_on'] = Variable<String>(endsOn);
    }
    if (!nullToAbsent || active != null) {
      map['active'] = Variable<bool>(active);
    }
    return map;
  }

  RecurrencesCompanion toCompanion(bool nullToAbsent) {
    return RecurrencesCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      pendingDeleteUntil: pendingDeleteUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingDeleteUntil),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      weekdayMask: weekdayMask == null && nullToAbsent
          ? const Value.absent()
          : Value(weekdayMask),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      endsOn: endsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(endsOn),
      active: active == null && nullToAbsent
          ? const Value.absent()
          : Value(active),
    );
  }

  factory RecurrenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $RecurrencesTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $RecurrencesTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $RecurrencesTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      pendingDeleteUntil: $RecurrencesTable.$converterpendingDeleteUntil
          .fromJson(serializer.fromJson<String?>(json['pending_delete_until'])),
      title: serializer.fromJson<String?>(json['title']),
      subjectId: serializer.fromJson<String?>(json['subject_id']),
      weekdayMask: serializer.fromJson<int?>(json['weekday_mask']),
      startTime: serializer.fromJson<String?>(json['start_time']),
      endTime: serializer.fromJson<String?>(json['end_time']),
      endsOn: serializer.fromJson<String?>(json['ends_on']),
      active: serializer.fromJson<bool?>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $RecurrencesTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $RecurrencesTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $RecurrencesTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'pending_delete_until': serializer.toJson<String?>(
        $RecurrencesTable.$converterpendingDeleteUntil.toJson(
          pendingDeleteUntil,
        ),
      ),
      'title': serializer.toJson<String?>(title),
      'subject_id': serializer.toJson<String?>(subjectId),
      'weekday_mask': serializer.toJson<int?>(weekdayMask),
      'start_time': serializer.toJson<String?>(startTime),
      'end_time': serializer.toJson<String?>(endTime),
      'ends_on': serializer.toJson<String?>(endsOn),
      'active': serializer.toJson<bool?>(active),
    };
  }

  RecurrenceRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    Value<DateTime?> pendingDeleteUntil = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> subjectId = const Value.absent(),
    Value<int?> weekdayMask = const Value.absent(),
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    Value<String?> endsOn = const Value.absent(),
    Value<bool?> active = const Value.absent(),
  }) => RecurrenceRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    pendingDeleteUntil: pendingDeleteUntil.present
        ? pendingDeleteUntil.value
        : this.pendingDeleteUntil,
    title: title.present ? title.value : this.title,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    weekdayMask: weekdayMask.present ? weekdayMask.value : this.weekdayMask,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    endsOn: endsOn.present ? endsOn.value : this.endsOn,
    active: active.present ? active.value : this.active,
  );
  RecurrenceRow copyWithCompanion(RecurrencesCompanion data) {
    return RecurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      pendingDeleteUntil: data.pendingDeleteUntil.present
          ? data.pendingDeleteUntil.value
          : this.pendingDeleteUntil,
      title: data.title.present ? data.title.value : this.title,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      weekdayMask: data.weekdayMask.present
          ? data.weekdayMask.value
          : this.weekdayMask,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      endsOn: data.endsOn.present ? data.endsOn.value : this.endsOn,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('pendingDeleteUntil: $pendingDeleteUntil, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('weekdayMask: $weekdayMask, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('endsOn: $endsOn, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    pendingDeleteUntil,
    title,
    subjectId,
    weekdayMask,
    startTime,
    endTime,
    endsOn,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.pendingDeleteUntil == this.pendingDeleteUntil &&
          other.title == this.title &&
          other.subjectId == this.subjectId &&
          other.weekdayMask == this.weekdayMask &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.endsOn == this.endsOn &&
          other.active == this.active);
}

class RecurrencesCompanion extends UpdateCompanion<RecurrenceRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<DateTime?> pendingDeleteUntil;
  final Value<String?> title;
  final Value<String?> subjectId;
  final Value<int?> weekdayMask;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<String?> endsOn;
  final Value<bool?> active;
  final Value<int> rowid;
  const RecurrencesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.pendingDeleteUntil = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.weekdayMask = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurrencesCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.pendingDeleteUntil = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.weekdayMask = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId);
  static Insertable<RecurrenceRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? pendingDeleteUntil,
    Expression<String>? title,
    Expression<String>? subjectId,
    Expression<int>? weekdayMask,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? endsOn,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (pendingDeleteUntil != null)
        'pending_delete_until': pendingDeleteUntil,
      if (title != null) 'title': title,
      if (subjectId != null) 'subject_id': subjectId,
      if (weekdayMask != null) 'weekday_mask': weekdayMask,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (endsOn != null) 'ends_on': endsOn,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<DateTime?>? pendingDeleteUntil,
    Value<String?>? title,
    Value<String?>? subjectId,
    Value<int?>? weekdayMask,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<String?>? endsOn,
    Value<bool?>? active,
    Value<int>? rowid,
  }) {
    return RecurrencesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      pendingDeleteUntil: pendingDeleteUntil ?? this.pendingDeleteUntil,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      weekdayMask: weekdayMask ?? this.weekdayMask,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      endsOn: endsOn ?? this.endsOn,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $RecurrencesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $RecurrencesTable.$converterclientUpdatedAt.toSql(
          clientUpdatedAt.value,
        ),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $RecurrencesTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (pendingDeleteUntil.present) {
      map['pending_delete_until'] = Variable<String>(
        $RecurrencesTable.$converterpendingDeleteUntil.toSql(
          pendingDeleteUntil.value,
        ),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (weekdayMask.present) {
      map['weekday_mask'] = Variable<int>(weekdayMask.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (endsOn.present) {
      map['ends_on'] = Variable<String>(endsOn.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrencesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('pendingDeleteUntil: $pendingDeleteUntil, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('weekdayMask: $weekdayMask, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('endsOn: $endsOn, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingRequestsTable extends ReadingRequests
    with TableInfo<$ReadingRequestsTable, ReadingRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReadingRequestsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($ReadingRequestsTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReadingRequestsTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rangeTextMeta = const VerificationMeta(
    'rangeText',
  );
  @override
  late final GeneratedColumn<String> rangeText = GeneratedColumn<String>(
    'range_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannerItemIdMeta = const VerificationMeta(
    'plannerItemId',
  );
  @override
  late final GeneratedColumn<String> plannerItemId = GeneratedColumn<String>(
    'planner_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReadingOrigin?, String> origin =
      GeneratedColumn<String>(
        'origin',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ReadingOrigin?>($ReadingRequestsTable.$converterorigin);
  static const VerificationMeta _payloadHashMeta = const VerificationMeta(
    'payloadHash',
  );
  @override
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
    'payload_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReadingRequestStatus?, String>
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ReadingRequestStatus?>(
        $ReadingRequestsTable.$converterstatus,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> submittedAt =
      GeneratedColumn<String>(
        'submitted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReadingRequestsTable.$convertersubmittedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> completedAt =
      GeneratedColumn<String>(
        'completed_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReadingRequestsTable.$convertercompletedAt);
  static const VerificationMeta _quotaMonthMeta = const VerificationMeta(
    'quotaMonth',
  );
  @override
  late final GeneratedColumn<String> quotaMonth = GeneratedColumn<String>(
    'quota_month',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotaChargedMeta = const VerificationMeta(
    'quotaCharged',
  );
  @override
  late final GeneratedColumn<bool> quotaCharged = GeneratedColumn<bool>(
    'quota_charged',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quota_charged" IN (0, 1))',
    ),
  );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marksJsonMeta = const VerificationMeta(
    'marksJson',
  );
  @override
  late final GeneratedColumn<String> marksJson = GeneratedColumn<String>(
    'marks_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failReasonMeta = const VerificationMeta(
    'failReason',
  );
  @override
  late final GeneratedColumn<String> failReason = GeneratedColumn<String>(
    'fail_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedMarksJsonMeta =
      const VerificationMeta('confirmedMarksJson');
  @override
  late final GeneratedColumn<String> confirmedMarksJson =
      GeneratedColumn<String>(
        'confirmed_marks_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    requestId,
    subjectId,
    rangeText,
    sessionId,
    plannerItemId,
    origin,
    payloadHash,
    status,
    submittedAt,
    completedAt,
    quotaMonth,
    quotaCharged,
    resultJson,
    marksJson,
    failReason,
    confirmedMarksJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingRequestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('range_text')) {
      context.handle(
        _rangeTextMeta,
        rangeText.isAcceptableOrUnknown(data['range_text']!, _rangeTextMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('planner_item_id')) {
      context.handle(
        _plannerItemIdMeta,
        plannerItemId.isAcceptableOrUnknown(
          data['planner_item_id']!,
          _plannerItemIdMeta,
        ),
      );
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
        _payloadHashMeta,
        payloadHash.isAcceptableOrUnknown(
          data['payload_hash']!,
          _payloadHashMeta,
        ),
      );
    }
    if (data.containsKey('quota_month')) {
      context.handle(
        _quotaMonthMeta,
        quotaMonth.isAcceptableOrUnknown(data['quota_month']!, _quotaMonthMeta),
      );
    }
    if (data.containsKey('quota_charged')) {
      context.handle(
        _quotaChargedMeta,
        quotaCharged.isAcceptableOrUnknown(
          data['quota_charged']!,
          _quotaChargedMeta,
        ),
      );
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    }
    if (data.containsKey('marks_json')) {
      context.handle(
        _marksJsonMeta,
        marksJson.isAcceptableOrUnknown(data['marks_json']!, _marksJsonMeta),
      );
    }
    if (data.containsKey('fail_reason')) {
      context.handle(
        _failReasonMeta,
        failReason.isAcceptableOrUnknown(data['fail_reason']!, _failReasonMeta),
      );
    }
    if (data.containsKey('confirmed_marks_json')) {
      context.handle(
        _confirmedMarksJsonMeta,
        confirmedMarksJson.isAcceptableOrUnknown(
          data['confirmed_marks_json']!,
          _confirmedMarksJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingRequestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $ReadingRequestsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $ReadingRequestsTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $ReadingRequestsTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      rangeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range_text'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      plannerItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planner_item_id'],
      ),
      origin: $ReadingRequestsTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        ),
      ),
      payloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_hash'],
      ),
      status: $ReadingRequestsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        ),
      ),
      submittedAt: $ReadingRequestsTable.$convertersubmittedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}submitted_at'],
        ),
      ),
      completedAt: $ReadingRequestsTable.$convertercompletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}completed_at'],
        ),
      ),
      quotaMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quota_month'],
      ),
      quotaCharged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quota_charged'],
      ),
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      ),
      marksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marks_json'],
      ),
      failReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fail_reason'],
      ),
      confirmedMarksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_marks_json'],
      ),
    );
  }

  @override
  $ReadingRequestsTable createAlias(String alias) {
    return $ReadingRequestsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<ReadingOrigin?, String?, String?> $converterorigin =
      const NullableWireEnumConverter(ReadingOrigin.values);
  static JsonTypeConverter2<ReadingRequestStatus?, String?, String?>
  $converterstatus = const NullableWireEnumConverter(
    ReadingRequestStatus.values,
  );
  static JsonTypeConverter2<DateTime?, String?, String?> $convertersubmittedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $convertercompletedAt =
      const NullableUtcDateTimeConverter();
}

class ReadingRequestRow extends DataClass
    implements Insertable<ReadingRequestRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;

  /// Keep key. Idempotency key; the client uses the same uuid as [id].
  final String requestId;
  final String? subjectId;
  final String? rangeText;
  final String? sessionId;
  final String? plannerItemId;
  final ReadingOrigin? origin;
  final String? payloadHash;
  final ReadingRequestStatus? status;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final String? quotaMonth;
  final bool? quotaCharged;
  final String? resultJson;
  final String? marksJson;
  final String? failReason;

  /// Local only: confirmed marks kept until the save succeeds.
  final String? confirmedMarksJson;
  const ReadingRequestRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    required this.requestId,
    this.subjectId,
    this.rangeText,
    this.sessionId,
    this.plannerItemId,
    this.origin,
    this.payloadHash,
    this.status,
    this.submittedAt,
    this.completedAt,
    this.quotaMonth,
    this.quotaCharged,
    this.resultJson,
    this.marksJson,
    this.failReason,
    this.confirmedMarksJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $ReadingRequestsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $ReadingRequestsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $ReadingRequestsTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    map['request_id'] = Variable<String>(requestId);
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || rangeText != null) {
      map['range_text'] = Variable<String>(rangeText);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    if (!nullToAbsent || plannerItemId != null) {
      map['planner_item_id'] = Variable<String>(plannerItemId);
    }
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(
        $ReadingRequestsTable.$converterorigin.toSql(origin),
      );
    }
    if (!nullToAbsent || payloadHash != null) {
      map['payload_hash'] = Variable<String>(payloadHash);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(
        $ReadingRequestsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<String>(
        $ReadingRequestsTable.$convertersubmittedAt.toSql(submittedAt),
      );
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(
        $ReadingRequestsTable.$convertercompletedAt.toSql(completedAt),
      );
    }
    if (!nullToAbsent || quotaMonth != null) {
      map['quota_month'] = Variable<String>(quotaMonth);
    }
    if (!nullToAbsent || quotaCharged != null) {
      map['quota_charged'] = Variable<bool>(quotaCharged);
    }
    if (!nullToAbsent || resultJson != null) {
      map['result_json'] = Variable<String>(resultJson);
    }
    if (!nullToAbsent || marksJson != null) {
      map['marks_json'] = Variable<String>(marksJson);
    }
    if (!nullToAbsent || failReason != null) {
      map['fail_reason'] = Variable<String>(failReason);
    }
    if (!nullToAbsent || confirmedMarksJson != null) {
      map['confirmed_marks_json'] = Variable<String>(confirmedMarksJson);
    }
    return map;
  }

  ReadingRequestsCompanion toCompanion(bool nullToAbsent) {
    return ReadingRequestsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      requestId: Value(requestId),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      rangeText: rangeText == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeText),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      plannerItemId: plannerItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannerItemId),
      origin: origin == null && nullToAbsent
          ? const Value.absent()
          : Value(origin),
      payloadHash: payloadHash == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadHash),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      quotaMonth: quotaMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaMonth),
      quotaCharged: quotaCharged == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaCharged),
      resultJson: resultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(resultJson),
      marksJson: marksJson == null && nullToAbsent
          ? const Value.absent()
          : Value(marksJson),
      failReason: failReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failReason),
      confirmedMarksJson: confirmedMarksJson == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedMarksJson),
    );
  }

  factory ReadingRequestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingRequestRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $ReadingRequestsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $ReadingRequestsTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $ReadingRequestsTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      requestId: serializer.fromJson<String>(json['request_id']),
      subjectId: serializer.fromJson<String?>(json['subject_id']),
      rangeText: serializer.fromJson<String?>(json['range_text']),
      sessionId: serializer.fromJson<String?>(json['session_id']),
      plannerItemId: serializer.fromJson<String?>(json['planner_item_id']),
      origin: $ReadingRequestsTable.$converterorigin.fromJson(
        serializer.fromJson<String?>(json['origin']),
      ),
      payloadHash: serializer.fromJson<String?>(json['payload_hash']),
      status: $ReadingRequestsTable.$converterstatus.fromJson(
        serializer.fromJson<String?>(json['status']),
      ),
      submittedAt: $ReadingRequestsTable.$convertersubmittedAt.fromJson(
        serializer.fromJson<String?>(json['submitted_at']),
      ),
      completedAt: $ReadingRequestsTable.$convertercompletedAt.fromJson(
        serializer.fromJson<String?>(json['completed_at']),
      ),
      quotaMonth: serializer.fromJson<String?>(json['quota_month']),
      quotaCharged: serializer.fromJson<bool?>(json['quota_charged']),
      resultJson: serializer.fromJson<String?>(json['result_json']),
      marksJson: serializer.fromJson<String?>(json['marks_json']),
      failReason: serializer.fromJson<String?>(json['fail_reason']),
      confirmedMarksJson: serializer.fromJson<String?>(
        json['confirmed_marks_json'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $ReadingRequestsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $ReadingRequestsTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $ReadingRequestsTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'request_id': serializer.toJson<String>(requestId),
      'subject_id': serializer.toJson<String?>(subjectId),
      'range_text': serializer.toJson<String?>(rangeText),
      'session_id': serializer.toJson<String?>(sessionId),
      'planner_item_id': serializer.toJson<String?>(plannerItemId),
      'origin': serializer.toJson<String?>(
        $ReadingRequestsTable.$converterorigin.toJson(origin),
      ),
      'payload_hash': serializer.toJson<String?>(payloadHash),
      'status': serializer.toJson<String?>(
        $ReadingRequestsTable.$converterstatus.toJson(status),
      ),
      'submitted_at': serializer.toJson<String?>(
        $ReadingRequestsTable.$convertersubmittedAt.toJson(submittedAt),
      ),
      'completed_at': serializer.toJson<String?>(
        $ReadingRequestsTable.$convertercompletedAt.toJson(completedAt),
      ),
      'quota_month': serializer.toJson<String?>(quotaMonth),
      'quota_charged': serializer.toJson<bool?>(quotaCharged),
      'result_json': serializer.toJson<String?>(resultJson),
      'marks_json': serializer.toJson<String?>(marksJson),
      'fail_reason': serializer.toJson<String?>(failReason),
      'confirmed_marks_json': serializer.toJson<String?>(confirmedMarksJson),
    };
  }

  ReadingRequestRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    String? requestId,
    Value<String?> subjectId = const Value.absent(),
    Value<String?> rangeText = const Value.absent(),
    Value<String?> sessionId = const Value.absent(),
    Value<String?> plannerItemId = const Value.absent(),
    Value<ReadingOrigin?> origin = const Value.absent(),
    Value<String?> payloadHash = const Value.absent(),
    Value<ReadingRequestStatus?> status = const Value.absent(),
    Value<DateTime?> submittedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> quotaMonth = const Value.absent(),
    Value<bool?> quotaCharged = const Value.absent(),
    Value<String?> resultJson = const Value.absent(),
    Value<String?> marksJson = const Value.absent(),
    Value<String?> failReason = const Value.absent(),
    Value<String?> confirmedMarksJson = const Value.absent(),
  }) => ReadingRequestRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    requestId: requestId ?? this.requestId,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    rangeText: rangeText.present ? rangeText.value : this.rangeText,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    plannerItemId: plannerItemId.present
        ? plannerItemId.value
        : this.plannerItemId,
    origin: origin.present ? origin.value : this.origin,
    payloadHash: payloadHash.present ? payloadHash.value : this.payloadHash,
    status: status.present ? status.value : this.status,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    quotaMonth: quotaMonth.present ? quotaMonth.value : this.quotaMonth,
    quotaCharged: quotaCharged.present ? quotaCharged.value : this.quotaCharged,
    resultJson: resultJson.present ? resultJson.value : this.resultJson,
    marksJson: marksJson.present ? marksJson.value : this.marksJson,
    failReason: failReason.present ? failReason.value : this.failReason,
    confirmedMarksJson: confirmedMarksJson.present
        ? confirmedMarksJson.value
        : this.confirmedMarksJson,
  );
  ReadingRequestRow copyWithCompanion(ReadingRequestsCompanion data) {
    return ReadingRequestRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      rangeText: data.rangeText.present ? data.rangeText.value : this.rangeText,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      plannerItemId: data.plannerItemId.present
          ? data.plannerItemId.value
          : this.plannerItemId,
      origin: data.origin.present ? data.origin.value : this.origin,
      payloadHash: data.payloadHash.present
          ? data.payloadHash.value
          : this.payloadHash,
      status: data.status.present ? data.status.value : this.status,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      quotaMonth: data.quotaMonth.present
          ? data.quotaMonth.value
          : this.quotaMonth,
      quotaCharged: data.quotaCharged.present
          ? data.quotaCharged.value
          : this.quotaCharged,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      marksJson: data.marksJson.present ? data.marksJson.value : this.marksJson,
      failReason: data.failReason.present
          ? data.failReason.value
          : this.failReason,
      confirmedMarksJson: data.confirmedMarksJson.present
          ? data.confirmedMarksJson.value
          : this.confirmedMarksJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingRequestRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('requestId: $requestId, ')
          ..write('subjectId: $subjectId, ')
          ..write('rangeText: $rangeText, ')
          ..write('sessionId: $sessionId, ')
          ..write('plannerItemId: $plannerItemId, ')
          ..write('origin: $origin, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('status: $status, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('quotaMonth: $quotaMonth, ')
          ..write('quotaCharged: $quotaCharged, ')
          ..write('resultJson: $resultJson, ')
          ..write('marksJson: $marksJson, ')
          ..write('failReason: $failReason, ')
          ..write('confirmedMarksJson: $confirmedMarksJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    requestId,
    subjectId,
    rangeText,
    sessionId,
    plannerItemId,
    origin,
    payloadHash,
    status,
    submittedAt,
    completedAt,
    quotaMonth,
    quotaCharged,
    resultJson,
    marksJson,
    failReason,
    confirmedMarksJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingRequestRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.requestId == this.requestId &&
          other.subjectId == this.subjectId &&
          other.rangeText == this.rangeText &&
          other.sessionId == this.sessionId &&
          other.plannerItemId == this.plannerItemId &&
          other.origin == this.origin &&
          other.payloadHash == this.payloadHash &&
          other.status == this.status &&
          other.submittedAt == this.submittedAt &&
          other.completedAt == this.completedAt &&
          other.quotaMonth == this.quotaMonth &&
          other.quotaCharged == this.quotaCharged &&
          other.resultJson == this.resultJson &&
          other.marksJson == this.marksJson &&
          other.failReason == this.failReason &&
          other.confirmedMarksJson == this.confirmedMarksJson);
}

class ReadingRequestsCompanion extends UpdateCompanion<ReadingRequestRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<String> requestId;
  final Value<String?> subjectId;
  final Value<String?> rangeText;
  final Value<String?> sessionId;
  final Value<String?> plannerItemId;
  final Value<ReadingOrigin?> origin;
  final Value<String?> payloadHash;
  final Value<ReadingRequestStatus?> status;
  final Value<DateTime?> submittedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> quotaMonth;
  final Value<bool?> quotaCharged;
  final Value<String?> resultJson;
  final Value<String?> marksJson;
  final Value<String?> failReason;
  final Value<String?> confirmedMarksJson;
  final Value<int> rowid;
  const ReadingRequestsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.requestId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.rangeText = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.plannerItemId = const Value.absent(),
    this.origin = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.status = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.quotaMonth = const Value.absent(),
    this.quotaCharged = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.marksJson = const Value.absent(),
    this.failReason = const Value.absent(),
    this.confirmedMarksJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingRequestsCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    required String requestId,
    this.subjectId = const Value.absent(),
    this.rangeText = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.plannerItemId = const Value.absent(),
    this.origin = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.status = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.quotaMonth = const Value.absent(),
    this.quotaCharged = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.marksJson = const Value.absent(),
    this.failReason = const Value.absent(),
    this.confirmedMarksJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId),
       requestId = Value(requestId);
  static Insertable<ReadingRequestRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? requestId,
    Expression<String>? subjectId,
    Expression<String>? rangeText,
    Expression<String>? sessionId,
    Expression<String>? plannerItemId,
    Expression<String>? origin,
    Expression<String>? payloadHash,
    Expression<String>? status,
    Expression<String>? submittedAt,
    Expression<String>? completedAt,
    Expression<String>? quotaMonth,
    Expression<bool>? quotaCharged,
    Expression<String>? resultJson,
    Expression<String>? marksJson,
    Expression<String>? failReason,
    Expression<String>? confirmedMarksJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (requestId != null) 'request_id': requestId,
      if (subjectId != null) 'subject_id': subjectId,
      if (rangeText != null) 'range_text': rangeText,
      if (sessionId != null) 'session_id': sessionId,
      if (plannerItemId != null) 'planner_item_id': plannerItemId,
      if (origin != null) 'origin': origin,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (status != null) 'status': status,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (quotaMonth != null) 'quota_month': quotaMonth,
      if (quotaCharged != null) 'quota_charged': quotaCharged,
      if (resultJson != null) 'result_json': resultJson,
      if (marksJson != null) 'marks_json': marksJson,
      if (failReason != null) 'fail_reason': failReason,
      if (confirmedMarksJson != null)
        'confirmed_marks_json': confirmedMarksJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingRequestsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<String>? requestId,
    Value<String?>? subjectId,
    Value<String?>? rangeText,
    Value<String?>? sessionId,
    Value<String?>? plannerItemId,
    Value<ReadingOrigin?>? origin,
    Value<String?>? payloadHash,
    Value<ReadingRequestStatus?>? status,
    Value<DateTime?>? submittedAt,
    Value<DateTime?>? completedAt,
    Value<String?>? quotaMonth,
    Value<bool?>? quotaCharged,
    Value<String?>? resultJson,
    Value<String?>? marksJson,
    Value<String?>? failReason,
    Value<String?>? confirmedMarksJson,
    Value<int>? rowid,
  }) {
    return ReadingRequestsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      requestId: requestId ?? this.requestId,
      subjectId: subjectId ?? this.subjectId,
      rangeText: rangeText ?? this.rangeText,
      sessionId: sessionId ?? this.sessionId,
      plannerItemId: plannerItemId ?? this.plannerItemId,
      origin: origin ?? this.origin,
      payloadHash: payloadHash ?? this.payloadHash,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      completedAt: completedAt ?? this.completedAt,
      quotaMonth: quotaMonth ?? this.quotaMonth,
      quotaCharged: quotaCharged ?? this.quotaCharged,
      resultJson: resultJson ?? this.resultJson,
      marksJson: marksJson ?? this.marksJson,
      failReason: failReason ?? this.failReason,
      confirmedMarksJson: confirmedMarksJson ?? this.confirmedMarksJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $ReadingRequestsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $ReadingRequestsTable.$converterclientUpdatedAt.toSql(
          clientUpdatedAt.value,
        ),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $ReadingRequestsTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (rangeText.present) {
      map['range_text'] = Variable<String>(rangeText.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (plannerItemId.present) {
      map['planner_item_id'] = Variable<String>(plannerItemId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        $ReadingRequestsTable.$converterorigin.toSql(origin.value),
      );
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ReadingRequestsTable.$converterstatus.toSql(status.value),
      );
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<String>(
        $ReadingRequestsTable.$convertersubmittedAt.toSql(submittedAt.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(
        $ReadingRequestsTable.$convertercompletedAt.toSql(completedAt.value),
      );
    }
    if (quotaMonth.present) {
      map['quota_month'] = Variable<String>(quotaMonth.value);
    }
    if (quotaCharged.present) {
      map['quota_charged'] = Variable<bool>(quotaCharged.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (marksJson.present) {
      map['marks_json'] = Variable<String>(marksJson.value);
    }
    if (failReason.present) {
      map['fail_reason'] = Variable<String>(failReason.value);
    }
    if (confirmedMarksJson.present) {
      map['confirmed_marks_json'] = Variable<String>(confirmedMarksJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingRequestsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('requestId: $requestId, ')
          ..write('subjectId: $subjectId, ')
          ..write('rangeText: $rangeText, ')
          ..write('sessionId: $sessionId, ')
          ..write('plannerItemId: $plannerItemId, ')
          ..write('origin: $origin, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('status: $status, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('quotaMonth: $quotaMonth, ')
          ..write('quotaCharged: $quotaCharged, ')
          ..write('resultJson: $resultJson, ')
          ..write('marksJson: $marksJson, ')
          ..write('failReason: $failReason, ')
          ..write('confirmedMarksJson: $confirmedMarksJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WrongItemsTable extends WrongItems
    with TableInfo<$WrongItemsTable, WrongItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WrongItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($WrongItemsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($WrongItemsTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($WrongItemsTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rangeTextMeta = const VerificationMeta(
    'rangeText',
  );
  @override
  late final GeneratedColumn<String> rangeText = GeneratedColumn<String>(
    'range_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WrongMark?, String> mark =
      GeneratedColumn<String>(
        'mark',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<WrongMark?>($WrongItemsTable.$convertermark);
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userConfirmedMeta = const VerificationMeta(
    'userConfirmed',
  );
  @override
  late final GeneratedColumn<bool> userConfirmed = GeneratedColumn<bool>(
    'user_confirmed',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_confirmed" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<WrongItemStatus?, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<WrongItemStatus?>($WrongItemsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> resolvedAt =
      GeneratedColumn<String>(
        'resolved_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($WrongItemsTable.$converterresolvedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    requestId,
    subjectId,
    rangeText,
    pageIndex,
    number,
    mark,
    confidence,
    userConfirmed,
    status,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wrong_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WrongItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('range_text')) {
      context.handle(
        _rangeTextMeta,
        rangeText.isAcceptableOrUnknown(data['range_text']!, _rangeTextMeta),
      );
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('user_confirmed')) {
      context.handle(
        _userConfirmedMeta,
        userConfirmed.isAcceptableOrUnknown(
          data['user_confirmed']!,
          _userConfirmedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WrongItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WrongItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $WrongItemsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $WrongItemsTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $WrongItemsTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      rangeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range_text'],
      ),
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      ),
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      ),
      mark: $WrongItemsTable.$convertermark.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mark'],
        ),
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      userConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_confirmed'],
      ),
      status: $WrongItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        ),
      ),
      resolvedAt: $WrongItemsTable.$converterresolvedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}resolved_at'],
        ),
      ),
    );
  }

  @override
  $WrongItemsTable createAlias(String alias) {
    return $WrongItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<WrongMark?, String?, String?> $convertermark =
      const NullableWireEnumConverter(WrongMark.values);
  static JsonTypeConverter2<WrongItemStatus?, String?, String?>
  $converterstatus = const NullableWireEnumConverter(WrongItemStatus.values);
  static JsonTypeConverter2<DateTime?, String?, String?> $converterresolvedAt =
      const NullableUtcDateTimeConverter();
}

class WrongItemRow extends DataClass implements Insertable<WrongItemRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;

  /// Keep key.
  final String requestId;
  final String? subjectId;
  final String? rangeText;
  final int? pageIndex;
  final int? number;
  final WrongMark? mark;
  final double? confidence;
  final bool? userConfirmed;
  final WrongItemStatus? status;
  final DateTime? resolvedAt;
  const WrongItemRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    required this.requestId,
    this.subjectId,
    this.rangeText,
    this.pageIndex,
    this.number,
    this.mark,
    this.confidence,
    this.userConfirmed,
    this.status,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $WrongItemsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $WrongItemsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $WrongItemsTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    map['request_id'] = Variable<String>(requestId);
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || rangeText != null) {
      map['range_text'] = Variable<String>(rangeText);
    }
    if (!nullToAbsent || pageIndex != null) {
      map['page_index'] = Variable<int>(pageIndex);
    }
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    if (!nullToAbsent || mark != null) {
      map['mark'] = Variable<String>(
        $WrongItemsTable.$convertermark.toSql(mark),
      );
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || userConfirmed != null) {
      map['user_confirmed'] = Variable<bool>(userConfirmed);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(
        $WrongItemsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<String>(
        $WrongItemsTable.$converterresolvedAt.toSql(resolvedAt),
      );
    }
    return map;
  }

  WrongItemsCompanion toCompanion(bool nullToAbsent) {
    return WrongItemsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      requestId: Value(requestId),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      rangeText: rangeText == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeText),
      pageIndex: pageIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(pageIndex),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      mark: mark == null && nullToAbsent ? const Value.absent() : Value(mark),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      userConfirmed: userConfirmed == null && nullToAbsent
          ? const Value.absent()
          : Value(userConfirmed),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory WrongItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WrongItemRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $WrongItemsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $WrongItemsTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $WrongItemsTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      requestId: serializer.fromJson<String>(json['request_id']),
      subjectId: serializer.fromJson<String?>(json['subject_id']),
      rangeText: serializer.fromJson<String?>(json['range_text']),
      pageIndex: serializer.fromJson<int?>(json['page_index']),
      number: serializer.fromJson<int?>(json['number']),
      mark: $WrongItemsTable.$convertermark.fromJson(
        serializer.fromJson<String?>(json['mark']),
      ),
      confidence: serializer.fromJson<double?>(json['confidence']),
      userConfirmed: serializer.fromJson<bool?>(json['user_confirmed']),
      status: $WrongItemsTable.$converterstatus.fromJson(
        serializer.fromJson<String?>(json['status']),
      ),
      resolvedAt: $WrongItemsTable.$converterresolvedAt.fromJson(
        serializer.fromJson<String?>(json['resolved_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $WrongItemsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $WrongItemsTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $WrongItemsTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'request_id': serializer.toJson<String>(requestId),
      'subject_id': serializer.toJson<String?>(subjectId),
      'range_text': serializer.toJson<String?>(rangeText),
      'page_index': serializer.toJson<int?>(pageIndex),
      'number': serializer.toJson<int?>(number),
      'mark': serializer.toJson<String?>(
        $WrongItemsTable.$convertermark.toJson(mark),
      ),
      'confidence': serializer.toJson<double?>(confidence),
      'user_confirmed': serializer.toJson<bool?>(userConfirmed),
      'status': serializer.toJson<String?>(
        $WrongItemsTable.$converterstatus.toJson(status),
      ),
      'resolved_at': serializer.toJson<String?>(
        $WrongItemsTable.$converterresolvedAt.toJson(resolvedAt),
      ),
    };
  }

  WrongItemRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    String? requestId,
    Value<String?> subjectId = const Value.absent(),
    Value<String?> rangeText = const Value.absent(),
    Value<int?> pageIndex = const Value.absent(),
    Value<int?> number = const Value.absent(),
    Value<WrongMark?> mark = const Value.absent(),
    Value<double?> confidence = const Value.absent(),
    Value<bool?> userConfirmed = const Value.absent(),
    Value<WrongItemStatus?> status = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => WrongItemRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    requestId: requestId ?? this.requestId,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    rangeText: rangeText.present ? rangeText.value : this.rangeText,
    pageIndex: pageIndex.present ? pageIndex.value : this.pageIndex,
    number: number.present ? number.value : this.number,
    mark: mark.present ? mark.value : this.mark,
    confidence: confidence.present ? confidence.value : this.confidence,
    userConfirmed: userConfirmed.present
        ? userConfirmed.value
        : this.userConfirmed,
    status: status.present ? status.value : this.status,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  WrongItemRow copyWithCompanion(WrongItemsCompanion data) {
    return WrongItemRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      rangeText: data.rangeText.present ? data.rangeText.value : this.rangeText,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      number: data.number.present ? data.number.value : this.number,
      mark: data.mark.present ? data.mark.value : this.mark,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      userConfirmed: data.userConfirmed.present
          ? data.userConfirmed.value
          : this.userConfirmed,
      status: data.status.present ? data.status.value : this.status,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WrongItemRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('requestId: $requestId, ')
          ..write('subjectId: $subjectId, ')
          ..write('rangeText: $rangeText, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('number: $number, ')
          ..write('mark: $mark, ')
          ..write('confidence: $confidence, ')
          ..write('userConfirmed: $userConfirmed, ')
          ..write('status: $status, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    requestId,
    subjectId,
    rangeText,
    pageIndex,
    number,
    mark,
    confidence,
    userConfirmed,
    status,
    resolvedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WrongItemRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.requestId == this.requestId &&
          other.subjectId == this.subjectId &&
          other.rangeText == this.rangeText &&
          other.pageIndex == this.pageIndex &&
          other.number == this.number &&
          other.mark == this.mark &&
          other.confidence == this.confidence &&
          other.userConfirmed == this.userConfirmed &&
          other.status == this.status &&
          other.resolvedAt == this.resolvedAt);
}

class WrongItemsCompanion extends UpdateCompanion<WrongItemRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<String> requestId;
  final Value<String?> subjectId;
  final Value<String?> rangeText;
  final Value<int?> pageIndex;
  final Value<int?> number;
  final Value<WrongMark?> mark;
  final Value<double?> confidence;
  final Value<bool?> userConfirmed;
  final Value<WrongItemStatus?> status;
  final Value<DateTime?> resolvedAt;
  final Value<int> rowid;
  const WrongItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.requestId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.rangeText = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.number = const Value.absent(),
    this.mark = const Value.absent(),
    this.confidence = const Value.absent(),
    this.userConfirmed = const Value.absent(),
    this.status = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WrongItemsCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    required String requestId,
    this.subjectId = const Value.absent(),
    this.rangeText = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.number = const Value.absent(),
    this.mark = const Value.absent(),
    this.confidence = const Value.absent(),
    this.userConfirmed = const Value.absent(),
    this.status = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId),
       requestId = Value(requestId);
  static Insertable<WrongItemRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? requestId,
    Expression<String>? subjectId,
    Expression<String>? rangeText,
    Expression<int>? pageIndex,
    Expression<int>? number,
    Expression<String>? mark,
    Expression<double>? confidence,
    Expression<bool>? userConfirmed,
    Expression<String>? status,
    Expression<String>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (requestId != null) 'request_id': requestId,
      if (subjectId != null) 'subject_id': subjectId,
      if (rangeText != null) 'range_text': rangeText,
      if (pageIndex != null) 'page_index': pageIndex,
      if (number != null) 'number': number,
      if (mark != null) 'mark': mark,
      if (confidence != null) 'confidence': confidence,
      if (userConfirmed != null) 'user_confirmed': userConfirmed,
      if (status != null) 'status': status,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WrongItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<String>? requestId,
    Value<String?>? subjectId,
    Value<String?>? rangeText,
    Value<int?>? pageIndex,
    Value<int?>? number,
    Value<WrongMark?>? mark,
    Value<double?>? confidence,
    Value<bool?>? userConfirmed,
    Value<WrongItemStatus?>? status,
    Value<DateTime?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return WrongItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      requestId: requestId ?? this.requestId,
      subjectId: subjectId ?? this.subjectId,
      rangeText: rangeText ?? this.rangeText,
      pageIndex: pageIndex ?? this.pageIndex,
      number: number ?? this.number,
      mark: mark ?? this.mark,
      confidence: confidence ?? this.confidence,
      userConfirmed: userConfirmed ?? this.userConfirmed,
      status: status ?? this.status,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $WrongItemsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $WrongItemsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $WrongItemsTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (rangeText.present) {
      map['range_text'] = Variable<String>(rangeText.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (mark.present) {
      map['mark'] = Variable<String>(
        $WrongItemsTable.$convertermark.toSql(mark.value),
      );
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (userConfirmed.present) {
      map['user_confirmed'] = Variable<bool>(userConfirmed.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $WrongItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<String>(
        $WrongItemsTable.$converterresolvedAt.toSql(resolvedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WrongItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('requestId: $requestId, ')
          ..write('subjectId: $subjectId, ')
          ..write('rangeText: $rangeText, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('number: $number, ')
          ..write('mark: $mark, ')
          ..write('confidence: $confidence, ')
          ..write('userConfirmed: $userConfirmed, ')
          ..write('status: $status, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewEntriesTable extends ReviewEntries
    with TableInfo<$ReviewEntriesTable, ReviewEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReviewEntriesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($ReviewEntriesTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReviewEntriesTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wrongItemIdMeta = const VerificationMeta(
    'wrongItemId',
  );
  @override
  late final GeneratedColumn<String> wrongItemId = GeneratedColumn<String>(
    'wrong_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> dueAt =
      GeneratedColumn<String>(
        'due_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReviewEntriesTable.$converterdueAt);
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consecutiveCorrectMeta =
      const VerificationMeta('consecutiveCorrect');
  @override
  late final GeneratedColumn<int> consecutiveCorrect = GeneratedColumn<int>(
    'consecutive_correct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RetryResult?, String> lastResult =
      GeneratedColumn<String>(
        'last_result',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<RetryResult?>($ReviewEntriesTable.$converterlastResult);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    wrongItemId,
    dueAt,
    intervalDays,
    consecutiveCorrect,
    lastResult,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('wrong_item_id')) {
      context.handle(
        _wrongItemIdMeta,
        wrongItemId.isAcceptableOrUnknown(
          data['wrong_item_id']!,
          _wrongItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wrongItemIdMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('consecutive_correct')) {
      context.handle(
        _consecutiveCorrectMeta,
        consecutiveCorrect.isAcceptableOrUnknown(
          data['consecutive_correct']!,
          _consecutiveCorrectMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $ReviewEntriesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $ReviewEntriesTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $ReviewEntriesTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      wrongItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wrong_item_id'],
      )!,
      dueAt: $ReviewEntriesTable.$converterdueAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}due_at'],
        ),
      ),
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      ),
      consecutiveCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_correct'],
      ),
      lastResult: $ReviewEntriesTable.$converterlastResult.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_result'],
        ),
      ),
    );
  }

  @override
  $ReviewEntriesTable createAlias(String alias) {
    return $ReviewEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdueAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<RetryResult?, String?, String?>
  $converterlastResult = const NullableWireEnumConverter(RetryResult.values);
}

class ReviewEntryRow extends DataClass implements Insertable<ReviewEntryRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;

  /// Keep key. One live entry per wrong item — enforced by the partial
  /// unique index `review_entries_live_wrong_item` created in
  /// `AppDatabase.migration.onCreate` (drift's @TableIndex has no WHERE).
  final String wrongItemId;
  final DateTime? dueAt;
  final int? intervalDays;
  final int? consecutiveCorrect;
  final RetryResult? lastResult;
  const ReviewEntryRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    required this.wrongItemId,
    this.dueAt,
    this.intervalDays,
    this.consecutiveCorrect,
    this.lastResult,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $ReviewEntriesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $ReviewEntriesTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $ReviewEntriesTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    map['wrong_item_id'] = Variable<String>(wrongItemId);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<String>(
        $ReviewEntriesTable.$converterdueAt.toSql(dueAt),
      );
    }
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    if (!nullToAbsent || consecutiveCorrect != null) {
      map['consecutive_correct'] = Variable<int>(consecutiveCorrect);
    }
    if (!nullToAbsent || lastResult != null) {
      map['last_result'] = Variable<String>(
        $ReviewEntriesTable.$converterlastResult.toSql(lastResult),
      );
    }
    return map;
  }

  ReviewEntriesCompanion toCompanion(bool nullToAbsent) {
    return ReviewEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      wrongItemId: Value(wrongItemId),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      consecutiveCorrect: consecutiveCorrect == null && nullToAbsent
          ? const Value.absent()
          : Value(consecutiveCorrect),
      lastResult: lastResult == null && nullToAbsent
          ? const Value.absent()
          : Value(lastResult),
    );
  }

  factory ReviewEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewEntryRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $ReviewEntriesTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $ReviewEntriesTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $ReviewEntriesTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      wrongItemId: serializer.fromJson<String>(json['wrong_item_id']),
      dueAt: $ReviewEntriesTable.$converterdueAt.fromJson(
        serializer.fromJson<String?>(json['due_at']),
      ),
      intervalDays: serializer.fromJson<int?>(json['interval_days']),
      consecutiveCorrect: serializer.fromJson<int?>(
        json['consecutive_correct'],
      ),
      lastResult: $ReviewEntriesTable.$converterlastResult.fromJson(
        serializer.fromJson<String?>(json['last_result']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $ReviewEntriesTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $ReviewEntriesTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $ReviewEntriesTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'wrong_item_id': serializer.toJson<String>(wrongItemId),
      'due_at': serializer.toJson<String?>(
        $ReviewEntriesTable.$converterdueAt.toJson(dueAt),
      ),
      'interval_days': serializer.toJson<int?>(intervalDays),
      'consecutive_correct': serializer.toJson<int?>(consecutiveCorrect),
      'last_result': serializer.toJson<String?>(
        $ReviewEntriesTable.$converterlastResult.toJson(lastResult),
      ),
    };
  }

  ReviewEntryRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    String? wrongItemId,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<int?> intervalDays = const Value.absent(),
    Value<int?> consecutiveCorrect = const Value.absent(),
    Value<RetryResult?> lastResult = const Value.absent(),
  }) => ReviewEntryRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    wrongItemId: wrongItemId ?? this.wrongItemId,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    intervalDays: intervalDays.present ? intervalDays.value : this.intervalDays,
    consecutiveCorrect: consecutiveCorrect.present
        ? consecutiveCorrect.value
        : this.consecutiveCorrect,
    lastResult: lastResult.present ? lastResult.value : this.lastResult,
  );
  ReviewEntryRow copyWithCompanion(ReviewEntriesCompanion data) {
    return ReviewEntryRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      wrongItemId: data.wrongItemId.present
          ? data.wrongItemId.value
          : this.wrongItemId,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      consecutiveCorrect: data.consecutiveCorrect.present
          ? data.consecutiveCorrect.value
          : this.consecutiveCorrect,
      lastResult: data.lastResult.present
          ? data.lastResult.value
          : this.lastResult,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEntryRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('wrongItemId: $wrongItemId, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('consecutiveCorrect: $consecutiveCorrect, ')
          ..write('lastResult: $lastResult')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    wrongItemId,
    dueAt,
    intervalDays,
    consecutiveCorrect,
    lastResult,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewEntryRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.wrongItemId == this.wrongItemId &&
          other.dueAt == this.dueAt &&
          other.intervalDays == this.intervalDays &&
          other.consecutiveCorrect == this.consecutiveCorrect &&
          other.lastResult == this.lastResult);
}

class ReviewEntriesCompanion extends UpdateCompanion<ReviewEntryRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<String> wrongItemId;
  final Value<DateTime?> dueAt;
  final Value<int?> intervalDays;
  final Value<int?> consecutiveCorrect;
  final Value<RetryResult?> lastResult;
  final Value<int> rowid;
  const ReviewEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.wrongItemId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.consecutiveCorrect = const Value.absent(),
    this.lastResult = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewEntriesCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    required String wrongItemId,
    this.dueAt = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.consecutiveCorrect = const Value.absent(),
    this.lastResult = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId),
       wrongItemId = Value(wrongItemId);
  static Insertable<ReviewEntryRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? wrongItemId,
    Expression<String>? dueAt,
    Expression<int>? intervalDays,
    Expression<int>? consecutiveCorrect,
    Expression<String>? lastResult,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (wrongItemId != null) 'wrong_item_id': wrongItemId,
      if (dueAt != null) 'due_at': dueAt,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (consecutiveCorrect != null) 'consecutive_correct': consecutiveCorrect,
      if (lastResult != null) 'last_result': lastResult,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<String>? wrongItemId,
    Value<DateTime?>? dueAt,
    Value<int?>? intervalDays,
    Value<int?>? consecutiveCorrect,
    Value<RetryResult?>? lastResult,
    Value<int>? rowid,
  }) {
    return ReviewEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      wrongItemId: wrongItemId ?? this.wrongItemId,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastResult: lastResult ?? this.lastResult,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $ReviewEntriesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $ReviewEntriesTable.$converterclientUpdatedAt.toSql(
          clientUpdatedAt.value,
        ),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $ReviewEntriesTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (wrongItemId.present) {
      map['wrong_item_id'] = Variable<String>(wrongItemId.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<String>(
        $ReviewEntriesTable.$converterdueAt.toSql(dueAt.value),
      );
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (consecutiveCorrect.present) {
      map['consecutive_correct'] = Variable<int>(consecutiveCorrect.value);
    }
    if (lastResult.present) {
      map['last_result'] = Variable<String>(
        $ReviewEntriesTable.$converterlastResult.toSql(lastResult.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('wrongItemId: $wrongItemId, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('consecutiveCorrect: $consecutiveCorrect, ')
          ..write('lastResult: $lastResult, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RetryRecordsTable extends RetryRecords
    with TableInfo<$RetryRecordsTable, RetryRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RetryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RetryRecordsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($RetryRecordsTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($RetryRecordsTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wrongItemIdMeta = const VerificationMeta(
    'wrongItemId',
  );
  @override
  late final GeneratedColumn<String> wrongItemId = GeneratedColumn<String>(
    'wrong_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RetryResult?, String> result =
      GeneratedColumn<String>(
        'result',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<RetryResult?>($RetryRecordsTable.$converterresult);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> at =
      GeneratedColumn<String>(
        'at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($RetryRecordsTable.$converterat);
  static const VerificationMeta _voidedMeta = const VerificationMeta('voided');
  @override
  late final GeneratedColumn<bool> voided = GeneratedColumn<bool>(
    'voided',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("voided" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> voidedAt =
      GeneratedColumn<String>(
        'voided_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($RetryRecordsTable.$convertervoidedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    wrongItemId,
    result,
    at,
    voided,
    voidedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'retry_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<RetryRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('wrong_item_id')) {
      context.handle(
        _wrongItemIdMeta,
        wrongItemId.isAcceptableOrUnknown(
          data['wrong_item_id']!,
          _wrongItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wrongItemIdMeta);
    }
    if (data.containsKey('voided')) {
      context.handle(
        _voidedMeta,
        voided.isAcceptableOrUnknown(data['voided']!, _voidedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RetryRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RetryRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $RetryRecordsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $RetryRecordsTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $RetryRecordsTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      wrongItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wrong_item_id'],
      )!,
      result: $RetryRecordsTable.$converterresult.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}result'],
        ),
      ),
      at: $RetryRecordsTable.$converterat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}at'],
        ),
      ),
      voided: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}voided'],
      ),
      voidedAt: $RetryRecordsTable.$convertervoidedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}voided_at'],
        ),
      ),
    );
  }

  @override
  $RetryRecordsTable createAlias(String alias) {
    return $RetryRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<RetryResult?, String?, String?> $converterresult =
      const NullableWireEnumConverter(RetryResult.values);
  static JsonTypeConverter2<DateTime?, String?, String?> $converterat =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $convertervoidedAt =
      const NullableUtcDateTimeConverter();
}

class RetryRecordRow extends DataClass implements Insertable<RetryRecordRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;

  /// Keep key.
  final String wrongItemId;
  final RetryResult? result;
  final DateTime? at;
  final bool? voided;
  final DateTime? voidedAt;
  const RetryRecordRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    required this.wrongItemId,
    this.result,
    this.at,
    this.voided,
    this.voidedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $RetryRecordsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $RetryRecordsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $RetryRecordsTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    map['wrong_item_id'] = Variable<String>(wrongItemId);
    if (!nullToAbsent || result != null) {
      map['result'] = Variable<String>(
        $RetryRecordsTable.$converterresult.toSql(result),
      );
    }
    if (!nullToAbsent || at != null) {
      map['at'] = Variable<String>($RetryRecordsTable.$converterat.toSql(at));
    }
    if (!nullToAbsent || voided != null) {
      map['voided'] = Variable<bool>(voided);
    }
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<String>(
        $RetryRecordsTable.$convertervoidedAt.toSql(voidedAt),
      );
    }
    return map;
  }

  RetryRecordsCompanion toCompanion(bool nullToAbsent) {
    return RetryRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      wrongItemId: Value(wrongItemId),
      result: result == null && nullToAbsent
          ? const Value.absent()
          : Value(result),
      at: at == null && nullToAbsent ? const Value.absent() : Value(at),
      voided: voided == null && nullToAbsent
          ? const Value.absent()
          : Value(voided),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
    );
  }

  factory RetryRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RetryRecordRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $RetryRecordsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $RetryRecordsTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $RetryRecordsTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      wrongItemId: serializer.fromJson<String>(json['wrong_item_id']),
      result: $RetryRecordsTable.$converterresult.fromJson(
        serializer.fromJson<String?>(json['result']),
      ),
      at: $RetryRecordsTable.$converterat.fromJson(
        serializer.fromJson<String?>(json['at']),
      ),
      voided: serializer.fromJson<bool?>(json['voided']),
      voidedAt: $RetryRecordsTable.$convertervoidedAt.fromJson(
        serializer.fromJson<String?>(json['voided_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $RetryRecordsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $RetryRecordsTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $RetryRecordsTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'wrong_item_id': serializer.toJson<String>(wrongItemId),
      'result': serializer.toJson<String?>(
        $RetryRecordsTable.$converterresult.toJson(result),
      ),
      'at': serializer.toJson<String?>(
        $RetryRecordsTable.$converterat.toJson(at),
      ),
      'voided': serializer.toJson<bool?>(voided),
      'voided_at': serializer.toJson<String?>(
        $RetryRecordsTable.$convertervoidedAt.toJson(voidedAt),
      ),
    };
  }

  RetryRecordRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    String? wrongItemId,
    Value<RetryResult?> result = const Value.absent(),
    Value<DateTime?> at = const Value.absent(),
    Value<bool?> voided = const Value.absent(),
    Value<DateTime?> voidedAt = const Value.absent(),
  }) => RetryRecordRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    wrongItemId: wrongItemId ?? this.wrongItemId,
    result: result.present ? result.value : this.result,
    at: at.present ? at.value : this.at,
    voided: voided.present ? voided.value : this.voided,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
  );
  RetryRecordRow copyWithCompanion(RetryRecordsCompanion data) {
    return RetryRecordRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      wrongItemId: data.wrongItemId.present
          ? data.wrongItemId.value
          : this.wrongItemId,
      result: data.result.present ? data.result.value : this.result,
      at: data.at.present ? data.at.value : this.at,
      voided: data.voided.present ? data.voided.value : this.voided,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RetryRecordRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('wrongItemId: $wrongItemId, ')
          ..write('result: $result, ')
          ..write('at: $at, ')
          ..write('voided: $voided, ')
          ..write('voidedAt: $voidedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    wrongItemId,
    result,
    at,
    voided,
    voidedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RetryRecordRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.wrongItemId == this.wrongItemId &&
          other.result == this.result &&
          other.at == this.at &&
          other.voided == this.voided &&
          other.voidedAt == this.voidedAt);
}

class RetryRecordsCompanion extends UpdateCompanion<RetryRecordRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<String> wrongItemId;
  final Value<RetryResult?> result;
  final Value<DateTime?> at;
  final Value<bool?> voided;
  final Value<DateTime?> voidedAt;
  final Value<int> rowid;
  const RetryRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.wrongItemId = const Value.absent(),
    this.result = const Value.absent(),
    this.at = const Value.absent(),
    this.voided = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RetryRecordsCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    required String wrongItemId,
    this.result = const Value.absent(),
    this.at = const Value.absent(),
    this.voided = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId),
       wrongItemId = Value(wrongItemId);
  static Insertable<RetryRecordRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? wrongItemId,
    Expression<String>? result,
    Expression<String>? at,
    Expression<bool>? voided,
    Expression<String>? voidedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (wrongItemId != null) 'wrong_item_id': wrongItemId,
      if (result != null) 'result': result,
      if (at != null) 'at': at,
      if (voided != null) 'voided': voided,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RetryRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<String>? wrongItemId,
    Value<RetryResult?>? result,
    Value<DateTime?>? at,
    Value<bool?>? voided,
    Value<DateTime?>? voidedAt,
    Value<int>? rowid,
  }) {
    return RetryRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      wrongItemId: wrongItemId ?? this.wrongItemId,
      result: result ?? this.result,
      at: at ?? this.at,
      voided: voided ?? this.voided,
      voidedAt: voidedAt ?? this.voidedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $RetryRecordsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $RetryRecordsTable.$converterclientUpdatedAt.toSql(
          clientUpdatedAt.value,
        ),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $RetryRecordsTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (wrongItemId.present) {
      map['wrong_item_id'] = Variable<String>(wrongItemId.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(
        $RetryRecordsTable.$converterresult.toSql(result.value),
      );
    }
    if (at.present) {
      map['at'] = Variable<String>(
        $RetryRecordsTable.$converterat.toSql(at.value),
      );
    }
    if (voided.present) {
      map['voided'] = Variable<bool>(voided.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<String>(
        $RetryRecordsTable.$convertervoidedAt.toSql(voidedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RetryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('wrongItemId: $wrongItemId, ')
          ..write('result: $result, ')
          ..write('at: $at, ')
          ..write('voided: $voided, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SettingsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($SettingsTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SettingsTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    key,
    valueJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $SettingsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $SettingsTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $SettingsTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      ),
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;
  final String? key;
  final String? valueJson;
  const SettingRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    this.key,
    this.valueJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $SettingsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $SettingsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $SettingsTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    if (!nullToAbsent || key != null) {
      map['key'] = Variable<String>(key);
    }
    if (!nullToAbsent || valueJson != null) {
      map['value_json'] = Variable<String>(valueJson);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      key: key == null && nullToAbsent ? const Value.absent() : Value(key),
      valueJson: valueJson == null && nullToAbsent
          ? const Value.absent()
          : Value(valueJson),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $SettingsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $SettingsTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $SettingsTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      key: serializer.fromJson<String?>(json['key']),
      valueJson: serializer.fromJson<String?>(json['value_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $SettingsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $SettingsTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $SettingsTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'key': serializer.toJson<String?>(key),
      'value_json': serializer.toJson<String?>(valueJson),
    };
  }

  SettingRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    Value<String?> key = const Value.absent(),
    Value<String?> valueJson = const Value.absent(),
  }) => SettingRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    key: key.present ? key.value : this.key,
    valueJson: valueJson.present ? valueJson.value : this.valueJson,
  );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    key,
    valueJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.key == this.key &&
          other.valueJson == this.valueJson);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<String?> key;
  final Value<String?> valueJson;
  final Value<int> rowid;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId);
  static Insertable<SettingRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<String?>? key,
    Value<String?>? valueJson,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $SettingsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $SettingsTable.$converterclientUpdatedAt.toSql(clientUpdatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $SettingsTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityDaysTable extends ActivityDays
    with TableInfo<$ActivityDaysTable, ActivityDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ActivityDaysTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String>
  clientUpdatedAt = GeneratedColumn<String>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($ActivityDaysTable.$converterclientUpdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ActivityDaysTable.$converterdeletedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRevMeta = const VerificationMeta(
    'clientRev',
  );
  @override
  late final GeneratedColumn<int> clientRev = GeneratedColumn<int>(
    'client_rev',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeEpochMeta = const VerificationMeta(
    'purgeEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeEpoch = GeneratedColumn<int>(
    'purge_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    date,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_rev')) {
      context.handle(
        _clientRevMeta,
        clientRev.isAcceptableOrUnknown(data['client_rev']!, _clientRevMeta),
      );
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    if (data.containsKey('purge_epoch')) {
      context.handle(
        _purgeEpochMeta,
        purgeEpoch.isAcceptableOrUnknown(data['purge_epoch']!, _purgeEpochMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityDayRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: $ActivityDaysTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      clientUpdatedAt: $ActivityDaysTable.$converterclientUpdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}client_updated_at'],
        )!,
      ),
      deletedAt: $ActivityDaysTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_rev'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
      purgeEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_epoch'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $ActivityDaysTable createAlias(String alias) {
    return $ActivityDaysTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String>
  $converterclientUpdatedAt = const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
}

class ActivityDayRow extends DataClass implements Insertable<ActivityDayRow> {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// Local only. +1 on every user write.
  final int clientRev;

  /// Local only. Last seen server version (null = unconfirmed new row).
  final int? baseServerVersion;
  final int? serverVersion;
  final int? serverSeq;
  final int purgeEpoch;

  /// Keep key. Local `yyyy-MM-dd`. `id` = uuid v5 (D24).
  final String date;
  const ActivityDayRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.clientUpdatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.clientRev,
    this.baseServerVersion,
    this.serverVersion,
    this.serverSeq,
    required this.purgeEpoch,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    {
      map['created_at'] = Variable<String>(
        $ActivityDaysTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['client_updated_at'] = Variable<String>(
        $ActivityDaysTable.$converterclientUpdatedAt.toSql(clientUpdatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $ActivityDaysTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['client_rev'] = Variable<int>(clientRev);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    map['purge_epoch'] = Variable<int>(purgeEpoch);
    map['date'] = Variable<String>(date);
    return map;
  }

  ActivityDaysCompanion toCompanion(bool nullToAbsent) {
    return ActivityDaysCompanion(
      id: Value(id),
      userId: Value(userId),
      createdAt: Value(createdAt),
      clientUpdatedAt: Value(clientUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      clientRev: Value(clientRev),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
      purgeEpoch: Value(purgeEpoch),
      date: Value(date),
    );
  }

  factory ActivityDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityDayRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      createdAt: $ActivityDaysTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      clientUpdatedAt: $ActivityDaysTable.$converterclientUpdatedAt.fromJson(
        serializer.fromJson<String>(json['client_updated_at']),
      ),
      deletedAt: $ActivityDaysTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
      deviceId: serializer.fromJson<String>(json['device_id']),
      clientRev: serializer.fromJson<int>(json['client_rev']),
      baseServerVersion: serializer.fromJson<int?>(json['base_server_version']),
      serverVersion: serializer.fromJson<int?>(json['server_version']),
      serverSeq: serializer.fromJson<int?>(json['server_seq']),
      purgeEpoch: serializer.fromJson<int>(json['purge_epoch']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'created_at': serializer.toJson<String>(
        $ActivityDaysTable.$convertercreatedAt.toJson(createdAt),
      ),
      'client_updated_at': serializer.toJson<String>(
        $ActivityDaysTable.$converterclientUpdatedAt.toJson(clientUpdatedAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $ActivityDaysTable.$converterdeletedAt.toJson(deletedAt),
      ),
      'device_id': serializer.toJson<String>(deviceId),
      'client_rev': serializer.toJson<int>(clientRev),
      'base_server_version': serializer.toJson<int?>(baseServerVersion),
      'server_version': serializer.toJson<int?>(serverVersion),
      'server_seq': serializer.toJson<int?>(serverSeq),
      'purge_epoch': serializer.toJson<int>(purgeEpoch),
      'date': serializer.toJson<String>(date),
    };
  }

  ActivityDayRow copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? clientUpdatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    int? clientRev,
    Value<int?> baseServerVersion = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
    int? purgeEpoch,
    String? date,
  }) => ActivityDayRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    clientRev: clientRev ?? this.clientRev,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
    purgeEpoch: purgeEpoch ?? this.purgeEpoch,
    date: date ?? this.date,
  );
  ActivityDayRow copyWithCompanion(ActivityDaysCompanion data) {
    return ActivityDayRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientRev: data.clientRev.present ? data.clientRev.value : this.clientRev,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      purgeEpoch: data.purgeEpoch.present
          ? data.purgeEpoch.value
          : this.purgeEpoch,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityDayRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    createdAt,
    clientUpdatedAt,
    deletedAt,
    deviceId,
    clientRev,
    baseServerVersion,
    serverVersion,
    serverSeq,
    purgeEpoch,
    date,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityDayRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.clientRev == this.clientRev &&
          other.baseServerVersion == this.baseServerVersion &&
          other.serverVersion == this.serverVersion &&
          other.serverSeq == this.serverSeq &&
          other.purgeEpoch == this.purgeEpoch &&
          other.date == this.date);
}

class ActivityDaysCompanion extends UpdateCompanion<ActivityDayRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> clientUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> clientRev;
  final Value<int?> baseServerVersion;
  final Value<int?> serverVersion;
  final Value<int?> serverSeq;
  final Value<int> purgeEpoch;
  final Value<String> date;
  final Value<int> rowid;
  const ActivityDaysCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityDaysCompanion.insert({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.clientRev = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.purgeEpoch = const Value.absent(),
    required String date,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       clientUpdatedAt = Value(clientUpdatedAt),
       deviceId = Value(deviceId),
       date = Value(date);
  static Insertable<ActivityDayRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? createdAt,
    Expression<String>? clientUpdatedAt,
    Expression<String>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? clientRev,
    Expression<int>? baseServerVersion,
    Expression<int>? serverVersion,
    Expression<int>? serverSeq,
    Expression<int>? purgeEpoch,
    Expression<String>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (clientRev != null) 'client_rev': clientRev,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (purgeEpoch != null) 'purge_epoch': purgeEpoch,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityDaysCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? clientUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? clientRev,
    Value<int?>? baseServerVersion,
    Value<int?>? serverVersion,
    Value<int?>? serverSeq,
    Value<int>? purgeEpoch,
    Value<String>? date,
    Value<int>? rowid,
  }) {
    return ActivityDaysCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      clientRev: clientRev ?? this.clientRev,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      serverSeq: serverSeq ?? this.serverSeq,
      purgeEpoch: purgeEpoch ?? this.purgeEpoch,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $ActivityDaysTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<String>(
        $ActivityDaysTable.$converterclientUpdatedAt.toSql(
          clientUpdatedAt.value,
        ),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $ActivityDaysTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientRev.present) {
      map['client_rev'] = Variable<int>(clientRev.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (purgeEpoch.present) {
      map['purge_epoch'] = Variable<int>(purgeEpoch.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityDaysCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientRev: $clientRev, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('purgeEpoch: $purgeEpoch, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionStatesTable extends SubscriptionStates
    with TableInfo<$SubscriptionStatesTable, SubscriptionStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entitledMeta = const VerificationMeta(
    'entitled',
  );
  @override
  late final GeneratedColumn<bool> entitled = GeneratedColumn<bool>(
    'entitled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("entitled" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> expiresAt =
      GeneratedColumn<String>(
        'expires_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SubscriptionStatesTable.$converterexpiresAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String>
  graceExpiresAt = GeneratedColumn<String>(
    'grace_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($SubscriptionStatesTable.$convertergraceExpiresAt);
  static const VerificationMeta _periodTypeMeta = const VerificationMeta(
    'periodType',
  );
  @override
  late final GeneratedColumn<String> periodType = GeneratedColumn<String>(
    'period_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _willRenewMeta = const VerificationMeta(
    'willRenew',
  );
  @override
  late final GeneratedColumn<bool> willRenew = GeneratedColumn<bool>(
    'will_renew',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("will_renew" IN (0, 1))',
    ),
  );
  static const VerificationMeta _trialUsedMeta = const VerificationMeta(
    'trialUsed',
  );
  @override
  late final GeneratedColumn<bool> trialUsed = GeneratedColumn<bool>(
    'trial_used',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("trial_used" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SubscriptionSource, String>
  source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SubscriptionSource>(
        $SubscriptionStatesTable.$convertersource,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> lastCheckedAt =
      GeneratedColumn<String>(
        'last_checked_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $SubscriptionStatesTable.$converterlastCheckedAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    status,
    entitled,
    expiresAt,
    graceExpiresAt,
    periodType,
    willRenew,
    trialUsed,
    source,
    lastCheckedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscription_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('entitled')) {
      context.handle(
        _entitledMeta,
        entitled.isAcceptableOrUnknown(data['entitled']!, _entitledMeta),
      );
    } else if (isInserting) {
      context.missing(_entitledMeta);
    }
    if (data.containsKey('period_type')) {
      context.handle(
        _periodTypeMeta,
        periodType.isAcceptableOrUnknown(data['period_type']!, _periodTypeMeta),
      );
    }
    if (data.containsKey('will_renew')) {
      context.handle(
        _willRenewMeta,
        willRenew.isAcceptableOrUnknown(data['will_renew']!, _willRenewMeta),
      );
    } else if (isInserting) {
      context.missing(_willRenewMeta);
    }
    if (data.containsKey('trial_used')) {
      context.handle(
        _trialUsedMeta,
        trialUsed.isAcceptableOrUnknown(data['trial_used']!, _trialUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_trialUsedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  SubscriptionStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionStateRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      entitled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}entitled'],
      )!,
      expiresAt: $SubscriptionStatesTable.$converterexpiresAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}expires_at'],
        ),
      ),
      graceExpiresAt: $SubscriptionStatesTable.$convertergraceExpiresAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}grace_expires_at'],
        ),
      ),
      periodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_type'],
      ),
      willRenew: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}will_renew'],
      )!,
      trialUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}trial_used'],
      )!,
      source: $SubscriptionStatesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      lastCheckedAt: $SubscriptionStatesTable.$converterlastCheckedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_checked_at'],
        )!,
      ),
    );
  }

  @override
  $SubscriptionStatesTable createAlias(String alias) {
    return $SubscriptionStatesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime?, String?, String?> $converterexpiresAt =
      const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?>
  $convertergraceExpiresAt = const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<SubscriptionSource, String, String>
  $convertersource = const WireEnumConverter(SubscriptionSource.values);
  static JsonTypeConverter2<DateTime, String, String> $converterlastCheckedAt =
      const UtcDateTimeConverter();
}

class SubscriptionStateRow extends DataClass
    implements Insertable<SubscriptionStateRow> {
  final String userId;
  final String status;
  final bool entitled;
  final DateTime? expiresAt;
  final DateTime? graceExpiresAt;
  final String? periodType;
  final bool willRenew;
  final bool trialUsed;
  final SubscriptionSource source;
  final DateTime lastCheckedAt;
  const SubscriptionStateRow({
    required this.userId,
    required this.status,
    required this.entitled,
    this.expiresAt,
    this.graceExpiresAt,
    this.periodType,
    required this.willRenew,
    required this.trialUsed,
    required this.source,
    required this.lastCheckedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['status'] = Variable<String>(status);
    map['entitled'] = Variable<bool>(entitled);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<String>(
        $SubscriptionStatesTable.$converterexpiresAt.toSql(expiresAt),
      );
    }
    if (!nullToAbsent || graceExpiresAt != null) {
      map['grace_expires_at'] = Variable<String>(
        $SubscriptionStatesTable.$convertergraceExpiresAt.toSql(graceExpiresAt),
      );
    }
    if (!nullToAbsent || periodType != null) {
      map['period_type'] = Variable<String>(periodType);
    }
    map['will_renew'] = Variable<bool>(willRenew);
    map['trial_used'] = Variable<bool>(trialUsed);
    {
      map['source'] = Variable<String>(
        $SubscriptionStatesTable.$convertersource.toSql(source),
      );
    }
    {
      map['last_checked_at'] = Variable<String>(
        $SubscriptionStatesTable.$converterlastCheckedAt.toSql(lastCheckedAt),
      );
    }
    return map;
  }

  SubscriptionStatesCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionStatesCompanion(
      userId: Value(userId),
      status: Value(status),
      entitled: Value(entitled),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      graceExpiresAt: graceExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(graceExpiresAt),
      periodType: periodType == null && nullToAbsent
          ? const Value.absent()
          : Value(periodType),
      willRenew: Value(willRenew),
      trialUsed: Value(trialUsed),
      source: Value(source),
      lastCheckedAt: Value(lastCheckedAt),
    );
  }

  factory SubscriptionStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionStateRow(
      userId: serializer.fromJson<String>(json['user_id']),
      status: serializer.fromJson<String>(json['status']),
      entitled: serializer.fromJson<bool>(json['entitled']),
      expiresAt: $SubscriptionStatesTable.$converterexpiresAt.fromJson(
        serializer.fromJson<String?>(json['expires_at']),
      ),
      graceExpiresAt: $SubscriptionStatesTable.$convertergraceExpiresAt
          .fromJson(serializer.fromJson<String?>(json['grace_expires_at'])),
      periodType: serializer.fromJson<String?>(json['period_type']),
      willRenew: serializer.fromJson<bool>(json['will_renew']),
      trialUsed: serializer.fromJson<bool>(json['trial_used']),
      source: $SubscriptionStatesTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      lastCheckedAt: $SubscriptionStatesTable.$converterlastCheckedAt.fromJson(
        serializer.fromJson<String>(json['last_checked_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'user_id': serializer.toJson<String>(userId),
      'status': serializer.toJson<String>(status),
      'entitled': serializer.toJson<bool>(entitled),
      'expires_at': serializer.toJson<String?>(
        $SubscriptionStatesTable.$converterexpiresAt.toJson(expiresAt),
      ),
      'grace_expires_at': serializer.toJson<String?>(
        $SubscriptionStatesTable.$convertergraceExpiresAt.toJson(
          graceExpiresAt,
        ),
      ),
      'period_type': serializer.toJson<String?>(periodType),
      'will_renew': serializer.toJson<bool>(willRenew),
      'trial_used': serializer.toJson<bool>(trialUsed),
      'source': serializer.toJson<String>(
        $SubscriptionStatesTable.$convertersource.toJson(source),
      ),
      'last_checked_at': serializer.toJson<String>(
        $SubscriptionStatesTable.$converterlastCheckedAt.toJson(lastCheckedAt),
      ),
    };
  }

  SubscriptionStateRow copyWith({
    String? userId,
    String? status,
    bool? entitled,
    Value<DateTime?> expiresAt = const Value.absent(),
    Value<DateTime?> graceExpiresAt = const Value.absent(),
    Value<String?> periodType = const Value.absent(),
    bool? willRenew,
    bool? trialUsed,
    SubscriptionSource? source,
    DateTime? lastCheckedAt,
  }) => SubscriptionStateRow(
    userId: userId ?? this.userId,
    status: status ?? this.status,
    entitled: entitled ?? this.entitled,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    graceExpiresAt: graceExpiresAt.present
        ? graceExpiresAt.value
        : this.graceExpiresAt,
    periodType: periodType.present ? periodType.value : this.periodType,
    willRenew: willRenew ?? this.willRenew,
    trialUsed: trialUsed ?? this.trialUsed,
    source: source ?? this.source,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
  );
  SubscriptionStateRow copyWithCompanion(SubscriptionStatesCompanion data) {
    return SubscriptionStateRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      status: data.status.present ? data.status.value : this.status,
      entitled: data.entitled.present ? data.entitled.value : this.entitled,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      graceExpiresAt: data.graceExpiresAt.present
          ? data.graceExpiresAt.value
          : this.graceExpiresAt,
      periodType: data.periodType.present
          ? data.periodType.value
          : this.periodType,
      willRenew: data.willRenew.present ? data.willRenew.value : this.willRenew,
      trialUsed: data.trialUsed.present ? data.trialUsed.value : this.trialUsed,
      source: data.source.present ? data.source.value : this.source,
      lastCheckedAt: data.lastCheckedAt.present
          ? data.lastCheckedAt.value
          : this.lastCheckedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionStateRow(')
          ..write('userId: $userId, ')
          ..write('status: $status, ')
          ..write('entitled: $entitled, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('graceExpiresAt: $graceExpiresAt, ')
          ..write('periodType: $periodType, ')
          ..write('willRenew: $willRenew, ')
          ..write('trialUsed: $trialUsed, ')
          ..write('source: $source, ')
          ..write('lastCheckedAt: $lastCheckedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    status,
    entitled,
    expiresAt,
    graceExpiresAt,
    periodType,
    willRenew,
    trialUsed,
    source,
    lastCheckedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionStateRow &&
          other.userId == this.userId &&
          other.status == this.status &&
          other.entitled == this.entitled &&
          other.expiresAt == this.expiresAt &&
          other.graceExpiresAt == this.graceExpiresAt &&
          other.periodType == this.periodType &&
          other.willRenew == this.willRenew &&
          other.trialUsed == this.trialUsed &&
          other.source == this.source &&
          other.lastCheckedAt == this.lastCheckedAt);
}

class SubscriptionStatesCompanion
    extends UpdateCompanion<SubscriptionStateRow> {
  final Value<String> userId;
  final Value<String> status;
  final Value<bool> entitled;
  final Value<DateTime?> expiresAt;
  final Value<DateTime?> graceExpiresAt;
  final Value<String?> periodType;
  final Value<bool> willRenew;
  final Value<bool> trialUsed;
  final Value<SubscriptionSource> source;
  final Value<DateTime> lastCheckedAt;
  final Value<int> rowid;
  const SubscriptionStatesCompanion({
    this.userId = const Value.absent(),
    this.status = const Value.absent(),
    this.entitled = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.graceExpiresAt = const Value.absent(),
    this.periodType = const Value.absent(),
    this.willRenew = const Value.absent(),
    this.trialUsed = const Value.absent(),
    this.source = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionStatesCompanion.insert({
    required String userId,
    required String status,
    required bool entitled,
    this.expiresAt = const Value.absent(),
    this.graceExpiresAt = const Value.absent(),
    this.periodType = const Value.absent(),
    required bool willRenew,
    required bool trialUsed,
    required SubscriptionSource source,
    required DateTime lastCheckedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       status = Value(status),
       entitled = Value(entitled),
       willRenew = Value(willRenew),
       trialUsed = Value(trialUsed),
       source = Value(source),
       lastCheckedAt = Value(lastCheckedAt);
  static Insertable<SubscriptionStateRow> custom({
    Expression<String>? userId,
    Expression<String>? status,
    Expression<bool>? entitled,
    Expression<String>? expiresAt,
    Expression<String>? graceExpiresAt,
    Expression<String>? periodType,
    Expression<bool>? willRenew,
    Expression<bool>? trialUsed,
    Expression<String>? source,
    Expression<String>? lastCheckedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (status != null) 'status': status,
      if (entitled != null) 'entitled': entitled,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (graceExpiresAt != null) 'grace_expires_at': graceExpiresAt,
      if (periodType != null) 'period_type': periodType,
      if (willRenew != null) 'will_renew': willRenew,
      if (trialUsed != null) 'trial_used': trialUsed,
      if (source != null) 'source': source,
      if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionStatesCompanion copyWith({
    Value<String>? userId,
    Value<String>? status,
    Value<bool>? entitled,
    Value<DateTime?>? expiresAt,
    Value<DateTime?>? graceExpiresAt,
    Value<String?>? periodType,
    Value<bool>? willRenew,
    Value<bool>? trialUsed,
    Value<SubscriptionSource>? source,
    Value<DateTime>? lastCheckedAt,
    Value<int>? rowid,
  }) {
    return SubscriptionStatesCompanion(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      entitled: entitled ?? this.entitled,
      expiresAt: expiresAt ?? this.expiresAt,
      graceExpiresAt: graceExpiresAt ?? this.graceExpiresAt,
      periodType: periodType ?? this.periodType,
      willRenew: willRenew ?? this.willRenew,
      trialUsed: trialUsed ?? this.trialUsed,
      source: source ?? this.source,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (entitled.present) {
      map['entitled'] = Variable<bool>(entitled.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<String>(
        $SubscriptionStatesTable.$converterexpiresAt.toSql(expiresAt.value),
      );
    }
    if (graceExpiresAt.present) {
      map['grace_expires_at'] = Variable<String>(
        $SubscriptionStatesTable.$convertergraceExpiresAt.toSql(
          graceExpiresAt.value,
        ),
      );
    }
    if (periodType.present) {
      map['period_type'] = Variable<String>(periodType.value);
    }
    if (willRenew.present) {
      map['will_renew'] = Variable<bool>(willRenew.value);
    }
    if (trialUsed.present) {
      map['trial_used'] = Variable<bool>(trialUsed.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $SubscriptionStatesTable.$convertersource.toSql(source.value),
      );
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<String>(
        $SubscriptionStatesTable.$converterlastCheckedAt.toSql(
          lastCheckedAt.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionStatesCompanion(')
          ..write('userId: $userId, ')
          ..write('status: $status, ')
          ..write('entitled: $entitled, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('graceExpiresAt: $graceExpiresAt, ')
          ..write('periodType: $periodType, ')
          ..write('willRenew: $willRenew, ')
          ..write('trialUsed: $trialUsed, ')
          ..write('source: $source, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingQuotasTable extends ReadingQuotas
    with TableInfo<$ReadingQuotasTable, ReadingQuotaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingQuotasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedMeta = const VerificationMeta('used');
  @override
  late final GeneratedColumn<int> used = GeneratedColumn<int>(
    'used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reservedMeta = const VerificationMeta(
    'reserved',
  );
  @override
  late final GeneratedColumn<int> reserved = GeneratedColumn<int>(
    'reserved',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quotaLimitMeta = const VerificationMeta(
    'quotaLimit',
  );
  @override
  late final GeneratedColumn<int> quotaLimit = GeneratedColumn<int>(
    'quota_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    month,
    used,
    reserved,
    quotaLimit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_quota';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingQuotaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('used')) {
      context.handle(
        _usedMeta,
        used.isAcceptableOrUnknown(data['used']!, _usedMeta),
      );
    } else if (isInserting) {
      context.missing(_usedMeta);
    }
    if (data.containsKey('reserved')) {
      context.handle(
        _reservedMeta,
        reserved.isAcceptableOrUnknown(data['reserved']!, _reservedMeta),
      );
    } else if (isInserting) {
      context.missing(_reservedMeta);
    }
    if (data.containsKey('quota_limit')) {
      context.handle(
        _quotaLimitMeta,
        quotaLimit.isAcceptableOrUnknown(data['quota_limit']!, _quotaLimitMeta),
      );
    } else if (isInserting) {
      context.missing(_quotaLimitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, month};
  @override
  ReadingQuotaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingQuotaRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      used: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used'],
      )!,
      reserved: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reserved'],
      )!,
      quotaLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quota_limit'],
      )!,
    );
  }

  @override
  $ReadingQuotasTable createAlias(String alias) {
    return $ReadingQuotasTable(attachedDatabase, alias);
  }
}

class ReadingQuotaRow extends DataClass implements Insertable<ReadingQuotaRow> {
  final String userId;

  /// `yyyy-MM` (KST month, fixed by the server).
  final String month;
  final int used;
  final int reserved;

  /// Server JSON key `limit` (SQL reserved word — [S02] decision).
  final int quotaLimit;
  const ReadingQuotaRow({
    required this.userId,
    required this.month,
    required this.used,
    required this.reserved,
    required this.quotaLimit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['month'] = Variable<String>(month);
    map['used'] = Variable<int>(used);
    map['reserved'] = Variable<int>(reserved);
    map['quota_limit'] = Variable<int>(quotaLimit);
    return map;
  }

  ReadingQuotasCompanion toCompanion(bool nullToAbsent) {
    return ReadingQuotasCompanion(
      userId: Value(userId),
      month: Value(month),
      used: Value(used),
      reserved: Value(reserved),
      quotaLimit: Value(quotaLimit),
    );
  }

  factory ReadingQuotaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingQuotaRow(
      userId: serializer.fromJson<String>(json['user_id']),
      month: serializer.fromJson<String>(json['month']),
      used: serializer.fromJson<int>(json['used']),
      reserved: serializer.fromJson<int>(json['reserved']),
      quotaLimit: serializer.fromJson<int>(json['quota_limit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'user_id': serializer.toJson<String>(userId),
      'month': serializer.toJson<String>(month),
      'used': serializer.toJson<int>(used),
      'reserved': serializer.toJson<int>(reserved),
      'quota_limit': serializer.toJson<int>(quotaLimit),
    };
  }

  ReadingQuotaRow copyWith({
    String? userId,
    String? month,
    int? used,
    int? reserved,
    int? quotaLimit,
  }) => ReadingQuotaRow(
    userId: userId ?? this.userId,
    month: month ?? this.month,
    used: used ?? this.used,
    reserved: reserved ?? this.reserved,
    quotaLimit: quotaLimit ?? this.quotaLimit,
  );
  ReadingQuotaRow copyWithCompanion(ReadingQuotasCompanion data) {
    return ReadingQuotaRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      month: data.month.present ? data.month.value : this.month,
      used: data.used.present ? data.used.value : this.used,
      reserved: data.reserved.present ? data.reserved.value : this.reserved,
      quotaLimit: data.quotaLimit.present
          ? data.quotaLimit.value
          : this.quotaLimit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingQuotaRow(')
          ..write('userId: $userId, ')
          ..write('month: $month, ')
          ..write('used: $used, ')
          ..write('reserved: $reserved, ')
          ..write('quotaLimit: $quotaLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, month, used, reserved, quotaLimit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingQuotaRow &&
          other.userId == this.userId &&
          other.month == this.month &&
          other.used == this.used &&
          other.reserved == this.reserved &&
          other.quotaLimit == this.quotaLimit);
}

class ReadingQuotasCompanion extends UpdateCompanion<ReadingQuotaRow> {
  final Value<String> userId;
  final Value<String> month;
  final Value<int> used;
  final Value<int> reserved;
  final Value<int> quotaLimit;
  final Value<int> rowid;
  const ReadingQuotasCompanion({
    this.userId = const Value.absent(),
    this.month = const Value.absent(),
    this.used = const Value.absent(),
    this.reserved = const Value.absent(),
    this.quotaLimit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingQuotasCompanion.insert({
    required String userId,
    required String month,
    required int used,
    required int reserved,
    required int quotaLimit,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       month = Value(month),
       used = Value(used),
       reserved = Value(reserved),
       quotaLimit = Value(quotaLimit);
  static Insertable<ReadingQuotaRow> custom({
    Expression<String>? userId,
    Expression<String>? month,
    Expression<int>? used,
    Expression<int>? reserved,
    Expression<int>? quotaLimit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (month != null) 'month': month,
      if (used != null) 'used': used,
      if (reserved != null) 'reserved': reserved,
      if (quotaLimit != null) 'quota_limit': quotaLimit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingQuotasCompanion copyWith({
    Value<String>? userId,
    Value<String>? month,
    Value<int>? used,
    Value<int>? reserved,
    Value<int>? quotaLimit,
    Value<int>? rowid,
  }) {
    return ReadingQuotasCompanion(
      userId: userId ?? this.userId,
      month: month ?? this.month,
      used: used ?? this.used,
      reserved: reserved ?? this.reserved,
      quotaLimit: quotaLimit ?? this.quotaLimit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (used.present) {
      map['used'] = Variable<int>(used.value);
    }
    if (reserved.present) {
      map['reserved'] = Variable<int>(reserved.value);
    }
    if (quotaLimit.present) {
      map['quota_limit'] = Variable<int>(quotaLimit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingQuotasCompanion(')
          ..write('userId: $userId, ')
          ..write('month: $month, ')
          ..write('used: $used, ')
          ..write('reserved: $reserved, ')
          ..write('quotaLimit: $quotaLimit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, PhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> takenAt =
      GeneratedColumn<String>(
        'taken_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PhotosTable.$convertertakenAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> expiresAt =
      GeneratedColumn<String>(
        'expires_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PhotosTable.$converterexpiresAt);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PhotosTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> deletedAt =
      GeneratedColumn<String>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($PhotosTable.$converterdeletedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    requestId,
    localPath,
    takenAt,
    expiresAt,
    width,
    height,
    pageIndex,
    createdAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      takenAt: $PhotosTable.$convertertakenAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}taken_at'],
        )!,
      ),
      expiresAt: $PhotosTable.$converterexpiresAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}expires_at'],
        )!,
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      )!,
      createdAt: $PhotosTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      deletedAt: $PhotosTable.$converterdeletedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $convertertakenAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String> $converterexpiresAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String> $convertercreatedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?> $converterdeletedAt =
      const NullableUtcDateTimeConverter();
}

class PhotoRow extends DataClass implements Insertable<PhotoRow> {
  final String id;
  final String userId;
  final String? requestId;

  /// Relative to `ApplicationSupport/photos/`. Never logged.
  final String localPath;
  final DateTime takenAt;
  final DateTime expiresAt;
  final int width;
  final int height;
  final int pageIndex;
  final DateTime createdAt;

  /// Set after the file was deleted ("삭제됨" marker).
  final DateTime? deletedAt;
  const PhotoRow({
    required this.id,
    required this.userId,
    this.requestId,
    required this.localPath,
    required this.takenAt,
    required this.expiresAt,
    required this.width,
    required this.height,
    required this.pageIndex,
    required this.createdAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || requestId != null) {
      map['request_id'] = Variable<String>(requestId);
    }
    map['local_path'] = Variable<String>(localPath);
    {
      map['taken_at'] = Variable<String>(
        $PhotosTable.$convertertakenAt.toSql(takenAt),
      );
    }
    {
      map['expires_at'] = Variable<String>(
        $PhotosTable.$converterexpiresAt.toSql(expiresAt),
      );
    }
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['page_index'] = Variable<int>(pageIndex);
    {
      map['created_at'] = Variable<String>(
        $PhotosTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(
        $PhotosTable.$converterdeletedAt.toSql(deletedAt),
      );
    }
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      userId: Value(userId),
      requestId: requestId == null && nullToAbsent
          ? const Value.absent()
          : Value(requestId),
      localPath: Value(localPath),
      takenAt: Value(takenAt),
      expiresAt: Value(expiresAt),
      width: Value(width),
      height: Value(height),
      pageIndex: Value(pageIndex),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      requestId: serializer.fromJson<String?>(json['request_id']),
      localPath: serializer.fromJson<String>(json['local_path']),
      takenAt: $PhotosTable.$convertertakenAt.fromJson(
        serializer.fromJson<String>(json['taken_at']),
      ),
      expiresAt: $PhotosTable.$converterexpiresAt.fromJson(
        serializer.fromJson<String>(json['expires_at']),
      ),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      pageIndex: serializer.fromJson<int>(json['page_index']),
      createdAt: $PhotosTable.$convertercreatedAt.fromJson(
        serializer.fromJson<String>(json['created_at']),
      ),
      deletedAt: $PhotosTable.$converterdeletedAt.fromJson(
        serializer.fromJson<String?>(json['deleted_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'request_id': serializer.toJson<String?>(requestId),
      'local_path': serializer.toJson<String>(localPath),
      'taken_at': serializer.toJson<String>(
        $PhotosTable.$convertertakenAt.toJson(takenAt),
      ),
      'expires_at': serializer.toJson<String>(
        $PhotosTable.$converterexpiresAt.toJson(expiresAt),
      ),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'page_index': serializer.toJson<int>(pageIndex),
      'created_at': serializer.toJson<String>(
        $PhotosTable.$convertercreatedAt.toJson(createdAt),
      ),
      'deleted_at': serializer.toJson<String?>(
        $PhotosTable.$converterdeletedAt.toJson(deletedAt),
      ),
    };
  }

  PhotoRow copyWith({
    String? id,
    String? userId,
    Value<String?> requestId = const Value.absent(),
    String? localPath,
    DateTime? takenAt,
    DateTime? expiresAt,
    int? width,
    int? height,
    int? pageIndex,
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => PhotoRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    requestId: requestId.present ? requestId.value : this.requestId,
    localPath: localPath ?? this.localPath,
    takenAt: takenAt ?? this.takenAt,
    expiresAt: expiresAt ?? this.expiresAt,
    width: width ?? this.width,
    height: height ?? this.height,
    pageIndex: pageIndex ?? this.pageIndex,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  PhotoRow copyWithCompanion(PhotosCompanion data) {
    return PhotoRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('requestId: $requestId, ')
          ..write('localPath: $localPath, ')
          ..write('takenAt: $takenAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    requestId,
    localPath,
    takenAt,
    expiresAt,
    width,
    height,
    pageIndex,
    createdAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.requestId == this.requestId &&
          other.localPath == this.localPath &&
          other.takenAt == this.takenAt &&
          other.expiresAt == this.expiresAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.pageIndex == this.pageIndex &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class PhotosCompanion extends UpdateCompanion<PhotoRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> requestId;
  final Value<String> localPath;
  final Value<DateTime> takenAt;
  final Value<DateTime> expiresAt;
  final Value<int> width;
  final Value<int> height;
  final Value<int> pageIndex;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.requestId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotosCompanion.insert({
    required String id,
    required String userId,
    this.requestId = const Value.absent(),
    required String localPath,
    required DateTime takenAt,
    required DateTime expiresAt,
    required int width,
    required int height,
    required int pageIndex,
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       localPath = Value(localPath),
       takenAt = Value(takenAt),
       expiresAt = Value(expiresAt),
       width = Value(width),
       height = Value(height),
       pageIndex = Value(pageIndex),
       createdAt = Value(createdAt);
  static Insertable<PhotoRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? requestId,
    Expression<String>? localPath,
    Expression<String>? takenAt,
    Expression<String>? expiresAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? pageIndex,
    Expression<String>? createdAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (requestId != null) 'request_id': requestId,
      if (localPath != null) 'local_path': localPath,
      if (takenAt != null) 'taken_at': takenAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (pageIndex != null) 'page_index': pageIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? requestId,
    Value<String>? localPath,
    Value<DateTime>? takenAt,
    Value<DateTime>? expiresAt,
    Value<int>? width,
    Value<int>? height,
    Value<int>? pageIndex,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      requestId: requestId ?? this.requestId,
      localPath: localPath ?? this.localPath,
      takenAt: takenAt ?? this.takenAt,
      expiresAt: expiresAt ?? this.expiresAt,
      width: width ?? this.width,
      height: height ?? this.height,
      pageIndex: pageIndex ?? this.pageIndex,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<String>(
        $PhotosTable.$convertertakenAt.toSql(takenAt.value),
      );
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<String>(
        $PhotosTable.$converterexpiresAt.toSql(expiresAt.value),
      );
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $PhotosTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(
        $PhotosTable.$converterdeletedAt.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('requestId: $requestId, ')
          ..write('localPath: $localPath, ')
          ..write('takenAt: $takenAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tableMeta = const VerificationMeta('table');
  @override
  late final GeneratedColumn<String> table = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentClientRevMeta = const VerificationMeta(
    'sentClientRev',
  );
  @override
  late final GeneratedColumn<int> sentClientRev = GeneratedColumn<int>(
    'sent_client_rev',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> queuedAt =
      GeneratedColumn<String>(
        'queued_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SyncOutboxTable.$converterqueuedAt);
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    table,
    rowId,
    mutationId,
    sentClientRev,
    queuedAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('table_name')) {
      context.handle(
        _tableMeta,
        table.isAcceptableOrUnknown(data['table_name']!, _tableMeta),
      );
    } else if (isInserting) {
      context.missing(_tableMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('sent_client_rev')) {
      context.handle(
        _sentClientRevMeta,
        sentClientRev.isAcceptableOrUnknown(
          data['sent_client_rev']!,
          _sentClientRevMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {table, rowId};
  @override
  SyncOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxRow(
      table: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      sentClientRev: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_client_rev'],
      ),
      queuedAt: $SyncOutboxTable.$converterqueuedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}queued_at'],
        )!,
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, String, String> $converterqueuedAt =
      const UtcDateTimeConverter();
}

class SyncOutboxRow extends DataClass implements Insertable<SyncOutboxRow> {
  /// SQL column `table_name` (`tableName` is taken by the drift DSL).
  final String table;
  final String rowId;
  final String mutationId;
  final int? sentClientRev;
  final DateTime queuedAt;
  final int attempts;
  final String? lastError;
  const SyncOutboxRow({
    required this.table,
    required this.rowId,
    required this.mutationId,
    this.sentClientRev,
    required this.queuedAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['table_name'] = Variable<String>(table);
    map['row_id'] = Variable<String>(rowId);
    map['mutation_id'] = Variable<String>(mutationId);
    if (!nullToAbsent || sentClientRev != null) {
      map['sent_client_rev'] = Variable<int>(sentClientRev);
    }
    {
      map['queued_at'] = Variable<String>(
        $SyncOutboxTable.$converterqueuedAt.toSql(queuedAt),
      );
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      table: Value(table),
      rowId: Value(rowId),
      mutationId: Value(mutationId),
      sentClientRev: sentClientRev == null && nullToAbsent
          ? const Value.absent()
          : Value(sentClientRev),
      queuedAt: Value(queuedAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxRow(
      table: serializer.fromJson<String>(json['table_name']),
      rowId: serializer.fromJson<String>(json['row_id']),
      mutationId: serializer.fromJson<String>(json['mutation_id']),
      sentClientRev: serializer.fromJson<int?>(json['sent_client_rev']),
      queuedAt: $SyncOutboxTable.$converterqueuedAt.fromJson(
        serializer.fromJson<String>(json['queued_at']),
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['last_error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'table_name': serializer.toJson<String>(table),
      'row_id': serializer.toJson<String>(rowId),
      'mutation_id': serializer.toJson<String>(mutationId),
      'sent_client_rev': serializer.toJson<int?>(sentClientRev),
      'queued_at': serializer.toJson<String>(
        $SyncOutboxTable.$converterqueuedAt.toJson(queuedAt),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'last_error': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxRow copyWith({
    String? table,
    String? rowId,
    String? mutationId,
    Value<int?> sentClientRev = const Value.absent(),
    DateTime? queuedAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => SyncOutboxRow(
    table: table ?? this.table,
    rowId: rowId ?? this.rowId,
    mutationId: mutationId ?? this.mutationId,
    sentClientRev: sentClientRev.present
        ? sentClientRev.value
        : this.sentClientRev,
    queuedAt: queuedAt ?? this.queuedAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOutboxRow copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxRow(
      table: data.table.present ? data.table.value : this.table,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      sentClientRev: data.sentClientRev.present
          ? data.sentClientRev.value
          : this.sentClientRev,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRow(')
          ..write('table: $table, ')
          ..write('rowId: $rowId, ')
          ..write('mutationId: $mutationId, ')
          ..write('sentClientRev: $sentClientRev, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    table,
    rowId,
    mutationId,
    sentClientRev,
    queuedAt,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxRow &&
          other.table == this.table &&
          other.rowId == this.rowId &&
          other.mutationId == this.mutationId &&
          other.sentClientRev == this.sentClientRev &&
          other.queuedAt == this.queuedAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxRow> {
  final Value<String> table;
  final Value<String> rowId;
  final Value<String> mutationId;
  final Value<int?> sentClientRev;
  final Value<DateTime> queuedAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncOutboxCompanion({
    this.table = const Value.absent(),
    this.rowId = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.sentClientRev = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    required String table,
    required String rowId,
    required String mutationId,
    this.sentClientRev = const Value.absent(),
    required DateTime queuedAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : table = Value(table),
       rowId = Value(rowId),
       mutationId = Value(mutationId),
       queuedAt = Value(queuedAt);
  static Insertable<SyncOutboxRow> custom({
    Expression<String>? table,
    Expression<String>? rowId,
    Expression<String>? mutationId,
    Expression<int>? sentClientRev,
    Expression<String>? queuedAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (table != null) 'table_name': table,
      if (rowId != null) 'row_id': rowId,
      if (mutationId != null) 'mutation_id': mutationId,
      if (sentClientRev != null) 'sent_client_rev': sentClientRev,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<String>? table,
    Value<String>? rowId,
    Value<String>? mutationId,
    Value<int?>? sentClientRev,
    Value<DateTime>? queuedAt,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncOutboxCompanion(
      table: table ?? this.table,
      rowId: rowId ?? this.rowId,
      mutationId: mutationId ?? this.mutationId,
      sentClientRev: sentClientRev ?? this.sentClientRev,
      queuedAt: queuedAt ?? this.queuedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (table.present) {
      map['table_name'] = Variable<String>(table.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (sentClientRev.present) {
      map['sent_client_rev'] = Variable<int>(sentClientRev.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<String>(
        $SyncOutboxTable.$converterqueuedAt.toSql(queuedAt.value),
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('table: $table, ')
          ..write('rowId: $rowId, ')
          ..write('mutationId: $mutationId, ')
          ..write('sentClientRev: $sentClientRev, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaRow extends DataClass implements Insertable<SyncMetaRow> {
  final String key;
  final String value;
  const SyncMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetaRow copyWith({String? key, String? value}) =>
      SyncMetaRow(key: key ?? this.key, value: value ?? this.value);
  SyncMetaRow copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictsTable extends SyncConflicts
    with TableInfo<$SyncConflictsTable, SyncConflictRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tableMeta = const VerificationMeta('table');
  @override
  late final GeneratedColumn<String> table = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localJsonMeta = const VerificationMeta(
    'localJson',
  );
  @override
  late final GeneratedColumn<String> localJson = GeneratedColumn<String>(
    'local_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverJsonMeta = const VerificationMeta(
    'serverJson',
  );
  @override
  late final GeneratedColumn<String> serverJson = GeneratedColumn<String>(
    'server_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ConflictResolution, String>
  resolvedAs = GeneratedColumn<String>(
    'resolved_as',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ConflictResolution>($SyncConflictsTable.$converterresolvedAs);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> at =
      GeneratedColumn<String>(
        'at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SyncConflictsTable.$converterat);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    table,
    rowId,
    localJson,
    serverJson,
    resolvedAs,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncConflictRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _tableMeta,
        table.isAcceptableOrUnknown(data['table_name']!, _tableMeta),
      );
    } else if (isInserting) {
      context.missing(_tableMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('local_json')) {
      context.handle(
        _localJsonMeta,
        localJson.isAcceptableOrUnknown(data['local_json']!, _localJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_localJsonMeta);
    }
    if (data.containsKey('server_json')) {
      context.handle(
        _serverJsonMeta,
        serverJson.isAcceptableOrUnknown(data['server_json']!, _serverJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_serverJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflictRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflictRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      table: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      localJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_json'],
      )!,
      serverJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_json'],
      )!,
      resolvedAs: $SyncConflictsTable.$converterresolvedAs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}resolved_as'],
        )!,
      ),
      at: $SyncConflictsTable.$converterat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}at'],
        )!,
      ),
    );
  }

  @override
  $SyncConflictsTable createAlias(String alias) {
    return $SyncConflictsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ConflictResolution, String, String>
  $converterresolvedAs = const WireEnumConverter(ConflictResolution.values);
  static JsonTypeConverter2<DateTime, String, String> $converterat =
      const UtcDateTimeConverter();
}

class SyncConflictRow extends DataClass implements Insertable<SyncConflictRow> {
  final int id;
  final String table;
  final String rowId;
  final String localJson;
  final String serverJson;
  final ConflictResolution resolvedAs;
  final DateTime at;
  const SyncConflictRow({
    required this.id,
    required this.table,
    required this.rowId,
    required this.localJson,
    required this.serverJson,
    required this.resolvedAs,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['table_name'] = Variable<String>(table);
    map['row_id'] = Variable<String>(rowId);
    map['local_json'] = Variable<String>(localJson);
    map['server_json'] = Variable<String>(serverJson);
    {
      map['resolved_as'] = Variable<String>(
        $SyncConflictsTable.$converterresolvedAs.toSql(resolvedAs),
      );
    }
    {
      map['at'] = Variable<String>($SyncConflictsTable.$converterat.toSql(at));
    }
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      id: Value(id),
      table: Value(table),
      rowId: Value(rowId),
      localJson: Value(localJson),
      serverJson: Value(serverJson),
      resolvedAs: Value(resolvedAs),
      at: Value(at),
    );
  }

  factory SyncConflictRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflictRow(
      id: serializer.fromJson<int>(json['id']),
      table: serializer.fromJson<String>(json['table_name']),
      rowId: serializer.fromJson<String>(json['row_id']),
      localJson: serializer.fromJson<String>(json['local_json']),
      serverJson: serializer.fromJson<String>(json['server_json']),
      resolvedAs: $SyncConflictsTable.$converterresolvedAs.fromJson(
        serializer.fromJson<String>(json['resolved_as']),
      ),
      at: $SyncConflictsTable.$converterat.fromJson(
        serializer.fromJson<String>(json['at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'table_name': serializer.toJson<String>(table),
      'row_id': serializer.toJson<String>(rowId),
      'local_json': serializer.toJson<String>(localJson),
      'server_json': serializer.toJson<String>(serverJson),
      'resolved_as': serializer.toJson<String>(
        $SyncConflictsTable.$converterresolvedAs.toJson(resolvedAs),
      ),
      'at': serializer.toJson<String>(
        $SyncConflictsTable.$converterat.toJson(at),
      ),
    };
  }

  SyncConflictRow copyWith({
    int? id,
    String? table,
    String? rowId,
    String? localJson,
    String? serverJson,
    ConflictResolution? resolvedAs,
    DateTime? at,
  }) => SyncConflictRow(
    id: id ?? this.id,
    table: table ?? this.table,
    rowId: rowId ?? this.rowId,
    localJson: localJson ?? this.localJson,
    serverJson: serverJson ?? this.serverJson,
    resolvedAs: resolvedAs ?? this.resolvedAs,
    at: at ?? this.at,
  );
  SyncConflictRow copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflictRow(
      id: data.id.present ? data.id.value : this.id,
      table: data.table.present ? data.table.value : this.table,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      localJson: data.localJson.present ? data.localJson.value : this.localJson,
      serverJson: data.serverJson.present
          ? data.serverJson.value
          : this.serverJson,
      resolvedAs: data.resolvedAs.present
          ? data.resolvedAs.value
          : this.resolvedAs,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictRow(')
          ..write('id: $id, ')
          ..write('table: $table, ')
          ..write('rowId: $rowId, ')
          ..write('localJson: $localJson, ')
          ..write('serverJson: $serverJson, ')
          ..write('resolvedAs: $resolvedAs, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, table, rowId, localJson, serverJson, resolvedAs, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflictRow &&
          other.id == this.id &&
          other.table == this.table &&
          other.rowId == this.rowId &&
          other.localJson == this.localJson &&
          other.serverJson == this.serverJson &&
          other.resolvedAs == this.resolvedAs &&
          other.at == this.at);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflictRow> {
  final Value<int> id;
  final Value<String> table;
  final Value<String> rowId;
  final Value<String> localJson;
  final Value<String> serverJson;
  final Value<ConflictResolution> resolvedAs;
  final Value<DateTime> at;
  const SyncConflictsCompanion({
    this.id = const Value.absent(),
    this.table = const Value.absent(),
    this.rowId = const Value.absent(),
    this.localJson = const Value.absent(),
    this.serverJson = const Value.absent(),
    this.resolvedAs = const Value.absent(),
    this.at = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    this.id = const Value.absent(),
    required String table,
    required String rowId,
    required String localJson,
    required String serverJson,
    required ConflictResolution resolvedAs,
    required DateTime at,
  }) : table = Value(table),
       rowId = Value(rowId),
       localJson = Value(localJson),
       serverJson = Value(serverJson),
       resolvedAs = Value(resolvedAs),
       at = Value(at);
  static Insertable<SyncConflictRow> custom({
    Expression<int>? id,
    Expression<String>? table,
    Expression<String>? rowId,
    Expression<String>? localJson,
    Expression<String>? serverJson,
    Expression<String>? resolvedAs,
    Expression<String>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (table != null) 'table_name': table,
      if (rowId != null) 'row_id': rowId,
      if (localJson != null) 'local_json': localJson,
      if (serverJson != null) 'server_json': serverJson,
      if (resolvedAs != null) 'resolved_as': resolvedAs,
      if (at != null) 'at': at,
    });
  }

  SyncConflictsCompanion copyWith({
    Value<int>? id,
    Value<String>? table,
    Value<String>? rowId,
    Value<String>? localJson,
    Value<String>? serverJson,
    Value<ConflictResolution>? resolvedAs,
    Value<DateTime>? at,
  }) {
    return SyncConflictsCompanion(
      id: id ?? this.id,
      table: table ?? this.table,
      rowId: rowId ?? this.rowId,
      localJson: localJson ?? this.localJson,
      serverJson: serverJson ?? this.serverJson,
      resolvedAs: resolvedAs ?? this.resolvedAs,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (table.present) {
      map['table_name'] = Variable<String>(table.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (localJson.present) {
      map['local_json'] = Variable<String>(localJson.value);
    }
    if (serverJson.present) {
      map['server_json'] = Variable<String>(serverJson.value);
    }
    if (resolvedAs.present) {
      map['resolved_as'] = Variable<String>(
        $SyncConflictsTable.$converterresolvedAs.toSql(resolvedAs.value),
      );
    }
    if (at.present) {
      map['at'] = Variable<String>(
        $SyncConflictsTable.$converterat.toSql(at.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('id: $id, ')
          ..write('table: $table, ')
          ..write('rowId: $rowId, ')
          ..write('localJson: $localJson, ')
          ..write('serverJson: $serverJson, ')
          ..write('resolvedAs: $resolvedAs, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $SessionSnapshotsTable extends SessionSnapshots
    with TableInfo<$SessionSnapshotsTable, SessionSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionMode>($SessionSnapshotsTable.$convertermode);
  static const VerificationMeta _segmentsJsonMeta = const VerificationMeta(
    'segmentsJson',
  );
  @override
  late final GeneratedColumn<String> segmentsJson = GeneratedColumn<String>(
    'segments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SegmentKind, String> openKind =
      GeneratedColumn<String>(
        'open_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SegmentKind>($SessionSnapshotsTable.$converteropenKind);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> openStart =
      GeneratedColumn<String>(
        'open_start',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SessionSnapshotsTable.$converteropenStart);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> lastSeatedAt =
      GeneratedColumn<String>(
        'last_seated_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SessionSnapshotsTable.$converterlastSeatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String>
  awayCandidateSince =
      GeneratedColumn<String>(
        'away_candidate_since',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $SessionSnapshotsTable.$converterawayCandidateSince,
      );
  static const VerificationMeta _sensitivityMeta = const VerificationMeta(
    'sensitivity',
  );
  @override
  late final GeneratedColumn<int> sensitivity = GeneratedColumn<int>(
    'sensitivity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> savedAt =
      GeneratedColumn<String>(
        'saved_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SessionSnapshotsTable.$convertersavedAt);
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannerItemIdMeta = const VerificationMeta(
    'plannerItemId',
  );
  @override
  late final GeneratedColumn<String> plannerItemId = GeneratedColumn<String>(
    'planner_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionKind>($SessionSnapshotsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> startedAt =
      GeneratedColumn<String>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SessionSnapshotsTable.$converterstartedAt);
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    mode,
    segmentsJson,
    openKind,
    openStart,
    lastSeatedAt,
    awayCandidateSince,
    sensitivity,
    savedAt,
    subjectId,
    plannerItemId,
    kind,
    startedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_snapshot';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('segments_json')) {
      context.handle(
        _segmentsJsonMeta,
        segmentsJson.isAcceptableOrUnknown(
          data['segments_json']!,
          _segmentsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_segmentsJsonMeta);
    }
    if (data.containsKey('sensitivity')) {
      context.handle(
        _sensitivityMeta,
        sensitivity.isAcceptableOrUnknown(
          data['sensitivity']!,
          _sensitivityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sensitivityMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('planner_item_id')) {
      context.handle(
        _plannerItemIdMeta,
        plannerItemId.isAcceptableOrUnknown(
          data['planner_item_id']!,
          _plannerItemIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  SessionSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionSnapshotRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      mode: $SessionSnapshotsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      segmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segments_json'],
      )!,
      openKind: $SessionSnapshotsTable.$converteropenKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}open_kind'],
        )!,
      ),
      openStart: $SessionSnapshotsTable.$converteropenStart.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}open_start'],
        )!,
      ),
      lastSeatedAt: $SessionSnapshotsTable.$converterlastSeatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_seated_at'],
        ),
      ),
      awayCandidateSince: $SessionSnapshotsTable.$converterawayCandidateSince
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}away_candidate_since'],
            ),
          ),
      sensitivity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sensitivity'],
      )!,
      savedAt: $SessionSnapshotsTable.$convertersavedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}saved_at'],
        )!,
      ),
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      plannerItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planner_item_id'],
      ),
      kind: $SessionSnapshotsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      startedAt: $SessionSnapshotsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}started_at'],
        )!,
      ),
    );
  }

  @override
  $SessionSnapshotsTable createAlias(String alias) {
    return $SessionSnapshotsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionMode, String, String> $convertermode =
      const WireEnumConverter(SessionMode.values);
  static JsonTypeConverter2<SegmentKind, String, String> $converteropenKind =
      const WireEnumConverter(SegmentKind.values);
  static JsonTypeConverter2<DateTime, String, String> $converteropenStart =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?>
  $converterlastSeatedAt = const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime?, String?, String?>
  $converterawayCandidateSince = const NullableUtcDateTimeConverter();
  static JsonTypeConverter2<DateTime, String, String> $convertersavedAt =
      const UtcDateTimeConverter();
  static JsonTypeConverter2<SessionKind, String, String> $converterkind =
      const WireEnumConverter(SessionKind.values);
  static JsonTypeConverter2<DateTime, String, String> $converterstartedAt =
      const UtcDateTimeConverter();
}

class SessionSnapshotRow extends DataClass
    implements Insertable<SessionSnapshotRow> {
  final String sessionId;
  final SessionMode mode;

  /// Closed segments: `[{id, kind, start_at, end_at, corrected}]`.
  final String segmentsJson;
  final SegmentKind openKind;
  final DateTime openStart;
  final DateTime? lastSeatedAt;
  final DateTime? awayCandidateSince;
  final int sensitivity;
  final DateTime savedAt;
  final String? subjectId;
  final String? plannerItemId;
  final SessionKind kind;
  final DateTime startedAt;
  const SessionSnapshotRow({
    required this.sessionId,
    required this.mode,
    required this.segmentsJson,
    required this.openKind,
    required this.openStart,
    this.lastSeatedAt,
    this.awayCandidateSince,
    required this.sensitivity,
    required this.savedAt,
    this.subjectId,
    this.plannerItemId,
    required this.kind,
    required this.startedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    {
      map['mode'] = Variable<String>(
        $SessionSnapshotsTable.$convertermode.toSql(mode),
      );
    }
    map['segments_json'] = Variable<String>(segmentsJson);
    {
      map['open_kind'] = Variable<String>(
        $SessionSnapshotsTable.$converteropenKind.toSql(openKind),
      );
    }
    {
      map['open_start'] = Variable<String>(
        $SessionSnapshotsTable.$converteropenStart.toSql(openStart),
      );
    }
    if (!nullToAbsent || lastSeatedAt != null) {
      map['last_seated_at'] = Variable<String>(
        $SessionSnapshotsTable.$converterlastSeatedAt.toSql(lastSeatedAt),
      );
    }
    if (!nullToAbsent || awayCandidateSince != null) {
      map['away_candidate_since'] = Variable<String>(
        $SessionSnapshotsTable.$converterawayCandidateSince.toSql(
          awayCandidateSince,
        ),
      );
    }
    map['sensitivity'] = Variable<int>(sensitivity);
    {
      map['saved_at'] = Variable<String>(
        $SessionSnapshotsTable.$convertersavedAt.toSql(savedAt),
      );
    }
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || plannerItemId != null) {
      map['planner_item_id'] = Variable<String>(plannerItemId);
    }
    {
      map['kind'] = Variable<String>(
        $SessionSnapshotsTable.$converterkind.toSql(kind),
      );
    }
    {
      map['started_at'] = Variable<String>(
        $SessionSnapshotsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    return map;
  }

  SessionSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SessionSnapshotsCompanion(
      sessionId: Value(sessionId),
      mode: Value(mode),
      segmentsJson: Value(segmentsJson),
      openKind: Value(openKind),
      openStart: Value(openStart),
      lastSeatedAt: lastSeatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeatedAt),
      awayCandidateSince: awayCandidateSince == null && nullToAbsent
          ? const Value.absent()
          : Value(awayCandidateSince),
      sensitivity: Value(sensitivity),
      savedAt: Value(savedAt),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      plannerItemId: plannerItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannerItemId),
      kind: Value(kind),
      startedAt: Value(startedAt),
    );
  }

  factory SessionSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionSnapshotRow(
      sessionId: serializer.fromJson<String>(json['session_id']),
      mode: $SessionSnapshotsTable.$convertermode.fromJson(
        serializer.fromJson<String>(json['mode']),
      ),
      segmentsJson: serializer.fromJson<String>(json['segments_json']),
      openKind: $SessionSnapshotsTable.$converteropenKind.fromJson(
        serializer.fromJson<String>(json['open_kind']),
      ),
      openStart: $SessionSnapshotsTable.$converteropenStart.fromJson(
        serializer.fromJson<String>(json['open_start']),
      ),
      lastSeatedAt: $SessionSnapshotsTable.$converterlastSeatedAt.fromJson(
        serializer.fromJson<String?>(json['last_seated_at']),
      ),
      awayCandidateSince: $SessionSnapshotsTable.$converterawayCandidateSince
          .fromJson(serializer.fromJson<String?>(json['away_candidate_since'])),
      sensitivity: serializer.fromJson<int>(json['sensitivity']),
      savedAt: $SessionSnapshotsTable.$convertersavedAt.fromJson(
        serializer.fromJson<String>(json['saved_at']),
      ),
      subjectId: serializer.fromJson<String?>(json['subject_id']),
      plannerItemId: serializer.fromJson<String?>(json['planner_item_id']),
      kind: $SessionSnapshotsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      startedAt: $SessionSnapshotsTable.$converterstartedAt.fromJson(
        serializer.fromJson<String>(json['started_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'session_id': serializer.toJson<String>(sessionId),
      'mode': serializer.toJson<String>(
        $SessionSnapshotsTable.$convertermode.toJson(mode),
      ),
      'segments_json': serializer.toJson<String>(segmentsJson),
      'open_kind': serializer.toJson<String>(
        $SessionSnapshotsTable.$converteropenKind.toJson(openKind),
      ),
      'open_start': serializer.toJson<String>(
        $SessionSnapshotsTable.$converteropenStart.toJson(openStart),
      ),
      'last_seated_at': serializer.toJson<String?>(
        $SessionSnapshotsTable.$converterlastSeatedAt.toJson(lastSeatedAt),
      ),
      'away_candidate_since': serializer.toJson<String?>(
        $SessionSnapshotsTable.$converterawayCandidateSince.toJson(
          awayCandidateSince,
        ),
      ),
      'sensitivity': serializer.toJson<int>(sensitivity),
      'saved_at': serializer.toJson<String>(
        $SessionSnapshotsTable.$convertersavedAt.toJson(savedAt),
      ),
      'subject_id': serializer.toJson<String?>(subjectId),
      'planner_item_id': serializer.toJson<String?>(plannerItemId),
      'kind': serializer.toJson<String>(
        $SessionSnapshotsTable.$converterkind.toJson(kind),
      ),
      'started_at': serializer.toJson<String>(
        $SessionSnapshotsTable.$converterstartedAt.toJson(startedAt),
      ),
    };
  }

  SessionSnapshotRow copyWith({
    String? sessionId,
    SessionMode? mode,
    String? segmentsJson,
    SegmentKind? openKind,
    DateTime? openStart,
    Value<DateTime?> lastSeatedAt = const Value.absent(),
    Value<DateTime?> awayCandidateSince = const Value.absent(),
    int? sensitivity,
    DateTime? savedAt,
    Value<String?> subjectId = const Value.absent(),
    Value<String?> plannerItemId = const Value.absent(),
    SessionKind? kind,
    DateTime? startedAt,
  }) => SessionSnapshotRow(
    sessionId: sessionId ?? this.sessionId,
    mode: mode ?? this.mode,
    segmentsJson: segmentsJson ?? this.segmentsJson,
    openKind: openKind ?? this.openKind,
    openStart: openStart ?? this.openStart,
    lastSeatedAt: lastSeatedAt.present ? lastSeatedAt.value : this.lastSeatedAt,
    awayCandidateSince: awayCandidateSince.present
        ? awayCandidateSince.value
        : this.awayCandidateSince,
    sensitivity: sensitivity ?? this.sensitivity,
    savedAt: savedAt ?? this.savedAt,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    plannerItemId: plannerItemId.present
        ? plannerItemId.value
        : this.plannerItemId,
    kind: kind ?? this.kind,
    startedAt: startedAt ?? this.startedAt,
  );
  SessionSnapshotRow copyWithCompanion(SessionSnapshotsCompanion data) {
    return SessionSnapshotRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      mode: data.mode.present ? data.mode.value : this.mode,
      segmentsJson: data.segmentsJson.present
          ? data.segmentsJson.value
          : this.segmentsJson,
      openKind: data.openKind.present ? data.openKind.value : this.openKind,
      openStart: data.openStart.present ? data.openStart.value : this.openStart,
      lastSeatedAt: data.lastSeatedAt.present
          ? data.lastSeatedAt.value
          : this.lastSeatedAt,
      awayCandidateSince: data.awayCandidateSince.present
          ? data.awayCandidateSince.value
          : this.awayCandidateSince,
      sensitivity: data.sensitivity.present
          ? data.sensitivity.value
          : this.sensitivity,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      plannerItemId: data.plannerItemId.present
          ? data.plannerItemId.value
          : this.plannerItemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionSnapshotRow(')
          ..write('sessionId: $sessionId, ')
          ..write('mode: $mode, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('openKind: $openKind, ')
          ..write('openStart: $openStart, ')
          ..write('lastSeatedAt: $lastSeatedAt, ')
          ..write('awayCandidateSince: $awayCandidateSince, ')
          ..write('sensitivity: $sensitivity, ')
          ..write('savedAt: $savedAt, ')
          ..write('subjectId: $subjectId, ')
          ..write('plannerItemId: $plannerItemId, ')
          ..write('kind: $kind, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    mode,
    segmentsJson,
    openKind,
    openStart,
    lastSeatedAt,
    awayCandidateSince,
    sensitivity,
    savedAt,
    subjectId,
    plannerItemId,
    kind,
    startedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionSnapshotRow &&
          other.sessionId == this.sessionId &&
          other.mode == this.mode &&
          other.segmentsJson == this.segmentsJson &&
          other.openKind == this.openKind &&
          other.openStart == this.openStart &&
          other.lastSeatedAt == this.lastSeatedAt &&
          other.awayCandidateSince == this.awayCandidateSince &&
          other.sensitivity == this.sensitivity &&
          other.savedAt == this.savedAt &&
          other.subjectId == this.subjectId &&
          other.plannerItemId == this.plannerItemId &&
          other.kind == this.kind &&
          other.startedAt == this.startedAt);
}

class SessionSnapshotsCompanion extends UpdateCompanion<SessionSnapshotRow> {
  final Value<String> sessionId;
  final Value<SessionMode> mode;
  final Value<String> segmentsJson;
  final Value<SegmentKind> openKind;
  final Value<DateTime> openStart;
  final Value<DateTime?> lastSeatedAt;
  final Value<DateTime?> awayCandidateSince;
  final Value<int> sensitivity;
  final Value<DateTime> savedAt;
  final Value<String?> subjectId;
  final Value<String?> plannerItemId;
  final Value<SessionKind> kind;
  final Value<DateTime> startedAt;
  final Value<int> rowid;
  const SessionSnapshotsCompanion({
    this.sessionId = const Value.absent(),
    this.mode = const Value.absent(),
    this.segmentsJson = const Value.absent(),
    this.openKind = const Value.absent(),
    this.openStart = const Value.absent(),
    this.lastSeatedAt = const Value.absent(),
    this.awayCandidateSince = const Value.absent(),
    this.sensitivity = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.plannerItemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionSnapshotsCompanion.insert({
    required String sessionId,
    required SessionMode mode,
    required String segmentsJson,
    required SegmentKind openKind,
    required DateTime openStart,
    this.lastSeatedAt = const Value.absent(),
    this.awayCandidateSince = const Value.absent(),
    required int sensitivity,
    required DateTime savedAt,
    this.subjectId = const Value.absent(),
    this.plannerItemId = const Value.absent(),
    required SessionKind kind,
    required DateTime startedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       mode = Value(mode),
       segmentsJson = Value(segmentsJson),
       openKind = Value(openKind),
       openStart = Value(openStart),
       sensitivity = Value(sensitivity),
       savedAt = Value(savedAt),
       kind = Value(kind),
       startedAt = Value(startedAt);
  static Insertable<SessionSnapshotRow> custom({
    Expression<String>? sessionId,
    Expression<String>? mode,
    Expression<String>? segmentsJson,
    Expression<String>? openKind,
    Expression<String>? openStart,
    Expression<String>? lastSeatedAt,
    Expression<String>? awayCandidateSince,
    Expression<int>? sensitivity,
    Expression<String>? savedAt,
    Expression<String>? subjectId,
    Expression<String>? plannerItemId,
    Expression<String>? kind,
    Expression<String>? startedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (mode != null) 'mode': mode,
      if (segmentsJson != null) 'segments_json': segmentsJson,
      if (openKind != null) 'open_kind': openKind,
      if (openStart != null) 'open_start': openStart,
      if (lastSeatedAt != null) 'last_seated_at': lastSeatedAt,
      if (awayCandidateSince != null)
        'away_candidate_since': awayCandidateSince,
      if (sensitivity != null) 'sensitivity': sensitivity,
      if (savedAt != null) 'saved_at': savedAt,
      if (subjectId != null) 'subject_id': subjectId,
      if (plannerItemId != null) 'planner_item_id': plannerItemId,
      if (kind != null) 'kind': kind,
      if (startedAt != null) 'started_at': startedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionSnapshotsCompanion copyWith({
    Value<String>? sessionId,
    Value<SessionMode>? mode,
    Value<String>? segmentsJson,
    Value<SegmentKind>? openKind,
    Value<DateTime>? openStart,
    Value<DateTime?>? lastSeatedAt,
    Value<DateTime?>? awayCandidateSince,
    Value<int>? sensitivity,
    Value<DateTime>? savedAt,
    Value<String?>? subjectId,
    Value<String?>? plannerItemId,
    Value<SessionKind>? kind,
    Value<DateTime>? startedAt,
    Value<int>? rowid,
  }) {
    return SessionSnapshotsCompanion(
      sessionId: sessionId ?? this.sessionId,
      mode: mode ?? this.mode,
      segmentsJson: segmentsJson ?? this.segmentsJson,
      openKind: openKind ?? this.openKind,
      openStart: openStart ?? this.openStart,
      lastSeatedAt: lastSeatedAt ?? this.lastSeatedAt,
      awayCandidateSince: awayCandidateSince ?? this.awayCandidateSince,
      sensitivity: sensitivity ?? this.sensitivity,
      savedAt: savedAt ?? this.savedAt,
      subjectId: subjectId ?? this.subjectId,
      plannerItemId: plannerItemId ?? this.plannerItemId,
      kind: kind ?? this.kind,
      startedAt: startedAt ?? this.startedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $SessionSnapshotsTable.$convertermode.toSql(mode.value),
      );
    }
    if (segmentsJson.present) {
      map['segments_json'] = Variable<String>(segmentsJson.value);
    }
    if (openKind.present) {
      map['open_kind'] = Variable<String>(
        $SessionSnapshotsTable.$converteropenKind.toSql(openKind.value),
      );
    }
    if (openStart.present) {
      map['open_start'] = Variable<String>(
        $SessionSnapshotsTable.$converteropenStart.toSql(openStart.value),
      );
    }
    if (lastSeatedAt.present) {
      map['last_seated_at'] = Variable<String>(
        $SessionSnapshotsTable.$converterlastSeatedAt.toSql(lastSeatedAt.value),
      );
    }
    if (awayCandidateSince.present) {
      map['away_candidate_since'] = Variable<String>(
        $SessionSnapshotsTable.$converterawayCandidateSince.toSql(
          awayCandidateSince.value,
        ),
      );
    }
    if (sensitivity.present) {
      map['sensitivity'] = Variable<int>(sensitivity.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<String>(
        $SessionSnapshotsTable.$convertersavedAt.toSql(savedAt.value),
      );
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (plannerItemId.present) {
      map['planner_item_id'] = Variable<String>(plannerItemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SessionSnapshotsTable.$converterkind.toSql(kind.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(
        $SessionSnapshotsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionSnapshotsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('mode: $mode, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('openKind: $openKind, ')
          ..write('openStart: $openStart, ')
          ..write('lastSeatedAt: $lastSeatedAt, ')
          ..write('awayCandidateSince: $awayCandidateSince, ')
          ..write('sensitivity: $sensitivity, ')
          ..write('savedAt: $savedAt, ')
          ..write('subjectId: $subjectId, ')
          ..write('plannerItemId: $plannerItemId, ')
          ..write('kind: $kind, ')
          ..write('startedAt: $startedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionSegmentsTable sessionSegments = $SessionSegmentsTable(
    this,
  );
  late final $CorrectionsTable corrections = $CorrectionsTable(this);
  late final $PlannerItemsTable plannerItems = $PlannerItemsTable(this);
  late final $RecurrencesTable recurrences = $RecurrencesTable(this);
  late final $ReadingRequestsTable readingRequests = $ReadingRequestsTable(
    this,
  );
  late final $WrongItemsTable wrongItems = $WrongItemsTable(this);
  late final $ReviewEntriesTable reviewEntries = $ReviewEntriesTable(this);
  late final $RetryRecordsTable retryRecords = $RetryRecordsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ActivityDaysTable activityDays = $ActivityDaysTable(this);
  late final $SubscriptionStatesTable subscriptionStates =
      $SubscriptionStatesTable(this);
  late final $ReadingQuotasTable readingQuotas = $ReadingQuotasTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $SyncConflictsTable syncConflicts = $SyncConflictsTable(this);
  late final $SessionSnapshotsTable sessionSnapshots = $SessionSnapshotsTable(
    this,
  );
  late final Index subjectsUserSort = Index(
    'subjects_user_sort',
    'CREATE INDEX subjects_user_sort ON subjects (user_id, sort_order)',
  );
  late final Index sessionsUserStarted = Index(
    'sessions_user_started',
    'CREATE INDEX sessions_user_started ON sessions (user_id, started_at)',
  );
  late final Index sessionsUserStatus = Index(
    'sessions_user_status',
    'CREATE INDEX sessions_user_status ON sessions (user_id, status)',
  );
  late final Index sessionSegmentsSessionStart = Index(
    'session_segments_session_start',
    'CREATE INDEX session_segments_session_start ON session_segments (session_id, start_at)',
  );
  late final Index correctionsUserAt = Index(
    'corrections_user_at',
    'CREATE INDEX corrections_user_at ON corrections (user_id, at)',
  );
  late final Index correctionsSession = Index(
    'corrections_session',
    'CREATE INDEX corrections_session ON corrections (session_id)',
  );
  late final Index plannerItemsUserDate = Index(
    'planner_items_user_date',
    'CREATE INDEX planner_items_user_date ON planner_items (user_id, date)',
  );
  late final Index plannerItemsUserBand = Index(
    'planner_items_user_band',
    'CREATE INDEX planner_items_user_band ON planner_items (user_id, band_start)',
  );
  late final Index plannerItemsRecurrence = Index(
    'planner_items_recurrence',
    'CREATE INDEX planner_items_recurrence ON planner_items (recurrence_id)',
  );
  late final Index readingRequestsUserRequest = Index(
    'reading_requests_user_request',
    'CREATE UNIQUE INDEX reading_requests_user_request ON reading_requests (user_id, request_id)',
  );
  late final Index readingRequestsUserStatus = Index(
    'reading_requests_user_status',
    'CREATE INDEX reading_requests_user_status ON reading_requests (user_id, status)',
  );
  late final Index wrongItemsUserStatus = Index(
    'wrong_items_user_status',
    'CREATE INDEX wrong_items_user_status ON wrong_items (user_id, status)',
  );
  late final Index wrongItemsRequest = Index(
    'wrong_items_request',
    'CREATE INDEX wrong_items_request ON wrong_items (request_id)',
  );
  late final Index wrongItemsUserSubject = Index(
    'wrong_items_user_subject',
    'CREATE INDEX wrong_items_user_subject ON wrong_items (user_id, subject_id)',
  );
  late final Index reviewEntriesUserDue = Index(
    'review_entries_user_due',
    'CREATE INDEX review_entries_user_due ON review_entries (user_id, due_at)',
  );
  late final Index retryRecordsWrongItemAt = Index(
    'retry_records_wrong_item_at',
    'CREATE INDEX retry_records_wrong_item_at ON retry_records (wrong_item_id, at)',
  );
  late final Index settingsUserKey = Index(
    'settings_user_key',
    'CREATE UNIQUE INDEX settings_user_key ON settings (user_id, "key")',
  );
  late final Index activityDaysUserDate = Index(
    'activity_days_user_date',
    'CREATE UNIQUE INDEX activity_days_user_date ON activity_days (user_id, date)',
  );
  late final Index photosRequestPage = Index(
    'photos_request_page',
    'CREATE INDEX photos_request_page ON photos (request_id, page_index)',
  );
  late final Index photosExpires = Index(
    'photos_expires',
    'CREATE INDEX photos_expires ON photos (expires_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    subjects,
    sessions,
    sessionSegments,
    corrections,
    plannerItems,
    recurrences,
    readingRequests,
    wrongItems,
    reviewEntries,
    retryRecords,
    settings,
    activityDays,
    subscriptionStates,
    readingQuotas,
    photos,
    syncOutbox,
    syncMeta,
    syncConflicts,
    sessionSnapshots,
    subjectsUserSort,
    sessionsUserStarted,
    sessionsUserStatus,
    sessionSegmentsSessionStart,
    correctionsUserAt,
    correctionsSession,
    plannerItemsUserDate,
    plannerItemsUserBand,
    plannerItemsRecurrence,
    readingRequestsUserRequest,
    readingRequestsUserStatus,
    wrongItemsUserStatus,
    wrongItemsRequest,
    wrongItemsUserSubject,
    reviewEntriesUserDue,
    retryRecordsWrongItemAt,
    settingsUserKey,
    activityDaysUserDate,
    photosRequestPage,
    photosExpires,
  ];
}

typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  required String id,
  required String userId,
  required DateTime createdAt,
  required DateTime clientUpdatedAt,
  Value<DateTime?> deletedAt,
  required String deviceId,
  Value<int> clientRev,
  Value<int?> baseServerVersion,
  Value<int?> serverVersion,
  Value<int?> serverSeq,
  Value<int> purgeEpoch,
  Value<DateTime?> pendingDeleteUntil,
  Value<String?> name,
  Value<int?> colorIndex,
  Value<int?> sortOrder,
  Value<bool?> isDefault,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> createdAt,
  Value<DateTime> clientUpdatedAt,
  Value<DateTime?> deletedAt,
  Value<String> deviceId,
  Value<int> clientRev,
  Value<int?> baseServerVersion,
  Value<int?> serverVersion,
  Value<int?> serverSeq,
  Value<int> purgeEpoch,
  Value<DateTime?> pendingDeleteUntil,
  Value<String?> name,
  Value<int?> colorIndex,
  Value<int?> sortOrder,
  Value<bool?> isDefault,
  Value<int> rowid,
});

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get pendingDeleteUntil => $composableBuilder(
    column: $table.pendingDeleteUntil,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingDeleteUntil => $composableBuilder(
    column: $table.pendingDeleteUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, String> get pendingDeleteUntil =>
      $composableBuilder(
        column: $table.pendingDeleteUntil,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$SubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectsTable,
          SubjectRow,
          $$SubjectsTableFilterComposer,
          $$SubjectsTableOrderingComposer,
          $$SubjectsTableAnnotationComposer,
          $$SubjectsTableCreateCompanionBuilder,
          $$SubjectsTableUpdateCompanionBuilder,
          (
            SubjectRow,
            BaseReferences<_$AppDatabase, $SubjectsTable, SubjectRow>,
          ),
          SubjectRow,
          PrefetchHooks Function()
        > {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<DateTime?> pendingDeleteUntil = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> colorIndex = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<bool?> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                pendingDeleteUntil: pendingDeleteUntil,
                name: name,
                colorIndex: colorIndex,
                sortOrder: sortOrder,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<DateTime?> pendingDeleteUntil = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> colorIndex = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<bool?> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                pendingDeleteUntil: pendingDeleteUntil,
                name: name,
                colorIndex: colorIndex,
                sortOrder: sortOrder,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubjectsTable, SubjectRow>(table),
                  BaseReferences<_$AppDatabase, $SubjectsTable, SubjectRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectsTable,
      SubjectRow,
      $$SubjectsTableFilterComposer,
      $$SubjectsTableOrderingComposer,
      $$SubjectsTableAnnotationComposer,
      $$SubjectsTableCreateCompanionBuilder,
      $$SubjectsTableUpdateCompanionBuilder,
      (SubjectRow, BaseReferences<_$AppDatabase, $SubjectsTable, SubjectRow>),
      SubjectRow,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required String userId,
  required DateTime createdAt,
  required DateTime clientUpdatedAt,
  Value<DateTime?> deletedAt,
  required String deviceId,
  Value<int> clientRev,
  Value<int?> baseServerVersion,
  Value<int?> serverVersion,
  Value<int?> serverSeq,
  Value<int> purgeEpoch,
  Value<DateTime?> pendingDeleteUntil,
  Value<String?> subjectId,
  Value<String?> plannerItemId,
  Value<SessionKind?> kind,
  Value<SessionMode?> mode,
  Value<DateTime?> startedAt,
  Value<DateTime?> endedAt,
  Value<SessionStatus?> status,
  Value<int?> seatedSeconds,
  Value<int?> sensitivityLevel,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> createdAt,
  Value<DateTime> clientUpdatedAt,
  Value<DateTime?> deletedAt,
  Value<String> deviceId,
  Value<int> clientRev,
  Value<int?> baseServerVersion,
  Value<int?> serverVersion,
  Value<int?> serverSeq,
  Value<int> purgeEpoch,
  Value<DateTime?> pendingDeleteUntil,
  Value<String?> subjectId,
  Value<String?> plannerItemId,
  Value<SessionKind?> kind,
  Value<SessionMode?> mode,
  Value<DateTime?> startedAt,
  Value<DateTime?> endedAt,
  Value<SessionStatus?> status,
  Value<int?> seatedSeconds,
  Value<int?> sensitivityLevel,
  Value<String?> note,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get pendingDeleteUntil => $composableBuilder(
    column: $table.pendingDeleteUntil,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannerItemId => $composableBuilder(
    column: $table.plannerItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionKind?, SessionKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SessionMode?, SessionMode, String> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get endedAt =>
      $composableBuilder(
        column: $table.endedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SessionStatus?, SessionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get seatedSeconds => $composableBuilder(
    column: $table.seatedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sensitivityLevel => $composableBuilder(
    column: $table.sensitivityLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingDeleteUntil => $composableBuilder(
    column: $table.pendingDeleteUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannerItemId => $composableBuilder(
    column: $table.plannerItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seatedSeconds => $composableBuilder(
    column: $table.seatedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sensitivityLevel => $composableBuilder(
    column: $table.sensitivityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, String> get pendingDeleteUntil =>
      $composableBuilder(
        column: $table.pendingDeleteUntil,
        builder: (column) => column,
      );

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get plannerItemId => $composableBuilder(
    column: $table.plannerItemId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SessionKind?, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionMode?, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionStatus?, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get seatedSeconds => $composableBuilder(
    column: $table.seatedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sensitivityLevel => $composableBuilder(
    column: $table.sensitivityLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (
            SessionRow,
            BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>,
          ),
          SessionRow,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<DateTime?> pendingDeleteUntil = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> plannerItemId = const Value.absent(),
                Value<SessionKind?> kind = const Value.absent(),
                Value<SessionMode?> mode = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<SessionStatus?> status = const Value.absent(),
                Value<int?> seatedSeconds = const Value.absent(),
                Value<int?> sensitivityLevel = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                pendingDeleteUntil: pendingDeleteUntil,
                subjectId: subjectId,
                plannerItemId: plannerItemId,
                kind: kind,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                seatedSeconds: seatedSeconds,
                sensitivityLevel: sensitivityLevel,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<DateTime?> pendingDeleteUntil = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> plannerItemId = const Value.absent(),
                Value<SessionKind?> kind = const Value.absent(),
                Value<SessionMode?> mode = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<SessionStatus?> status = const Value.absent(),
                Value<int?> seatedSeconds = const Value.absent(),
                Value<int?> sensitivityLevel = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                pendingDeleteUntil: pendingDeleteUntil,
                subjectId: subjectId,
                plannerItemId: plannerItemId,
                kind: kind,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                seatedSeconds: seatedSeconds,
                sensitivityLevel: sensitivityLevel,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>),
      SessionRow,
      PrefetchHooks Function()
    >;
typedef $$SessionSegmentsTableCreateCompanionBuilder =
    SessionSegmentsCompanion Function({
      required String id,
      required String userId,
      required DateTime createdAt,
      required DateTime clientUpdatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      required String sessionId,
      Value<SegmentKind?> kind,
      Value<DateTime?> startAt,
      Value<DateTime?> endAt,
      Value<bool?> corrected,
      Value<int> rowid,
    });
typedef $$SessionSegmentsTableUpdateCompanionBuilder =
    SessionSegmentsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> createdAt,
      Value<DateTime> clientUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<String> sessionId,
      Value<SegmentKind?> kind,
      Value<DateTime?> startAt,
      Value<DateTime?> endAt,
      Value<bool?> corrected,
      Value<int> rowid,
    });

class $$SessionSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionSegmentsTable> {
  $$SessionSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SegmentKind?, SegmentKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get startAt =>
      $composableBuilder(
        column: $table.startAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get endAt =>
      $composableBuilder(
        column: $table.endAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get corrected => $composableBuilder(
    column: $table.corrected,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionSegmentsTable> {
  $$SessionSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get corrected => $composableBuilder(
    column: $table.corrected,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionSegmentsTable> {
  $$SessionSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SegmentKind?, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<bool> get corrected =>
      $composableBuilder(column: $table.corrected, builder: (column) => column);
}

class $$SessionSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionSegmentsTable,
          SessionSegmentRow,
          $$SessionSegmentsTableFilterComposer,
          $$SessionSegmentsTableOrderingComposer,
          $$SessionSegmentsTableAnnotationComposer,
          $$SessionSegmentsTableCreateCompanionBuilder,
          $$SessionSegmentsTableUpdateCompanionBuilder,
          (
            SessionSegmentRow,
            BaseReferences<
              _$AppDatabase,
              $SessionSegmentsTable,
              SessionSegmentRow
            >,
          ),
          SessionSegmentRow,
          PrefetchHooks Function()
        > {
  $$SessionSegmentsTableTableManager(
    _$AppDatabase db,
    $SessionSegmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<SegmentKind?> kind = const Value.absent(),
                Value<DateTime?> startAt = const Value.absent(),
                Value<DateTime?> endAt = const Value.absent(),
                Value<bool?> corrected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionSegmentsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                sessionId: sessionId,
                kind: kind,
                startAt: startAt,
                endAt: endAt,
                corrected: corrected,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                required String sessionId,
                Value<SegmentKind?> kind = const Value.absent(),
                Value<DateTime?> startAt = const Value.absent(),
                Value<DateTime?> endAt = const Value.absent(),
                Value<bool?> corrected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionSegmentsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                sessionId: sessionId,
                kind: kind,
                startAt: startAt,
                endAt: endAt,
                corrected: corrected,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionSegmentsTable, SessionSegmentRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SessionSegmentsTable,
                    SessionSegmentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionSegmentsTable,
      SessionSegmentRow,
      $$SessionSegmentsTableFilterComposer,
      $$SessionSegmentsTableOrderingComposer,
      $$SessionSegmentsTableAnnotationComposer,
      $$SessionSegmentsTableCreateCompanionBuilder,
      $$SessionSegmentsTableUpdateCompanionBuilder,
      (
        SessionSegmentRow,
        BaseReferences<_$AppDatabase, $SessionSegmentsTable, SessionSegmentRow>,
      ),
      SessionSegmentRow,
      PrefetchHooks Function()
    >;
typedef $$CorrectionsTableCreateCompanionBuilder =
    CorrectionsCompanion Function({
      required String id,
      required String userId,
      required DateTime createdAt,
      required DateTime clientUpdatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      required String sessionId,
      Value<String?> segmentId,
      Value<SegmentKind?> fromKind,
      Value<SegmentKind?> toKind,
      Value<DateTime?> at,
      Value<int?> sensitivityBefore,
      Value<int?> sensitivityAfter,
      Value<int> rowid,
    });
typedef $$CorrectionsTableUpdateCompanionBuilder =
    CorrectionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> createdAt,
      Value<DateTime> clientUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<String> sessionId,
      Value<String?> segmentId,
      Value<SegmentKind?> fromKind,
      Value<SegmentKind?> toKind,
      Value<DateTime?> at,
      Value<int?> sensitivityBefore,
      Value<int?> sensitivityAfter,
      Value<int> rowid,
    });

class $$CorrectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SegmentKind?, SegmentKind, String>
  get fromKind => $composableBuilder(
    column: $table.fromKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SegmentKind?, SegmentKind, String>
  get toKind => $composableBuilder(
    column: $table.toKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get at =>
      $composableBuilder(
        column: $table.at,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get sensitivityBefore => $composableBuilder(
    column: $table.sensitivityBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sensitivityAfter => $composableBuilder(
    column: $table.sensitivityAfter,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CorrectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromKind => $composableBuilder(
    column: $table.fromKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toKind => $composableBuilder(
    column: $table.toKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sensitivityBefore => $composableBuilder(
    column: $table.sensitivityBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sensitivityAfter => $composableBuilder(
    column: $table.sensitivityAfter,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CorrectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CorrectionsTable> {
  $$CorrectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get segmentId =>
      $composableBuilder(column: $table.segmentId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SegmentKind?, String> get fromKind =>
      $composableBuilder(column: $table.fromKind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SegmentKind?, String> get toKind =>
      $composableBuilder(column: $table.toKind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get sensitivityBefore => $composableBuilder(
    column: $table.sensitivityBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sensitivityAfter => $composableBuilder(
    column: $table.sensitivityAfter,
    builder: (column) => column,
  );
}

class $$CorrectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CorrectionsTable,
          CorrectionRow,
          $$CorrectionsTableFilterComposer,
          $$CorrectionsTableOrderingComposer,
          $$CorrectionsTableAnnotationComposer,
          $$CorrectionsTableCreateCompanionBuilder,
          $$CorrectionsTableUpdateCompanionBuilder,
          (
            CorrectionRow,
            BaseReferences<_$AppDatabase, $CorrectionsTable, CorrectionRow>,
          ),
          CorrectionRow,
          PrefetchHooks Function()
        > {
  $$CorrectionsTableTableManager(_$AppDatabase db, $CorrectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CorrectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CorrectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CorrectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String?> segmentId = const Value.absent(),
                Value<SegmentKind?> fromKind = const Value.absent(),
                Value<SegmentKind?> toKind = const Value.absent(),
                Value<DateTime?> at = const Value.absent(),
                Value<int?> sensitivityBefore = const Value.absent(),
                Value<int?> sensitivityAfter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CorrectionsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                sessionId: sessionId,
                segmentId: segmentId,
                fromKind: fromKind,
                toKind: toKind,
                at: at,
                sensitivityBefore: sensitivityBefore,
                sensitivityAfter: sensitivityAfter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                required String sessionId,
                Value<String?> segmentId = const Value.absent(),
                Value<SegmentKind?> fromKind = const Value.absent(),
                Value<SegmentKind?> toKind = const Value.absent(),
                Value<DateTime?> at = const Value.absent(),
                Value<int?> sensitivityBefore = const Value.absent(),
                Value<int?> sensitivityAfter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CorrectionsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                sessionId: sessionId,
                segmentId: segmentId,
                fromKind: fromKind,
                toKind: toKind,
                at: at,
                sensitivityBefore: sensitivityBefore,
                sensitivityAfter: sensitivityAfter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CorrectionsTable, CorrectionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CorrectionsTable,
                    CorrectionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CorrectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CorrectionsTable,
      CorrectionRow,
      $$CorrectionsTableFilterComposer,
      $$CorrectionsTableOrderingComposer,
      $$CorrectionsTableAnnotationComposer,
      $$CorrectionsTableCreateCompanionBuilder,
      $$CorrectionsTableUpdateCompanionBuilder,
      (
        CorrectionRow,
        BaseReferences<_$AppDatabase, $CorrectionsTable, CorrectionRow>,
      ),
      CorrectionRow,
      PrefetchHooks Function()
    >;
typedef $$PlannerItemsTableCreateCompanionBuilder =
    PlannerItemsCompanion Function({
      required String id,
      required String userId,
      required DateTime createdAt,
      required DateTime clientUpdatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<DateTime?> pendingDeleteUntil,
      Value<PlannerKind?> kind,
      Value<String?> title,
      Value<String?> subjectId,
      Value<String?> rangeText,
      Value<int?> targetMinutes,
      Value<String?> date,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<bool?> isDone,
      Value<DateTime?> doneAt,
      Value<String?> recurrenceId,
      Value<String?> bandStart,
      Value<String?> bandEnd,
      Value<int?> sortOrder,
      Value<int> rowid,
    });
typedef $$PlannerItemsTableUpdateCompanionBuilder =
    PlannerItemsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> createdAt,
      Value<DateTime> clientUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<DateTime?> pendingDeleteUntil,
      Value<PlannerKind?> kind,
      Value<String?> title,
      Value<String?> subjectId,
      Value<String?> rangeText,
      Value<int?> targetMinutes,
      Value<String?> date,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<bool?> isDone,
      Value<DateTime?> doneAt,
      Value<String?> recurrenceId,
      Value<String?> bandStart,
      Value<String?> bandEnd,
      Value<int?> sortOrder,
      Value<int> rowid,
    });

class $$PlannerItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PlannerItemsTable> {
  $$PlannerItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get pendingDeleteUntil => $composableBuilder(
    column: $table.pendingDeleteUntil,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PlannerKind?, PlannerKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rangeText => $composableBuilder(
    column: $table.rangeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get doneAt =>
      $composableBuilder(
        column: $table.doneAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get recurrenceId => $composableBuilder(
    column: $table.recurrenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bandStart => $composableBuilder(
    column: $table.bandStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bandEnd => $composableBuilder(
    column: $table.bandEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannerItemsTable> {
  $$PlannerItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingDeleteUntil => $composableBuilder(
    column: $table.pendingDeleteUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rangeText => $composableBuilder(
    column: $table.rangeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceId => $composableBuilder(
    column: $table.recurrenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bandStart => $composableBuilder(
    column: $table.bandStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bandEnd => $composableBuilder(
    column: $table.bandEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannerItemsTable> {
  $$PlannerItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, String> get pendingDeleteUntil =>
      $composableBuilder(
        column: $table.pendingDeleteUntil,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<PlannerKind?, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get rangeText =>
      $composableBuilder(column: $table.rangeText, builder: (column) => column);

  GeneratedColumn<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<String> get recurrenceId => $composableBuilder(
    column: $table.recurrenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bandStart =>
      $composableBuilder(column: $table.bandStart, builder: (column) => column);

  GeneratedColumn<String> get bandEnd =>
      $composableBuilder(column: $table.bandEnd, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$PlannerItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannerItemsTable,
          PlannerItemRow,
          $$PlannerItemsTableFilterComposer,
          $$PlannerItemsTableOrderingComposer,
          $$PlannerItemsTableAnnotationComposer,
          $$PlannerItemsTableCreateCompanionBuilder,
          $$PlannerItemsTableUpdateCompanionBuilder,
          (
            PlannerItemRow,
            BaseReferences<_$AppDatabase, $PlannerItemsTable, PlannerItemRow>,
          ),
          PlannerItemRow,
          PrefetchHooks Function()
        > {
  $$PlannerItemsTableTableManager(_$AppDatabase db, $PlannerItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannerItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannerItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<DateTime?> pendingDeleteUntil = const Value.absent(),
                Value<PlannerKind?> kind = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> rangeText = const Value.absent(),
                Value<int?> targetMinutes = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<bool?> isDone = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String?> recurrenceId = const Value.absent(),
                Value<String?> bandStart = const Value.absent(),
                Value<String?> bandEnd = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerItemsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                pendingDeleteUntil: pendingDeleteUntil,
                kind: kind,
                title: title,
                subjectId: subjectId,
                rangeText: rangeText,
                targetMinutes: targetMinutes,
                date: date,
                startTime: startTime,
                endTime: endTime,
                isDone: isDone,
                doneAt: doneAt,
                recurrenceId: recurrenceId,
                bandStart: bandStart,
                bandEnd: bandEnd,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<DateTime?> pendingDeleteUntil = const Value.absent(),
                Value<PlannerKind?> kind = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> rangeText = const Value.absent(),
                Value<int?> targetMinutes = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<bool?> isDone = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String?> recurrenceId = const Value.absent(),
                Value<String?> bandStart = const Value.absent(),
                Value<String?> bandEnd = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannerItemsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                pendingDeleteUntil: pendingDeleteUntil,
                kind: kind,
                title: title,
                subjectId: subjectId,
                rangeText: rangeText,
                targetMinutes: targetMinutes,
                date: date,
                startTime: startTime,
                endTime: endTime,
                isDone: isDone,
                doneAt: doneAt,
                recurrenceId: recurrenceId,
                bandStart: bandStart,
                bandEnd: bandEnd,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlannerItemsTable, PlannerItemRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlannerItemsTable,
                    PlannerItemRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannerItemsTable,
      PlannerItemRow,
      $$PlannerItemsTableFilterComposer,
      $$PlannerItemsTableOrderingComposer,
      $$PlannerItemsTableAnnotationComposer,
      $$PlannerItemsTableCreateCompanionBuilder,
      $$PlannerItemsTableUpdateCompanionBuilder,
      (
        PlannerItemRow,
        BaseReferences<_$AppDatabase, $PlannerItemsTable, PlannerItemRow>,
      ),
      PlannerItemRow,
      PrefetchHooks Function()
    >;
typedef $$RecurrencesTableCreateCompanionBuilder =
    RecurrencesCompanion Function({
      required String id,
      required String userId,
      required DateTime createdAt,
      required DateTime clientUpdatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<DateTime?> pendingDeleteUntil,
      Value<String?> title,
      Value<String?> subjectId,
      Value<int?> weekdayMask,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<String?> endsOn,
      Value<bool?> active,
      Value<int> rowid,
    });
typedef $$RecurrencesTableUpdateCompanionBuilder =
    RecurrencesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> createdAt,
      Value<DateTime> clientUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<DateTime?> pendingDeleteUntil,
      Value<String?> title,
      Value<String?> subjectId,
      Value<int?> weekdayMask,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<String?> endsOn,
      Value<bool?> active,
      Value<int> rowid,
    });

class $$RecurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get pendingDeleteUntil => $composableBuilder(
    column: $table.pendingDeleteUntil,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekdayMask => $composableBuilder(
    column: $table.weekdayMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingDeleteUntil => $composableBuilder(
    column: $table.pendingDeleteUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekdayMask => $composableBuilder(
    column: $table.weekdayMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, String> get pendingDeleteUntil =>
      $composableBuilder(
        column: $table.pendingDeleteUntil,
        builder: (column) => column,
      );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<int> get weekdayMask => $composableBuilder(
    column: $table.weekdayMask,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get endsOn =>
      $composableBuilder(column: $table.endsOn, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$RecurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurrencesTable,
          RecurrenceRow,
          $$RecurrencesTableFilterComposer,
          $$RecurrencesTableOrderingComposer,
          $$RecurrencesTableAnnotationComposer,
          $$RecurrencesTableCreateCompanionBuilder,
          $$RecurrencesTableUpdateCompanionBuilder,
          (
            RecurrenceRow,
            BaseReferences<_$AppDatabase, $RecurrencesTable, RecurrenceRow>,
          ),
          RecurrenceRow,
          PrefetchHooks Function()
        > {
  $$RecurrencesTableTableManager(_$AppDatabase db, $RecurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<DateTime?> pendingDeleteUntil = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<int?> weekdayMask = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<bool?> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrencesCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                pendingDeleteUntil: pendingDeleteUntil,
                title: title,
                subjectId: subjectId,
                weekdayMask: weekdayMask,
                startTime: startTime,
                endTime: endTime,
                endsOn: endsOn,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<DateTime?> pendingDeleteUntil = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<int?> weekdayMask = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<bool?> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrencesCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                pendingDeleteUntil: pendingDeleteUntil,
                title: title,
                subjectId: subjectId,
                weekdayMask: weekdayMask,
                startTime: startTime,
                endTime: endTime,
                endsOn: endsOn,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurrencesTable, RecurrenceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RecurrencesTable,
                    RecurrenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurrencesTable,
      RecurrenceRow,
      $$RecurrencesTableFilterComposer,
      $$RecurrencesTableOrderingComposer,
      $$RecurrencesTableAnnotationComposer,
      $$RecurrencesTableCreateCompanionBuilder,
      $$RecurrencesTableUpdateCompanionBuilder,
      (
        RecurrenceRow,
        BaseReferences<_$AppDatabase, $RecurrencesTable, RecurrenceRow>,
      ),
      RecurrenceRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingRequestsTableCreateCompanionBuilder =
    ReadingRequestsCompanion Function({
      required String id,
      required String userId,
      required DateTime createdAt,
      required DateTime clientUpdatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      required String requestId,
      Value<String?> subjectId,
      Value<String?> rangeText,
      Value<String?> sessionId,
      Value<String?> plannerItemId,
      Value<ReadingOrigin?> origin,
      Value<String?> payloadHash,
      Value<ReadingRequestStatus?> status,
      Value<DateTime?> submittedAt,
      Value<DateTime?> completedAt,
      Value<String?> quotaMonth,
      Value<bool?> quotaCharged,
      Value<String?> resultJson,
      Value<String?> marksJson,
      Value<String?> failReason,
      Value<String?> confirmedMarksJson,
      Value<int> rowid,
    });
typedef $$ReadingRequestsTableUpdateCompanionBuilder =
    ReadingRequestsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> createdAt,
      Value<DateTime> clientUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<String> requestId,
      Value<String?> subjectId,
      Value<String?> rangeText,
      Value<String?> sessionId,
      Value<String?> plannerItemId,
      Value<ReadingOrigin?> origin,
      Value<String?> payloadHash,
      Value<ReadingRequestStatus?> status,
      Value<DateTime?> submittedAt,
      Value<DateTime?> completedAt,
      Value<String?> quotaMonth,
      Value<bool?> quotaCharged,
      Value<String?> resultJson,
      Value<String?> marksJson,
      Value<String?> failReason,
      Value<String?> confirmedMarksJson,
      Value<int> rowid,
    });

class $$ReadingRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingRequestsTable> {
  $$ReadingRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rangeText => $composableBuilder(
    column: $table.rangeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannerItemId => $composableBuilder(
    column: $table.plannerItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReadingOrigin?, ReadingOrigin, String>
  get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ReadingRequestStatus?,
    ReadingRequestStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get submittedAt =>
      $composableBuilder(
        column: $table.submittedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get quotaMonth => $composableBuilder(
    column: $table.quotaMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quotaCharged => $composableBuilder(
    column: $table.quotaCharged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marksJson => $composableBuilder(
    column: $table.marksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failReason => $composableBuilder(
    column: $table.failReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmedMarksJson => $composableBuilder(
    column: $table.confirmedMarksJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingRequestsTable> {
  $$ReadingRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rangeText => $composableBuilder(
    column: $table.rangeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannerItemId => $composableBuilder(
    column: $table.plannerItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quotaMonth => $composableBuilder(
    column: $table.quotaMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quotaCharged => $composableBuilder(
    column: $table.quotaCharged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marksJson => $composableBuilder(
    column: $table.marksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failReason => $composableBuilder(
    column: $table.failReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedMarksJson => $composableBuilder(
    column: $table.confirmedMarksJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingRequestsTable> {
  $$ReadingRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get rangeText =>
      $composableBuilder(column: $table.rangeText, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get plannerItemId => $composableBuilder(
    column: $table.plannerItemId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReadingOrigin?, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReadingRequestStatus?, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get submittedAt =>
      $composableBuilder(
        column: $table.submittedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get quotaMonth => $composableBuilder(
    column: $table.quotaMonth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quotaCharged => $composableBuilder(
    column: $table.quotaCharged,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marksJson =>
      $composableBuilder(column: $table.marksJson, builder: (column) => column);

  GeneratedColumn<String> get failReason => $composableBuilder(
    column: $table.failReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confirmedMarksJson => $composableBuilder(
    column: $table.confirmedMarksJson,
    builder: (column) => column,
  );
}

class $$ReadingRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingRequestsTable,
          ReadingRequestRow,
          $$ReadingRequestsTableFilterComposer,
          $$ReadingRequestsTableOrderingComposer,
          $$ReadingRequestsTableAnnotationComposer,
          $$ReadingRequestsTableCreateCompanionBuilder,
          $$ReadingRequestsTableUpdateCompanionBuilder,
          (
            ReadingRequestRow,
            BaseReferences<
              _$AppDatabase,
              $ReadingRequestsTable,
              ReadingRequestRow
            >,
          ),
          ReadingRequestRow,
          PrefetchHooks Function()
        > {
  $$ReadingRequestsTableTableManager(
    _$AppDatabase db,
    $ReadingRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<String> requestId = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> rangeText = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> plannerItemId = const Value.absent(),
                Value<ReadingOrigin?> origin = const Value.absent(),
                Value<String?> payloadHash = const Value.absent(),
                Value<ReadingRequestStatus?> status = const Value.absent(),
                Value<DateTime?> submittedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> quotaMonth = const Value.absent(),
                Value<bool?> quotaCharged = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> marksJson = const Value.absent(),
                Value<String?> failReason = const Value.absent(),
                Value<String?> confirmedMarksJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingRequestsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                requestId: requestId,
                subjectId: subjectId,
                rangeText: rangeText,
                sessionId: sessionId,
                plannerItemId: plannerItemId,
                origin: origin,
                payloadHash: payloadHash,
                status: status,
                submittedAt: submittedAt,
                completedAt: completedAt,
                quotaMonth: quotaMonth,
                quotaCharged: quotaCharged,
                resultJson: resultJson,
                marksJson: marksJson,
                failReason: failReason,
                confirmedMarksJson: confirmedMarksJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                required String requestId,
                Value<String?> subjectId = const Value.absent(),
                Value<String?> rangeText = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String?> plannerItemId = const Value.absent(),
                Value<ReadingOrigin?> origin = const Value.absent(),
                Value<String?> payloadHash = const Value.absent(),
                Value<ReadingRequestStatus?> status = const Value.absent(),
                Value<DateTime?> submittedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> quotaMonth = const Value.absent(),
                Value<bool?> quotaCharged = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> marksJson = const Value.absent(),
                Value<String?> failReason = const Value.absent(),
                Value<String?> confirmedMarksJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingRequestsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                requestId: requestId,
                subjectId: subjectId,
                rangeText: rangeText,
                sessionId: sessionId,
                plannerItemId: plannerItemId,
                origin: origin,
                payloadHash: payloadHash,
                status: status,
                submittedAt: submittedAt,
                completedAt: completedAt,
                quotaMonth: quotaMonth,
                quotaCharged: quotaCharged,
                resultJson: resultJson,
                marksJson: marksJson,
                failReason: failReason,
                confirmedMarksJson: confirmedMarksJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingRequestsTable, ReadingRequestRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReadingRequestsTable,
                    ReadingRequestRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingRequestsTable,
      ReadingRequestRow,
      $$ReadingRequestsTableFilterComposer,
      $$ReadingRequestsTableOrderingComposer,
      $$ReadingRequestsTableAnnotationComposer,
      $$ReadingRequestsTableCreateCompanionBuilder,
      $$ReadingRequestsTableUpdateCompanionBuilder,
      (
        ReadingRequestRow,
        BaseReferences<_$AppDatabase, $ReadingRequestsTable, ReadingRequestRow>,
      ),
      ReadingRequestRow,
      PrefetchHooks Function()
    >;
typedef $$WrongItemsTableCreateCompanionBuilder = WrongItemsCompanion Function({
  required String id,
  required String userId,
  required DateTime createdAt,
  required DateTime clientUpdatedAt,
  Value<DateTime?> deletedAt,
  required String deviceId,
  Value<int> clientRev,
  Value<int?> baseServerVersion,
  Value<int?> serverVersion,
  Value<int?> serverSeq,
  Value<int> purgeEpoch,
  required String requestId,
  Value<String?> subjectId,
  Value<String?> rangeText,
  Value<int?> pageIndex,
  Value<int?> number,
  Value<WrongMark?> mark,
  Value<double?> confidence,
  Value<bool?> userConfirmed,
  Value<WrongItemStatus?> status,
  Value<DateTime?> resolvedAt,
  Value<int> rowid,
});
typedef $$WrongItemsTableUpdateCompanionBuilder = WrongItemsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> createdAt,
  Value<DateTime> clientUpdatedAt,
  Value<DateTime?> deletedAt,
  Value<String> deviceId,
  Value<int> clientRev,
  Value<int?> baseServerVersion,
  Value<int?> serverVersion,
  Value<int?> serverSeq,
  Value<int> purgeEpoch,
  Value<String> requestId,
  Value<String?> subjectId,
  Value<String?> rangeText,
  Value<int?> pageIndex,
  Value<int?> number,
  Value<WrongMark?> mark,
  Value<double?> confidence,
  Value<bool?> userConfirmed,
  Value<WrongItemStatus?> status,
  Value<DateTime?> resolvedAt,
  Value<int> rowid,
});

class $$WrongItemsTableFilterComposer
    extends Composer<_$AppDatabase, $WrongItemsTable> {
  $$WrongItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rangeText => $composableBuilder(
    column: $table.rangeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WrongMark?, WrongMark, String> get mark =>
      $composableBuilder(
        column: $table.mark,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userConfirmed => $composableBuilder(
    column: $table.userConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WrongItemStatus?, WrongItemStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get resolvedAt =>
      $composableBuilder(
        column: $table.resolvedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$WrongItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $WrongItemsTable> {
  $$WrongItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rangeText => $composableBuilder(
    column: $table.rangeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mark => $composableBuilder(
    column: $table.mark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userConfirmed => $composableBuilder(
    column: $table.userConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WrongItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WrongItemsTable> {
  $$WrongItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get rangeText =>
      $composableBuilder(column: $table.rangeText, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WrongMark?, String> get mark =>
      $composableBuilder(column: $table.mark, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get userConfirmed => $composableBuilder(
    column: $table.userConfirmed,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WrongItemStatus?, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get resolvedAt =>
      $composableBuilder(
        column: $table.resolvedAt,
        builder: (column) => column,
      );
}

class $$WrongItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WrongItemsTable,
          WrongItemRow,
          $$WrongItemsTableFilterComposer,
          $$WrongItemsTableOrderingComposer,
          $$WrongItemsTableAnnotationComposer,
          $$WrongItemsTableCreateCompanionBuilder,
          $$WrongItemsTableUpdateCompanionBuilder,
          (
            WrongItemRow,
            BaseReferences<_$AppDatabase, $WrongItemsTable, WrongItemRow>,
          ),
          WrongItemRow,
          PrefetchHooks Function()
        > {
  $$WrongItemsTableTableManager(_$AppDatabase db, $WrongItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WrongItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WrongItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WrongItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<String> requestId = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> rangeText = const Value.absent(),
                Value<int?> pageIndex = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<WrongMark?> mark = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<bool?> userConfirmed = const Value.absent(),
                Value<WrongItemStatus?> status = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WrongItemsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                requestId: requestId,
                subjectId: subjectId,
                rangeText: rangeText,
                pageIndex: pageIndex,
                number: number,
                mark: mark,
                confidence: confidence,
                userConfirmed: userConfirmed,
                status: status,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                required String requestId,
                Value<String?> subjectId = const Value.absent(),
                Value<String?> rangeText = const Value.absent(),
                Value<int?> pageIndex = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<WrongMark?> mark = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<bool?> userConfirmed = const Value.absent(),
                Value<WrongItemStatus?> status = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WrongItemsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                requestId: requestId,
                subjectId: subjectId,
                rangeText: rangeText,
                pageIndex: pageIndex,
                number: number,
                mark: mark,
                confidence: confidence,
                userConfirmed: userConfirmed,
                status: status,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WrongItemsTable, WrongItemRow>(table),
                  BaseReferences<_$AppDatabase, $WrongItemsTable, WrongItemRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WrongItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WrongItemsTable,
      WrongItemRow,
      $$WrongItemsTableFilterComposer,
      $$WrongItemsTableOrderingComposer,
      $$WrongItemsTableAnnotationComposer,
      $$WrongItemsTableCreateCompanionBuilder,
      $$WrongItemsTableUpdateCompanionBuilder,
      (
        WrongItemRow,
        BaseReferences<_$AppDatabase, $WrongItemsTable, WrongItemRow>,
      ),
      WrongItemRow,
      PrefetchHooks Function()
    >;
typedef $$ReviewEntriesTableCreateCompanionBuilder =
    ReviewEntriesCompanion Function({
      required String id,
      required String userId,
      required DateTime createdAt,
      required DateTime clientUpdatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      required String wrongItemId,
      Value<DateTime?> dueAt,
      Value<int?> intervalDays,
      Value<int?> consecutiveCorrect,
      Value<RetryResult?> lastResult,
      Value<int> rowid,
    });
typedef $$ReviewEntriesTableUpdateCompanionBuilder =
    ReviewEntriesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> createdAt,
      Value<DateTime> clientUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<String> wrongItemId,
      Value<DateTime?> dueAt,
      Value<int?> intervalDays,
      Value<int?> consecutiveCorrect,
      Value<RetryResult?> lastResult,
      Value<int> rowid,
    });

class $$ReviewEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewEntriesTable> {
  $$ReviewEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wrongItemId => $composableBuilder(
    column: $table.wrongItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get dueAt =>
      $composableBuilder(
        column: $table.dueAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveCorrect => $composableBuilder(
    column: $table.consecutiveCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RetryResult?, RetryResult, String>
  get lastResult => $composableBuilder(
    column: $table.lastResult,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$ReviewEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewEntriesTable> {
  $$ReviewEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wrongItemId => $composableBuilder(
    column: $table.wrongItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveCorrect => $composableBuilder(
    column: $table.consecutiveCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastResult => $composableBuilder(
    column: $table.lastResult,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewEntriesTable> {
  $$ReviewEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wrongItemId => $composableBuilder(
    column: $table.wrongItemId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, String> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consecutiveCorrect => $composableBuilder(
    column: $table.consecutiveCorrect,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RetryResult?, String> get lastResult =>
      $composableBuilder(
        column: $table.lastResult,
        builder: (column) => column,
      );
}

class $$ReviewEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewEntriesTable,
          ReviewEntryRow,
          $$ReviewEntriesTableFilterComposer,
          $$ReviewEntriesTableOrderingComposer,
          $$ReviewEntriesTableAnnotationComposer,
          $$ReviewEntriesTableCreateCompanionBuilder,
          $$ReviewEntriesTableUpdateCompanionBuilder,
          (
            ReviewEntryRow,
            BaseReferences<_$AppDatabase, $ReviewEntriesTable, ReviewEntryRow>,
          ),
          ReviewEntryRow,
          PrefetchHooks Function()
        > {
  $$ReviewEntriesTableTableManager(_$AppDatabase db, $ReviewEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<String> wrongItemId = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<int?> consecutiveCorrect = const Value.absent(),
                Value<RetryResult?> lastResult = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewEntriesCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                wrongItemId: wrongItemId,
                dueAt: dueAt,
                intervalDays: intervalDays,
                consecutiveCorrect: consecutiveCorrect,
                lastResult: lastResult,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                required String wrongItemId,
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<int?> consecutiveCorrect = const Value.absent(),
                Value<RetryResult?> lastResult = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewEntriesCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                wrongItemId: wrongItemId,
                dueAt: dueAt,
                intervalDays: intervalDays,
                consecutiveCorrect: consecutiveCorrect,
                lastResult: lastResult,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewEntriesTable, ReviewEntryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReviewEntriesTable,
                    ReviewEntryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewEntriesTable,
      ReviewEntryRow,
      $$ReviewEntriesTableFilterComposer,
      $$ReviewEntriesTableOrderingComposer,
      $$ReviewEntriesTableAnnotationComposer,
      $$ReviewEntriesTableCreateCompanionBuilder,
      $$ReviewEntriesTableUpdateCompanionBuilder,
      (
        ReviewEntryRow,
        BaseReferences<_$AppDatabase, $ReviewEntriesTable, ReviewEntryRow>,
      ),
      ReviewEntryRow,
      PrefetchHooks Function()
    >;
typedef $$RetryRecordsTableCreateCompanionBuilder =
    RetryRecordsCompanion Function({
      required String id,
      required String userId,
      required DateTime createdAt,
      required DateTime clientUpdatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      required String wrongItemId,
      Value<RetryResult?> result,
      Value<DateTime?> at,
      Value<bool?> voided,
      Value<DateTime?> voidedAt,
      Value<int> rowid,
    });
typedef $$RetryRecordsTableUpdateCompanionBuilder =
    RetryRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> createdAt,
      Value<DateTime> clientUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<String> wrongItemId,
      Value<RetryResult?> result,
      Value<DateTime?> at,
      Value<bool?> voided,
      Value<DateTime?> voidedAt,
      Value<int> rowid,
    });

class $$RetryRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RetryRecordsTable> {
  $$RetryRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wrongItemId => $composableBuilder(
    column: $table.wrongItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RetryResult?, RetryResult, String>
  get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get at =>
      $composableBuilder(
        column: $table.at,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get voidedAt =>
      $composableBuilder(
        column: $table.voidedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$RetryRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RetryRecordsTable> {
  $$RetryRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wrongItemId => $composableBuilder(
    column: $table.wrongItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get voided => $composableBuilder(
    column: $table.voided,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RetryRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RetryRecordsTable> {
  $$RetryRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wrongItemId => $composableBuilder(
    column: $table.wrongItemId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RetryResult?, String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<bool> get voided =>
      $composableBuilder(column: $table.voided, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);
}

class $$RetryRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RetryRecordsTable,
          RetryRecordRow,
          $$RetryRecordsTableFilterComposer,
          $$RetryRecordsTableOrderingComposer,
          $$RetryRecordsTableAnnotationComposer,
          $$RetryRecordsTableCreateCompanionBuilder,
          $$RetryRecordsTableUpdateCompanionBuilder,
          (
            RetryRecordRow,
            BaseReferences<_$AppDatabase, $RetryRecordsTable, RetryRecordRow>,
          ),
          RetryRecordRow,
          PrefetchHooks Function()
        > {
  $$RetryRecordsTableTableManager(_$AppDatabase db, $RetryRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RetryRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RetryRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RetryRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<String> wrongItemId = const Value.absent(),
                Value<RetryResult?> result = const Value.absent(),
                Value<DateTime?> at = const Value.absent(),
                Value<bool?> voided = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RetryRecordsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                wrongItemId: wrongItemId,
                result: result,
                at: at,
                voided: voided,
                voidedAt: voidedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                required String wrongItemId,
                Value<RetryResult?> result = const Value.absent(),
                Value<DateTime?> at = const Value.absent(),
                Value<bool?> voided = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RetryRecordsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                wrongItemId: wrongItemId,
                result: result,
                at: at,
                voided: voided,
                voidedAt: voidedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RetryRecordsTable, RetryRecordRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RetryRecordsTable,
                    RetryRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RetryRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RetryRecordsTable,
      RetryRecordRow,
      $$RetryRecordsTableFilterComposer,
      $$RetryRecordsTableOrderingComposer,
      $$RetryRecordsTableAnnotationComposer,
      $$RetryRecordsTableCreateCompanionBuilder,
      $$RetryRecordsTableUpdateCompanionBuilder,
      (
        RetryRecordRow,
        BaseReferences<_$AppDatabase, $RetryRecordsTable, RetryRecordRow>,
      ),
      RetryRecordRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String id,
  required String userId,
  required DateTime createdAt,
  required DateTime clientUpdatedAt,
  Value<DateTime?> deletedAt,
  required String deviceId,
  Value<int> clientRev,
  Value<int?> baseServerVersion,
  Value<int?> serverVersion,
  Value<int?> serverSeq,
  Value<int> purgeEpoch,
  Value<String?> key,
  Value<String?> valueJson,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> createdAt,
  Value<DateTime> clientUpdatedAt,
  Value<DateTime?> deletedAt,
  Value<String> deviceId,
  Value<int> clientRev,
  Value<int?> baseServerVersion,
  Value<int?> serverVersion,
  Value<int?> serverSeq,
  Value<int> purgeEpoch,
  Value<String?> key,
  Value<String?> valueJson,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<String?> valueJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<String?> valueJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$ActivityDaysTableCreateCompanionBuilder =
    ActivityDaysCompanion Function({
      required String id,
      required String userId,
      required DateTime createdAt,
      required DateTime clientUpdatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      required String date,
      Value<int> rowid,
    });
typedef $$ActivityDaysTableUpdateCompanionBuilder =
    ActivityDaysCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> createdAt,
      Value<DateTime> clientUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> clientRev,
      Value<int?> baseServerVersion,
      Value<int?> serverVersion,
      Value<int?> serverSeq,
      Value<int> purgeEpoch,
      Value<String> date,
      Value<int> rowid,
    });

class $$ActivityDaysTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityDaysTable> {
  $$ActivityDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityDaysTable> {
  $$ActivityDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientRev => $composableBuilder(
    column: $table.clientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityDaysTable> {
  $$ActivityDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get clientUpdatedAt =>
      $composableBuilder(
        column: $table.clientUpdatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientRev =>
      $composableBuilder(column: $table.clientRev, builder: (column) => column);

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<int> get purgeEpoch => $composableBuilder(
    column: $table.purgeEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$ActivityDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityDaysTable,
          ActivityDayRow,
          $$ActivityDaysTableFilterComposer,
          $$ActivityDaysTableOrderingComposer,
          $$ActivityDaysTableAnnotationComposer,
          $$ActivityDaysTableCreateCompanionBuilder,
          $$ActivityDaysTableUpdateCompanionBuilder,
          (
            ActivityDayRow,
            BaseReferences<_$AppDatabase, $ActivityDaysTable, ActivityDayRow>,
          ),
          ActivityDayRow,
          PrefetchHooks Function()
        > {
  $$ActivityDaysTableTableManager(_$AppDatabase db, $ActivityDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityDaysCompanion(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime createdAt,
                required DateTime clientUpdatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> clientRev = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> purgeEpoch = const Value.absent(),
                required String date,
                Value<int> rowid = const Value.absent(),
              }) => ActivityDaysCompanion.insert(
                id: id,
                userId: userId,
                createdAt: createdAt,
                clientUpdatedAt: clientUpdatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                clientRev: clientRev,
                baseServerVersion: baseServerVersion,
                serverVersion: serverVersion,
                serverSeq: serverSeq,
                purgeEpoch: purgeEpoch,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivityDaysTable, ActivityDayRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ActivityDaysTable,
                    ActivityDayRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityDaysTable,
      ActivityDayRow,
      $$ActivityDaysTableFilterComposer,
      $$ActivityDaysTableOrderingComposer,
      $$ActivityDaysTableAnnotationComposer,
      $$ActivityDaysTableCreateCompanionBuilder,
      $$ActivityDaysTableUpdateCompanionBuilder,
      (
        ActivityDayRow,
        BaseReferences<_$AppDatabase, $ActivityDaysTable, ActivityDayRow>,
      ),
      ActivityDayRow,
      PrefetchHooks Function()
    >;
typedef $$SubscriptionStatesTableCreateCompanionBuilder =
    SubscriptionStatesCompanion Function({
      required String userId,
      required String status,
      required bool entitled,
      Value<DateTime?> expiresAt,
      Value<DateTime?> graceExpiresAt,
      Value<String?> periodType,
      required bool willRenew,
      required bool trialUsed,
      required SubscriptionSource source,
      required DateTime lastCheckedAt,
      Value<int> rowid,
    });
typedef $$SubscriptionStatesTableUpdateCompanionBuilder =
    SubscriptionStatesCompanion Function({
      Value<String> userId,
      Value<String> status,
      Value<bool> entitled,
      Value<DateTime?> expiresAt,
      Value<DateTime?> graceExpiresAt,
      Value<String?> periodType,
      Value<bool> willRenew,
      Value<bool> trialUsed,
      Value<SubscriptionSource> source,
      Value<DateTime> lastCheckedAt,
      Value<int> rowid,
    });

class $$SubscriptionStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionStatesTable> {
  $$SubscriptionStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get entitled => $composableBuilder(
    column: $table.entitled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get expiresAt =>
      $composableBuilder(
        column: $table.expiresAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get graceExpiresAt => $composableBuilder(
    column: $table.graceExpiresAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get willRenew => $composableBuilder(
    column: $table.willRenew,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trialUsed => $composableBuilder(
    column: $table.trialUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SubscriptionSource, SubscriptionSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String>
  get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$SubscriptionStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionStatesTable> {
  $$SubscriptionStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get entitled => $composableBuilder(
    column: $table.entitled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get graceExpiresAt => $composableBuilder(
    column: $table.graceExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get willRenew => $composableBuilder(
    column: $table.willRenew,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trialUsed => $composableBuilder(
    column: $table.trialUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionStatesTable> {
  $$SubscriptionStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get entitled =>
      $composableBuilder(column: $table.entitled, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get graceExpiresAt =>
      $composableBuilder(
        column: $table.graceExpiresAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get willRenew =>
      $composableBuilder(column: $table.willRenew, builder: (column) => column);

  GeneratedColumn<bool> get trialUsed =>
      $composableBuilder(column: $table.trialUsed, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SubscriptionSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get lastCheckedAt =>
      $composableBuilder(
        column: $table.lastCheckedAt,
        builder: (column) => column,
      );
}

class $$SubscriptionStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionStatesTable,
          SubscriptionStateRow,
          $$SubscriptionStatesTableFilterComposer,
          $$SubscriptionStatesTableOrderingComposer,
          $$SubscriptionStatesTableAnnotationComposer,
          $$SubscriptionStatesTableCreateCompanionBuilder,
          $$SubscriptionStatesTableUpdateCompanionBuilder,
          (
            SubscriptionStateRow,
            BaseReferences<
              _$AppDatabase,
              $SubscriptionStatesTable,
              SubscriptionStateRow
            >,
          ),
          SubscriptionStateRow,
          PrefetchHooks Function()
        > {
  $$SubscriptionStatesTableTableManager(
    _$AppDatabase db,
    $SubscriptionStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> entitled = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime?> graceExpiresAt = const Value.absent(),
                Value<String?> periodType = const Value.absent(),
                Value<bool> willRenew = const Value.absent(),
                Value<bool> trialUsed = const Value.absent(),
                Value<SubscriptionSource> source = const Value.absent(),
                Value<DateTime> lastCheckedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionStatesCompanion(
                userId: userId,
                status: status,
                entitled: entitled,
                expiresAt: expiresAt,
                graceExpiresAt: graceExpiresAt,
                periodType: periodType,
                willRenew: willRenew,
                trialUsed: trialUsed,
                source: source,
                lastCheckedAt: lastCheckedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String status,
                required bool entitled,
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime?> graceExpiresAt = const Value.absent(),
                Value<String?> periodType = const Value.absent(),
                required bool willRenew,
                required bool trialUsed,
                required SubscriptionSource source,
                required DateTime lastCheckedAt,
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionStatesCompanion.insert(
                userId: userId,
                status: status,
                entitled: entitled,
                expiresAt: expiresAt,
                graceExpiresAt: graceExpiresAt,
                periodType: periodType,
                willRenew: willRenew,
                trialUsed: trialUsed,
                source: source,
                lastCheckedAt: lastCheckedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubscriptionStatesTable, SubscriptionStateRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SubscriptionStatesTable,
                    SubscriptionStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionStatesTable,
      SubscriptionStateRow,
      $$SubscriptionStatesTableFilterComposer,
      $$SubscriptionStatesTableOrderingComposer,
      $$SubscriptionStatesTableAnnotationComposer,
      $$SubscriptionStatesTableCreateCompanionBuilder,
      $$SubscriptionStatesTableUpdateCompanionBuilder,
      (
        SubscriptionStateRow,
        BaseReferences<
          _$AppDatabase,
          $SubscriptionStatesTable,
          SubscriptionStateRow
        >,
      ),
      SubscriptionStateRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingQuotasTableCreateCompanionBuilder =
    ReadingQuotasCompanion Function({
      required String userId,
      required String month,
      required int used,
      required int reserved,
      required int quotaLimit,
      Value<int> rowid,
    });
typedef $$ReadingQuotasTableUpdateCompanionBuilder =
    ReadingQuotasCompanion Function({
      Value<String> userId,
      Value<String> month,
      Value<int> used,
      Value<int> reserved,
      Value<int> quotaLimit,
      Value<int> rowid,
    });

class $$ReadingQuotasTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingQuotasTable> {
  $$ReadingQuotasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reserved => $composableBuilder(
    column: $table.reserved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quotaLimit => $composableBuilder(
    column: $table.quotaLimit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingQuotasTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingQuotasTable> {
  $$ReadingQuotasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reserved => $composableBuilder(
    column: $table.reserved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quotaLimit => $composableBuilder(
    column: $table.quotaLimit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingQuotasTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingQuotasTable> {
  $$ReadingQuotasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get used =>
      $composableBuilder(column: $table.used, builder: (column) => column);

  GeneratedColumn<int> get reserved =>
      $composableBuilder(column: $table.reserved, builder: (column) => column);

  GeneratedColumn<int> get quotaLimit => $composableBuilder(
    column: $table.quotaLimit,
    builder: (column) => column,
  );
}

class $$ReadingQuotasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingQuotasTable,
          ReadingQuotaRow,
          $$ReadingQuotasTableFilterComposer,
          $$ReadingQuotasTableOrderingComposer,
          $$ReadingQuotasTableAnnotationComposer,
          $$ReadingQuotasTableCreateCompanionBuilder,
          $$ReadingQuotasTableUpdateCompanionBuilder,
          (
            ReadingQuotaRow,
            BaseReferences<_$AppDatabase, $ReadingQuotasTable, ReadingQuotaRow>,
          ),
          ReadingQuotaRow,
          PrefetchHooks Function()
        > {
  $$ReadingQuotasTableTableManager(_$AppDatabase db, $ReadingQuotasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingQuotasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingQuotasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingQuotasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<int> used = const Value.absent(),
                Value<int> reserved = const Value.absent(),
                Value<int> quotaLimit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingQuotasCompanion(
                userId: userId,
                month: month,
                used: used,
                reserved: reserved,
                quotaLimit: quotaLimit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String month,
                required int used,
                required int reserved,
                required int quotaLimit,
                Value<int> rowid = const Value.absent(),
              }) => ReadingQuotasCompanion.insert(
                userId: userId,
                month: month,
                used: used,
                reserved: reserved,
                quotaLimit: quotaLimit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingQuotasTable, ReadingQuotaRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReadingQuotasTable,
                    ReadingQuotaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingQuotasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingQuotasTable,
      ReadingQuotaRow,
      $$ReadingQuotasTableFilterComposer,
      $$ReadingQuotasTableOrderingComposer,
      $$ReadingQuotasTableAnnotationComposer,
      $$ReadingQuotasTableCreateCompanionBuilder,
      $$ReadingQuotasTableUpdateCompanionBuilder,
      (
        ReadingQuotaRow,
        BaseReferences<_$AppDatabase, $ReadingQuotasTable, ReadingQuotaRow>,
      ),
      ReadingQuotaRow,
      PrefetchHooks Function()
    >;
typedef $$PhotosTableCreateCompanionBuilder = PhotosCompanion Function({
  required String id,
  required String userId,
  Value<String?> requestId,
  required String localPath,
  required DateTime takenAt,
  required DateTime expiresAt,
  required int width,
  required int height,
  required int pageIndex,
  required DateTime createdAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$PhotosTableUpdateCompanionBuilder = PhotosCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> requestId,
  Value<String> localPath,
  Value<DateTime> takenAt,
  Value<DateTime> expiresAt,
  Value<int> width,
  Value<int> height,
  Value<int> pageIndex,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get takenAt =>
      $composableBuilder(
        column: $table.takenAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get expiresAt =>
      $composableBuilder(
        column: $table.expiresAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          PhotoRow,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (PhotoRow, BaseReferences<_$AppDatabase, $PhotosTable, PhotoRow>),
          PhotoRow,
          PrefetchHooks Function()
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> requestId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> pageIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                userId: userId,
                requestId: requestId,
                localPath: localPath,
                takenAt: takenAt,
                expiresAt: expiresAt,
                width: width,
                height: height,
                pageIndex: pageIndex,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> requestId = const Value.absent(),
                required String localPath,
                required DateTime takenAt,
                required DateTime expiresAt,
                required int width,
                required int height,
                required int pageIndex,
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion.insert(
                id: id,
                userId: userId,
                requestId: requestId,
                localPath: localPath,
                takenAt: takenAt,
                expiresAt: expiresAt,
                width: width,
                height: height,
                pageIndex: pageIndex,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PhotosTable, PhotoRow>(table),
                  BaseReferences<_$AppDatabase, $PhotosTable, PhotoRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      PhotoRow,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (PhotoRow, BaseReferences<_$AppDatabase, $PhotosTable, PhotoRow>),
      PhotoRow,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder = SyncOutboxCompanion Function({
  required String table,
  required String rowId,
  required String mutationId,
  Value<int?> sentClientRev,
  required DateTime queuedAt,
  Value<int> attempts,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncOutboxTableUpdateCompanionBuilder = SyncOutboxCompanion Function({
  Value<String> table,
  Value<String> rowId,
  Value<String> mutationId,
  Value<int?> sentClientRev,
  Value<DateTime> queuedAt,
  Value<int> attempts,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get table => $composableBuilder(
    column: $table.table,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentClientRev => $composableBuilder(
    column: $table.sentClientRev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get queuedAt =>
      $composableBuilder(
        column: $table.queuedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get table => $composableBuilder(
    column: $table.table,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentClientRev => $composableBuilder(
    column: $table.sentClientRev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get table =>
      $composableBuilder(column: $table.table, builder: (column) => column);

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sentClientRev => $composableBuilder(
    column: $table.sentClientRev,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTable,
          SyncOutboxRow,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxRow,
            BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxRow>,
          ),
          SyncOutboxRow,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$AppDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> table = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> mutationId = const Value.absent(),
                Value<int?> sentClientRev = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion(
                table: table,
                rowId: rowId,
                mutationId: mutationId,
                sentClientRev: sentClientRev,
                queuedAt: queuedAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String table,
                required String rowId,
                required String mutationId,
                Value<int?> sentClientRev = const Value.absent(),
                required DateTime queuedAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                table: table,
                rowId: rowId,
                mutationId: mutationId,
                sentClientRev: sentClientRev,
                queuedAt: queuedAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncOutboxTable, SyncOutboxRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncOutboxTable,
                    SyncOutboxRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTable,
      SyncOutboxRow,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxRow,
        BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxRow>,
      ),
      SyncOutboxRow,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaRow,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaRow,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>,
          ),
          SyncMetaRow,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SyncMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetaTable, SyncMetaRow>(table),
                  BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaRow,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (SyncMetaRow, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>),
      SyncMetaRow,
      PrefetchHooks Function()
    >;
typedef $$SyncConflictsTableCreateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<int> id,
      required String table,
      required String rowId,
      required String localJson,
      required String serverJson,
      required ConflictResolution resolvedAs,
      required DateTime at,
    });
typedef $$SyncConflictsTableUpdateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<int> id,
      Value<String> table,
      Value<String> rowId,
      Value<String> localJson,
      Value<String> serverJson,
      Value<ConflictResolution> resolvedAs,
      Value<DateTime> at,
    });

class $$SyncConflictsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableFilterComposer({
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

  ColumnFilters<String> get table => $composableBuilder(
    column: $table.table,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localJson => $composableBuilder(
    column: $table.localJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ConflictResolution, ConflictResolution, String>
  get resolvedAs => $composableBuilder(
    column: $table.resolvedAs,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get at =>
      $composableBuilder(
        column: $table.at,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$SyncConflictsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableOrderingComposer({
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

  ColumnOrderings<String> get table => $composableBuilder(
    column: $table.table,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localJson => $composableBuilder(
    column: $table.localJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedAs => $composableBuilder(
    column: $table.resolvedAs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncConflictsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get table =>
      $composableBuilder(column: $table.table, builder: (column) => column);

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get localJson =>
      $composableBuilder(column: $table.localJson, builder: (column) => column);

  GeneratedColumn<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ConflictResolution, String> get resolvedAs =>
      $composableBuilder(
        column: $table.resolvedAs,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$SyncConflictsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncConflictsTable,
          SyncConflictRow,
          $$SyncConflictsTableFilterComposer,
          $$SyncConflictsTableOrderingComposer,
          $$SyncConflictsTableAnnotationComposer,
          $$SyncConflictsTableCreateCompanionBuilder,
          $$SyncConflictsTableUpdateCompanionBuilder,
          (
            SyncConflictRow,
            BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflictRow>,
          ),
          SyncConflictRow,
          PrefetchHooks Function()
        > {
  $$SyncConflictsTableTableManager(_$AppDatabase db, $SyncConflictsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> table = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> localJson = const Value.absent(),
                Value<String> serverJson = const Value.absent(),
                Value<ConflictResolution> resolvedAs = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => SyncConflictsCompanion(
                id: id,
                table: table,
                rowId: rowId,
                localJson: localJson,
                serverJson: serverJson,
                resolvedAs: resolvedAs,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String table,
                required String rowId,
                required String localJson,
                required String serverJson,
                required ConflictResolution resolvedAs,
                required DateTime at,
              }) => SyncConflictsCompanion.insert(
                id: id,
                table: table,
                rowId: rowId,
                localJson: localJson,
                serverJson: serverJson,
                resolvedAs: resolvedAs,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncConflictsTable, SyncConflictRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncConflictsTable,
                    SyncConflictRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncConflictsTable,
      SyncConflictRow,
      $$SyncConflictsTableFilterComposer,
      $$SyncConflictsTableOrderingComposer,
      $$SyncConflictsTableAnnotationComposer,
      $$SyncConflictsTableCreateCompanionBuilder,
      $$SyncConflictsTableUpdateCompanionBuilder,
      (
        SyncConflictRow,
        BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflictRow>,
      ),
      SyncConflictRow,
      PrefetchHooks Function()
    >;
typedef $$SessionSnapshotsTableCreateCompanionBuilder =
    SessionSnapshotsCompanion Function({
      required String sessionId,
      required SessionMode mode,
      required String segmentsJson,
      required SegmentKind openKind,
      required DateTime openStart,
      Value<DateTime?> lastSeatedAt,
      Value<DateTime?> awayCandidateSince,
      required int sensitivity,
      required DateTime savedAt,
      Value<String?> subjectId,
      Value<String?> plannerItemId,
      required SessionKind kind,
      required DateTime startedAt,
      Value<int> rowid,
    });
typedef $$SessionSnapshotsTableUpdateCompanionBuilder =
    SessionSnapshotsCompanion Function({
      Value<String> sessionId,
      Value<SessionMode> mode,
      Value<String> segmentsJson,
      Value<SegmentKind> openKind,
      Value<DateTime> openStart,
      Value<DateTime?> lastSeatedAt,
      Value<DateTime?> awayCandidateSince,
      Value<int> sensitivity,
      Value<DateTime> savedAt,
      Value<String?> subjectId,
      Value<String?> plannerItemId,
      Value<SessionKind> kind,
      Value<DateTime> startedAt,
      Value<int> rowid,
    });

class $$SessionSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionSnapshotsTable> {
  $$SessionSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionMode, SessionMode, String> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SegmentKind, SegmentKind, String>
  get openKind => $composableBuilder(
    column: $table.openKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get openStart =>
      $composableBuilder(
        column: $table.openStart,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get lastSeatedAt => $composableBuilder(
    column: $table.lastSeatedAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get awayCandidateSince => $composableBuilder(
    column: $table.awayCandidateSince,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get sensitivity => $composableBuilder(
    column: $table.sensitivity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get savedAt =>
      $composableBuilder(
        column: $table.savedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannerItemId => $composableBuilder(
    column: $table.plannerItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionKind, SessionKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$SessionSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionSnapshotsTable> {
  $$SessionSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openKind => $composableBuilder(
    column: $table.openKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openStart => $composableBuilder(
    column: $table.openStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSeatedAt => $composableBuilder(
    column: $table.lastSeatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get awayCandidateSince => $composableBuilder(
    column: $table.awayCandidateSince,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sensitivity => $composableBuilder(
    column: $table.sensitivity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannerItemId => $composableBuilder(
    column: $table.plannerItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionSnapshotsTable> {
  $$SessionSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SegmentKind, String> get openKind =>
      $composableBuilder(column: $table.openKind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get openStart =>
      $composableBuilder(column: $table.openStart, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get lastSeatedAt =>
      $composableBuilder(
        column: $table.lastSeatedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, String> get awayCandidateSince =>
      $composableBuilder(
        column: $table.awayCandidateSince,
        builder: (column) => column,
      );

  GeneratedColumn<int> get sensitivity => $composableBuilder(
    column: $table.sensitivity,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get plannerItemId => $composableBuilder(
    column: $table.plannerItemId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SessionKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);
}

class $$SessionSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionSnapshotsTable,
          SessionSnapshotRow,
          $$SessionSnapshotsTableFilterComposer,
          $$SessionSnapshotsTableOrderingComposer,
          $$SessionSnapshotsTableAnnotationComposer,
          $$SessionSnapshotsTableCreateCompanionBuilder,
          $$SessionSnapshotsTableUpdateCompanionBuilder,
          (
            SessionSnapshotRow,
            BaseReferences<
              _$AppDatabase,
              $SessionSnapshotsTable,
              SessionSnapshotRow
            >,
          ),
          SessionSnapshotRow,
          PrefetchHooks Function()
        > {
  $$SessionSnapshotsTableTableManager(
    _$AppDatabase db,
    $SessionSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<SessionMode> mode = const Value.absent(),
                Value<String> segmentsJson = const Value.absent(),
                Value<SegmentKind> openKind = const Value.absent(),
                Value<DateTime> openStart = const Value.absent(),
                Value<DateTime?> lastSeatedAt = const Value.absent(),
                Value<DateTime?> awayCandidateSince = const Value.absent(),
                Value<int> sensitivity = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> plannerItemId = const Value.absent(),
                Value<SessionKind> kind = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionSnapshotsCompanion(
                sessionId: sessionId,
                mode: mode,
                segmentsJson: segmentsJson,
                openKind: openKind,
                openStart: openStart,
                lastSeatedAt: lastSeatedAt,
                awayCandidateSince: awayCandidateSince,
                sensitivity: sensitivity,
                savedAt: savedAt,
                subjectId: subjectId,
                plannerItemId: plannerItemId,
                kind: kind,
                startedAt: startedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required SessionMode mode,
                required String segmentsJson,
                required SegmentKind openKind,
                required DateTime openStart,
                Value<DateTime?> lastSeatedAt = const Value.absent(),
                Value<DateTime?> awayCandidateSince = const Value.absent(),
                required int sensitivity,
                required DateTime savedAt,
                Value<String?> subjectId = const Value.absent(),
                Value<String?> plannerItemId = const Value.absent(),
                required SessionKind kind,
                required DateTime startedAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionSnapshotsCompanion.insert(
                sessionId: sessionId,
                mode: mode,
                segmentsJson: segmentsJson,
                openKind: openKind,
                openStart: openStart,
                lastSeatedAt: lastSeatedAt,
                awayCandidateSince: awayCandidateSince,
                sensitivity: sensitivity,
                savedAt: savedAt,
                subjectId: subjectId,
                plannerItemId: plannerItemId,
                kind: kind,
                startedAt: startedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionSnapshotsTable, SessionSnapshotRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SessionSnapshotsTable,
                    SessionSnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionSnapshotsTable,
      SessionSnapshotRow,
      $$SessionSnapshotsTableFilterComposer,
      $$SessionSnapshotsTableOrderingComposer,
      $$SessionSnapshotsTableAnnotationComposer,
      $$SessionSnapshotsTableCreateCompanionBuilder,
      $$SessionSnapshotsTableUpdateCompanionBuilder,
      (
        SessionSnapshotRow,
        BaseReferences<
          _$AppDatabase,
          $SessionSnapshotsTable,
          SessionSnapshotRow
        >,
      ),
      SessionSnapshotRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionSegmentsTableTableManager get sessionSegments =>
      $$SessionSegmentsTableTableManager(_db, _db.sessionSegments);
  $$CorrectionsTableTableManager get corrections =>
      $$CorrectionsTableTableManager(_db, _db.corrections);
  $$PlannerItemsTableTableManager get plannerItems =>
      $$PlannerItemsTableTableManager(_db, _db.plannerItems);
  $$RecurrencesTableTableManager get recurrences =>
      $$RecurrencesTableTableManager(_db, _db.recurrences);
  $$ReadingRequestsTableTableManager get readingRequests =>
      $$ReadingRequestsTableTableManager(_db, _db.readingRequests);
  $$WrongItemsTableTableManager get wrongItems =>
      $$WrongItemsTableTableManager(_db, _db.wrongItems);
  $$ReviewEntriesTableTableManager get reviewEntries =>
      $$ReviewEntriesTableTableManager(_db, _db.reviewEntries);
  $$RetryRecordsTableTableManager get retryRecords =>
      $$RetryRecordsTableTableManager(_db, _db.retryRecords);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$ActivityDaysTableTableManager get activityDays =>
      $$ActivityDaysTableTableManager(_db, _db.activityDays);
  $$SubscriptionStatesTableTableManager get subscriptionStates =>
      $$SubscriptionStatesTableTableManager(_db, _db.subscriptionStates);
  $$ReadingQuotasTableTableManager get readingQuotas =>
      $$ReadingQuotasTableTableManager(_db, _db.readingQuotas);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$SyncConflictsTableTableManager get syncConflicts =>
      $$SyncConflictsTableTableManager(_db, _db.syncConflicts);
  $$SessionSnapshotsTableTableManager get sessionSnapshots =>
      $$SessionSnapshotsTableTableManager(_db, _db.sessionSnapshots);
}
