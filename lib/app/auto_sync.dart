import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/logging.dart';
import 'app_state.dart';
import 'sync_service.dart';

/// Runs sync automatically while the app is open, when the user has opted in
/// (Settings → Sync → Auto sync): once shortly after this provider comes alive
/// (startup, or the moment the setting is switched on), then repeatedly at the
/// chosen interval. Failures are logged, never surfaced — auto sync must stay
/// invisible, and the next tick (or a manual sync) retries anyway.
///
/// Watched by the main shell so it lives exactly as long as the UI does.
final autoSyncControllerProvider = Provider<void>((ref) {
  final enabled = ref.watch(autoSyncEnabledProvider);
  if (!enabled) return;
  final minutes = ref.watch(autoSyncIntervalProvider);

  var syncing = false;
  var disposed = false;
  Future<void> run(String trigger) async {
    if (syncing || disposed) return;
    syncing = true;
    try {
      await ref.read(syncServiceProvider).sync();
    } catch (e, stack) {
      logError(e, stack, context: 'autoSync: $trigger');
    } finally {
      syncing = false;
    }
  }

  // Deferred a few seconds so the startup sync never competes with first
  // paint and the DB warm-up.
  final startup = Timer(const Duration(seconds: 5), () => run('startup'));
  final periodic =
      Timer.periodic(Duration(minutes: minutes), (_) => run('interval'));
  ref.onDispose(() {
    disposed = true;
    startup.cancel();
    periodic.cancel();
  });
});
