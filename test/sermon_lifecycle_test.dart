import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/sermons/sermon_editor_screen.dart';
import 'package:study_bible/ui/sermons/sermons_panel.dart';

/// No-op achievement evaluation: the real one reads many tables and can fire UI
/// notifications via main.dart, neither of which this lifecycle test needs.
class _NoopAchievementService extends AchievementService {
  _NoopAchievementService(super.ref);
  @override
  Future<void> evaluateAchievements() async {}
}

void main() {
  // Regression test for the "crash when creating a new sermon" fix (0da8e21).
  // The New Sermon dialog used to dispose its text controllers the instant
  // showDialog returned and open the editor synchronously while the dialog
  // route was still tearing down, corrupting the element tree
  // ("_dependents.isEmpty is not true" / "TextEditingController used after
  // disposed"). Creating a sermon must mount the editor cleanly.
  testWidgets('creating a sermon mounts the editor without a lifecycle crash',
      (tester) async {
    // Wide surface so SermonsPanel takes the desktop path: creating a sermon
    // sets selectedSermonIdProvider and rebuilds the panel into the editor
    // in-place — the same "mount the editor right after the dialog" sequence
    // that used to crash.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final user = UserStore(NativeDatabase.memory());
    addTearDown(user.close);

    final container = ProviderContainer(overrides: [
      userStoreProvider.overrideWithValue(user),
      // path_provider-backed; would throw MissingPluginException in tests.
      deviceIdProvider.overrideWith((ref) async => 'test-device'),
      achievementServiceProvider.overrideWith((ref) => _NoopAchievementService(ref)),
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
        child: const MaterialApp(
          localizationsDelegates: [
            FlutterQuillLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: SermonsPanel()),
        ),
      ),
    );

    // Let the (empty) sermons stream resolve.
    await _settle(tester);
    expect(find.text('No sermons yet. Tap + to create one.'), findsOneWidget);

    // Open the New Sermon dialog.
    await tester.tap(find.byTooltip('New Sermon'));
    await tester.pumpAndSettle();
    expect(find.text('New Sermon'), findsOneWidget);

    // Fill the title and create.
    await tester.enterText(find.byType(TextField).first, 'Sermon on the Mount');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));

    // Drive the dialog dismiss + async createSermon + editor mount.
    await _settle(tester);

    final lifecycleErrors = errors
        .where((e) =>
            e.exceptionAsString().contains('_dependents.isEmpty') ||
            e.exceptionAsString().contains('used after') ||
            e.exceptionAsString().contains('called during build') ||
            e.exceptionAsString().contains('disposed'))
        .toList();
    expect(lifecycleErrors, isEmpty,
        reason: lifecycleErrors.map((e) => e.exceptionAsString()).join('\n\n'));

    // The editor actually mounted (the crash used to happen here).
    expect(find.byType(SermonEditorScreen), findsOneWidget);
  });
}

/// Pump several frames interleaved with real async turns so in-memory Drift
/// inserts and stream emissions complete (mirrors reader_self_heal_test).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
}
