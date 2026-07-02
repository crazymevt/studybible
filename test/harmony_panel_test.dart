import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/harmony_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/domain/harmony/gospel_harmony.dart';
import 'package:study_bible/ui/reader/harmony_panel.dart';

const _fixture = '''
{
  "attribution": "Test harmony attribution",
  "sections": [
    {
      "title": "Signs",
      "events": [
        {"title": "Water into wine", "jn": [2, 1, 2, 3]},
        {"title": "Feeding crowds", "mt": [14, 13, 14, 21], "jn": [2, 2, 2, 3]}
      ]
    }
  ]
}
''';

/// Renders the Harmony panel against an in-memory content store: the event
/// list (with the current-chapter shortcut group), then an event's parallel
/// accounts with the verse-range query trimmed to the ref's bounds.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'selectedBookName': 'John',
      'selectedChapter': 2,
      'activeVersions': ['KJV'],
    });
    store = ContentStore(NativeDatabase.memory());
    await store.into(store.versions).insert(const Version(
        id: 'KJV', abbreviation: 'KJV', name: 'King James', language: 'en'));
    await store.into(store.books).insert(const BooksCompanion(
        id: Value(1),
        versionId: Value('KJV'),
        name: Value('John'),
        bookOrder: Value(43),
        testament: Value('NT')));
    for (var v = 1; v <= 5; v++) {
      await store.into(store.verses).insert(VersesCompanion(
          bookId: const Value(1),
          chapter: const Value(2),
          verse: Value(v),
          textContent: Value('John two verse $v.'),
          segments: const Value('[]')));
    }
  });

  tearDown(() async {
    await store.close();
  });

  Future<ProviderContainer> pumpPanel(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      contentStoreProvider.overrideWithValue(store),
      sharedPreferencesProvider.overrideWithValue(prefs),
      gospelHarmonyProvider.overrideWith(
          (ref) async => GospelHarmony.fromJsonString(_fixture)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: HarmonyPanel())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('lists sections, events, and the current-chapter group',
      (tester) async {
    await pumpPanel(tester);

    expect(find.text('Gospel Harmony'), findsOneWidget);
    expect(find.text('Signs'), findsOneWidget);
    // Both events touch John 2, so both repeat under the shortcut group.
    expect(find.text('In John 2'), findsOneWidget);
    expect(find.text('Water into wine'), findsNWidgets(2));
    expect(find.text('Test harmony attribution'), findsOneWidget);
  });

  testWidgets('opening an event shows each account trimmed to its range',
      (tester) async {
    final container = await pumpPanel(tester);

    await tester.tap(find.text('Feeding crowds').first);
    await tester.pumpAndSettle();

    expect(container.read(selectedHarmonyEventProvider), 1);
    // The John account covers 2:2-3 only.
    expect(find.text('John 2:2–3'), findsOneWidget);
    final text = tester
        .widget<SelectableText>(find.byType(SelectableText))
        .textSpan!
        .toPlainText();
    expect(text, contains('John two verse 2.'));
    expect(text, contains('John two verse 3.'));
    expect(text, isNot(contains('John two verse 1.')));
    expect(text, isNot(contains('John two verse 4.')));
    // The Matthew account isn't in this one-book store.
    expect(find.text('Matthew 14:13–21'), findsOneWidget);
    expect(find.text('Passage not available in the current version.'),
        findsOneWidget);

    // Back returns to the event list.
    await tester.tap(find.byTooltip('Back to events'));
    await tester.pumpAndSettle();
    expect(container.read(selectedHarmonyEventProvider), isNull);
    expect(find.text('Signs'), findsOneWidget);
  });
}
