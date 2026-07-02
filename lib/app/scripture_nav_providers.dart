import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content_store.dart';
import '../domain/scripture/bible_reference_scanner.dart';
import '../domain/scripture/scripture_route.dart';
import 'app_state.dart';
import 'content_providers.dart';
import 'reader_state.dart';

/// Session-only "scripture navigation" mode: an ordered route of references
/// from a sermon that the reader steps through, temporarily highlighting each
/// stop's verses. Nothing here is persisted — closing the bar (or restarting
/// the app) discards it, and the highlights are purely visual.
class ScriptureNavState {
  final String sermonTitle;
  final List<ScriptureRouteStop> stops;
  final int index;

  const ScriptureNavState({
    required this.sermonTitle,
    required this.stops,
    required this.index,
  });

  ScriptureRouteStop get current => stops[index];
  bool get hasPrevious => index > 0;
  bool get hasNext => index < stops.length - 1;
}

/// Builds a sermon's route by scanning its plain text for references, in
/// document order. Chapter-only references are kept ("Psalm 23" is a normal
/// sermon citation); immediate repeats are collapsed.
List<ScriptureRouteStop> scanSermonRoute(String plainText, List<Book> books) {
  final matches = BibleReferenceScanner.scan(plainText, books);
  final stops = matches
      .map((m) => ScriptureRouteStop(
            bookName: m.book.name,
            chapter: m.chapter,
            verse: m.verse,
            endChapter: m.endChapter,
            endVerse: m.endVerse,
          ))
      .toList();
  return dedupeConsecutiveStops(stops);
}

class ScriptureNavNotifier extends Notifier<ScriptureNavState?> {
  @override
  ScriptureNavState? build() => null;

  /// Enters the mode on the first stop. [stops] must be non-empty.
  void start({
    required String sermonTitle,
    required List<ScriptureRouteStop> stops,
  }) {
    assert(stops.isNotEmpty);
    state = ScriptureNavState(sermonTitle: sermonTitle, stops: stops, index: 0);
    _navigateToCurrent();
  }

  void next() => jumpTo((state?.index ?? 0) + 1);

  void previous() => jumpTo((state?.index ?? 0) - 1);

  void jumpTo(int index) {
    final s = state;
    if (s == null || index < 0 || index >= s.stops.length) return;
    state = ScriptureNavState(
      sermonTitle: s.sermonTitle,
      stops: s.stops,
      index: index,
    );
    _navigateToCurrent();
  }

  void exit() {
    state = null;
  }

  /// Sends the reader to the current stop, mirroring how reference links
  /// navigate (see handleReferenceLaunch) minus the verse selection — the
  /// route's own temporary highlight marks the passage instead.
  void _navigateToCurrent() {
    final stop = state?.current;
    if (stop == null) return;
    ref.read(selectedBookNameProvider.notifier).set(stop.bookName);
    ref.read(selectedChapterProvider.notifier).set(stop.chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(stop.verse ?? 1);
    ref.read(selectedVersesProvider.notifier).clear();
    ref.read(navigationControllerProvider).recordHistory(verse: stop.verse);
    ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
  }
}

final scriptureNavProvider =
    NotifierProvider<ScriptureNavNotifier, ScriptureNavState?>(
  () => ScriptureNavNotifier(),
);
