import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/reader/reader_screen.dart';

void main() {
  testWidgets(
      'ReaderScreen does not throw setState-during-build when the stored '
      'active version is not installed (self-heal path)', (tester) async {
    SharedPreferences.setMockInitialValues({
      'activeVersions': <String>['NLT'],
      'selectedBookName': 'John',
      'selectedChapter': 1,
    });
    final prefs = await SharedPreferences.getInstance();

    final content = ContentStore(NativeDatabase.memory());
    final user = UserStore(NativeDatabase.memory());

    await content.into(content.versions).insert(const VersionsCompanion(
          id: Value('BSB'),
          abbreviation: Value('BSB'),
          name: Value('Berean Standard Bible'),
        ));
    final bookId = await content.into(content.books).insert(BooksCompanion(
          versionId: const Value('BSB'),
          name: const Value('John'),
          bookOrder: const Value(43),
          testament: const Value('NT'),
        ));
    await content.into(content.verses).insert(VersesCompanion(
          bookId: Value(bookId),
          chapter: const Value(1),
          verse: const Value(1),
          textContent: const Value('In the beginning was the Word.'),
          segments: const Value('[]'),
        ));

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      contentStoreProvider.overrideWithValue(content),
      userStoreProvider.overrideWithValue(user),
    ]);
    addTearDown(container.dispose);

    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ReaderScreen()),
      ),
    );

    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Confirm the self-heal actually ran: stored ['NLT'] (not installed) should
    // have been corrected to the installed ['BSB'].
    expect(container.read(activeVersionsProvider), <String>['BSB'],
        reason: 'self-heal did not run; the scenario was not exercised');

    final buildErrors = errors
        .where((e) =>
            e.exceptionAsString().contains('called during build') ||
            e.exceptionAsString().contains('markNeedsBuild'))
        .toList();
    expect(buildErrors, isEmpty,
        reason: buildErrors.map((e) => e.exceptionAsString()).join('\n\n'));
  });
}
