import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'content_providers.dart';
import 'user_providers.dart';

class SearchResult {
  final String type; // 'verse', 'note', 'commentary', 'dictionary'
  final int referenceId;
  final String textContent;
  final String title;
  final String? book;
  final int? chapter;
  final int? verse;
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

final globalSearchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

final globalSearchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final contentStore = ref.watch(contentStoreProvider);
  final userStore = ref.watch(userStoreProvider);
  final query = ref.watch(globalSearchQueryProvider);
  
  if (query.trim().isEmpty) return [];

  final searchPattern = query.trim(); // For SQLite FTS5 MATCH
  
  final List<SearchResult> results = [];

  // 1. Query Content Database
  final contentQuery = '''
    SELECT 
      f.type, 
      f.reference_id, 
      f.text_content,
      v.chapter as verse_chapter, v.verse as verse_num, b.name as verse_book, b.book_order as verse_book_order,
      ce.book_name as comm_book, ce.chapter as comm_chapter, c.name as comm_name,
      de.word as dict_word, de.definition as dict_def, d.name as dict_name
    FROM content_search f
    LEFT JOIN verses v ON f.type = 'verse' AND f.reference_id = v.id
    LEFT JOIN books b ON v.book_id = b.id
    LEFT JOIN commentary_entries ce ON f.type = 'commentary' AND f.reference_id = ce.id
    LEFT JOIN commentaries c ON ce.commentary_id = c.id
    LEFT JOIN dictionary_entries de ON f.type = 'dictionary' AND f.reference_id = de.id
    LEFT JOIN dictionaries d ON de.dictionary_id = d.id
    WHERE content_search MATCH ?
    ORDER BY rank
    LIMIT 100
  ''';

  final contentRows = await contentStore.customSelect(contentQuery, variables: [Variable.withString(searchPattern)]).get();
  for (final row in contentRows) {
    final type = row.read<String>('type');
    final refId = row.read<int>('reference_id');
    final text = row.read<String>('text_content');
    
    if (type == 'verse') {
      final bName = row.read<String>('verse_book');
      final cNum = row.read<int>('verse_chapter');
      final vNum = row.read<int>('verse_num');
      final bOrder = row.read<int>('verse_book_order');
      results.add(SearchResult(
        type: type,
        referenceId: refId,
        textContent: text,
        title: '$bName $cNum:$vNum',
        book: bName,
        chapter: cNum,
        verse: vNum,
        bookOrder: bOrder,
      ));
    } else if (type == 'commentary') {
      final cName = row.read<String>('comm_name');
      final cBook = row.read<String?>('comm_book') ?? 'General';
      final cChapter = row.read<int?>('comm_chapter');
      results.add(SearchResult(
        type: type,
        referenceId: refId,
        textContent: text,
        title: '$cName - $cBook',
        book: cBook,
        chapter: cChapter,
        sourceName: cName,
      ));
    } else if (type == 'dictionary') {
      final word = row.read<String>('dict_word');
      final def = row.read<String>('dict_def');
      final dName = row.read<String>('dict_name');
      results.add(SearchResult(
        type: type,
        referenceId: refId,
        textContent: def,
        title: word,
        sourceName: dName,
      ));
    }
  }

  // 2. Query User Database
  final userQuery = '''
    SELECT 
      f.type, 
      f.reference_id, 
      f.text_content,
      n.book_name as note_book, n.chapter as note_chapter, n.verse as note_verse
    FROM user_search f
    LEFT JOIN notes n ON f.type = 'note' AND f.reference_id = n.id
    WHERE user_search MATCH ?
    ORDER BY rank
    LIMIT 100
  ''';

  try {
    final userRows = await userStore.customSelect(userQuery, variables: [Variable.withString(searchPattern)]).get();
    for (final row in userRows) {
      final type = row.read<String>('type');
      final refId = row.read<int>('reference_id');
      final text = row.read<String>('text_content');
      
      if (type == 'note') {
        final bName = row.read<String>('note_book');
        final cNum = row.read<int>('note_chapter');
        final vNum = row.readNullable<int>('note_verse');
        final target = vNum != null ? '$bName $cNum:$vNum' : '$bName $cNum';
        results.add(SearchResult(
          type: type,
          referenceId: refId,
          textContent: text,
          title: 'Note: $target',
          book: bName,
          chapter: cNum,
        ));
      }
    }
  } catch (e) {
    // If user_search table doesn't exist yet (before hot restart), ignore
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
