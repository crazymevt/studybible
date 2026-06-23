import 'package:drift/drift.dart';

@DataClassName('Version')
class Versions extends Table {
  TextColumn get id => text()(); // e.g. "KJV"
  TextColumn get abbreviation => text()();
  TextColumn get name => text()();
  TextColumn get language => text().withDefault(const Constant('en'))();
  TextColumn get about => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Book')
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get versionId => text().references(Versions, #id)();
  TextColumn get name => text()();
  IntColumn get bookOrder => integer()();
  TextColumn get testament => text()(); // "OT" or "NT"
}

@DataClassName('Verse')
class Verses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id)();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get textContent => text()(); // Plain text for search
  TextColumn get segments => text()(); // JSON string with rich segments
}

@DataClassName('CrossReference')
class CrossReferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceBookName => text()();
  IntColumn get sourceChapter => integer()();
  IntColumn get sourceVerse => integer()();

  TextColumn get targetBookName => text()();
  IntColumn get targetChapter => integer()();
  IntColumn get targetVerse => integer()();
  IntColumn get votes => integer().nullable()();
}

@DataClassName('Commentary')
class Commentaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get abbreviation => text()();
  TextColumn get name => text()();
  TextColumn get about => text().nullable()();
}

@DataClassName('CommentaryEntry')
class CommentaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get commentaryId => integer().references(Commentaries, #id)();
  TextColumn get bookName => text()();
  IntColumn get chapter => integer().nullable()();
  IntColumn get verse => integer().nullable()();
  TextColumn get textContent => text()();
}

@DataClassName('Dictionary')
class Dictionaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get abbreviation => text()();
  TextColumn get name => text()();
  TextColumn get about => text().nullable()();
}

@DataClassName('DictionaryEntry')
class DictionaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictionaryId => integer().references(Dictionaries, #id)();
  TextColumn get word => text()();
  TextColumn get definition => text()();
}

@DataClassName('Subheading')
class Subheadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get versionId => text().references(Versions, #id)();
  IntColumn get bookOrder => integer()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  IntColumn get orderIfSeveral => integer().withDefault(const Constant(0))();
  TextColumn get textContent => text()();
  TextColumn get about => text().nullable()();
}

@DataClassName('Topic')
class Topics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // e.g. "AARON"
  TextColumn get section => text()(); // single-letter A–Z bucket
}

@DataClassName('TopicEntry')
class TopicEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer().references(Topics, #id)();
  IntColumn get ordinal => integer()(); // order within the topic
  TextColumn get description => text()();
  // Newline-joined names of cross-referenced topics ("See …"), or null.
  TextColumn get seeAlso => text().nullable()();
}

@DataClassName('TopicReference')
@TableIndex(name: 'idx_topic_ref_location', columns: {#bookName, #chapter})
class TopicReferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer().references(Topics, #id)();
  IntColumn get entryId => integer().references(TopicEntries, #id)();
  TextColumn get bookName => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer().nullable()(); // null = whole chapter
  IntColumn get verseEnd => integer().nullable()(); // null = single verse
}

@DataClassName('Devotional')
class Devotionals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get abbreviation => text()();
  TextColumn get name => text()();
  TextColumn get about => text().nullable()();
}

@DataClassName('DevotionalEntry')
class DevotionalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get devotionalId => integer().references(Devotionals, #id)();
  IntColumn get day => integer()();
  TextColumn get textContent => text()();
}
