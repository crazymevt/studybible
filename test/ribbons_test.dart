import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/reader/verse_action_bar.dart';

/// Ribbons are single-verse return markers stored as [Bookmark] rows. These
/// exercise the one-tap toggle placement and the providers that back the reader
/// markers and the jump list.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookmarkAction.toggleBookmark', () {
    late UserStore store;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'selectedBookName': 'John',
        'selectedChapter': 3,
      });
      final prefs = await SharedPreferences.getInstance();
      store = UserStore(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        userStoreProvider.overrideWithValue(store),
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceIdProvider.overrideWith((ref) async => 'A'),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await store.close();
    });

    Future<List<Bookmark>> live() => (store.select(store.bookmarks)
          ..where((b) => b.deleted.equals(false)))
        .get();

    test('adds a ribbon auto-labeled with the reference, then removes it',
        () async {
      final action = container.read(bookmarkActionProvider);

      final added = await action.toggleBookmark(16);
      expect(added, isTrue);
      final rows = await live();
      expect(rows, hasLength(1));
      expect(rows.single.bookName, 'John');
      expect(rows.single.chapter, 3);
      expect(rows.single.verse, 16);
      expect(rows.single.label, 'John 3:16');

      final removed = await action.toggleBookmark(16);
      expect(removed, isFalse);
      expect(await live(), isEmpty);
    });

    test('toggling a second verse leaves the first in place', () async {
      final action = container.read(bookmarkActionProvider);
      await action.toggleBookmark(16);
      await action.toggleBookmark(17);
      expect((await live()).map((b) => b.verse).toSet(), {16, 17});
    });

    test('re-adding after removal produces a fresh, non-deleted row', () async {
      final action = container.read(bookmarkActionProvider);
      await action.toggleBookmark(16);
      await action.toggleBookmark(16); // remove
      final readded = await action.toggleBookmark(16);
      expect(readded, isTrue);
      expect(await live(), hasLength(1));
    });

    test('addBookmark is idempotent — never creates a duplicate', () async {
      final action = container.read(bookmarkActionProvider);
      await action.addBookmark(16);
      await action.addBookmark(16);
      expect(await live(), hasLength(1));
    });

    test('removeBookmark clears the ribbon and is safe when absent', () async {
      final action = container.read(bookmarkActionProvider);
      await action.addBookmark(16);
      await action.removeBookmark(16);
      await action.removeBookmark(16); // no-op, must not throw
      expect(await live(), isEmpty);
    });
  });

  group('ribbon read providers', () {
    late UserStore store;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'selectedBookName': 'John',
        'selectedChapter': 3,
      });
      final prefs = await SharedPreferences.getInstance();
      store = UserStore(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        userStoreProvider.overrideWithValue(store),
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceIdProvider.overrideWith((ref) async => 'A'),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await store.close();
    });

    test('chapter family exposes only the current chapter\'s verses', () async {
      final action = container.read(bookmarkActionProvider);
      await action.toggleBookmark(16); // John 3:16

      // A ribbon in a different chapter must not leak into John 3's set.
      container.read(selectedChapterProvider.notifier).set(1);
      await action.toggleBookmark(1); // John 1:1
      container.read(selectedChapterProvider.notifier).set(3);

      // Wait for the first non-loading emission, then drop the subscription
      // (reading `provider.future` directly races the container teardown).
      final completer = Completer<Set<int>>();
      final sub = container.listen(
        chapterVersesWithRibbonsFamilyProvider((bookName: 'John', chapter: 3)),
        (_, next) {
          if (next is AsyncData<Set<int>> && !completer.isCompleted) {
            completer.complete(next.value);
          }
        },
        fireImmediately: true,
      );
      final set = await completer.future;
      sub.close();
      expect(set, {16});
    });

    test('allBookmarksProvider returns every non-deleted ribbon', () async {
      final action = container.read(bookmarkActionProvider);
      await action.toggleBookmark(16);
      await action.toggleBookmark(17);
      await action.toggleBookmark(17); // remove 17

      final completer = Completer<List<Bookmark>>();
      final sub = container.listen(allBookmarksProvider, (_, next) {
        if (next is AsyncData<List<Bookmark>> && !completer.isCompleted) {
          completer.complete(next.value);
        }
      }, fireImmediately: true);
      final all = await completer.future;
      sub.close();
      expect(all.map((b) => b.verse), [16]);
    });
  });

  group('VerseActionBar Ribbon action', () {
    late UserStore store;
    late ProviderContainer container;

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: VerseActionBar())),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<List<int>> ribbonedVerses() async => ((await (store.select(
              store.bookmarks,
            )..where((b) => b.deleted.equals(false)))
                .get())
            .map((b) => b.verse)
            .toList()
          ..sort());

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'selectedBookName': 'John',
        'selectedChapter': 3,
      });
      final prefs = await SharedPreferences.getInstance();
      store = UserStore(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        userStoreProvider.overrideWithValue(store),
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceIdProvider.overrideWith((ref) async => 'A'),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await store.close();
    });

    testWidgets(
        'a mixed selection adds the missing ribbon without removing the existing one',
        (tester) async {
      // Verse 16 already ribboned; both 16 and 17 selected (the "navigated
      // verse still selected" case that used to un-ribbon 16).
      await container.read(bookmarkActionProvider).addBookmark(16);
      container.read(selectedVersesProvider.notifier).toggle(16);
      container.read(selectedVersesProvider.notifier).toggle(17);

      await pump(tester);
      await tester.tap(find.byTooltip('Ribbon'));
      await tester.pumpAndSettle();

      expect(await ribbonedVerses(), [16, 17]);
    });

    testWidgets('a fully-ribboned selection removes the ribbons',
        (tester) async {
      await container.read(bookmarkActionProvider).addBookmark(16);
      container.read(selectedVersesProvider.notifier).toggle(16);

      await pump(tester);
      await tester.tap(find.byTooltip('Ribbon'));
      await tester.pumpAndSettle();

      expect(await ribbonedVerses(), isEmpty);
    });
  });
}
