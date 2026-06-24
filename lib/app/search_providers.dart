import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/importer/mybible_verse_parser.dart';
import '../domain/search/reference_parser.dart';
import 'content_providers.dart';
import 'user_providers.dart';
import 'reader_state.dart';

class SearchResult {
  final String type; // 'verse', 'note', 'commentary', 'dictionary'
  final String referenceId;
  final String textContent;
  final String title;
  final String? book;
  final int? chapter;
  final int? verse;
  final String? selectedVerses;
  final int? bookOrder;
  final String? sourceName;

  SearchResult({
    required this.type,
    required this.referenceId,
    required this.textContent,
    required this.title,
    this.book,
    this.chapter,
    this.verse,
    this.selectedVerses,
    this.bookOrder,
    this.sourceName,
  });
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final globalSearchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  () => SearchQueryNotifier(),
);



final autocompleteWordsProvider = FutureProvider<List<String>>((ref) async {
  final query = ref.watch(globalSearchQueryProvider).trim();
  if (query.isEmpty) return [];

  // Get the last word the user is typing
  final words = query.split(RegExp(r'\s+'));
  final lastWord = words.last.toLowerCase();
  
  // Only suggest if at least 2 characters are typed
  if (lastWord.length < 2) return [];

  final contentStore = ref.watch(contentStoreProvider);

  try {
    // Escape single quotes for SQL
    final safeWord = lastWord.replaceAll("'", "''");
    // Restrict to alphabetic, sane-length terms: the FTS index includes raw
    // commentary HTML, so the vocab contains markup and junk tokens.
    final rows = await contentStore.customSelect(
      "SELECT term FROM content_vocab WHERE term LIKE ? "
      "AND term NOT GLOB '*[^a-z]*' AND length(term) BETWEEN 2 AND 18 "
      "ORDER BY cnt DESC LIMIT 15",
      variables: [Variable.withString('$safeWord%')],
    ).get();

    return rows.map((row) => row.read<String>('term')).toList();
  } catch (e) {
    // If table doesn't exist yet (migration not run), just return empty
    return [];
  }
});

final globalSearchResultsProvider = FutureProvider<List<SearchResult>>((
  ref,
) async {
  final contentStore = ref.watch(contentStoreProvider);
  final userStore = ref.watch(userStoreProvider);
  final query = ref.watch(globalSearchQueryProvider);

  if (query.trim().isEmpty) return [];

  // Sanitize the query for FTS5 to prevent syntax errors with punctuation
  final cleanQuery = query.trim().replaceAll('"', '""');
  final searchPattern = '"$cleanQuery"*'; // Match prefix as phrase

  final List<SearchResult> results = [];

  // Check if query is a reference for quick navigation
  final activeVersions = ref.watch(activeVersionsProvider);
  if (activeVersions.isNotEmpty) {
    try {
      final books = await ref.watch(booksForVersionProvider(activeVersions.first).future);
      final parsed = ReferenceParser.parse(query, books);
      if (parsed != null) {
        String titleStr = parsed.book.name;
        if (parsed.chapter > 0) titleStr += ' ${parsed.chapter}';
        if (parsed.verse != null) titleStr += ':${parsed.verse}';
        results.add(
          SearchResult(
            type: 'navigation',
            referenceId: 'nav',
            textContent: 'Tap to open $titleStr',
            title: 'Navigate to $titleStr',
            book: parsed.book.name,
            chapter: parsed.chapter,
            verse: parsed.verse,
          ),
        );
      }
    } catch (e) {
      // Ignore parsing errors
    }
  }

  // 1. Query Content Database
  final contentQuery = '''
    SELECT 
      f.type, 
      f.reference_id, 
      f.text_content,
      v.chapter as verse_chapter, v.verse as verse_num, b.name as verse_book, b.book_order as verse_book_order,
      ce.book_name as comm_book, ce.chapter as comm_chapter, c.name as comm_name,
      de.word as dict_word, de.definition as dict_def, d.name as dict_name,
      tp.name as topic_name
    FROM content_search f
    LEFT JOIN verses v ON f.type = 'verse' AND f.reference_id = v.id
    LEFT JOIN books b ON v.book_id = b.id
    LEFT JOIN commentary_entries ce ON f.type = 'commentary' AND f.reference_id = ce.id
    LEFT JOIN commentaries c ON ce.commentary_id = c.id
    LEFT JOIN dictionary_entries de ON f.type = 'dictionary' AND f.reference_id = de.id
    LEFT JOIN dictionaries d ON de.dictionary_id = d.id
    LEFT JOIN topics tp ON f.type = 'topic' AND f.reference_id = tp.id
    WHERE content_search MATCH ?
    ORDER BY rank
    LIMIT 100
  ''';

  final contentRows = await contentStore
      .customSelect(
        contentQuery,
        variables: [Variable.withString(searchPattern)],
      )
      .get();
  for (final row in contentRows) {
    final type = row.read<String>('type');
    final refId = row.read<int>('reference_id').toString();
    final text = row.read<String>('text_content');

    if (type == 'verse') {
      final bName = row.readNullable<String>('verse_book') ?? 'Unknown Book';
      final cNum = row.readNullable<int>('verse_chapter') ?? 1;
      final vNum = row.readNullable<int>('verse_num') ?? 1;
      final bOrder = row.readNullable<int>('verse_book_order') ?? 0;
      
      final cleanText = MyBibleVerseParser()
          .parseVerse(text)
          .map((s) => s.text)
          .join('')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      results.add(
        SearchResult(
          type: type,
          referenceId: refId,
          textContent: cleanText,
          title: '$bName $cNum:$vNum',
          book: bName,
          chapter: cNum,
          verse: vNum,
          bookOrder: bOrder,
        ),
      );
    } else if (type == 'commentary') {
      final cName =
          row.readNullable<String>('comm_name') ?? 'Unknown Commentary';
      final cBook = row.readNullable<String>('comm_book') ?? 'General';
      final cChapter = row.readNullable<int>('comm_chapter');
      results.add(
        SearchResult(
          type: type,
          referenceId: refId,
          textContent: text,
          title: '$cName - $cBook',
          book: cBook,
          chapter: cChapter,
          sourceName: cName,
        ),
      );
    } else if (type == 'dictionary') {
      final word = row.readNullable<String>('dict_word') ?? 'Unknown Word';
      final def = row.readNullable<String>('dict_def') ?? '';
      final dName =
          row.readNullable<String>('dict_name') ?? 'Unknown Dictionary';
      results.add(
        SearchResult(
          type: type,
          referenceId: refId,
          textContent: def,
          title: word,
          sourceName: dName,
        ),
      );
    } else if (type == 'topic') {
      final name = row.readNullable<String>('topic_name') ?? text;
      results.add(
        SearchResult(
          type: type,
          referenceId: refId,
          textContent: '',
          title: _titleCaseTopic(name),
          sourceName: "Nave's Topical Bible",
        ),
      );
    }
  }

  // 2. Query User Database
  final userQuery = '''
    SELECT 
      f.type, 
      f.reference_id, 
      f.text_content,
      n.book_name as note_book, n.chapter as note_chapter, n.verse as note_verse, n.selected_verses as note_selected_verses, n.deleted as note_deleted,
      s.title as sermon_title, s.series as sermon_series, s.deleted as sermon_deleted,
      j.title as journal_title, j.deleted as journal_deleted,
      p.name as prayer_name, p.deleted as prayer_deleted
    FROM user_search f
    LEFT JOIN notes n ON f.type = 'note' AND f.reference_id = n.id
    LEFT JOIN sermons s ON f.type = 'sermon' AND f.reference_id = s.id
    LEFT JOIN journals j ON f.type = 'journal' AND f.reference_id = j.id
    LEFT JOIN prayers p ON f.type = 'prayer' AND f.reference_id = p.id
    WHERE user_search MATCH ?
    ORDER BY rank
    LIMIT 100
  ''';

  try {
    final userRows = await userStore
        .customSelect(
          userQuery,
          variables: [Variable.withString(searchPattern)],
        )
        .get();
    for (final row in userRows) {
      final type = row.readNullable<String>('type');
      if (type == null) continue;
      final refId = row.readNullable<String>('reference_id') ?? '';
      final text = row.readNullable<String>('text_content') ?? '';

      if (type == 'verse') {
        final refId = row.readNullable<String>('reference_id') ?? '';
        final parts = refId.split(':');
        if (parts.length > 1) {
          final data = parts[1].split('|');
          if (data.length >= 3) {
            final book = data[0];
            final chapter = int.tryParse(data[1]);
            final verse = int.tryParse(data[2]);
            
            results.add(SearchResult(
              type: type,
              referenceId: refId,
              textContent: text,
              title: '$book $chapter:$verse',
              book: book,
              chapter: chapter,
              verse: verse,
            ));
          }
        }
      } else if (type == 'journal') {
        final isDeleted = row.readNullable<bool>('journal_deleted') ?? false;
        if (isDeleted) continue;
        final jTitle = row.readNullable<String>('journal_title') ?? 'Journal';
        results.add(SearchResult(
          type: type,
          referenceId: refId,
          textContent: text,
          title: 'Journal: $jTitle',
        ));
      } else if (type == 'prayer') {
        final isDeleted = row.readNullable<bool>('prayer_deleted') ?? false;
        if (isDeleted) continue;
        final pName = row.readNullable<String>('prayer_name') ?? 'Prayer';
        results.add(SearchResult(
          type: type,
          referenceId: refId,
          textContent: text,
          title: 'Prayer: $pName',
        ));
      } else if (type == 'note') {
        final isDeleted = row.readNullable<bool>('note_deleted') ?? false;
        if (isDeleted) continue;
        final bName = row.readNullable<String>('note_book') ?? 'Unknown Book';
        final cNum = row.readNullable<int>('note_chapter') ?? 1;
        final vNum = row.readNullable<int>('note_verse');
        final sVerses = row.readNullable<String>('note_selected_verses');
        
        String targetStr = '$bName $cNum';
        if (sVerses != null) {
            targetStr += ':$sVerses';
        } else if (vNum != null) {
            targetStr += ':$vNum';
        }

        results.add(
          SearchResult(
            type: type,
            referenceId: refId,
            textContent: text,
            title: 'Note: $targetStr',
            book: bName,
            chapter: cNum,
            verse: vNum,
            selectedVerses: sVerses,
          ),
        );
      } else if (type == 'sermon') {
        final isDeleted = row.readNullable<bool>('sermon_deleted') ?? false;
        if (isDeleted) continue;
        final sTitle = row.readNullable<String>('sermon_title') ?? 'Sermon';
        final sSeries = row.readNullable<String>('sermon_series');
        final displayTitle = sSeries != null ? '$sTitle ($sSeries)' : sTitle;

        // user_search now indexes plain text for sermons, so the snippet is
        // already clean — no Delta JSON to strip.
        results.add(
          SearchResult(
            type: type,
            referenceId: refId,
            textContent: text.trim(),
            title: 'Sermon: $displayTitle',
          ),
        );
      }
    }
  } catch (e) {
    // If user_search table doesn't exist yet (before hot restart), ignore
  }

  // 3. Direct tag search — don't rely on FTS triggers for tags
  try {
    final tagSearchPattern = query.trim().replaceAll(RegExp(r'^#'), '');
    if (tagSearchPattern.isNotEmpty) {
      final tagQuery = '''
        SELECT et.entity_id, et.entity_type, t.name as tag_name,
          n.book_name as note_book, n.chapter as note_chapter, n.verse as note_verse, n.selected_verses as note_selected_verses, n.content as note_content, n.deleted as note_deleted,
          s.title as sermon_title, s.series as sermon_series, s.deleted as sermon_deleted,
          j.title as journal_title, j.content as journal_content, j.deleted as journal_deleted,
          p.name as prayer_name, p.description as prayer_desc, p.deleted as prayer_deleted
        FROM entity_tags et
        JOIN tags t ON et.tag_id = t.id AND t.deleted = 0
        LEFT JOIN notes n ON et.entity_type = 'note' AND et.entity_id = n.id
        LEFT JOIN sermons s ON et.entity_type = 'sermon' AND et.entity_id = s.id
        LEFT JOIN journals j ON et.entity_type = 'journal' AND et.entity_id = j.id
        LEFT JOIN prayers p ON et.entity_type = 'prayer' AND et.entity_id = p.id
        WHERE et.deleted = 0 AND LOWER(t.name) LIKE ?
        LIMIT 100
      ''';

      final tagRows = await userStore
          .customSelect(
            tagQuery,
            variables: [Variable.withString('%${tagSearchPattern.toLowerCase()}%')],
          )
          .get();

      // Collect existing result keys to avoid duplicates
      final existingKeys = results.map((r) => '${r.type}:${r.referenceId}').toSet();

      for (final row in tagRows) {
        final entityType = row.readNullable<String>('entity_type') ?? '';
        final entityId = row.readNullable<String>('entity_id') ?? '';
        final tagName = row.readNullable<String>('tag_name') ?? '';
        final key = '$entityType:$entityId';
        if (existingKeys.contains(key)) continue;
        existingKeys.add(key);

        if (entityType == 'verse') {
          final parts = entityId.split(':');
          if (parts.length > 1) {
            final data = parts[1].split('|');
            if (data.length >= 3) {
              results.add(SearchResult(
                type: 'verse',
                referenceId: entityId,
                textContent: '#$tagName',
                title: '${data[0]} ${data[1]}:${data[2]}',
                book: data[0],
                chapter: int.tryParse(data[1]),
                verse: int.tryParse(data[2]),
              ));
            }
          }
        } else if (entityType == 'note') {
          final isDeleted = row.readNullable<bool>('note_deleted') ?? false;
          if (isDeleted) continue;
          final bName = row.readNullable<String>('note_book') ?? 'Unknown Book';
          final cNum = row.readNullable<int>('note_chapter') ?? 1;
          final vNum = row.readNullable<int>('note_verse');
          final sVerses = row.readNullable<String>('note_selected_verses');
          final noteContent = row.readNullable<String>('note_content') ?? '#$tagName';
          String targetStr = '$bName $cNum';
          if (sVerses != null) {
            targetStr += ':$sVerses';
          } else if (vNum != null) {
            targetStr += ':$vNum';
          }
          results.add(SearchResult(
            type: 'note',
            referenceId: entityId,
            textContent: noteContent,
            title: 'Note: $targetStr',
            book: bName,
            chapter: cNum,
            verse: vNum,
            selectedVerses: sVerses,
          ));
        } else if (entityType == 'sermon') {
          final isDeleted = row.readNullable<bool>('sermon_deleted') ?? false;
          if (isDeleted) continue;
          final sTitle = row.readNullable<String>('sermon_title') ?? 'Sermon';
          final sSeries = row.readNullable<String>('sermon_series');
          final displayTitle = sSeries != null ? '$sTitle ($sSeries)' : sTitle;
          results.add(SearchResult(
            type: 'sermon',
            referenceId: entityId,
            textContent: '#$tagName',
            title: 'Sermon: $displayTitle',
          ));
        } else if (entityType == 'journal') {
          final isDeleted = row.readNullable<bool>('journal_deleted') ?? false;
          if (isDeleted) continue;
          final jTitle = row.readNullable<String>('journal_title') ?? 'Journal';
          results.add(SearchResult(
            type: 'journal',
            referenceId: entityId,
            textContent: '#$tagName',
            title: 'Journal: $jTitle',
          ));
        } else if (entityType == 'prayer') {
          final isDeleted = row.readNullable<bool>('prayer_deleted') ?? false;
          if (isDeleted) continue;
          final pName = row.readNullable<String>('prayer_name') ?? 'Prayer';
          results.add(SearchResult(
            type: 'prayer',
            referenceId: entityId,
            textContent: '#$tagName',
            title: 'Prayer: $pName',
          ));
        }
      }
    }
  } catch (e) {
    // Tag search failed, ignore
  }

  // Deduplicate and sort verses by canonical order
  final verses = results.where((r) => r.type == 'verse').toList();
  final others = results.where((r) => r.type != 'verse').toList();

  // Make distinct by title (book chapter:verse) just in case
  final Map<String, SearchResult> distinctVerses = {};
  for (final v in verses) {
    distinctVerses[v.title] = v;
  }

  final uniqueVerses = distinctVerses.values.toList();
  uniqueVerses.sort((a, b) {
    int bookCmp = (a.bookOrder ?? 0).compareTo(b.bookOrder ?? 0);
    if (bookCmp != 0) return bookCmp;
    int chapterCmp = (a.chapter ?? 0).compareTo(b.chapter ?? 0);
    if (chapterCmp != 0) return chapterCmp;
    return (a.verse ?? 0).compareTo(b.verse ?? 0);
  });

  return [...uniqueVerses, ...others];
});

/// Nave's topic names are stored upper-cased; display them in title case.
String _titleCaseTopic(String s) {
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
