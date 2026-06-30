import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/revision_common.dart';
import 'package:study_bible/app/sermon_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/sermons/sermon_revisions_dialog.dart';

class _NoopAchievementService extends AchievementService {
  _NoopAchievementService(super.ref);
  @override
  Future<void> evaluateAchievements() async {}
}

String _delta(String text) => jsonEncode([
      {'insert': '$text\n'}
    ]);

Future<void> _insertSermon(
  UserStore store, {
  required String id,
  required String content,
  required int updatedAt,
  String device = 'A',
  String title = 'Sermon',
}) async {
  await store.into(store.sermons).insert(SermonsCompanion.insert(
        id: id,
        createdAt: 1,
        updatedAt: updatedAt,
        deviceId: device,
        title: title,
        content: content,
      ));
}

Future<List<SermonRevision>> _liveRevisions(
        UserStore store, String sermonId) =>
    (store.select(store.sermonRevisions)
          ..where((t) => t.sermonId.equals(sermonId) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

void main() {
  group('SermonRevisionActionNotifier', () {
    late UserStore store;
    late ProviderContainer container;

    setUp(() {
      store = UserStore(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        userStoreProvider.overrideWithValue(store),
        deviceIdProvider.overrideWith((ref) async => 'A'),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await store.close();
    });

    test('saveRevision stores a manual snapshot', () async {
      await _insertSermon(store,
          id: 's1', content: _delta('draft'), updatedAt: 100);

      await container.read(sermonRevisionActionProvider).saveRevision(
            sermonId: 's1',
            title: 'My Sermon',
            content: _delta('draft'),
            label: 'First draft',
            kind: RevisionKind.manual,
          );

      final revs = await _liveRevisions(store, 's1');
      expect(revs, hasLength(1));
      expect(revs.single.kind, RevisionKind.manual);
      expect(revs.single.label, 'First draft');
      expect(revs.single.content, _delta('draft'));
    });

    test('restoreRevision restores content and snapshots the prior version',
        () async {
      await _insertSermon(store,
          id: 's1', content: _delta('original'), updatedAt: 100);
      await container.read(sermonRevisionActionProvider).saveRevision(
            sermonId: 's1',
            title: 'Sermon',
            content: _delta('original'),
            kind: RevisionKind.manual,
          );

      // Sermon moves on.
      await container
          .read(sermonActionProvider)
          .updateSermon('s1', content: _delta('rewritten'));

      final manual = (await _liveRevisions(store, 's1'))
          .firstWhere((r) => r.kind == RevisionKind.manual);
      await container
          .read(sermonRevisionActionProvider)
          .restoreRevision(manual.id);

      // Sermon content is back to the restored revision.
      final sermon = await (store.select(store.sermons)
            ..where((t) => t.id.equals('s1')))
          .getSingle();
      expect(sermon.content, _delta('original'));

      // The pre-restore ("rewritten") state was preserved as a restore snapshot.
      final restoreSnaps = (await _liveRevisions(store, 's1'))
          .where((r) => r.kind == RevisionKind.restore)
          .toList();
      expect(restoreSnaps, hasLength(1));
      expect(restoreSnaps.single.content, _delta('rewritten'));
    });

    test('automatic revisions are pruned to the cap; manual ones are kept',
        () async {
      await _insertSermon(store,
          id: 's1', content: _delta('x'), updatedAt: 100);

      await container.read(sermonRevisionActionProvider).saveRevision(
            sermonId: 's1',
            title: 'Sermon',
            content: _delta('manual-keep'),
            kind: RevisionKind.manual,
          );

      for (var i = 0; i < kMaxAutoRevisions + 5; i++) {
        await container.read(sermonRevisionActionProvider).saveRevision(
              sermonId: 's1',
              title: 'Sermon',
              content: _delta('auto-$i'),
              kind: RevisionKind.conflict,
            );
      }

      final revs = await _liveRevisions(store, 's1');
      final auto =
          revs.where((r) => r.kind != RevisionKind.manual).toList();
      final manual =
          revs.where((r) => r.kind == RevisionKind.manual).toList();
      expect(auto, hasLength(kMaxAutoRevisions));
      expect(manual, hasLength(1));
      expect(manual.single.content, _delta('manual-keep'));
    });
  });

  group('Sync conflict backstop', () {
    test('snapshots the losing local sermon before a remote edit overwrites it',
        () async {
      final tmpDir =
          await Directory.systemTemp.createTemp('sermon_revisions_sync');
      addTearDown(() => tmpDir.delete(recursive: true));

      final store = UserStore(NativeDatabase.memory());
      addTearDown(store.close);

      // Local sermon, edited on this device.
      await _insertSermon(store,
          id: 's1',
          content: _delta('my local work'),
          updatedAt: 100,
          device: 'A');

      // A newer version of the same sermon from device B, sitting in the sync
      // folder waiting to be pulled.
      final remoteLine = jsonEncode({
        'id': 's1',
        'updatedAt': 200,
        'deviceId': 'B',
        'deleted': false,
        'type': 'sermon',
        'createdAt': 1,
        'title': 'Sermon',
        'series': null,
        'content': _delta('edit from other device'),
      });
      await File('${tmpDir.path}/state-B.jsonl').writeAsString('$remoteLine\n');

      SharedPreferences.setMockInitialValues({
        'syncFolderPath': tmpDir.path,
        'googleDriveEnabled': false,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        userStoreProvider.overrideWithValue(store),
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceIdProvider.overrideWith((ref) async => 'A'),
        achievementServiceProvider
            .overrideWith((ref) => _NoopAchievementService(ref)),
      ]);
      addTearDown(container.dispose);

      await container.read(syncServiceProvider).sync();

      // Remote version won (200 > 100).
      final sermon = await (store.select(store.sermons)
            ..where((t) => t.id.equals('s1')))
          .getSingle();
      expect(sermon.content, _delta('edit from other device'));

      // The overwritten local content was preserved as a conflict revision.
      final revs = await _liveRevisions(store, 's1');
      expect(revs, hasLength(1));
      expect(revs.single.kind, RevisionKind.conflict);
      expect(revs.single.content, _delta('my local work'));
    });

    test('no snapshot when the incoming version matches local content',
        () async {
      final tmpDir =
          await Directory.systemTemp.createTemp('sermon_revisions_sync2');
      addTearDown(() => tmpDir.delete(recursive: true));

      final store = UserStore(NativeDatabase.memory());
      addTearDown(store.close);

      await _insertSermon(store,
          id: 's1', content: _delta('same'), updatedAt: 100, device: 'A');

      final remoteLine = jsonEncode({
        'id': 's1',
        'updatedAt': 200,
        'deviceId': 'B',
        'deleted': false,
        'type': 'sermon',
        'createdAt': 1,
        'title': 'Sermon',
        'series': null,
        'content': _delta('same'),
      });
      await File('${tmpDir.path}/state-B.jsonl').writeAsString('$remoteLine\n');

      SharedPreferences.setMockInitialValues({
        'syncFolderPath': tmpDir.path,
        'googleDriveEnabled': false,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(overrides: [
        userStoreProvider.overrideWithValue(store),
        sharedPreferencesProvider.overrideWithValue(prefs),
        deviceIdProvider.overrideWith((ref) async => 'A'),
        achievementServiceProvider
            .overrideWith((ref) => _NoopAchievementService(ref)),
      ]);
      addTearDown(container.dispose);

      await container.read(syncServiceProvider).sync();

      expect(await _liveRevisions(store, 's1'), isEmpty);
    });
  });

  group('SermonRevisionsDialog', () {
    // Regression test: the save-label prompt used to dispose its
    // TextEditingController the instant showDialog returned, racing the dismiss
    // animation and throwing "_dependents.isEmpty is not true" /
    // "TextEditingController used after disposed" (same class as commit
    // 0da8e21). The prompt is now a StatefulWidget that disposes in dispose().
    testWidgets('saving a labelled revision does not crash on dialog dismiss',
        (tester) async {
      final store = UserStore(NativeDatabase.memory());
      addTearDown(store.close);
      await _insertSermon(store,
          id: 's1', content: _delta('draft'), updatedAt: 100);

      final container = ProviderContainer(overrides: [
        userStoreProvider.overrideWithValue(store),
        deviceIdProvider.overrideWith((ref) async => 'A'),
      ]);
      addTearDown(container.dispose);

      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => SermonRevisionsDialog.show(
                    context,
                    sermonId: 's1',
                    currentTitle: 'My Sermon',
                    currentContent: _delta('draft'),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Open the save-label prompt, enter a label, and save.
      await tester.tap(find.text('Save current version'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'First draft');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      final lifecycleErrors = errors
          .where((e) =>
              e.exceptionAsString().contains('_dependents.isEmpty') ||
              e.exceptionAsString().contains('used after') ||
              e.exceptionAsString().contains('wrong build scope') ||
              e.exceptionAsString().contains('disposed'))
          .toList();
      expect(lifecycleErrors, isEmpty,
          reason:
              lifecycleErrors.map((e) => e.exceptionAsString()).join('\n\n'));

      final revs = await _liveRevisions(store, 's1');
      expect(revs, hasLength(1));
      expect(revs.single.label, 'First draft');
    });
  });
}
