import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/importer/mybible_verse_parser.dart';
import '../domain/search/reference_parser.dart';
import '../domain/search/testament_scope.dart';
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

/// An active search scope (from an `ot:`/`nt:` or `BookName:` prefix), shown as
/// a dismissible chip. [bareTerms] is the query with the scope removed, used by
/// the chip's "search everywhere" action.
class SearchScope {
  final String label;
  final String bareTerms;
  const SearchScope({required this.label, required this.bareTerms});
}

/// Result of a global search: the [results] plus the [scope] that was applied
/// (null when the query had no scope prefix).
class GlobalSearchResults {
  final List<SearchResult> results;
  final SearchScope? scope;
  const GlobalSearchResults(this.results, {this.scope});
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
    // Drop pure-number tokens (verse/Strong's numbers) and absurdly long junk,
    // but keep non-ASCII words so Greek/Hebrew terms can autocomplete. HTML
    // content is markup-stripped before indexing, so no tag/attribute filtering
    // is needed here (older indexes are cleaned by the gen-1 rebuild prompt).
    final rows = await contentStore
        .customSelect(
          "SELECT term FROM content_vocab WHERE term LIKE ? "
          "AND term GLOB '*[^0-9]*' AND length(term) BETWEEN 2 AND 18 "
          "ORDER BY cnt DESC LIMIT 15",
          variables: [Variable.withString('$safeWord%')],
        )
        .get();

    return rows.map((row) => row.read<String>('term')).toList();
  } catch (e) {
    // If table doesn't exist yet (migration not run), just return empty
    return [];
  }
});

final globalSearchResultsProvider = FutureProvider<GlobalSearchResults>((
  ref,
) async {
  final contentStore = ref.watch(contentStoreProvider);
  final userStore = ref.watch(userStoreProvider);
  final query = ref.watch(globalSearchQueryProvider);

  // Invalidate this provider whenever relevant user data changes
  final sub = userStore.tableUpdates().listen((_) => ref.invalidateSelf());
  ref.onDispose(() => sub.cancel());

  if (query.trim().isEmpty) return const GlobalSearchResults([]);

  final activeVersions = ref.watch(activeVersionsProvider);

  // --- Determine the search scope ---
  // A query may be scoped to a testament (`ot:`/`nt:`) or to a single book
  // (`BookName: terms`). Both restrict to verses and suppress the reference
  // shortcut and the user-content/tag sections. A scope with no terms after it
  // is meaningless, so it falls through to a plain search (e.g. a bare
  // `Daniel:` just searches for the word).
  String? testament;
  String? bookName; // canonical book name for a book scope
  SearchScope? scope;
  String terms = query.trim();

  final ts = parseTestamentScope(query);
  if (ts.testament != null && ts.terms.isNotEmpty) {
    testament = ts.testament;
    terms = ts.terms;
    scope = SearchScope(
      label: testament == 'OT' ? 'Old Testament' : 'New Testament',
      bareTerms: terms,
    );
  } else if (activeVersions.isNotEmpty) {
    // Book scope: split on the first colon. The left side must resolve to a
    // bare book — reference forms like "John 3:16" leave a chapter number on
    // the left, don't resolve, and so fall through to the nav shortcut below.
    final colon = query.indexOf(':');
    if (colon > 0) {
      final left = query.substring(0, colon).trim();
      final right = query.substring(colon + 1).trim();
      if (right.isNotEmpty) {
        final books = await ref.watch(
          booksForVersionProvider(activeVersions.first).future,
        );
        final book = ReferenceParser.findBook(left.toLowerCase(), books);
        if (book != null) {
          bookName = book.name;
          terms = right;
          scope = SearchScope(label: book.name, bareTerms: terms);
        }
      }
    }
  }

  final scoped = testament != null || bookName != null;
  if (terms.isEmpty) return const GlobalSearchResults([]);

  // Sanitize the query for FTS5 to prevent syntax errors with punctuation
  String searchPattern;
  final nearMatches = RegExp(r'~([0-9]+)').allMatches(terms);
  if (nearMatches.isNotEmpty) {
    // It's a NEAR search. Extract the total distance.
    int distance = 0;
    for (final m in nearMatches) {
      distance += int.parse(m.group(1)!);
    }
    
    // Split the terms by the ~N pattern
    final parts = terms.split(RegExp(r'\s*~[0-9]+\s*'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
        
    if (parts.length >= 2) {
      final safeParts = parts.map((p) => '"${p.replaceAll('"', '""')}"').join(' ');
      searchPattern = 'NEAR($safeParts, $distance)';
    } else {
      final cleanQuery = terms.replaceAll('"', '""');
      searchPattern = '"$cleanQuery"*';
    }
  } else {
    final cleanQuery = terms.replaceAll('"', '""');
    searchPattern = '"$cleanQuery"*'; // Match prefix as phrase
  }

  final List<SearchResult> results = [];

  // Check if query is a reference for quick navigation. A scoped search is a
  // word search, so skip the reference shortcut there.
  if (!scoped && activeVersions.isNotEmpty) {
    try {
      final books = await ref.watch(
        booksForVersionProvider(activeVersions.first).future,
      );
      final parsed = ReferenceParser.parse(terms, books);
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

  // 1. Query Content Database.
  //
  // content_search indexes verses from every installed translation, so without
  // a filter a verse can match (and its snippet be shown) for a version other
  // than the one being read — and tapping the result opens the active version,
  // mismatching the preview. Restrict verse matches to the primary active
  // version. Non-verse rows (commentary/dictionary/topic) are unaffected.
  final primaryVersion = activeVersions.isNotEmpty
      ? activeVersions.first
      : null;
  final verseFilters = StringBuffer();
  final verseFilterVars = <Variable>[];
  if (primaryVersion != null) {
    verseFilters.write("\n    AND (f.type != 'verse' OR b.version_id = ?)");
    verseFilterVars.add(Variable.withString(primaryVersion));
  }
  if (testament != null) {
    // Testament scope: restrict to verses in the requested testament.
    verseFilters.write("\n    AND f.type = 'verse' AND b.testament = ?");
    verseFilterVars.add(Variable.withString(testament));
  }
  if (bookName != null) {
    // Book scope: restrict to verses in the requested book.
    verseFilters.write("\n    AND f.type = 'verse' AND b.name = ?");
    verseFilterVars.add(Variable.withString(bookName));
  }

  final contentQuery =
      '''
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
    WHERE content_search MATCH ?$verseFilters
    ORDER BY rank
    LIMIT 100
  ''';

  final contentRows = await contentStore
      .customSelect(
        contentQuery,
        variables: [Variable.withString(searchPattern), ...verseFilterVars],
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

  // User content (notes/sermons/journals/prayers) and tags aren't scripture,
  // so a testament-scoped search skips both sections.
  if (!scoped) {
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

              results.add(
                SearchResult(
                  type: type,
                  referenceId: refId,
                  textContent: text,
                  title: '$book $chapter:$verse',
                  book: book,
                  chapter: chapter,
                  verse: verse,
                ),
              );
            }
          }
        } else if (type == 'journal') {
          final isDeleted = row.readNullable<bool>('journal_deleted') ?? false;
          if (isDeleted) continue;
          final jTitle = row.readNullable<String>('journal_title') ?? 'Journal';
          results.add(
            SearchResult(
              type: type,
              referenceId: refId,
              textContent: text,
              title: 'Journal: $jTitle',
            ),
          );
        } else if (type == 'prayer') {
          final isDeleted = row.readNullable<bool>('prayer_deleted') ?? false;
          if (isDeleted) continue;
          final pName = row.readNullable<String>('prayer_name') ?? 'Prayer';
          results.add(
            SearchResult(
              type: type,
              referenceId: refId,
              textContent: text,
              title: 'Prayer: $pName',
            ),
          );
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
              variables: [
                Variable.withString('%${tagSearchPattern.toLowerCase()}%'),
              ],
            )
            .get();

        // Collect existing result keys to avoid duplicates
        final existingKeys = results
            .map((r) => '${r.type}:${r.referenceId}')
            .toSet();

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
                results.add(
                  SearchResult(
                    type: 'verse',
                    referenceId: entityId,
                    textContent: '#$tagName',
                    title: '${data[0]} ${data[1]}:${data[2]}',
                    book: data[0],
                    chapter: int.tryParse(data[1]),
                    verse: int.tryParse(data[2]),
                  ),
                );
              }
            }
          } else if (entityType == 'note') {
            final isDeleted = row.readNullable<bool>('note_deleted') ?? false;
            if (isDeleted) continue;
            final bName =
                row.readNullable<String>('note_book') ?? 'Unknown Book';
            final cNum = row.readNullable<int>('note_chapter') ?? 1;
            final vNum = row.readNullable<int>('note_verse');
            final sVerses = row.readNullable<String>('note_selected_verses');
            final noteContent =
                row.readNullable<String>('note_content') ?? '#$tagName';
            String targetStr = '$bName $cNum';
            if (sVerses != null) {
              targetStr += ':$sVerses';
            } else if (vNum != null) {
              targetStr += ':$vNum';
            }
            results.add(
              SearchResult(
                type: 'note',
                referenceId: entityId,
                textContent: noteContent,
                title: 'Note: $targetStr',
                book: bName,
                chapter: cNum,
                verse: vNum,
                selectedVerses: sVerses,
              ),
            );
          } else if (entityType == 'sermon') {
            final isDeleted = row.readNullable<bool>('sermon_deleted') ?? false;
            if (isDeleted) continue;
            final sTitle = row.readNullable<String>('sermon_title') ?? 'Sermon';
            final sSeries = row.readNullable<String>('sermon_series');
            final displayTitle = sSeries != null
                ? '$sTitle ($sSeries)'
                : sTitle;
            results.add(
              SearchResult(
                type: 'sermon',
                referenceId: entityId,
                textContent: '#$tagName',
                title: 'Sermon: $displayTitle',
              ),
            );
          } else if (entityType == 'journal') {
            final isDeleted =
                row.readNullable<bool>('journal_deleted') ?? false;
            if (isDeleted) continue;
            final jTitle =
                row.readNullable<String>('journal_title') ?? 'Journal';
            results.add(
              SearchResult(
                type: 'journal',
                referenceId: entityId,
                textContent: '#$tagName',
                title: 'Journal: $jTitle',
              ),
            );
          } else if (entityType == 'prayer') {
            final isDeleted = row.readNullable<bool>('prayer_deleted') ?? false;
            if (isDeleted) continue;
            final pName = row.readNullable<String>('prayer_name') ?? 'Prayer';
            results.add(
              SearchResult(
                type: 'prayer',
                referenceId: entityId,
                textContent: '#$tagName',
                title: 'Prayer: $pName',
              ),
            );
          }
        }
      }
    } catch (e) {
      // Tag search failed, ignore
    }
  } // end: unscoped-only (user content + tags)

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

  return GlobalSearchResults([...uniqueVerses, ...others], scope: scope);
});

/// Nave's topic names are stored upper-cased; display them in title case.
String _titleCaseTopic(String s) {
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
