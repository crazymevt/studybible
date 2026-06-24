import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/ui/whats_new_dialog.dart';

/// Pump a bounded number of frames. Avoids [WidgetTester.pumpAndSettle], which
/// never settles here because drift's in-memory background isolate keeps async
/// work pending across tests.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required bool showRebuildPrompt,
  required SharedPreferences prefs,
  required ContentStore store,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        contentStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: WhatsNewDialog(showRebuildPrompt: showRebuildPrompt),
        ),
      ),
    ),
  );
  await _settle(tester);
}

void main() {
  late ContentStore store;
  setUp(() => store = ContentStore(NativeDatabase.memory()));
  tearDown(() => store.close());

  testWidgets('shows the rebuild note and runs a one-tap rebuild', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pump(tester,
        showRebuildPrompt: true, prefs: prefs, store: store);

    expect(find.textContaining('Rebuild your search index'), findsOneWidget);
    expect(find.text('Rebuild now'), findsOneWidget);

    await tester.tap(find.text('Rebuild now'));
    await _settle(tester);

    // The note flips to a confirmation and the prompt is marked resolved for
    // the current generation.
    expect(find.textContaining('Search index rebuilt'), findsOneWidget);
    expect(prefs.getInt(kSearchIndexRebuiltGenKey), kSearchIndexGeneration);
  });

  testWidgets('omits the note when not prompted', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pump(tester,
        showRebuildPrompt: false, prefs: prefs, store: store);

    expect(find.text('Rebuild now'), findsNothing);
    expect(find.textContaining('Rebuild your search index'), findsNothing);
  });
}
