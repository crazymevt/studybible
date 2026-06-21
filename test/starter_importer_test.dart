// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:study_bible/data/content_store.dart';

void main() {
  test('Generate sample DB', () async {
    final dbFile = File('assets/content.db');
    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }
    
    if (!Directory('assets').existsSync()) {
      Directory('assets').createSync();
    }

    final db = ContentStore(NativeDatabase(dbFile));
    
    // Insert Versions
    await db.into(db.versions).insert(
      VersionsCompanion.insert(
        id: 'NLT',
        abbreviation: 'NLT',
        name: 'New Living Translation',
        language: const Value('en'),
      )
    );
    await db.into(db.versions).insert(
      VersionsCompanion.insert(
        id: 'KJV',
        abbreviation: 'KJV',
        name: 'King James Version',
        language: const Value('en'),
      )
    );

    // Insert Books
    final nltBookId = await db.into(db.books).insert(
      BooksCompanion.insert(
        versionId: 'NLT',
        name: 'John',
        bookOrder: 43,
        testament: 'NT',
      )
    );
    final kjvBookId = await db.into(db.books).insert(
      BooksCompanion.insert(
        versionId: 'KJV',
        name: 'John',
        bookOrder: 43,
        testament: 'NT',
      )
    );

    // Insert Genesis for KJV
    final genesisBookId = await db.into(db.books).insert(
      BooksCompanion.insert(
        versionId: 'KJV',
        name: 'Genesis',
        bookOrder: 1,
        testament: 'OT',
      )
    );

    // Insert Verses
    final segments1 = [
      {"text": "In the beginning the Word already existed. The Word was with God, and the Word was God."},
    ];
    final segments2 = [
      {"text": "He existed in the beginning with God."},
    ];
    final segments3 = [
      {"text": "God created everything through him, and nothing was created except through him."},
    ];

    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: nltBookId,
        chapter: 1,
        verse: 1,
        textContent: "In the beginning the Word already existed. The Word was with God, and the Word was God.",
        segments: jsonEncode(segments1),
      )
    );
    
    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: nltBookId,
        chapter: 1,
        verse: 2,
        textContent: "He existed in the beginning with God.",
        segments: jsonEncode(segments2),
      )
    );

    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: nltBookId,
        chapter: 1,
        verse: 3,
        textContent: "God created everything through him, and nothing was created except through him.",
        segments: jsonEncode(segments3),
      )
    );

    final kjvSeg1 = [
      {"text": "In the beginning was the Word, and the Word was with God, and the Word was God."},
    ];
    final kjvSeg2 = [
      {"text": "The same was in the beginning with God."},
    ];
    final kjvSeg3 = [
      {"text": "All things were made by him; and without him was not any thing made that was made."},
    ];

    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: kjvBookId,
        chapter: 1,
        verse: 1,
        textContent: "In the beginning was the Word, and the Word was with God, and the Word was God.",
        segments: jsonEncode(kjvSeg1),
      )
    );
    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: kjvBookId,
        chapter: 1,
        verse: 2,
        textContent: "The same was in the beginning with God.",
        segments: jsonEncode(kjvSeg2),
      )
    );
    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: kjvBookId,
        chapter: 1,
        verse: 3,
        textContent: "All things were made by him; and without him was not any thing made that was made.",
        segments: jsonEncode(kjvSeg3),
      )
    );

    final genSeg1 = [
      {"text": "In the beginning God created the heaven and the earth."},
    ];

    await db.into(db.verses).insert(
      VersesCompanion.insert(
        bookId: genesisBookId,
        chapter: 1,
        verse: 1,
        textContent: "In the beginning God created the heaven and the earth.",
        segments: jsonEncode(genSeg1),
      )
    );

    // Insert Cross References
    await db.into(db.crossReferences).insert(
      CrossReferencesCompanion.insert(
        sourceBookName: 'John',
        sourceChapter: 1,
        sourceVerse: 1,
        targetBookName: 'Genesis',
        targetChapter: 1,
        targetVerse: 1,
      )
    );

    // Insert Commentaries
    final commentaryId = await db.into(db.commentaries).insert(
      CommentariesCompanion.insert(
        abbreviation: 'MHC',
        name: "Matthew Henry's Concise Commentary",
      )
    );

    await db.into(db.commentaryEntries).insert(
      CommentaryEntriesCompanion.insert(
        commentaryId: commentaryId,
        bookName: 'John',
        chapter: const Value(1),
        verse: const Value(1),
        textContent: "<h3>John 1:1</h3><p>The plainest reason why the Son of God is called the Word, seems to be, that as our words explain our minds to others, so was the Son of God sent in order to reveal his Father's mind to the world.</p>",
      )
    );
    
    await db.into(db.commentaryEntries).insert(
      CommentaryEntriesCompanion.insert(
        commentaryId: commentaryId,
        bookName: 'John',
        chapter: const Value(1),
        verse: const Value(2),
        textContent: "<h3>John 1:2</h3><p>What the evangelist says of Christ proves that he is God. He asserts, His existence in the beginning; His coexistence with the Father.</p>",
      )
    );

    // Chapter level overview
    await db.into(db.commentaryEntries).insert(
      CommentaryEntriesCompanion.insert(
        commentaryId: commentaryId,
        bookName: 'John',
        chapter: const Value(1),
        verse: const Value(null),
        textContent: "<h2>Overview of John 1</h2><p>This chapter contains the foundational truth of the gospel: the deity and incarnation of Jesus Christ, the Word made flesh.</p>",
      )
    );

    // Book level overview
    await db.into(db.commentaryEntries).insert(
      CommentaryEntriesCompanion.insert(
        commentaryId: commentaryId,
        bookName: 'John',
        chapter: const Value(null),
        verse: const Value(null),
        textContent: "<h1>The Gospel According to John</h1><p>John's Gospel is distinct from the synoptic gospels. Its main focus is on the deity of Christ.</p>",
      )
    );

    // Seed Dictionaries
    final eastonId = await db.into(db.dictionaries).insert(
      DictionariesCompanion.insert(
        abbreviation: 'Easton',
        name: "Easton's Bible Dictionary",
      )
    );

    await db.into(db.dictionaryEntries).insert(
      DictionaryEntriesCompanion.insert(
        dictionaryId: eastonId,
        word: 'Grace',
        definition: "<h3>Grace</h3><p>Favours received. The free and unmerited favour of God as manifested in the salvation of sinners and the bestowal of blessings.</p>",
      )
    );

    await db.into(db.dictionaryEntries).insert(
      DictionaryEntriesCompanion.insert(
        dictionaryId: eastonId,
        word: 'Word',
        definition: "<h3>Word</h3><p>(Gr. Logos) A title of Jesus Christ (John 1:1, 14; 1 John 1:1; Rev. 19:13). In the beginning was the Word.</p>",
      )
    );

    // Setup FTS5 for Content Search
    await db.customStatement('''
      CREATE VIRTUAL TABLE content_search USING fts5(type UNINDEXED, reference_id UNINDEXED, text_content);
    ''');
    await db.customStatement('''
      INSERT INTO content_search(type, reference_id, text_content) SELECT 'verse', id, text_content FROM verses;
    ''');
    await db.customStatement('''
      INSERT INTO content_search(type, reference_id, text_content) SELECT 'commentary', id, text_content FROM commentary_entries;
    ''');
    await db.customStatement('''
      INSERT INTO content_search(type, reference_id, text_content) SELECT 'dictionary', id, word FROM dictionary_entries;
    ''');

    await db.close();
    print("✅ Generated sample assets/content.db");
  });
}
