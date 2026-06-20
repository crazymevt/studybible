import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs.dart';

class ActiveVersionsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getStringList('activeVersions') ?? ['NLT'];
  }

  void set(List<String> versions) {
    state = versions;
    ref
        .read(sharedPreferencesProvider)
        .setStringList('activeVersions', versions);
  }

  void toggle(String version) {
    List<String> newState;
    if (state.contains(version)) {
      if (state.length > 1) {
        newState = state.where((v) => v != version).toList();
      } else {
        return; // Don't allow removing the last version
      }
    } else {
      newState = [...state, version];
    }
    set(newState);
  }
}

final activeVersionsProvider =
    NotifierProvider<ActiveVersionsNotifier, List<String>>(
      () => ActiveVersionsNotifier(),
    );

class SelectedBookNameNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('selectedBookName') ?? 'John';
  }

  void set(String name) {
    state = name;
    ref.read(sharedPreferencesProvider).setString('selectedBookName', name);
    ref.read(selectedVersesProvider.notifier).clear();
  }
}

final selectedBookNameProvider =
    NotifierProvider<SelectedBookNameNotifier, String>(
      () => SelectedBookNameNotifier(),
    );

enum RightPanelModule {
  commentaries,
  dictionary,
  crossReferences,
  notes,
  search,
  media,
  readingPlans,
}

class SelectedChapterNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('selectedChapter') ?? 1;
  }

  void set(int chapter) {
    state = chapter;
    ref.read(sharedPreferencesProvider).setInt('selectedChapter', chapter);
    ref.read(selectedVersesProvider.notifier).clear();
  }
}

final selectedChapterProvider = NotifierProvider<SelectedChapterNotifier, int>(
  () => SelectedChapterNotifier(),
);

// Added to allow jumping to a specific verse when navigating from outside
class TargetVerseNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? verse) => state = verse;
}

final targetVerseToScrollProvider = NotifierProvider<TargetVerseNotifier, int?>(
  () => TargetVerseNotifier(),
);

class SelectedVersesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  void toggle(int verseId) {
    final newState = Set<int>.from(state);
    if (newState.contains(verseId)) {
      newState.remove(verseId);
    } else {
      newState.add(verseId);
    }
    state = newState;
  }

  void clear() {
    state = <int>{};
  }
}

final selectedVersesProvider =
    NotifierProvider<SelectedVersesNotifier, Set<int>>(
      () => SelectedVersesNotifier(),
    );

class SelectedCommentaryNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final val = prefs.getInt('selectedCommentary');
    return val == 0 ? null : val;
  }

  void set(int? id) {
    state = id;
    if (id != null) {
      ref.read(sharedPreferencesProvider).setInt('selectedCommentary', id);
    } else {
      ref.read(sharedPreferencesProvider).remove('selectedCommentary');
    }
  }
}

final selectedCommentaryProvider =
    NotifierProvider<SelectedCommentaryNotifier, int?>(
      () => SelectedCommentaryNotifier(),
    );

class SelectedDevotionalIdNotifier extends Notifier<int?> {
  @override
  int? build() {
    return null;
  }
  
  void set(int? id) => state = id;
}

final selectedDevotionalIdProvider = NotifierProvider<SelectedDevotionalIdNotifier, int?>(
  () => SelectedDevotionalIdNotifier(),
);

class SelectedDevotionalDayNotifier extends Notifier<int> {
  @override
  int build() {
    return _getToday();
  }
  
  int _getToday() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    return now.difference(firstDayOfYear).inDays + 1;
  }
  
  void increment() => state++;
  void decrement() => state--;
  void set(int day) => state = day;
  void setToday() => state = _getToday();
}

final selectedDevotionalDayProvider = NotifierProvider<SelectedDevotionalDayNotifier, int>(
  () => SelectedDevotionalDayNotifier(),
);
