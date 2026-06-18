import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveVersionsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ['NLT'];
  void set(List<String> versions) => state = versions;
  void toggle(String version) {
    if (state.contains(version)) {
      if (state.length > 1) {
        state = state.where((v) => v != version).toList();
      }
    } else {
      state = [...state, version];
    }
  }
}
final activeVersionsProvider = NotifierProvider<ActiveVersionsNotifier, List<String>>(() => ActiveVersionsNotifier());

class SelectedBookNameNotifier extends Notifier<String> {
  @override
  String build() => 'John';
  void set(String name) => state = name;
}
final selectedBookNameProvider = NotifierProvider<SelectedBookNameNotifier, String>(() => SelectedBookNameNotifier());

class SelectedChapterNotifier extends Notifier<int> {
  @override
  int build() => 1;
  void set(int chapter) => state = chapter;
}
final selectedChapterProvider = NotifierProvider<SelectedChapterNotifier, int>(() => SelectedChapterNotifier());


