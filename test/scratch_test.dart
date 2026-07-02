import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/scratch_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';

class _NoopAchievementService extends AchievementService {
  _NoopAchievementService(super.ref);
  @override
  Future<void> evaluateAchievements() async {}
}

/// The scratch pad is a single, device-local row that never syncs and can be
/// promoted into a full sermon.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<List<Scratch>> rows() => store.select(store.scratches).get();

  test('save upserts a single pad row (never a second)', () async {
    final action = container.read(scratchActionProvider);
    await action.save('[{"insert":"first\\n"}]');
    await action.save('[{"insert":"second\\n"}]');

    final all = await rows();
    expect(all, hasLength(1));
    expect(all.single.id, kScratchPadId);
    expect(all.single.content, '[{"insert":"second\\n"}]');
  });

  test('clear empties the pad content', () async {
    final action = container.read(scratchActionProvider);
    await action.save('[{"insert":"jot\\n"}]');
    await action.clear();
    expect((await rows()).single.content, '');
  });

  test('promoteToSermon creates a sermon with the pad content, pad untouched',
      () async {
    final action = container.read(scratchActionProvider);
    const delta = '[{"insert":"sermon seed\\n"}]';
    await action.save(delta);

    final sermon = await action.promoteToSermon('My Sermon', delta);
    expect(sermon.title, 'My Sermon');
    expect(sermon.content, delta);

    // A real, non-deleted sermon row exists...
    final sermons = await (store.select(store.sermons)
          ..where((s) => s.deleted.equals(false)))
        .get();
    expect(sermons, hasLength(1));
    // ...and the pad is left as-is.
    expect((await rows()).single.content, delta);
  });

  test('sync never writes scratch content out (a synced entity still does)',
      () async {
    final tmpDir = await Directory.systemTemp.createTemp('scratch_sync');
    addTearDown(() => tmpDir.delete(recursive: true));

    SharedPreferences.setMockInitialValues({
      'syncFolderPath': tmpDir.path,
      'googleDriveEnabled': false,
    });
    final prefs = await SharedPreferences.getInstance();

    final syncStore = UserStore(NativeDatabase.memory());
    addTearDown(syncStore.close);
    final syncContainer = ProviderContainer(overrides: [
      userStoreProvider.overrideWithValue(syncStore),
      sharedPreferencesProvider.overrideWithValue(prefs),
      deviceIdProvider.overrideWith((ref) async => 'A'),
      achievementServiceProvider
          .overrideWith((ref) => _NoopAchievementService(ref)),
    ]);
    addTearDown(syncContainer.dispose);

    const scratchMarker = 'SCRATCH_SECRET_NOTE';
    const bookmarkMarker = 'BOOKMARK_LABEL';
    await syncContainer
        .read(scratchActionProvider)
        .save('[{"insert":"$scratchMarker\\n"}]');
    // A normal synced entity, to prove sync actually wrote something out.
    await syncContainer
        .read(bookmarkActionProvider)
        .saveBookmark(1, bookmarkMarker);

    await syncContainer.read(syncServiceProvider).sync();

    // The local device writes its own state file; it must carry the bookmark
    // but never the scratch content.
    final stateFile = File('${tmpDir.path}/state-A.jsonl');
    expect(stateFile.existsSync(), isTrue);
    final written = await stateFile.readAsString();
    expect(written, contains(bookmarkMarker));
    expect(written, isNot(contains(scratchMarker)));
  });
}
