// Plain-text extraction for the full-text search index.
//
// Commentary and devotional content is stored as HTML. Indexing it verbatim
// pollutes the FTS5 vocabulary (and therefore search autocomplete) with markup
// and embedded junk tokens (tag names, attribute values, ids). Strip it to
// plain words before indexing.

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
