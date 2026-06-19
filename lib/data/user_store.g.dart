// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_store.dart';

// ignore_for_file: type=lint
class $HighlightsTable extends Highlights
    with TableInfo<$HighlightsTable, Highlight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseMeta = const VerificationMeta('verse');
  @override
  late final GeneratedColumn<int> verse = GeneratedColumn<int>(
    'verse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    verse,
    colorHex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'highlights';
  @override
  VerificationContext validateIntegrity(
    Insertable<Highlight> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('verse')) {
      context.handle(
        _verseMeta,
        verse.isAcceptableOrUnknown(data['verse']!, _verseMeta),
      );
    } else if (isInserting) {
      context.missing(_verseMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Highlight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Highlight(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      verse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
    );
  }

  @override
  $HighlightsTable createAlias(String alias) {
    return $HighlightsTable(attachedDatabase, alias);
  }
}

class Highlight extends DataClass implements Insertable<Highlight> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String bookName;
  final int chapter;
  final int verse;
  final String colorHex;
  const Highlight({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.colorHex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['book_name'] = Variable<String>(bookName);
    map['chapter'] = Variable<int>(chapter);
    map['verse'] = Variable<int>(verse);
    map['color_hex'] = Variable<String>(colorHex);
    return map;
  }

  HighlightsCompanion toCompanion(bool nullToAbsent) {
    return HighlightsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      bookName: Value(bookName),
      chapter: Value(chapter),
      verse: Value(verse),
      colorHex: Value(colorHex),
    );
  }

  factory Highlight.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Highlight(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      bookName: serializer.fromJson<String>(json['bookName']),
      chapter: serializer.fromJson<int>(json['chapter']),
      verse: serializer.fromJson<int>(json['verse']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'bookName': serializer.toJson<String>(bookName),
      'chapter': serializer.toJson<int>(chapter),
      'verse': serializer.toJson<int>(verse),
      'colorHex': serializer.toJson<String>(colorHex),
    };
  }

  Highlight copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? bookName,
    int? chapter,
    int? verse,
    String? colorHex,
  }) => Highlight(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    bookName: bookName ?? this.bookName,
    chapter: chapter ?? this.chapter,
    verse: verse ?? this.verse,
    colorHex: colorHex ?? this.colorHex,
  );
  Highlight copyWithCompanion(HighlightsCompanion data) {
    return Highlight(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verse: data.verse.present ? data.verse.value : this.verse,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Highlight(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('colorHex: $colorHex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    verse,
    colorHex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Highlight &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.bookName == this.bookName &&
          other.chapter == this.chapter &&
          other.verse == this.verse &&
          other.colorHex == this.colorHex);
}

class HighlightsCompanion extends UpdateCompanion<Highlight> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> bookName;
  final Value<int> chapter;
  final Value<int> verse;
  final Value<String> colorHex;
  final Value<int> rowid;
  const HighlightsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.bookName = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verse = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HighlightsCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String bookName,
    required int chapter,
    required int verse,
    required String colorHex,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       bookName = Value(bookName),
       chapter = Value(chapter),
       verse = Value(verse),
       colorHex = Value(colorHex);
  static Insertable<Highlight> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? bookName,
    Expression<int>? chapter,
    Expression<int>? verse,
    Expression<String>? colorHex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (bookName != null) 'book_name': bookName,
      if (chapter != null) 'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (colorHex != null) 'color_hex': colorHex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HighlightsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? bookName,
    Value<int>? chapter,
    Value<int>? verse,
    Value<String>? colorHex,
    Value<int>? rowid,
  }) {
    return HighlightsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      colorHex: colorHex ?? this.colorHex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verse.present) {
      map['verse'] = Variable<int>(verse.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HighlightsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('colorHex: $colorHex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseMeta = const VerificationMeta('verse');
  @override
  late final GeneratedColumn<int> verse = GeneratedColumn<int>(
    'verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    verse,
    content,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('verse')) {
      context.handle(
        _verseMeta,
        verse.isAcceptableOrUnknown(data['verse']!, _verseMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      verse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String bookName;
  final int chapter;
  final int? verse;
  final String content;
  const Note({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.bookName,
    required this.chapter,
    this.verse,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['book_name'] = Variable<String>(bookName);
    map['chapter'] = Variable<int>(chapter);
    if (!nullToAbsent || verse != null) {
      map['verse'] = Variable<int>(verse);
    }
    map['content'] = Variable<String>(content);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      bookName: Value(bookName),
      chapter: Value(chapter),
      verse: verse == null && nullToAbsent
          ? const Value.absent()
          : Value(verse),
      content: Value(content),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      bookName: serializer.fromJson<String>(json['bookName']),
      chapter: serializer.fromJson<int>(json['chapter']),
      verse: serializer.fromJson<int?>(json['verse']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'bookName': serializer.toJson<String>(bookName),
      'chapter': serializer.toJson<int>(chapter),
      'verse': serializer.toJson<int?>(verse),
      'content': serializer.toJson<String>(content),
    };
  }

  Note copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? bookName,
    int? chapter,
    Value<int?> verse = const Value.absent(),
    String? content,
  }) => Note(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    bookName: bookName ?? this.bookName,
    chapter: chapter ?? this.chapter,
    verse: verse.present ? verse.value : this.verse,
    content: content ?? this.content,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verse: data.verse.present ? data.verse.value : this.verse,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    verse,
    content,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.bookName == this.bookName &&
          other.chapter == this.chapter &&
          other.verse == this.verse &&
          other.content == this.content);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> bookName;
  final Value<int> chapter;
  final Value<int?> verse;
  final Value<String> content;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.bookName = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verse = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String bookName,
    required int chapter,
    this.verse = const Value.absent(),
    required String content,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       bookName = Value(bookName),
       chapter = Value(chapter),
       content = Value(content);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? bookName,
    Expression<int>? chapter,
    Expression<int>? verse,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (bookName != null) 'book_name': bookName,
      if (chapter != null) 'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? bookName,
    Value<int>? chapter,
    Value<int?>? verse,
    Value<String>? content,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verse.present) {
      map['verse'] = Variable<int>(verse.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseMeta = const VerificationMeta('verse');
  @override
  late final GeneratedColumn<int> verse = GeneratedColumn<int>(
    'verse',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    verse,
    label,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('verse')) {
      context.handle(
        _verseMeta,
        verse.isAcceptableOrUnknown(data['verse']!, _verseMeta),
      );
    } else if (isInserting) {
      context.missing(_verseMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      verse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String bookName;
  final int chapter;
  final int verse;
  final String label;
  const Bookmark({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['book_name'] = Variable<String>(bookName);
    map['chapter'] = Variable<int>(chapter);
    map['verse'] = Variable<int>(verse);
    map['label'] = Variable<String>(label);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      bookName: Value(bookName),
      chapter: Value(chapter),
      verse: Value(verse),
      label: Value(label),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      bookName: serializer.fromJson<String>(json['bookName']),
      chapter: serializer.fromJson<int>(json['chapter']),
      verse: serializer.fromJson<int>(json['verse']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'bookName': serializer.toJson<String>(bookName),
      'chapter': serializer.toJson<int>(chapter),
      'verse': serializer.toJson<int>(verse),
      'label': serializer.toJson<String>(label),
    };
  }

  Bookmark copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? bookName,
    int? chapter,
    int? verse,
    String? label,
  }) => Bookmark(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    bookName: bookName ?? this.bookName,
    chapter: chapter ?? this.chapter,
    verse: verse ?? this.verse,
    label: label ?? this.label,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verse: data.verse.present ? data.verse.value : this.verse,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    verse,
    label,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.bookName == this.bookName &&
          other.chapter == this.chapter &&
          other.verse == this.verse &&
          other.label == this.label);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> bookName;
  final Value<int> chapter;
  final Value<int> verse;
  final Value<String> label;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.bookName = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verse = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String bookName,
    required int chapter,
    required int verse,
    required String label,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       bookName = Value(bookName),
       chapter = Value(chapter),
       verse = Value(verse),
       label = Value(label);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? bookName,
    Expression<int>? chapter,
    Expression<int>? verse,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (bookName != null) 'book_name': bookName,
      if (chapter != null) 'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? bookName,
    Value<int>? chapter,
    Value<int>? verse,
    Value<String>? label,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verse.present) {
      map['verse'] = Variable<int>(verse.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalsTable extends Journals with TableInfo<$JournalsTable, Journal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    title,
    content,
    tags,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Journal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Journal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Journal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
    );
  }

  @override
  $JournalsTable createAlias(String alias) {
    return $JournalsTable(attachedDatabase, alias);
  }
}

class Journal extends DataClass implements Insertable<Journal> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String title;
  final String content;
  final String? tags;
  const Journal({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.title,
    required this.content,
    this.tags,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    return map;
  }

  JournalsCompanion toCompanion(bool nullToAbsent) {
    return JournalsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      title: Value(title),
      content: Value(content),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
    );
  }

  factory Journal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Journal(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      tags: serializer.fromJson<String?>(json['tags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'tags': serializer.toJson<String?>(tags),
    };
  }

  Journal copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? title,
    String? content,
    Value<String?> tags = const Value.absent(),
  }) => Journal(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    title: title ?? this.title,
    content: content ?? this.content,
    tags: tags.present ? tags.value : this.tags,
  );
  Journal copyWithCompanion(JournalsCompanion data) {
    return Journal(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      tags: data.tags.present ? data.tags.value : this.tags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Journal(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deviceId, deleted, title, content, tags);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Journal &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.title == this.title &&
          other.content == this.content &&
          other.tags == this.tags);
}

class JournalsCompanion extends UpdateCompanion<Journal> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> title;
  final Value<String> content;
  final Value<String?> tags;
  final Value<int> rowid;
  const JournalsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalsCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String title,
    required String content,
    this.tags = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       title = Value(title),
       content = Value(content);
  static Insertable<Journal> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? tags,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? title,
    Value<String>? content,
    Value<String?>? tags,
    Value<int>? rowid,
  }) {
    return JournalsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrayersTable extends Prayers with TableInfo<$PrayersTable, Prayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<int> answeredAt = GeneratedColumn<int>(
    'answered_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    name,
    description,
    createdAt,
    answeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
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
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prayer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}answered_at'],
      ),
    );
  }

  @override
  $PrayersTable createAlias(String alias) {
    return $PrayersTable(attachedDatabase, alias);
  }
}

class Prayer extends DataClass implements Insertable<Prayer> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String name;
  final String description;
  final int createdAt;
  final int? answeredAt;
  const Prayer({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.name,
    required this.description,
    required this.createdAt,
    this.answeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || answeredAt != null) {
      map['answered_at'] = Variable<int>(answeredAt);
    }
    return map;
  }

  PrayersCompanion toCompanion(bool nullToAbsent) {
    return PrayersCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
      answeredAt: answeredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(answeredAt),
    );
  }

  factory Prayer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prayer(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      answeredAt: serializer.fromJson<int?>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<int>(createdAt),
      'answeredAt': serializer.toJson<int?>(answeredAt),
    };
  }

  Prayer copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? name,
    String? description,
    int? createdAt,
    Value<int?> answeredAt = const Value.absent(),
  }) => Prayer(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    answeredAt: answeredAt.present ? answeredAt.value : this.answeredAt,
  );
  Prayer copyWithCompanion(PrayersCompanion data) {
    return Prayer(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prayer(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    name,
    description,
    createdAt,
    answeredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prayer &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.answeredAt == this.answeredAt);
}

class PrayersCompanion extends UpdateCompanion<Prayer> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String> description;
  final Value<int> createdAt;
  final Value<int?> answeredAt;
  final Value<int> rowid;
  const PrayersCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrayersCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String name,
    required String description,
    required int createdAt,
    this.answeredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       name = Value(name),
       description = Value(description),
       createdAt = Value(createdAt);
  static Insertable<Prayer> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? answeredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrayersCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String>? description,
    Value<int>? createdAt,
    Value<int?>? answeredAt,
    Value<int>? rowid,
  }) {
    return PrayersCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<int>(answeredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayersCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingProgressesTable extends ReadingProgresses
    with TableInfo<$ReadingProgressesTable, ReadingProgress> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<int> readAt = GeneratedColumn<int>(
    'read_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iterationMeta = const VerificationMeta(
    'iteration',
  );
  @override
  late final GeneratedColumn<int> iteration = GeneratedColumn<int>(
    'iteration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    readAt,
    iteration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progresses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgress> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    } else if (isInserting) {
      context.missing(_readAtMeta);
    }
    if (data.containsKey('iteration')) {
      context.handle(
        _iterationMeta,
        iteration.isAcceptableOrUnknown(data['iteration']!, _iterationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingProgress map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgress(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_at'],
      )!,
      iteration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}iteration'],
      )!,
    );
  }

  @override
  $ReadingProgressesTable createAlias(String alias) {
    return $ReadingProgressesTable(attachedDatabase, alias);
  }
}

class ReadingProgress extends DataClass implements Insertable<ReadingProgress> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String bookName;
  final int chapter;
  final int readAt;
  final int iteration;
  const ReadingProgress({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.bookName,
    required this.chapter,
    required this.readAt,
    required this.iteration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['book_name'] = Variable<String>(bookName);
    map['chapter'] = Variable<int>(chapter);
    map['read_at'] = Variable<int>(readAt);
    map['iteration'] = Variable<int>(iteration);
    return map;
  }

  ReadingProgressesCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      bookName: Value(bookName),
      chapter: Value(chapter),
      readAt: Value(readAt),
      iteration: Value(iteration),
    );
  }

  factory ReadingProgress.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgress(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      bookName: serializer.fromJson<String>(json['bookName']),
      chapter: serializer.fromJson<int>(json['chapter']),
      readAt: serializer.fromJson<int>(json['readAt']),
      iteration: serializer.fromJson<int>(json['iteration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'bookName': serializer.toJson<String>(bookName),
      'chapter': serializer.toJson<int>(chapter),
      'readAt': serializer.toJson<int>(readAt),
      'iteration': serializer.toJson<int>(iteration),
    };
  }

  ReadingProgress copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? bookName,
    int? chapter,
    int? readAt,
    int? iteration,
  }) => ReadingProgress(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    bookName: bookName ?? this.bookName,
    chapter: chapter ?? this.chapter,
    readAt: readAt ?? this.readAt,
    iteration: iteration ?? this.iteration,
  );
  ReadingProgress copyWithCompanion(ReadingProgressesCompanion data) {
    return ReadingProgress(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      iteration: data.iteration.present ? data.iteration.value : this.iteration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgress(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('readAt: $readAt, ')
          ..write('iteration: $iteration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    readAt,
    iteration,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgress &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.bookName == this.bookName &&
          other.chapter == this.chapter &&
          other.readAt == this.readAt &&
          other.iteration == this.iteration);
}

class ReadingProgressesCompanion extends UpdateCompanion<ReadingProgress> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> bookName;
  final Value<int> chapter;
  final Value<int> readAt;
  final Value<int> iteration;
  final Value<int> rowid;
  const ReadingProgressesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.bookName = const Value.absent(),
    this.chapter = const Value.absent(),
    this.readAt = const Value.absent(),
    this.iteration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingProgressesCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String bookName,
    required int chapter,
    required int readAt,
    this.iteration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       bookName = Value(bookName),
       chapter = Value(chapter),
       readAt = Value(readAt);
  static Insertable<ReadingProgress> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? bookName,
    Expression<int>? chapter,
    Expression<int>? readAt,
    Expression<int>? iteration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (bookName != null) 'book_name': bookName,
      if (chapter != null) 'chapter': chapter,
      if (readAt != null) 'read_at': readAt,
      if (iteration != null) 'iteration': iteration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingProgressesCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? bookName,
    Value<int>? chapter,
    Value<int>? readAt,
    Value<int>? iteration,
    Value<int>? rowid,
  }) {
    return ReadingProgressesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      readAt: readAt ?? this.readAt,
      iteration: iteration ?? this.iteration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<int>(readAt.value);
    }
    if (iteration.present) {
      map['iteration'] = Variable<int>(iteration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('readAt: $readAt, ')
          ..write('iteration: $iteration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimeTrackersTable extends TimeTrackers
    with TableInfo<$TimeTrackersTable, TimeTracker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeTrackersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    startTime,
    endTime,
    durationMs,
    activityType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_trackers';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimeTracker> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeTracker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeTracker(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_time'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      )!,
    );
  }

  @override
  $TimeTrackersTable createAlias(String alias) {
    return $TimeTrackersTable(attachedDatabase, alias);
  }
}

class TimeTracker extends DataClass implements Insertable<TimeTracker> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final int startTime;
  final int endTime;
  final int durationMs;
  final String activityType;
  const TimeTracker({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.startTime,
    required this.endTime,
    required this.durationMs,
    required this.activityType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    map['duration_ms'] = Variable<int>(durationMs);
    map['activity_type'] = Variable<String>(activityType);
    return map;
  }

  TimeTrackersCompanion toCompanion(bool nullToAbsent) {
    return TimeTrackersCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      startTime: Value(startTime),
      endTime: Value(endTime),
      durationMs: Value(durationMs),
      activityType: Value(activityType),
    );
  }

  factory TimeTracker.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeTracker(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      activityType: serializer.fromJson<String>(json['activityType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
      'durationMs': serializer.toJson<int>(durationMs),
      'activityType': serializer.toJson<String>(activityType),
    };
  }

  TimeTracker copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    int? startTime,
    int? endTime,
    int? durationMs,
    String? activityType,
  }) => TimeTracker(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    durationMs: durationMs ?? this.durationMs,
    activityType: activityType ?? this.activityType,
  );
  TimeTracker copyWithCompanion(TimeTrackersCompanion data) {
    return TimeTracker(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeTracker(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationMs: $durationMs, ')
          ..write('activityType: $activityType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    startTime,
    endTime,
    durationMs,
    activityType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeTracker &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationMs == this.durationMs &&
          other.activityType == this.activityType);
}

class TimeTrackersCompanion extends UpdateCompanion<TimeTracker> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<int> startTime;
  final Value<int> endTime;
  final Value<int> durationMs;
  final Value<String> activityType;
  final Value<int> rowid;
  const TimeTrackersCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.activityType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimeTrackersCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required int startTime,
    required int endTime,
    required int durationMs,
    required String activityType,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       startTime = Value(startTime),
       endTime = Value(endTime),
       durationMs = Value(durationMs),
       activityType = Value(activityType);
  static Insertable<TimeTracker> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<int>? durationMs,
    Expression<String>? activityType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationMs != null) 'duration_ms': durationMs,
      if (activityType != null) 'activity_type': activityType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimeTrackersCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<int>? startTime,
    Value<int>? endTime,
    Value<int>? durationMs,
    Value<String>? activityType,
    Value<int>? rowid,
  }) {
    return TimeTrackersCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMs: durationMs ?? this.durationMs,
      activityType: activityType ?? this.activityType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeTrackersCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationMs: $durationMs, ')
          ..write('activityType: $activityType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<int> unlockedAt = GeneratedColumn<int>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    unlockedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Achievement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unlocked_at'],
      )!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final int unlockedAt;
  const Achievement({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.unlockedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['unlocked_at'] = Variable<int>(unlockedAt);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      unlockedAt: Value(unlockedAt),
    );
  }

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      unlockedAt: serializer.fromJson<int>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'unlockedAt': serializer.toJson<int>(unlockedAt),
    };
  }

  Achievement copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    int? unlockedAt,
  }) => Achievement(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, deviceId, deleted, unlockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.unlockedAt == this.unlockedAt);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<int> unlockedAt;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required int unlockedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       unlockedAt = Value(unlockedAt);
  static Insertable<Achievement> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<int>? unlockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<int>? unlockedAt,
    Value<int>? rowid,
  }) {
    return AchievementsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<int>(unlockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NavigationHistoriesTable extends NavigationHistories
    with TableInfo<$NavigationHistoriesTable, NavigationHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NavigationHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseMeta = const VerificationMeta('verse');
  @override
  late final GeneratedColumn<int> verse = GeneratedColumn<int>(
    'verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verseTextMeta = const VerificationMeta(
    'verseText',
  );
  @override
  late final GeneratedColumn<String> verseText = GeneratedColumn<String>(
    'verse_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    verse,
    verseText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'navigation_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<NavigationHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('verse')) {
      context.handle(
        _verseMeta,
        verse.isAcceptableOrUnknown(data['verse']!, _verseMeta),
      );
    }
    if (data.containsKey('verse_text')) {
      context.handle(
        _verseTextMeta,
        verseText.isAcceptableOrUnknown(data['verse_text']!, _verseTextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NavigationHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NavigationHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      verse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verse'],
      ),
      verseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_text'],
      ),
    );
  }

  @override
  $NavigationHistoriesTable createAlias(String alias) {
    return $NavigationHistoriesTable(attachedDatabase, alias);
  }
}

class NavigationHistory extends DataClass
    implements Insertable<NavigationHistory> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String bookName;
  final int chapter;
  final int? verse;
  final String? verseText;
  const NavigationHistory({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.bookName,
    required this.chapter,
    this.verse,
    this.verseText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['book_name'] = Variable<String>(bookName);
    map['chapter'] = Variable<int>(chapter);
    if (!nullToAbsent || verse != null) {
      map['verse'] = Variable<int>(verse);
    }
    if (!nullToAbsent || verseText != null) {
      map['verse_text'] = Variable<String>(verseText);
    }
    return map;
  }

  NavigationHistoriesCompanion toCompanion(bool nullToAbsent) {
    return NavigationHistoriesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      bookName: Value(bookName),
      chapter: Value(chapter),
      verse: verse == null && nullToAbsent
          ? const Value.absent()
          : Value(verse),
      verseText: verseText == null && nullToAbsent
          ? const Value.absent()
          : Value(verseText),
    );
  }

  factory NavigationHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NavigationHistory(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      bookName: serializer.fromJson<String>(json['bookName']),
      chapter: serializer.fromJson<int>(json['chapter']),
      verse: serializer.fromJson<int?>(json['verse']),
      verseText: serializer.fromJson<String?>(json['verseText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'bookName': serializer.toJson<String>(bookName),
      'chapter': serializer.toJson<int>(chapter),
      'verse': serializer.toJson<int?>(verse),
      'verseText': serializer.toJson<String?>(verseText),
    };
  }

  NavigationHistory copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? bookName,
    int? chapter,
    Value<int?> verse = const Value.absent(),
    Value<String?> verseText = const Value.absent(),
  }) => NavigationHistory(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    bookName: bookName ?? this.bookName,
    chapter: chapter ?? this.chapter,
    verse: verse.present ? verse.value : this.verse,
    verseText: verseText.present ? verseText.value : this.verseText,
  );
  NavigationHistory copyWithCompanion(NavigationHistoriesCompanion data) {
    return NavigationHistory(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      verse: data.verse.present ? data.verse.value : this.verse,
      verseText: data.verseText.present ? data.verseText.value : this.verseText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NavigationHistory(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('verseText: $verseText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    bookName,
    chapter,
    verse,
    verseText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NavigationHistory &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.bookName == this.bookName &&
          other.chapter == this.chapter &&
          other.verse == this.verse &&
          other.verseText == this.verseText);
}

class NavigationHistoriesCompanion extends UpdateCompanion<NavigationHistory> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> bookName;
  final Value<int> chapter;
  final Value<int?> verse;
  final Value<String?> verseText;
  final Value<int> rowid;
  const NavigationHistoriesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.bookName = const Value.absent(),
    this.chapter = const Value.absent(),
    this.verse = const Value.absent(),
    this.verseText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NavigationHistoriesCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String bookName,
    required int chapter,
    this.verse = const Value.absent(),
    this.verseText = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       bookName = Value(bookName),
       chapter = Value(chapter);
  static Insertable<NavigationHistory> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? bookName,
    Expression<int>? chapter,
    Expression<int>? verse,
    Expression<String>? verseText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (bookName != null) 'book_name': bookName,
      if (chapter != null) 'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (verseText != null) 'verse_text': verseText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NavigationHistoriesCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? bookName,
    Value<int>? chapter,
    Value<int?>? verse,
    Value<String?>? verseText,
    Value<int>? rowid,
  }) {
    return NavigationHistoriesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      verseText: verseText ?? this.verseText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (verse.present) {
      map['verse'] = Variable<int>(verse.value);
    }
    if (verseText.present) {
      map['verse_text'] = Variable<String>(verseText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NavigationHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('bookName: $bookName, ')
          ..write('chapter: $chapter, ')
          ..write('verse: $verse, ')
          ..write('verseText: $verseText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingPlansTable extends ReadingPlans
    with TableInfo<$ReadingPlansTable, ReadingPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
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
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetEndDateMeta = const VerificationMeta(
    'targetEndDate',
  );
  @override
  late final GeneratedColumn<int> targetEndDate = GeneratedColumn<int>(
    'target_end_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    title,
    description,
    startDate,
    targetEndDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
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
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('target_end_date')) {
      context.handle(
        _targetEndDateMeta,
        targetEndDate.isAcceptableOrUnknown(
          data['target_end_date']!,
          _targetEndDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      )!,
      targetEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_end_date'],
      ),
    );
  }

  @override
  $ReadingPlansTable createAlias(String alias) {
    return $ReadingPlansTable(attachedDatabase, alias);
  }
}

class ReadingPlan extends DataClass implements Insertable<ReadingPlan> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String title;
  final String? description;
  final int startDate;
  final int? targetEndDate;
  const ReadingPlan({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.title,
    this.description,
    required this.startDate,
    this.targetEndDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_date'] = Variable<int>(startDate);
    if (!nullToAbsent || targetEndDate != null) {
      map['target_end_date'] = Variable<int>(targetEndDate);
    }
    return map;
  }

  ReadingPlansCompanion toCompanion(bool nullToAbsent) {
    return ReadingPlansCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startDate: Value(startDate),
      targetEndDate: targetEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetEndDate),
    );
  }

  factory ReadingPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingPlan(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startDate: serializer.fromJson<int>(json['startDate']),
      targetEndDate: serializer.fromJson<int?>(json['targetEndDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startDate': serializer.toJson<int>(startDate),
      'targetEndDate': serializer.toJson<int?>(targetEndDate),
    };
  }

  ReadingPlan copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? title,
    Value<String?> description = const Value.absent(),
    int? startDate,
    Value<int?> targetEndDate = const Value.absent(),
  }) => ReadingPlan(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    startDate: startDate ?? this.startDate,
    targetEndDate: targetEndDate.present
        ? targetEndDate.value
        : this.targetEndDate,
  );
  ReadingPlan copyWithCompanion(ReadingPlansCompanion data) {
    return ReadingPlan(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      targetEndDate: data.targetEndDate.present
          ? data.targetEndDate.value
          : this.targetEndDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPlan(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startDate: $startDate, ')
          ..write('targetEndDate: $targetEndDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    title,
    description,
    startDate,
    targetEndDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingPlan &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.title == this.title &&
          other.description == this.description &&
          other.startDate == this.startDate &&
          other.targetEndDate == this.targetEndDate);
}

class ReadingPlansCompanion extends UpdateCompanion<ReadingPlan> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> startDate;
  final Value<int?> targetEndDate;
  final Value<int> rowid;
  const ReadingPlansCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startDate = const Value.absent(),
    this.targetEndDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingPlansCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required int startDate,
    this.targetEndDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       title = Value(title),
       startDate = Value(startDate);
  static Insertable<ReadingPlan> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? startDate,
    Expression<int>? targetEndDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'start_date': startDate,
      if (targetEndDate != null) 'target_end_date': targetEndDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingPlansCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? startDate,
    Value<int?>? targetEndDate,
    Value<int>? rowid,
  }) {
    return ReadingPlansCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      targetEndDate: targetEndDate ?? this.targetEndDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (targetEndDate.present) {
      map['target_end_date'] = Variable<int>(targetEndDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPlansCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startDate: $startDate, ')
          ..write('targetEndDate: $targetEndDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingPlanDaysTable extends ReadingPlanDays
    with TableInfo<$ReadingPlanDaysTable, ReadingPlanDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingPlanDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta(
    'dayNumber',
  );
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    planId,
    dayNumber,
    date,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_plan_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingPlanDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(
        _dayNumberMeta,
        dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingPlanDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingPlanDay(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      dayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_number'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $ReadingPlanDaysTable createAlias(String alias) {
    return $ReadingPlanDaysTable(attachedDatabase, alias);
  }
}

class ReadingPlanDay extends DataClass implements Insertable<ReadingPlanDay> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String planId;
  final int dayNumber;
  final int? date;
  final bool completed;
  const ReadingPlanDay({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.planId,
    required this.dayNumber,
    this.date,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['plan_id'] = Variable<String>(planId);
    map['day_number'] = Variable<int>(dayNumber);
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<int>(date);
    }
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  ReadingPlanDaysCompanion toCompanion(bool nullToAbsent) {
    return ReadingPlanDaysCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      planId: Value(planId),
      dayNumber: Value(dayNumber),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      completed: Value(completed),
    );
  }

  factory ReadingPlanDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingPlanDay(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      planId: serializer.fromJson<String>(json['planId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      date: serializer.fromJson<int?>(json['date']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'planId': serializer.toJson<String>(planId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'date': serializer.toJson<int?>(date),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  ReadingPlanDay copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? planId,
    int? dayNumber,
    Value<int?> date = const Value.absent(),
    bool? completed,
  }) => ReadingPlanDay(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    planId: planId ?? this.planId,
    dayNumber: dayNumber ?? this.dayNumber,
    date: date.present ? date.value : this.date,
    completed: completed ?? this.completed,
  );
  ReadingPlanDay copyWithCompanion(ReadingPlanDaysCompanion data) {
    return ReadingPlanDay(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      planId: data.planId.present ? data.planId.value : this.planId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      date: data.date.present ? data.date.value : this.date,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPlanDay(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('planId: $planId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('date: $date, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    planId,
    dayNumber,
    date,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingPlanDay &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.planId == this.planId &&
          other.dayNumber == this.dayNumber &&
          other.date == this.date &&
          other.completed == this.completed);
}

class ReadingPlanDaysCompanion extends UpdateCompanion<ReadingPlanDay> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> planId;
  final Value<int> dayNumber;
  final Value<int?> date;
  final Value<bool> completed;
  final Value<int> rowid;
  const ReadingPlanDaysCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.planId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.date = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingPlanDaysCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String planId,
    required int dayNumber,
    this.date = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       planId = Value(planId),
       dayNumber = Value(dayNumber);
  static Insertable<ReadingPlanDay> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? planId,
    Expression<int>? dayNumber,
    Expression<int>? date,
    Expression<bool>? completed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (planId != null) 'plan_id': planId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (date != null) 'date': date,
      if (completed != null) 'completed': completed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingPlanDaysCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? planId,
    Value<int>? dayNumber,
    Value<int?>? date,
    Value<bool>? completed,
    Value<int>? rowid,
  }) {
    return ReadingPlanDaysCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPlanDaysCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('planId: $planId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('date: $date, ')
          ..write('completed: $completed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingPlanItemsTable extends ReadingPlanItems
    with TableInfo<$ReadingPlanItemsTable, ReadingPlanItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingPlanItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<String> dayId = GeneratedColumn<String>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookNameMeta = const VerificationMeta(
    'bookName',
  );
  @override
  late final GeneratedColumn<String> bookName = GeneratedColumn<String>(
    'book_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startChapterMeta = const VerificationMeta(
    'startChapter',
  );
  @override
  late final GeneratedColumn<int> startChapter = GeneratedColumn<int>(
    'start_chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endChapterMeta = const VerificationMeta(
    'endChapter',
  );
  @override
  late final GeneratedColumn<int> endChapter = GeneratedColumn<int>(
    'end_chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  @override
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deviceId,
    deleted,
    dayId,
    bookName,
    startChapter,
    endChapter,
    startVerse,
    endVerse,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_plan_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingPlanItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('book_name')) {
      context.handle(
        _bookNameMeta,
        bookName.isAcceptableOrUnknown(data['book_name']!, _bookNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bookNameMeta);
    }
    if (data.containsKey('start_chapter')) {
      context.handle(
        _startChapterMeta,
        startChapter.isAcceptableOrUnknown(
          data['start_chapter']!,
          _startChapterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startChapterMeta);
    }
    if (data.containsKey('end_chapter')) {
      context.handle(
        _endChapterMeta,
        endChapter.isAcceptableOrUnknown(data['end_chapter']!, _endChapterMeta),
      );
    } else if (isInserting) {
      context.missing(_endChapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingPlanItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingPlanItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_id'],
      )!,
      bookName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_name'],
      )!,
      startChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_chapter'],
      )!,
      endChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      ),
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $ReadingPlanItemsTable createAlias(String alias) {
    return $ReadingPlanItemsTable(attachedDatabase, alias);
  }
}

class ReadingPlanItem extends DataClass implements Insertable<ReadingPlanItem> {
  final String id;
  final int updatedAt;
  final String deviceId;
  final bool deleted;
  final String dayId;
  final String bookName;
  final int startChapter;
  final int endChapter;
  final int? startVerse;
  final int? endVerse;
  final bool completed;
  const ReadingPlanItem({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.dayId,
    required this.bookName,
    required this.startChapter,
    required this.endChapter,
    this.startVerse,
    this.endVerse,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    map['deleted'] = Variable<bool>(deleted);
    map['day_id'] = Variable<String>(dayId);
    map['book_name'] = Variable<String>(bookName);
    map['start_chapter'] = Variable<int>(startChapter);
    map['end_chapter'] = Variable<int>(endChapter);
    if (!nullToAbsent || startVerse != null) {
      map['start_verse'] = Variable<int>(startVerse);
    }
    if (!nullToAbsent || endVerse != null) {
      map['end_verse'] = Variable<int>(endVerse);
    }
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  ReadingPlanItemsCompanion toCompanion(bool nullToAbsent) {
    return ReadingPlanItemsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deleted: Value(deleted),
      dayId: Value(dayId),
      bookName: Value(bookName),
      startChapter: Value(startChapter),
      endChapter: Value(endChapter),
      startVerse: startVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(startVerse),
      endVerse: endVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(endVerse),
      completed: Value(completed),
    );
  }

  factory ReadingPlanItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingPlanItem(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      dayId: serializer.fromJson<String>(json['dayId']),
      bookName: serializer.fromJson<String>(json['bookName']),
      startChapter: serializer.fromJson<int>(json['startChapter']),
      endChapter: serializer.fromJson<int>(json['endChapter']),
      startVerse: serializer.fromJson<int?>(json['startVerse']),
      endVerse: serializer.fromJson<int?>(json['endVerse']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deleted': serializer.toJson<bool>(deleted),
      'dayId': serializer.toJson<String>(dayId),
      'bookName': serializer.toJson<String>(bookName),
      'startChapter': serializer.toJson<int>(startChapter),
      'endChapter': serializer.toJson<int>(endChapter),
      'startVerse': serializer.toJson<int?>(startVerse),
      'endVerse': serializer.toJson<int?>(endVerse),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  ReadingPlanItem copyWith({
    String? id,
    int? updatedAt,
    String? deviceId,
    bool? deleted,
    String? dayId,
    String? bookName,
    int? startChapter,
    int? endChapter,
    Value<int?> startVerse = const Value.absent(),
    Value<int?> endVerse = const Value.absent(),
    bool? completed,
  }) => ReadingPlanItem(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deleted: deleted ?? this.deleted,
    dayId: dayId ?? this.dayId,
    bookName: bookName ?? this.bookName,
    startChapter: startChapter ?? this.startChapter,
    endChapter: endChapter ?? this.endChapter,
    startVerse: startVerse.present ? startVerse.value : this.startVerse,
    endVerse: endVerse.present ? endVerse.value : this.endVerse,
    completed: completed ?? this.completed,
  );
  ReadingPlanItem copyWithCompanion(ReadingPlanItemsCompanion data) {
    return ReadingPlanItem(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      bookName: data.bookName.present ? data.bookName.value : this.bookName,
      startChapter: data.startChapter.present
          ? data.startChapter.value
          : this.startChapter,
      endChapter: data.endChapter.present
          ? data.endChapter.value
          : this.endChapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPlanItem(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('dayId: $dayId, ')
          ..write('bookName: $bookName, ')
          ..write('startChapter: $startChapter, ')
          ..write('endChapter: $endChapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deviceId,
    deleted,
    dayId,
    bookName,
    startChapter,
    endChapter,
    startVerse,
    endVerse,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingPlanItem &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deleted == this.deleted &&
          other.dayId == this.dayId &&
          other.bookName == this.bookName &&
          other.startChapter == this.startChapter &&
          other.endChapter == this.endChapter &&
          other.startVerse == this.startVerse &&
          other.endVerse == this.endVerse &&
          other.completed == this.completed);
}

class ReadingPlanItemsCompanion extends UpdateCompanion<ReadingPlanItem> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<String> deviceId;
  final Value<bool> deleted;
  final Value<String> dayId;
  final Value<String> bookName;
  final Value<int> startChapter;
  final Value<int> endChapter;
  final Value<int?> startVerse;
  final Value<int?> endVerse;
  final Value<bool> completed;
  final Value<int> rowid;
  const ReadingPlanItemsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.dayId = const Value.absent(),
    this.bookName = const Value.absent(),
    this.startChapter = const Value.absent(),
    this.endChapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingPlanItemsCompanion.insert({
    required String id,
    required int updatedAt,
    required String deviceId,
    this.deleted = const Value.absent(),
    required String dayId,
    required String bookName,
    required int startChapter,
    required int endChapter,
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       dayId = Value(dayId),
       bookName = Value(bookName),
       startChapter = Value(startChapter),
       endChapter = Value(endChapter);
  static Insertable<ReadingPlanItem> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<String>? deviceId,
    Expression<bool>? deleted,
    Expression<String>? dayId,
    Expression<String>? bookName,
    Expression<int>? startChapter,
    Expression<int>? endChapter,
    Expression<int>? startVerse,
    Expression<int>? endVerse,
    Expression<bool>? completed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deleted != null) 'deleted': deleted,
      if (dayId != null) 'day_id': dayId,
      if (bookName != null) 'book_name': bookName,
      if (startChapter != null) 'start_chapter': startChapter,
      if (endChapter != null) 'end_chapter': endChapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endVerse != null) 'end_verse': endVerse,
      if (completed != null) 'completed': completed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingPlanItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<String>? deviceId,
    Value<bool>? deleted,
    Value<String>? dayId,
    Value<String>? bookName,
    Value<int>? startChapter,
    Value<int>? endChapter,
    Value<int?>? startVerse,
    Value<int?>? endVerse,
    Value<bool>? completed,
    Value<int>? rowid,
  }) {
    return ReadingPlanItemsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deleted: deleted ?? this.deleted,
      dayId: dayId ?? this.dayId,
      bookName: bookName ?? this.bookName,
      startChapter: startChapter ?? this.startChapter,
      endChapter: endChapter ?? this.endChapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      completed: completed ?? this.completed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<String>(dayId.value);
    }
    if (bookName.present) {
      map['book_name'] = Variable<String>(bookName.value);
    }
    if (startChapter.present) {
      map['start_chapter'] = Variable<int>(startChapter.value);
    }
    if (endChapter.present) {
      map['end_chapter'] = Variable<int>(endChapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPlanItemsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deleted: $deleted, ')
          ..write('dayId: $dayId, ')
          ..write('bookName: $bookName, ')
          ..write('startChapter: $startChapter, ')
          ..write('endChapter: $endChapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('completed: $completed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserStore extends GeneratedDatabase {
  _$UserStore(QueryExecutor e) : super(e);
  $UserStoreManager get managers => $UserStoreManager(this);
  late final $HighlightsTable highlights = $HighlightsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $JournalsTable journals = $JournalsTable(this);
  late final $PrayersTable prayers = $PrayersTable(this);
  late final $ReadingProgressesTable readingProgresses =
      $ReadingProgressesTable(this);
  late final $TimeTrackersTable timeTrackers = $TimeTrackersTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $NavigationHistoriesTable navigationHistories =
      $NavigationHistoriesTable(this);
  late final $ReadingPlansTable readingPlans = $ReadingPlansTable(this);
  late final $ReadingPlanDaysTable readingPlanDays = $ReadingPlanDaysTable(
    this,
  );
  late final $ReadingPlanItemsTable readingPlanItems = $ReadingPlanItemsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    highlights,
    notes,
    bookmarks,
    journals,
    prayers,
    readingProgresses,
    timeTrackers,
    achievements,
    navigationHistories,
    readingPlans,
    readingPlanDays,
    readingPlanItems,
  ];
}

typedef $$HighlightsTableCreateCompanionBuilder =
    HighlightsCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String bookName,
      required int chapter,
      required int verse,
      required String colorHex,
      Value<int> rowid,
    });
typedef $$HighlightsTableUpdateCompanionBuilder =
    HighlightsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> bookName,
      Value<int> chapter,
      Value<int> verse,
      Value<String> colorHex,
      Value<int> rowid,
    });

class $$HighlightsTableFilterComposer
    extends Composer<_$UserStore, $HighlightsTable> {
  $$HighlightsTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HighlightsTableOrderingComposer
    extends Composer<_$UserStore, $HighlightsTable> {
  $$HighlightsTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HighlightsTableAnnotationComposer
    extends Composer<_$UserStore, $HighlightsTable> {
  $$HighlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get verse =>
      $composableBuilder(column: $table.verse, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);
}

class $$HighlightsTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $HighlightsTable,
          Highlight,
          $$HighlightsTableFilterComposer,
          $$HighlightsTableOrderingComposer,
          $$HighlightsTableAnnotationComposer,
          $$HighlightsTableCreateCompanionBuilder,
          $$HighlightsTableUpdateCompanionBuilder,
          (Highlight, BaseReferences<_$UserStore, $HighlightsTable, Highlight>),
          Highlight,
          PrefetchHooks Function()
        > {
  $$HighlightsTableTableManager(_$UserStore db, $HighlightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HighlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HighlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HighlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> verse = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HighlightsCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                colorHex: colorHex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String bookName,
                required int chapter,
                required int verse,
                required String colorHex,
                Value<int> rowid = const Value.absent(),
              }) => HighlightsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                colorHex: colorHex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HighlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $HighlightsTable,
      Highlight,
      $$HighlightsTableFilterComposer,
      $$HighlightsTableOrderingComposer,
      $$HighlightsTableAnnotationComposer,
      $$HighlightsTableCreateCompanionBuilder,
      $$HighlightsTableUpdateCompanionBuilder,
      (Highlight, BaseReferences<_$UserStore, $HighlightsTable, Highlight>),
      Highlight,
      PrefetchHooks Function()
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String bookName,
      required int chapter,
      Value<int?> verse,
      required String content,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> bookName,
      Value<int> chapter,
      Value<int?> verse,
      Value<String> content,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$UserStore, $NotesTable> {
  $$NotesTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer extends Composer<_$UserStore, $NotesTable> {
  $$NotesTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$UserStore, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get verse =>
      $composableBuilder(column: $table.verse, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$UserStore, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$UserStore db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int?> verse = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                content: content,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String bookName,
                required int chapter,
                Value<int?> verse = const Value.absent(),
                required String content,
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                content: content,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$UserStore, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String bookName,
      required int chapter,
      required int verse,
      required String label,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> bookName,
      Value<int> chapter,
      Value<int> verse,
      Value<String> label,
      Value<int> rowid,
    });

class $$BookmarksTableFilterComposer
    extends Composer<_$UserStore, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$UserStore, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$UserStore, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get verse =>
      $composableBuilder(column: $table.verse, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, BaseReferences<_$UserStore, $BookmarksTable, Bookmark>),
          Bookmark,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$UserStore db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> verse = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String bookName,
                required int chapter,
                required int verse,
                required String label,
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, BaseReferences<_$UserStore, $BookmarksTable, Bookmark>),
      Bookmark,
      PrefetchHooks Function()
    >;
typedef $$JournalsTableCreateCompanionBuilder =
    JournalsCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String title,
      required String content,
      Value<String?> tags,
      Value<int> rowid,
    });
typedef $$JournalsTableUpdateCompanionBuilder =
    JournalsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> title,
      Value<String> content,
      Value<String?> tags,
      Value<int> rowid,
    });

class $$JournalsTableFilterComposer
    extends Composer<_$UserStore, $JournalsTable> {
  $$JournalsTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalsTableOrderingComposer
    extends Composer<_$UserStore, $JournalsTable> {
  $$JournalsTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalsTableAnnotationComposer
    extends Composer<_$UserStore, $JournalsTable> {
  $$JournalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);
}

class $$JournalsTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $JournalsTable,
          Journal,
          $$JournalsTableFilterComposer,
          $$JournalsTableOrderingComposer,
          $$JournalsTableAnnotationComposer,
          $$JournalsTableCreateCompanionBuilder,
          $$JournalsTableUpdateCompanionBuilder,
          (Journal, BaseReferences<_$UserStore, $JournalsTable, Journal>),
          Journal,
          PrefetchHooks Function()
        > {
  $$JournalsTableTableManager(_$UserStore db, $JournalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalsCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                title: title,
                content: content,
                tags: tags,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String title,
                required String content,
                Value<String?> tags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                title: title,
                content: content,
                tags: tags,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $JournalsTable,
      Journal,
      $$JournalsTableFilterComposer,
      $$JournalsTableOrderingComposer,
      $$JournalsTableAnnotationComposer,
      $$JournalsTableCreateCompanionBuilder,
      $$JournalsTableUpdateCompanionBuilder,
      (Journal, BaseReferences<_$UserStore, $JournalsTable, Journal>),
      Journal,
      PrefetchHooks Function()
    >;
typedef $$PrayersTableCreateCompanionBuilder =
    PrayersCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String name,
      required String description,
      required int createdAt,
      Value<int?> answeredAt,
      Value<int> rowid,
    });
typedef $$PrayersTableUpdateCompanionBuilder =
    PrayersCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> name,
      Value<String> description,
      Value<int> createdAt,
      Value<int?> answeredAt,
      Value<int> rowid,
    });

class $$PrayersTableFilterComposer
    extends Composer<_$UserStore, $PrayersTable> {
  $$PrayersTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrayersTableOrderingComposer
    extends Composer<_$UserStore, $PrayersTable> {
  $$PrayersTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayersTableAnnotationComposer
    extends Composer<_$UserStore, $PrayersTable> {
  $$PrayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );
}

class $$PrayersTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $PrayersTable,
          Prayer,
          $$PrayersTableFilterComposer,
          $$PrayersTableOrderingComposer,
          $$PrayersTableAnnotationComposer,
          $$PrayersTableCreateCompanionBuilder,
          $$PrayersTableUpdateCompanionBuilder,
          (Prayer, BaseReferences<_$UserStore, $PrayersTable, Prayer>),
          Prayer,
          PrefetchHooks Function()
        > {
  $$PrayersTableTableManager(_$UserStore db, $PrayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> answeredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayersCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                name: name,
                description: description,
                createdAt: createdAt,
                answeredAt: answeredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String name,
                required String description,
                required int createdAt,
                Value<int?> answeredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayersCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                name: name,
                description: description,
                createdAt: createdAt,
                answeredAt: answeredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayersTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $PrayersTable,
      Prayer,
      $$PrayersTableFilterComposer,
      $$PrayersTableOrderingComposer,
      $$PrayersTableAnnotationComposer,
      $$PrayersTableCreateCompanionBuilder,
      $$PrayersTableUpdateCompanionBuilder,
      (Prayer, BaseReferences<_$UserStore, $PrayersTable, Prayer>),
      Prayer,
      PrefetchHooks Function()
    >;
typedef $$ReadingProgressesTableCreateCompanionBuilder =
    ReadingProgressesCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String bookName,
      required int chapter,
      required int readAt,
      Value<int> iteration,
      Value<int> rowid,
    });
typedef $$ReadingProgressesTableUpdateCompanionBuilder =
    ReadingProgressesCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> bookName,
      Value<int> chapter,
      Value<int> readAt,
      Value<int> iteration,
      Value<int> rowid,
    });

class $$ReadingProgressesTableFilterComposer
    extends Composer<_$UserStore, $ReadingProgressesTable> {
  $$ReadingProgressesTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iteration => $composableBuilder(
    column: $table.iteration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingProgressesTableOrderingComposer
    extends Composer<_$UserStore, $ReadingProgressesTable> {
  $$ReadingProgressesTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iteration => $composableBuilder(
    column: $table.iteration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingProgressesTableAnnotationComposer
    extends Composer<_$UserStore, $ReadingProgressesTable> {
  $$ReadingProgressesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<int> get iteration =>
      $composableBuilder(column: $table.iteration, builder: (column) => column);
}

class $$ReadingProgressesTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $ReadingProgressesTable,
          ReadingProgress,
          $$ReadingProgressesTableFilterComposer,
          $$ReadingProgressesTableOrderingComposer,
          $$ReadingProgressesTableAnnotationComposer,
          $$ReadingProgressesTableCreateCompanionBuilder,
          $$ReadingProgressesTableUpdateCompanionBuilder,
          (
            ReadingProgress,
            BaseReferences<
              _$UserStore,
              $ReadingProgressesTable,
              ReadingProgress
            >,
          ),
          ReadingProgress,
          PrefetchHooks Function()
        > {
  $$ReadingProgressesTableTableManager(
    _$UserStore db,
    $ReadingProgressesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingProgressesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingProgressesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingProgressesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> readAt = const Value.absent(),
                Value<int> iteration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressesCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                readAt: readAt,
                iteration: iteration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String bookName,
                required int chapter,
                required int readAt,
                Value<int> iteration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                readAt: readAt,
                iteration: iteration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingProgressesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $ReadingProgressesTable,
      ReadingProgress,
      $$ReadingProgressesTableFilterComposer,
      $$ReadingProgressesTableOrderingComposer,
      $$ReadingProgressesTableAnnotationComposer,
      $$ReadingProgressesTableCreateCompanionBuilder,
      $$ReadingProgressesTableUpdateCompanionBuilder,
      (
        ReadingProgress,
        BaseReferences<_$UserStore, $ReadingProgressesTable, ReadingProgress>,
      ),
      ReadingProgress,
      PrefetchHooks Function()
    >;
typedef $$TimeTrackersTableCreateCompanionBuilder =
    TimeTrackersCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required int startTime,
      required int endTime,
      required int durationMs,
      required String activityType,
      Value<int> rowid,
    });
typedef $$TimeTrackersTableUpdateCompanionBuilder =
    TimeTrackersCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<int> startTime,
      Value<int> endTime,
      Value<int> durationMs,
      Value<String> activityType,
      Value<int> rowid,
    });

class $$TimeTrackersTableFilterComposer
    extends Composer<_$UserStore, $TimeTrackersTable> {
  $$TimeTrackersTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimeTrackersTableOrderingComposer
    extends Composer<_$UserStore, $TimeTrackersTable> {
  $$TimeTrackersTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimeTrackersTableAnnotationComposer
    extends Composer<_$UserStore, $TimeTrackersTable> {
  $$TimeTrackersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );
}

class $$TimeTrackersTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $TimeTrackersTable,
          TimeTracker,
          $$TimeTrackersTableFilterComposer,
          $$TimeTrackersTableOrderingComposer,
          $$TimeTrackersTableAnnotationComposer,
          $$TimeTrackersTableCreateCompanionBuilder,
          $$TimeTrackersTableUpdateCompanionBuilder,
          (
            TimeTracker,
            BaseReferences<_$UserStore, $TimeTrackersTable, TimeTracker>,
          ),
          TimeTracker,
          PrefetchHooks Function()
        > {
  $$TimeTrackersTableTableManager(_$UserStore db, $TimeTrackersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeTrackersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeTrackersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeTrackersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> startTime = const Value.absent(),
                Value<int> endTime = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> activityType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimeTrackersCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                startTime: startTime,
                endTime: endTime,
                durationMs: durationMs,
                activityType: activityType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required int startTime,
                required int endTime,
                required int durationMs,
                required String activityType,
                Value<int> rowid = const Value.absent(),
              }) => TimeTrackersCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                startTime: startTime,
                endTime: endTime,
                durationMs: durationMs,
                activityType: activityType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimeTrackersTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $TimeTrackersTable,
      TimeTracker,
      $$TimeTrackersTableFilterComposer,
      $$TimeTrackersTableOrderingComposer,
      $$TimeTrackersTableAnnotationComposer,
      $$TimeTrackersTableCreateCompanionBuilder,
      $$TimeTrackersTableUpdateCompanionBuilder,
      (
        TimeTracker,
        BaseReferences<_$UserStore, $TimeTrackersTable, TimeTracker>,
      ),
      TimeTracker,
      PrefetchHooks Function()
    >;
typedef $$AchievementsTableCreateCompanionBuilder =
    AchievementsCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required int unlockedAt,
      Value<int> rowid,
    });
typedef $$AchievementsTableUpdateCompanionBuilder =
    AchievementsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<int> unlockedAt,
      Value<int> rowid,
    });

class $$AchievementsTableFilterComposer
    extends Composer<_$UserStore, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$UserStore, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$UserStore, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );
}

class $$AchievementsTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $AchievementsTable,
          Achievement,
          $$AchievementsTableFilterComposer,
          $$AchievementsTableOrderingComposer,
          $$AchievementsTableAnnotationComposer,
          $$AchievementsTableCreateCompanionBuilder,
          $$AchievementsTableUpdateCompanionBuilder,
          (
            Achievement,
            BaseReferences<_$UserStore, $AchievementsTable, Achievement>,
          ),
          Achievement,
          PrefetchHooks Function()
        > {
  $$AchievementsTableTableManager(_$UserStore db, $AchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required int unlockedAt,
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $AchievementsTable,
      Achievement,
      $$AchievementsTableFilterComposer,
      $$AchievementsTableOrderingComposer,
      $$AchievementsTableAnnotationComposer,
      $$AchievementsTableCreateCompanionBuilder,
      $$AchievementsTableUpdateCompanionBuilder,
      (
        Achievement,
        BaseReferences<_$UserStore, $AchievementsTable, Achievement>,
      ),
      Achievement,
      PrefetchHooks Function()
    >;
typedef $$NavigationHistoriesTableCreateCompanionBuilder =
    NavigationHistoriesCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String bookName,
      required int chapter,
      Value<int?> verse,
      Value<String?> verseText,
      Value<int> rowid,
    });
typedef $$NavigationHistoriesTableUpdateCompanionBuilder =
    NavigationHistoriesCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> bookName,
      Value<int> chapter,
      Value<int?> verse,
      Value<String?> verseText,
      Value<int> rowid,
    });

class $$NavigationHistoriesTableFilterComposer
    extends Composer<_$UserStore, $NavigationHistoriesTable> {
  $$NavigationHistoriesTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verseText => $composableBuilder(
    column: $table.verseText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NavigationHistoriesTableOrderingComposer
    extends Composer<_$UserStore, $NavigationHistoriesTable> {
  $$NavigationHistoriesTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verse => $composableBuilder(
    column: $table.verse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verseText => $composableBuilder(
    column: $table.verseText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NavigationHistoriesTableAnnotationComposer
    extends Composer<_$UserStore, $NavigationHistoriesTable> {
  $$NavigationHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get verse =>
      $composableBuilder(column: $table.verse, builder: (column) => column);

  GeneratedColumn<String> get verseText =>
      $composableBuilder(column: $table.verseText, builder: (column) => column);
}

class $$NavigationHistoriesTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $NavigationHistoriesTable,
          NavigationHistory,
          $$NavigationHistoriesTableFilterComposer,
          $$NavigationHistoriesTableOrderingComposer,
          $$NavigationHistoriesTableAnnotationComposer,
          $$NavigationHistoriesTableCreateCompanionBuilder,
          $$NavigationHistoriesTableUpdateCompanionBuilder,
          (
            NavigationHistory,
            BaseReferences<
              _$UserStore,
              $NavigationHistoriesTable,
              NavigationHistory
            >,
          ),
          NavigationHistory,
          PrefetchHooks Function()
        > {
  $$NavigationHistoriesTableTableManager(
    _$UserStore db,
    $NavigationHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NavigationHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NavigationHistoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NavigationHistoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int?> verse = const Value.absent(),
                Value<String?> verseText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NavigationHistoriesCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                verseText: verseText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String bookName,
                required int chapter,
                Value<int?> verse = const Value.absent(),
                Value<String?> verseText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NavigationHistoriesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                bookName: bookName,
                chapter: chapter,
                verse: verse,
                verseText: verseText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NavigationHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $NavigationHistoriesTable,
      NavigationHistory,
      $$NavigationHistoriesTableFilterComposer,
      $$NavigationHistoriesTableOrderingComposer,
      $$NavigationHistoriesTableAnnotationComposer,
      $$NavigationHistoriesTableCreateCompanionBuilder,
      $$NavigationHistoriesTableUpdateCompanionBuilder,
      (
        NavigationHistory,
        BaseReferences<
          _$UserStore,
          $NavigationHistoriesTable,
          NavigationHistory
        >,
      ),
      NavigationHistory,
      PrefetchHooks Function()
    >;
typedef $$ReadingPlansTableCreateCompanionBuilder =
    ReadingPlansCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String title,
      Value<String?> description,
      required int startDate,
      Value<int?> targetEndDate,
      Value<int> rowid,
    });
typedef $$ReadingPlansTableUpdateCompanionBuilder =
    ReadingPlansCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> title,
      Value<String?> description,
      Value<int> startDate,
      Value<int?> targetEndDate,
      Value<int> rowid,
    });

class $$ReadingPlansTableFilterComposer
    extends Composer<_$UserStore, $ReadingPlansTable> {
  $$ReadingPlansTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetEndDate => $composableBuilder(
    column: $table.targetEndDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingPlansTableOrderingComposer
    extends Composer<_$UserStore, $ReadingPlansTable> {
  $$ReadingPlansTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetEndDate => $composableBuilder(
    column: $table.targetEndDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingPlansTableAnnotationComposer
    extends Composer<_$UserStore, $ReadingPlansTable> {
  $$ReadingPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get targetEndDate => $composableBuilder(
    column: $table.targetEndDate,
    builder: (column) => column,
  );
}

class $$ReadingPlansTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $ReadingPlansTable,
          ReadingPlan,
          $$ReadingPlansTableFilterComposer,
          $$ReadingPlansTableOrderingComposer,
          $$ReadingPlansTableAnnotationComposer,
          $$ReadingPlansTableCreateCompanionBuilder,
          $$ReadingPlansTableUpdateCompanionBuilder,
          (
            ReadingPlan,
            BaseReferences<_$UserStore, $ReadingPlansTable, ReadingPlan>,
          ),
          ReadingPlan,
          PrefetchHooks Function()
        > {
  $$ReadingPlansTableTableManager(_$UserStore db, $ReadingPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> startDate = const Value.absent(),
                Value<int?> targetEndDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPlansCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                title: title,
                description: description,
                startDate: startDate,
                targetEndDate: targetEndDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required int startDate,
                Value<int?> targetEndDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPlansCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                title: title,
                description: description,
                startDate: startDate,
                targetEndDate: targetEndDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $ReadingPlansTable,
      ReadingPlan,
      $$ReadingPlansTableFilterComposer,
      $$ReadingPlansTableOrderingComposer,
      $$ReadingPlansTableAnnotationComposer,
      $$ReadingPlansTableCreateCompanionBuilder,
      $$ReadingPlansTableUpdateCompanionBuilder,
      (
        ReadingPlan,
        BaseReferences<_$UserStore, $ReadingPlansTable, ReadingPlan>,
      ),
      ReadingPlan,
      PrefetchHooks Function()
    >;
typedef $$ReadingPlanDaysTableCreateCompanionBuilder =
    ReadingPlanDaysCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String planId,
      required int dayNumber,
      Value<int?> date,
      Value<bool> completed,
      Value<int> rowid,
    });
typedef $$ReadingPlanDaysTableUpdateCompanionBuilder =
    ReadingPlanDaysCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> planId,
      Value<int> dayNumber,
      Value<int?> date,
      Value<bool> completed,
      Value<int> rowid,
    });

class $$ReadingPlanDaysTableFilterComposer
    extends Composer<_$UserStore, $ReadingPlanDaysTable> {
  $$ReadingPlanDaysTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingPlanDaysTableOrderingComposer
    extends Composer<_$UserStore, $ReadingPlanDaysTable> {
  $$ReadingPlanDaysTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingPlanDaysTableAnnotationComposer
    extends Composer<_$UserStore, $ReadingPlanDaysTable> {
  $$ReadingPlanDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$ReadingPlanDaysTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $ReadingPlanDaysTable,
          ReadingPlanDay,
          $$ReadingPlanDaysTableFilterComposer,
          $$ReadingPlanDaysTableOrderingComposer,
          $$ReadingPlanDaysTableAnnotationComposer,
          $$ReadingPlanDaysTableCreateCompanionBuilder,
          $$ReadingPlanDaysTableUpdateCompanionBuilder,
          (
            ReadingPlanDay,
            BaseReferences<_$UserStore, $ReadingPlanDaysTable, ReadingPlanDay>,
          ),
          ReadingPlanDay,
          PrefetchHooks Function()
        > {
  $$ReadingPlanDaysTableTableManager(
    _$UserStore db,
    $ReadingPlanDaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingPlanDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingPlanDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingPlanDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> dayNumber = const Value.absent(),
                Value<int?> date = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPlanDaysCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                planId: planId,
                dayNumber: dayNumber,
                date: date,
                completed: completed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String planId,
                required int dayNumber,
                Value<int?> date = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPlanDaysCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                planId: planId,
                dayNumber: dayNumber,
                date: date,
                completed: completed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingPlanDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $ReadingPlanDaysTable,
      ReadingPlanDay,
      $$ReadingPlanDaysTableFilterComposer,
      $$ReadingPlanDaysTableOrderingComposer,
      $$ReadingPlanDaysTableAnnotationComposer,
      $$ReadingPlanDaysTableCreateCompanionBuilder,
      $$ReadingPlanDaysTableUpdateCompanionBuilder,
      (
        ReadingPlanDay,
        BaseReferences<_$UserStore, $ReadingPlanDaysTable, ReadingPlanDay>,
      ),
      ReadingPlanDay,
      PrefetchHooks Function()
    >;
typedef $$ReadingPlanItemsTableCreateCompanionBuilder =
    ReadingPlanItemsCompanion Function({
      required String id,
      required int updatedAt,
      required String deviceId,
      Value<bool> deleted,
      required String dayId,
      required String bookName,
      required int startChapter,
      required int endChapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      Value<bool> completed,
      Value<int> rowid,
    });
typedef $$ReadingPlanItemsTableUpdateCompanionBuilder =
    ReadingPlanItemsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<String> deviceId,
      Value<bool> deleted,
      Value<String> dayId,
      Value<String> bookName,
      Value<int> startChapter,
      Value<int> endChapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      Value<bool> completed,
      Value<int> rowid,
    });

class $$ReadingPlanItemsTableFilterComposer
    extends Composer<_$UserStore, $ReadingPlanItemsTable> {
  $$ReadingPlanItemsTableFilterComposer({
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

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayId => $composableBuilder(
    column: $table.dayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endChapter => $composableBuilder(
    column: $table.endChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingPlanItemsTableOrderingComposer
    extends Composer<_$UserStore, $ReadingPlanItemsTable> {
  $$ReadingPlanItemsTableOrderingComposer({
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

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayId => $composableBuilder(
    column: $table.dayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookName => $composableBuilder(
    column: $table.bookName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endChapter => $composableBuilder(
    column: $table.endChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingPlanItemsTableAnnotationComposer
    extends Composer<_$UserStore, $ReadingPlanItemsTable> {
  $$ReadingPlanItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get dayId =>
      $composableBuilder(column: $table.dayId, builder: (column) => column);

  GeneratedColumn<String> get bookName =>
      $composableBuilder(column: $table.bookName, builder: (column) => column);

  GeneratedColumn<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endChapter => $composableBuilder(
    column: $table.endChapter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$ReadingPlanItemsTableTableManager
    extends
        RootTableManager<
          _$UserStore,
          $ReadingPlanItemsTable,
          ReadingPlanItem,
          $$ReadingPlanItemsTableFilterComposer,
          $$ReadingPlanItemsTableOrderingComposer,
          $$ReadingPlanItemsTableAnnotationComposer,
          $$ReadingPlanItemsTableCreateCompanionBuilder,
          $$ReadingPlanItemsTableUpdateCompanionBuilder,
          (
            ReadingPlanItem,
            BaseReferences<
              _$UserStore,
              $ReadingPlanItemsTable,
              ReadingPlanItem
            >,
          ),
          ReadingPlanItem,
          PrefetchHooks Function()
        > {
  $$ReadingPlanItemsTableTableManager(
    _$UserStore db,
    $ReadingPlanItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingPlanItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingPlanItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingPlanItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> dayId = const Value.absent(),
                Value<String> bookName = const Value.absent(),
                Value<int> startChapter = const Value.absent(),
                Value<int> endChapter = const Value.absent(),
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPlanItemsCompanion(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                dayId: dayId,
                bookName: bookName,
                startChapter: startChapter,
                endChapter: endChapter,
                startVerse: startVerse,
                endVerse: endVerse,
                completed: completed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                required String deviceId,
                Value<bool> deleted = const Value.absent(),
                required String dayId,
                required String bookName,
                required int startChapter,
                required int endChapter,
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPlanItemsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deleted: deleted,
                dayId: dayId,
                bookName: bookName,
                startChapter: startChapter,
                endChapter: endChapter,
                startVerse: startVerse,
                endVerse: endVerse,
                completed: completed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingPlanItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserStore,
      $ReadingPlanItemsTable,
      ReadingPlanItem,
      $$ReadingPlanItemsTableFilterComposer,
      $$ReadingPlanItemsTableOrderingComposer,
      $$ReadingPlanItemsTableAnnotationComposer,
      $$ReadingPlanItemsTableCreateCompanionBuilder,
      $$ReadingPlanItemsTableUpdateCompanionBuilder,
      (
        ReadingPlanItem,
        BaseReferences<_$UserStore, $ReadingPlanItemsTable, ReadingPlanItem>,
      ),
      ReadingPlanItem,
      PrefetchHooks Function()
    >;

class $UserStoreManager {
  final _$UserStore _db;
  $UserStoreManager(this._db);
  $$HighlightsTableTableManager get highlights =>
      $$HighlightsTableTableManager(_db, _db.highlights);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$JournalsTableTableManager get journals =>
      $$JournalsTableTableManager(_db, _db.journals);
  $$PrayersTableTableManager get prayers =>
      $$PrayersTableTableManager(_db, _db.prayers);
  $$ReadingProgressesTableTableManager get readingProgresses =>
      $$ReadingProgressesTableTableManager(_db, _db.readingProgresses);
  $$TimeTrackersTableTableManager get timeTrackers =>
      $$TimeTrackersTableTableManager(_db, _db.timeTrackers);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$NavigationHistoriesTableTableManager get navigationHistories =>
      $$NavigationHistoriesTableTableManager(_db, _db.navigationHistories);
  $$ReadingPlansTableTableManager get readingPlans =>
      $$ReadingPlansTableTableManager(_db, _db.readingPlans);
  $$ReadingPlanDaysTableTableManager get readingPlanDays =>
      $$ReadingPlanDaysTableTableManager(_db, _db.readingPlanDays);
  $$ReadingPlanItemsTableTableManager get readingPlanItems =>
      $$ReadingPlanItemsTableTableManager(_db, _db.readingPlanItems);
}
