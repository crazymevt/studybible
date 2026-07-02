import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/sermon_providers.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _NoopAchievementService extends AchievementService {
  _NoopAchievementService(super.ref);
  @override
  Future<void> evaluateAchievements() async {}
}

String _delta(String text) => jsonEncode([
      {'insert': '$text\n'}
    ]);

void main() {
  group('SermonActionNotifier.setPinned', () {
    late UserStore store;
    late ProviderContainer container;

    setUp(() {
      store = UserStore(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        userStoreProvider.overrideWithValue(store),
        deviceIdProvider.overrideWith((ref) async => 'A'),
        achievementServiceProvider
            .overrideWith((ref) => _NoopAchievementService(ref)),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await store.close();
    });

    test('new sermons start unpinned', () async {
      final actions = container.read(sermonActionProvider);
      final sermon = await actions.createSermon('Test', content: _delta('hi'));
      expect(sermon.pinned, isFalse);
    });

    test('pinning sets the flag and bumps updatedAt', () async {
      final actions = container.read(sermonActionProvider);
      final sermon = await actions.createSermon('Test', content: _delta('hi'));

      await actions.setPinned(sermon.id, true);
      final pinned = await (store.select(store.sermons)
            ..where((t) => t.id.equals(sermon.id)))
          .getSingle();
      expect(pinned.pinned, isTrue);
      // Pinning must advance updatedAt so the change wins under sync LWW.
      expect(pinned.updatedAt, greaterThanOrEqualTo(sermon.updatedAt));

      await actions.setPinned(sermon.id, false);
      final unpinned = await (store.select(store.sermons)
            ..where((t) => t.id.equals(sermon.id)))
          .getSingle();
      expect(unpinned.pinned, isFalse);
    });
  });
}
