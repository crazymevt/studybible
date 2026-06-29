import 'reader_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../data/user_store.dart';
import 'user_providers.dart';
import 'content_providers.dart';
import 'search_providers.dart';
import '../data/importer/mybible_verse_parser.dart';
import 'sync_service.dart';

// Represents a unified Tag definition
class TagData {
  final String id;
  final String name;
  final String? colorHex;

  TagData({required this.id, required this.name, this.colorHex});
}

// Represents a Tag linked to an Entity
class EntityTagData {
  final String id;
  final String tagId;
  final String entityId;
  final String entityType;
  final TagData tag;

  EntityTagData({
    required this.id,
    required this.tagId,
    required this.entityId,
    required this.entityType,
    required this.tag,
  });
}

// 1. Fetch all unique tags available in the system
final allTagsProvider = StreamProvider<List<TagData>>((ref) {
  final db = ref.watch(userStoreProvider);
  return (db.select(db.tags)..where((t) => t.deleted.equals(false)))
      .watch()
      .map((rows) => rows.map((r) => TagData(id: r.id, name: r.name, colorHex: r.colorHex)).toList());
});

// 2. Fetch tags for a specific entity
final tagsForEntityProvider = StreamProvider.family<List<EntityTagData>, String>((ref, entityId) {
  final db = ref.watch(userStoreProvider);
  
  final query = db.select(db.entityTags).join([
    innerJoin(db.tags, db.tags.id.equalsExp(db.entityTags.tagId)),
  ])
    ..where(db.entityTags.entityId.equals(entityId))
    ..where(db.entityTags.deleted.equals(false))
    ..where(db.tags.deleted.equals(false));

  return query.watch().map((rows) {
    return rows.map((row) {
      final et = row.readTable(db.entityTags);
      final t = row.readTable(db.tags);
      return EntityTagData(
        id: et.id,
        tagId: et.tagId,
        entityId: et.entityId,
        entityType: et.entityType,
        tag: TagData(id: t.id, name: t.name, colorHex: t.colorHex),
      );
    }).toList();
  });
});

class TagController {
  final Ref ref;
  TagController(this.ref);

  Future<void> addTagToEntity({
    required String entityId,
    required String entityType,
    required String tagName,
    String? colorHex,
  }) async {
    final db = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if tag already exists (case-insensitive)
    final existingTag = await (db.select(db.tags)
          ..where((t) => t.name.lower().equals(tagName.toLowerCase()))
          ..where((t) => t.deleted.equals(false)))
        .getSingleOrNull();

    String tagId;
    if (existingTag != null) {
      tagId = existingTag.id;
    } else {
      tagId = const Uuid().v4();
      await db.into(db.tags).insert(
            TagsCompanion.insert(
              id: tagId,
              updatedAt: now,
              deviceId: deviceId,
              name: tagName,
              colorHex: Value(colorHex),
            ),
          );
    }

    // Check if link already exists
    final existingLink = await (db.select(db.entityTags)
          ..where((et) => et.tagId.equals(tagId))
          ..where((et) => et.entityId.equals(entityId))
          ..where((et) => et.deleted.equals(false)))
        .getSingleOrNull();

    if (existingLink == null) {
      await db.into(db.entityTags).insert(
            EntityTagsCompanion.insert(
              id: const Uuid().v4(),
              updatedAt: now,
              deviceId: deviceId,
              tagId: tagId,
              entityId: entityId,
              entityType: entityType,
            ),
          );
    }
  }

  Future<void> removeTagFromEntity(String entityTagId) async {
    final db = ref.read(userStoreProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final link = await (db.select(db.entityTags)..where((et) => et.id.equals(entityTagId))).getSingleOrNull();
    if (link == null) return;
    
    await (db.update(db.entityTags)..where((et) => et.id.equals(entityTagId))).write(
      EntityTagsCompanion(
        deleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
    
    // Garbage collection: if no other entities are using this tag, delete it globally
    final otherLinks = await (db.select(db.entityTags)
      ..where((et) => et.tagId.equals(link.tagId))
      ..where((et) => et.deleted.equals(false))).get();
      
    if (otherLinks.isEmpty) {
      await (db.update(db.tags)..where((t) => t.id.equals(link.tagId))).write(
        TagsCompanion(
          deleted: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<void> removeAllTagsFromEntity(String entityId) async {
    final db = ref.read(userStoreProvider);
    final links = await (db.select(db.entityTags)
          ..where((et) => et.entityId.equals(entityId))
          ..where((et) => et.deleted.equals(false)))
        .get();
    for (final link in links) {
      await removeTagFromEntity(link.id);
    }
  }
}

final tagControllerProvider = Provider<TagController>((ref) {
  return TagController(ref);
});

// 3. Fetch all entities linked to a tag, returning them as SearchResult objects
final entitiesForTagProvider = FutureProvider.family<List<SearchResult>, String>((ref, tagId) async {
  final userDb = ref.watch(userStoreProvider);
  final contentDb = ref.watch(contentStoreProvider);
  
  // Get all entity links for this tag
  final links = await (userDb.select(userDb.entityTags)
        ..where((et) => et.tagId.equals(tagId))
        ..where((et) => et.deleted.equals(false)))
      .get();
      
  final List<SearchResult> results = [];
  
  for (final link in links) {
    if (link.entityType == 'verse') {
      // entityId is like 'Verse:Gen|1|1'
      final parts = link.entityId.split(':');
      if (parts.length > 1) {
        final data = parts[1].split('|');
        if (data.length >= 3) {
          final book = data[0];
          final chapter = int.tryParse(data[1]);
          final verse = int.tryParse(data[2]);
          
          if (chapter != null && verse != null) {
            final bookList = await (contentDb.select(contentDb.books)..where((b) => b.name.equals(book))).get();
            final bookQuery = bookList.firstOrNull;
            if (bookQuery != null) {
              final verseList = await (contentDb.select(contentDb.verses)
                    ..where((v) => v.bookId.equals(bookQuery.id))
                    ..where((v) => v.chapter.equals(chapter))
                    ..where((v) => v.verse.equals(verse)))
                  .get();
              final verseQuery = verseList.firstOrNull;
                  
              if (verseQuery != null) {
                final cleanText = MyBibleVerseParser()
                    .parseVerse(verseQuery.textContent)
                    .map((s) => s.text)
                    .join('')
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim();
                    
                results.add(SearchResult(
                  type: 'verse',
                  referenceId: verseQuery.id.toString(),
                  textContent: cleanText,
                  title: '$book $chapter:$verse',
                  book: book,
                  chapter: chapter,
                  verse: verse,
                  bookOrder: bookQuery.bookOrder,
                ));
              }
            }
          }
        }
      }
    } else if (link.entityType == 'note') {
      final note = await (userDb.select(userDb.notes)..where((n) => n.id.equals(link.entityId))).getSingleOrNull();
      if (note != null && !note.deleted) {
        results.add(SearchResult(
          type: 'note',
          referenceId: note.id,
          textContent: note.content,
          title: 'Note: ${note.bookName} ${note.chapter}',
          book: note.bookName,
          chapter: note.chapter,
          verse: note.verse,
          selectedVerses: note.selectedVerses,
        ));
      }
    } else if (link.entityType == 'sermon') {
      final sermon = await (userDb.select(userDb.sermons)..where((s) => s.id.equals(link.entityId))).getSingleOrNull();
      if (sermon != null && !sermon.deleted) {
        results.add(SearchResult(
          type: 'sermon',
          referenceId: sermon.id,
          textContent: sermon.content.replaceAll(RegExp(r'\{[^\}]+\}'), '').replaceAll(RegExp(r'[\[\]\\n"insert:]'), '').trim(),
          title: 'Sermon: ${sermon.title}',
        ));
      }
    } else if (link.entityType == 'prayer') {
      final prayer = await (userDb.select(userDb.prayers)..where((p) => p.id.equals(link.entityId))).getSingleOrNull();
      if (prayer != null && !prayer.deleted) {
        results.add(SearchResult(
          type: 'prayer',
          referenceId: prayer.id,
          textContent: prayer.description,
          title: 'Prayer: ${prayer.name}',
        ));
      }
    } else if (link.entityType == 'journal') {
      final journal = await (userDb.select(userDb.journals)..where((j) => j.id.equals(link.entityId))).getSingleOrNull();
      if (journal != null && !journal.deleted) {
        results.add(SearchResult(
          type: 'journal',
          referenceId: journal.id,
          textContent: journal.content,
          title: 'Journal: ${journal.title}',
        ));
      }
    }
  }
  
  return results;
});

// 4. Fetch verses with tags in current chapter
final chapterVersesWithTagsFamilyProvider = StreamProvider.family<Set<int>,
    ({String bookName, int chapter})>((ref, args) {
  final db = ref.watch(userStoreProvider);

  final prefix = 'Verse:${args.bookName}|${args.chapter}|%';

  return (db.select(db.entityTags)
    ..where((et) => et.entityType.equals('verse'))
    ..where((et) => et.entityId.like(prefix))
    ..where((et) => et.deleted.equals(false))
  ).watch().map((links) {
     final set = <int>{};
     for (final link in links) {
       final parts = link.entityId.split('|');
       if (parts.length >= 3) {
         final v = int.tryParse(parts[2]);
         if (v != null) set.add(v);
       }
     }
     return set;
  });
});

/// Verses with tags for the currently-selected chapter. Delegates to
/// [chapterVersesWithTagsFamilyProvider] so each reader swipe page can load its
/// own chapter.
final chapterVersesWithTagsProvider = Provider<AsyncValue<Set<int>>>((ref) {
  final bookName = ref.watch(selectedBookNameProvider);
  final chapter = ref.watch(selectedChapterProvider);
  return ref.watch(
    chapterVersesWithTagsFamilyProvider((bookName: bookName, chapter: chapter)),
  );
});
