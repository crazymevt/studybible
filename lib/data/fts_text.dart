// Plain-text extraction for the full-text search index.
//
// Commentary and devotional content is stored as HTML. Indexing it verbatim
// pollutes the FTS5 vocabulary (and therefore search autocomplete) with markup
// and embedded junk tokens (tag names, attribute values, ids). Strip it to
// plain words before indexing.

import 'dart:convert';

final RegExp _tagPattern = RegExp(r'<[^>]*>');
final RegExp _whitespacePattern = RegExp(r'\s+');

/// Removes HTML/XML markup and decodes the most common entities, producing
/// plain text suitable for the full-text search index. This is a fast, lenient
/// strip rather than a full HTML parse — it only needs to yield word tokens.
String stripMarkupForIndex(String input) {
  if (input.isEmpty || (!input.contains('<') && !input.contains('&'))) {
    return input;
  }

  var text = input.replaceAll(_tagPattern, ' ');

  if (text.contains('&')) {
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&'); // decode '&amp;' last to avoid re-decoding
  }

  return text.replaceAll(_whitespacePattern, ' ').trim();
}

/// Extracts plain text from a Quill Delta JSON string (a list of ops, each with
/// an `insert`). Used to index rich-text content (e.g. sermons) as words rather
/// than raw JSON. Falls back to returning the input unchanged if it is not
/// valid Delta JSON.
String deltaToPlainText(String deltaJson) {
  if (deltaJson.isEmpty) return deltaJson;
  try {
    final decoded = jsonDecode(deltaJson);
    if (decoded is! List) return deltaJson;
    final buffer = StringBuffer();
    for (final op in decoded) {
      if (op is Map && op['insert'] is String) {
        buffer.write(op['insert']);
      }
    }
    return buffer.toString().replaceAll(_whitespacePattern, ' ').trim();
  } catch (_) {
    return deltaJson;
  }
}
