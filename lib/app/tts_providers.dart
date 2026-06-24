import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content_store.dart';
import '../data/importer/mybible_verse_parser.dart';
import '../data/tts_service.dart';

enum TtsStatus { idle, playing, paused }

class TtsState {
  final TtsStatus status;

  /// Verse number currently being spoken (used to highlight + auto-scroll the
  /// reader), or null when idle.
  final int? currentVerse;

  /// User-facing playback speed multiplier (1.0 = normal).
  final double rate;

  const TtsState({
    this.status = TtsStatus.idle,
    this.currentVerse,
    this.rate = 1.0,
  });

  bool get isActive => status != TtsStatus.idle;

  TtsState copyWith({TtsStatus? status, int? currentVerse, double? rate}) {
    return TtsState(
      status: status ?? this.status,
      currentVerse: currentVerse ?? this.currentVerse,
      rate: rate ?? this.rate,
    );
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

/// Drives verse-by-verse read-aloud of the active chapter.
///
/// Each playback "session" captures a generation token; [stop]/[pause]/[start]
/// bump the generation so any in-flight `await speak()` loop notices it is stale
/// and exits cleanly. This sidesteps `flutter_tts`'s inconsistent pause/resume
/// support across platforms — pause is modelled as "stop, remember the verse"
/// and resume simply restarts the loop at that verse.
class TtsController extends Notifier<TtsState> {
  int _gen = 0;
  List<Verse> _verses = const [];

  @override
  TtsState build() {
    // Capture the service here; Riverpod forbids `ref.read` inside lifecycle
    // callbacks such as onDispose.
    final service = ref.watch(ttsServiceProvider);
    ref.onDispose(() {
      _gen++;
      service.stop();
    });
    return const TtsState();
  }

  /// Extract plain, speakable text for a verse. `textContent` carries inline
  /// MyBible markup (Strong's numbers, footnotes, formatting tags), so it must
  /// be run through the verse parser — the same cleaning the Copy action uses —
  /// before being spoken, or the engine reads the tag numbers aloud.
  String _plainText(Verse verse) {
    return MyBibleVerseParser()
        .parseVerse(verse.textContent)
        .map((s) => s.text)
        .join('')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Begin reading [verses], optionally starting at verse number [fromVerse].
  Future<void> start(List<Verse> verses, {int fromVerse = 0}) async {
    _gen++; // cancel any running loop
    await ref.read(ttsServiceProvider).stop();
    _verses = verses;
    final startIndex =
        fromVerse > 0 ? verses.indexWhere((v) => v.verse == fromVerse) : 0;
    _runFrom(startIndex < 0 ? 0 : startIndex);
  }

  Future<void> pause() async {
    _gen++;
    await ref.read(ttsServiceProvider).stop();
    state = state.copyWith(status: TtsStatus.paused);
  }

  Future<void> resume() async {
    final verse = state.currentVerse;
    final i = verse == null
        ? 0
        : _verses.indexWhere((v) => v.verse == verse);
    _runFrom(i < 0 ? 0 : i);
  }

  Future<void> stop() async {
    _gen++;
    await ref.read(ttsServiceProvider).stop();
    state = const TtsState();
  }

  /// Convenience for a single play/pause toggle button. [verses] and
  /// [fromVerse] are used only when starting fresh from idle; pausing then
  /// playing again resumes where it left off, ignoring [fromVerse].
  void toggle(List<Verse> verses, {int fromVerse = 0}) {
    switch (state.status) {
      case TtsStatus.playing:
        pause();
      case TtsStatus.paused:
        resume();
      case TtsStatus.idle:
        start(verses, fromVerse: fromVerse);
    }
  }

  Future<void> setRate(double multiplier) async {
    await ref.read(ttsServiceProvider).setRate(multiplier);
    state = state.copyWith(rate: multiplier);
  }

  Future<void> _runFrom(int startIndex) async {
    final svc = ref.read(ttsServiceProvider);
    final myGen = ++_gen;
    await svc.setRate(state.rate);

    var index = startIndex;
    while (index < _verses.length) {
      if (myGen != _gen) return; // superseded by stop/pause/start
      final verse = _verses[index];
      state = state.copyWith(status: TtsStatus.playing, currentVerse: verse.verse);
      final text = _plainText(verse);
      if (text.isNotEmpty) {
        try {
          await svc.speak(text);
        } catch (_) {
          // Swallow engine hiccups on a single verse and continue.
        }
      }
      if (myGen != _gen) return;
      index++;
    }
    // Reached the end of the chapter naturally.
    if (myGen == _gen) state = const TtsState();
  }
}

final ttsControllerProvider =
    NotifierProvider<TtsController, TtsState>(() => TtsController());

/// The verse number currently being read aloud, or null when not playing.
/// Used by the reader to tint + auto-scroll to the active verse.
final spokenVerseProvider = Provider<int?>((ref) {
  final s = ref.watch(ttsControllerProvider);
  return s.status == TtsStatus.idle ? null : s.currentVerse;
});
