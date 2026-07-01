import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../data/content_store.dart';
import '../../domain/scripture/bible_reference_scanner.dart';

/// Turns Bible references typed into a sermon/journal body into tappable links
/// that jump to the reader, and handles those taps.
///
/// Links are stored as ordinary Quill `link` attributes carrying a custom
/// [_scheme] URL, so the read-only sermon presentation renders them tappable
/// for free. [handleReferenceLaunch] intercepts that scheme; any other URL
/// (a real hyperlink the user added) is opened in the browser as before.

const String _scheme = 'sbref';

/// Must be passed to `QuillEditorConfig.customLinkPrefixes` wherever these
/// links are shown. Without it flutter_quill's `LinkValidator` rejects the
/// custom scheme and rewrites the URL to `https://sbref:…` before handing it to
/// `onLaunchUrl`, so the tap silently does nothing.
const List<String> referenceLinkPrefixes = <String>[_scheme];

/// Encodes a reference as `sbref:<book>|<chapter>|<verse>` (verse may be empty).
/// The book name is percent-encoded so `|` in a name can't corrupt the URL.
String buildReferenceUrl(Book book, int chapter, int? verse) =>
    '$_scheme:${Uri.encodeComponent(book.name)}|$chapter|${verse ?? ''}';

/// A reference parsed back out of an [buildReferenceUrl] string.
class ParsedReferenceUrl {
  final String bookName;
  final int chapter;
  final int? verse;
  const ParsedReferenceUrl(this.bookName, this.chapter, this.verse);
}

/// Parses an `sbref:` URL, or returns null if [url] isn't one of ours.
ParsedReferenceUrl? parseReferenceUrl(String url) {
  if (!url.startsWith('$_scheme:')) return null;
  final body = url.substring(_scheme.length + 1);
  final parts = body.split('|');
  if (parts.length != 3) return null;
  final chapter = int.tryParse(parts[1]);
  if (chapter == null) return null;
  final verse = parts[2].isEmpty ? null : int.tryParse(parts[2]);
  return ParsedReferenceUrl(Uri.decodeComponent(parts[0]), chapter, verse);
}

/// Applies reference links to any not-yet-linked references in [controller]'s
/// text. Scans with `requireVerse` so ordinary prose that merely contains a
/// book name ("Mark 5 boxes") isn't rewritten — only verse-bearing citations
/// ("Mark 5:3") become links.
///
/// Idempotent: a reference that already carries a link (ours from a previous
/// pass, or one the user added by hand) is left alone, so re-running after the
/// document-change echo does nothing and can't loop. Returns whether it changed
/// the document.
bool applyReferenceAutolinks(QuillController controller, List<Book> books) {
  if (books.isEmpty) return false;
  final text = controller.document.toPlainText();
  final refs = BibleReferenceScanner.scan(text, books, requireVerse: true);
  var changed = false;
  for (final ref in refs) {
    final len = ref.end - ref.start;
    final existing = controller.document.collectStyle(ref.start, len);
    if (existing.attributes.containsKey(Attribute.link.key)) continue;
    controller.formatText(
      ref.start,
      len,
      LinkAttribute(buildReferenceUrl(ref.book, ref.chapter, ref.verse)),
    );
    changed = true;
  }
  return changed;
}

/// The books the reader resolves references against — the primary active
/// version's book list (empty until it has loaded, in which case linking simply
/// waits for the next edit).
List<Book> autolinkBooks(WidgetRef ref) {
  final versions = ref.read(activeVersionsProvider);
  if (versions.isEmpty) return const [];
  return ref.read(booksForVersionProvider(versions.first)).value ?? const [];
}

/// A [QuillEditorConfig.customLinkPrefixes]-style hook for tap handling: makes
/// reference links respond to a plain tap on every platform. flutter_quill only
/// wires tap-to-launch for links in read-only mode or on desktop; in an
/// editable editor on mobile it installs a *long-press* handler instead, so a
/// tap does nothing. Returning a tap recognizer for our `sbref:` links (and
/// null for anything else, leaving normal hyperlinks to their default
/// behaviour) gives consistent one-tap navigation everywhere.
GestureRecognizer? Function(Attribute, Leaf) referenceRecognizerBuilder(
  WidgetRef ref,
  BuildContext context,
) {
  return (attribute, leaf) {
    if (attribute.key != Attribute.link.key) return null;
    final value = attribute.value;
    if (value is! String || parseReferenceUrl(value) == null) return null;
    return TapGestureRecognizer()
      ..onTap = () => handleReferenceLaunch(ref, context, value);
  };
}

/// Handles a tapped link. For an `sbref:` URL, navigates the reader to the
/// reference and returns to the app shell (popping any pushed route such as the
/// sermon presentation). Any other URL falls back to launching it externally,
/// preserving the default behaviour for user-added hyperlinks.
Future<void> handleReferenceLaunch(
  WidgetRef ref,
  BuildContext context,
  String url,
) async {
  final parsed = parseReferenceUrl(url);
  if (parsed == null) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return;
  }

  ref.read(selectedBookNameProvider.notifier).set(parsed.bookName);
  ref.read(selectedChapterProvider.notifier).set(parsed.chapter);
  ref.read(targetVerseToScrollProvider.notifier).set(parsed.verse);
  ref.read(selectedVersesProvider.notifier).clear();
  if (parsed.verse != null) {
    ref.read(selectedVersesProvider.notifier).toggle(parsed.verse!);
  }
  ref.read(navigationControllerProvider).recordHistory(verse: parsed.verse);
  ref.read(appModuleProvider.notifier).setModule(AppModule.reader);

  // Return to the shell so the reader is visible (a no-op on desktop where the
  // editor is already inline at the root route).
  Navigator.of(context).popUntil((route) => route.isFirst);
}
