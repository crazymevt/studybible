// Smoke test: boots the real StudyBibleApp and verifies its widget/provider
// graph (theming, localization, routing into the shell) wires up and renders
// without throwing.
//
// The databases are overridden with in-memory Drift instances and the
// data-loading providers with empty results, so booting touches no
// path_provider, asset, file, or network I/O (none of which exist in the
// headless test VM). With no installed bibles the shell routes to the
// onboarding screen — exercising the full theme + MainShell build path.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:study_bible/main.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/content_manager_providers.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/onboarding/onboarding_screen.dart';

class MockBibleVersionsNotifier extends BibleVersionsNotifier {
  @override
  Future<List<Version>> build() async => [];
}

void main() {
  testWidgets('App boots into the onboarding shell with no content installed',
      (WidgetTester tester) async {
    // The theme builds its text theme via GoogleFonts; keep it from making
    // (timer-scheduling) network requests for fonts in the headless test VM.
    GoogleFonts.config.allowRuntimeFetching = false;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Own the container so we can dispose it (and drain Drift's async stream
    // cleanup, which schedules a zero-duration timer on close) before the test
    // framework's teardown runs its pending-timer assertion.
    await tester.runAsync(() async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // In-memory databases: no path_provider, no real files. Replacing the
          // providers also bypasses the real contentStore's startup cross-ref
          // import (which needs path_provider + bundled assets).
          contentStoreProvider.overrideWith((ref) {
            final store = ContentStore(NativeDatabase.memory());
            ref.onDispose(store.close);
            return store;
          }),
          userStoreProvider.overrideWith((ref) {
            final store = UserStore(NativeDatabase.memory());
            ref.onDispose(store.close);
            return store;
          }),
          bibleVersionsProvider.overrideWith(MockBibleVersionsNotifier.new),
          ph4CatalogProvider.overrideWith((ref) async => []),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const StudyBibleApp(),
        ),
      );
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Detach the tree, dispose providers, and let Drift's stream cleanup
      // (a zero-duration Timer scheduled on close) fire before teardown's
      // pending-timer assertion. A real delay is used rather than
      // Duration.zero: under the full suite's parallel load a zero-delay
      // future can resolve before the Timer runs, which made this flaky.
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
  });
}
