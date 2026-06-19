class ParsedReference {
  final String bookName;
  final int startChapter;
  final int endChapter;
  final int? startVerse;
  final int? endVerse;

  ParsedReference({
    required this.bookName,
    required this.startChapter,
    required this.endChapter,
    this.startVerse,
    this.endVerse,
  });

  @override
  String toString() {
    return 'ParsedReference($bookName $startChapter${startVerse != null ? ':$startVerse' : ''} - $endChapter${endVerse != null ? ':$endVerse' : ''})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedReference &&
          runtimeType == other.runtimeType &&
          bookName == other.bookName &&
          startChapter == other.startChapter &&
          endChapter == other.endChapter &&
          startVerse == other.startVerse &&
          endVerse == other.endVerse;

  @override
  int get hashCode =>
      bookName.hashCode ^
      startChapter.hashCode ^
      endChapter.hashCode ^
      startVerse.hashCode ^
      endVerse.hashCode;
}

class ReferenceParser {
  static const Map<String, String> _bookAliases = {
    'SongOfSongs': 'Song of Solomon',
    'Song of Songs': 'Song of Solomon',
    '1 Thes': '1 Thessalonians',
    '2 Thes': '2 Thessalonians',
    '1Thes': '1 Thessalonians',
    '2Thes': '2 Thessalonians',
    '1 Thessalonians': '1 Thessalonians',
    '2 Thessalonians': '2 Thessalonians',
    '1 Corinthians': '1 Corinthians',
    '2 Corinthians': '2 Corinthians',
    '1 Cor': '1 Corinthians',
    '2 Cor': '2 Corinthians',
    '1 Samuel': '1 Samuel',
    '2 Samuel': '2 Samuel',
    '1 Kings': '1 Kings',
    '2 Kings': '2 Kings',
    '1 Chronicles': '1 Chronicles',
    '2 Chronicles': '2 Chronicles',
    '1Chronicles': '1 Chronicles',
    '2Chronicles': '2 Chronicles',
    '1 Peter': '1 Peter',
    '2 Peter': '2 Peter',
    '1 John': '1 John',
    '2 John': '2 John',
    '3 John': '3 John',
    '1 Timothy': '1 Timothy',
    '2 Timothy': '2 Timothy',
    '1Tim': '1 Timothy',
    '2Tim': '2 Timothy',
    '1 Cor.': '1 Corinthians',
    '2 Cor.': '2 Corinthians',
  };

  /// Normalizes a book name based on known aliases or spacing issues.
  static String normalizeBookName(String rawName) {
    var name = rawName.trim();
    if (_bookAliases.containsKey(name)) {
      return _bookAliases[name]!;
    }
    // Handle things like "1Samuel" -> "1 Samuel"
    if (RegExp(r'^\d[a-zA-Z]').hasMatch(name)) {
      name = '${name.substring(0, 1)} ${name.substring(1)}';
      if (_bookAliases.containsKey(name)) {
        return _bookAliases[name]!;
      }
    }
    return name;
  }

  /// Parses a string like "Genesis 1:1-3:24", "Genesis 9-10", "Luke 1:1-38", or "1 Thes 1".
  static ParsedReference parse(String ref) {
    // 1. Separate book name from the chapters/verses.
    // Book names can have numbers ("1 Samuel", "1Samuel") and spaces.
    // The reference part is always at the end and starts with a digit, 
    // but we must be careful not to match the "1" in "1 Samuel".
    
    // Find the last space that precedes a digit
    final regex = RegExp(r'^(.+?)\s+(\d.*)$');
    final match = regex.firstMatch(ref.trim());
    
    String bookPart;
    String refPart;

    if (match != null) {
      bookPart = match.group(1)!;
      refPart = match.group(2)!;
    } else {
      // It might be just a book name like "Obadiah" (though usually reading plans have chapters)
      // or "1Chronicles 1" without space: "1Chronicles1" (unlikely)
      // Let's fallback
      final fallbackMatch = RegExp(r'^([a-zA-Z\s]+)(\d.*)$').firstMatch(ref.trim());
      if (fallbackMatch != null) {
        bookPart = fallbackMatch.group(1)!;
        refPart = fallbackMatch.group(2)!;
      } else {
        return ParsedReference(bookName: normalizeBookName(ref), startChapter: 1, endChapter: 1);
      }
    }

    final bookName = normalizeBookName(bookPart);

    // 2. Parse the reference part: "1:1-3:24" or "9-10" or "1:1-38" or "1"
    int startChapter = 1;
    int endChapter = 1;
    int? startVerse;
    int? endVerse;

    if (refPart.contains('-')) {
      final rangeParts = refPart.split('-');
      final startPart = rangeParts[0];
      final endPart = rangeParts[1];

      if (startPart.contains(':')) {
        final startCv = startPart.split(':');
        startChapter = int.parse(startCv[0]);
        startVerse = int.parse(startCv[1]);
      } else {
        startChapter = int.parse(startPart);
      }

      if (endPart.contains(':')) {
        final endCv = endPart.split(':');
        endChapter = int.parse(endCv[0]);
        endVerse = int.parse(endCv[1]);
      } else {
        // If end part has no colon, it could be a verse (if start part had colon)
        // e.g. "1:1-38" -> endChapter is same as startChapter, endVerse is 38
        if (startPart.contains(':')) {
          endChapter = startChapter;
          endVerse = int.parse(endPart);
        } else {
          // e.g. "9-10" -> endChapter is 10
          endChapter = int.parse(endPart);
        }
      }
    } else {
      // No range, e.g. "1" or "1:1"
      if (refPart.contains(':')) {
        final cv = refPart.split(':');
        startChapter = int.parse(cv[0]);
        startVerse = int.parse(cv[1]);
        endChapter = startChapter;
        endVerse = startVerse;
      } else {
        startChapter = int.parse(refPart);
        endChapter = startChapter;
      }
    }

    return ParsedReference(
      bookName: bookName,
      startChapter: startChapter,
      endChapter: endChapter,
      startVerse: startVerse,
      endVerse: endVerse,
    );
  }
}
