import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/scripture_nav_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/domain/scripture/scripture_route.dart';
import 'package:study_bible/ui/reader/scripture_nav_bar.dart';

/// Drives the scripture-navigation mode through its bar: starting the mode
/// navigates the reader to the first stop, next/previous step through the
/// route, and closing ends the mode and removes the bar.
void main() {
  const stops = [
    ScriptureRouteStop(bookName: 'John', chapter: 3, verse: 16),
    ScriptureRouteStop(
      bookName: 'Romans',
      chapter: 8,
      verse: 28,
      endChapter: 8,
      endVerse: 30,
    ),
    ScriptureRouteStop(bookName: 'Psalms', chapter: 23),
  ];

  testWidgets('bar steps the reader through a sermon route', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedBookName': 'Genesis',
      'selectedChapter': 1,
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      contentStoreProvider.overrideWithValue(ContentStore(NativeDatabase.memory())),
      userStoreProvider.overrideWithValue(UserStore(NativeDatabase.memory())),
      // The real provider hits path_provider, which has no test implementation.
      deviceIdProvider.overrideWith((ref) async => 'test-device'),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ScriptureNavBar()),
        ),
      ),
    );

    // Inactive mode renders nothing.
    expect(find.byIcon(Icons.close), findsNothing);

    container
        .read(scriptureNavProvider.notifier)
        .start(sermonTitle: 'Grace', stops: stops);
    await tester.pump();

    // Starting the mode lands the reader on the first stop.
    expect(find.text('1/3'), findsOneWidget);
    expect(find.textContaining('John 3:16'), findsOneWidget);
    expect(container.read(selectedBookNameProvider), 'John');
    expect(container.read(selectedChapterProvider), 3);
    expect(container.read(targetVerseToScrollProvider), 16);

    // Next steps to the second stop.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(find.text('2/3'), findsOneWidget);
    expect(container.read(selectedBookNameProvider), 'Romans');
    expect(container.read(selectedChapterProvider), 8);
    expect(container.read(targetVerseToScrollProvider), 28);

    // A chapter-only stop targets verse 1.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(container.read(selectedBookNameProvider), 'Psalms');
    expect(container.read(selectedChapterProvider), 23);
    expect(container.read(targetVerseToScrollProvider), 1);

    // Next is disabled on the last stop; previous steps back.
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(find.text('2/3'), findsOneWidget);
    expect(container.read(selectedBookNameProvider), 'Romans');

    // Closing ends the mode and removes the bar.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(container.read(scriptureNavProvider), isNull);
    expect(find.text('2/3'), findsNothing);

    // Let recordHistory's async writes settle before the stores are disposed.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  });
}
