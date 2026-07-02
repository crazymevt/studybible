import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/app_state.dart';
import 'package:study_bible/app/auto_sync.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';

class _CountingSyncService extends SyncService {
  _CountingSyncService(super.store, super.ref);

  int calls = 0;

  @override
  Future<void> sync() async {
    calls++;
  }
}

/// The auto-sync controller: off by default, a deferred startup sync when
/// enabled, periodic re-syncs at the chosen interval, and clean cancellation
/// when switched off. testWidgets gives us fake timers, so "waiting" an hour
/// is a pump call.
void main() {
  late UserStore store;
  late ProviderContainer container;
  late _CountingSyncService service;

  Future<void> setUpWith(Map<String, Object> prefValues) async {
    SharedPreferences.setMockInitialValues(prefValues);
    final prefs = await SharedPreferences.getInstance();
    store = UserStore(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      userStoreProvider.overrideWithValue(store),
      sharedPreferencesProvider.overrideWithValue(prefs),
      syncServiceProvider.overrideWith((ref) {
        service = _CountingSyncService(store, ref);
        return service;
      }),
    ]);
    addTearDown(store.close);
    // The provider is lazy; instantiate the counting service up front so the
    // zero-sync tests have something to assert against.
    container.read(syncServiceProvider);
    // Keep the controller alive, as the main shell's watch does.
    container.listen(autoSyncControllerProvider, (_, _) {});
  }

  // Called at the end of each test body: cancels the controller's timers
  // before testWidgets' pending-timer check runs (addTearDown is too late).
  void disposeContainer() => container.dispose();

  testWidgets('does nothing while the setting is off (the default)',
      (tester) async {
    await setUpWith({});

    await tester.pump(const Duration(hours: 2));
    expect(service.calls, 0);
    disposeContainer();
  });

  testWidgets('syncs shortly after startup, then on the default interval',
      (tester) async {
    await setUpWith({'autoSyncEnabled': true});

    // Not yet — the startup sync is deferred past first paint.
    await tester.pump(const Duration(seconds: 1));
    expect(service.calls, 0);

    await tester.pump(const Duration(seconds: 5));
    expect(service.calls, 1);

    await tester.pump(const Duration(minutes: 15));
    expect(service.calls, 2);
    await tester.pump(const Duration(minutes: 15));
    expect(service.calls, 3);
    disposeContainer();
  });

  testWidgets('honours a stored interval choice', (tester) async {
    await setUpWith({'autoSyncEnabled': true, 'autoSyncIntervalMinutes': 60});

    await tester.pump(const Duration(seconds: 5));
    expect(service.calls, 1);

    // 15-minute default tick must NOT fire.
    await tester.pump(const Duration(minutes: 30));
    expect(service.calls, 1);
    await tester.pump(const Duration(minutes: 30));
    expect(service.calls, 2);
    disposeContainer();
  });

  testWidgets('falls back to the default for an unknown stored interval',
      (tester) async {
    await setUpWith({'autoSyncEnabled': true, 'autoSyncIntervalMinutes': 7});
    expect(container.read(autoSyncIntervalProvider),
        kDefaultAutoSyncIntervalMinutes);
    disposeContainer();
  });

  testWidgets('turning the setting on starts syncing; off cancels the timers',
      (tester) async {
    await setUpWith({});

    container.read(autoSyncEnabledProvider.notifier).setEnabled(true);
    await tester.pump(const Duration(seconds: 5));
    expect(service.calls, 1);

    container.read(autoSyncEnabledProvider.notifier).setEnabled(false);
    await tester.pump(const Duration(hours: 2));
    expect(service.calls, 1);
    disposeContainer();
  });
}
