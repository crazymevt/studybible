import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/journal_providers.dart';
import 'package:study_bible/app/revision_common.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/journals/journal_revisions_dialog.dart';

class _NoopAchievementService extends AchievementService {
  _NoopAchievementService(super.ref);
  @override
  Future<void> evaluateAchievements() async {}
}

Future<void> _insertJournal(
  UserStore store, {
  required String id,
  required String content,
  required int updatedAt,
  String device = 'A',
  String title = 'Journal',
}) async {
  await store.into(store.journals).insert(JournalsCompanion.insert(
        id: id,
        updatedAt: updatedAt,
        deviceId: device,
        title: title,
        content: content,
      ));
}

Future<List<JournalRevision>> _liveRevisions(UserStore store, String journalId) =>
    (store.select(store.journalRevisions)
          ..where((t) => t.journalId.equals(journalId) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

void main() {
  group('JournalRevisionAction', () {
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
      await _insertJournal(store, id: 'j1', content: 'draft', updatedAt: 100);

      await container.read(journalRevisionActionProvider).saveRevision(
            journalId: 'j1',
            title: 'My Entry',
            content: 'draft',
            label: 'Morning',
            kind: RevisionKind.manual,
          );

      final revs = await _liveRevisions(store, 'j1');
      expect(revs, hasLength(1));
      expect(revs.single.kind, RevisionKind.manual);
      expect(revs.single.label, 'Morning');
      expect(revs.single.content, 'draft');
    });

    test('restoreRevision restores content, snapshots prior, keeps the date',
        () async {
      await _insertJournal(store, id: 'j1', content: 'original', updatedAt: 100);
      await container.read(journalRevisionActionProvider).saveRevision(
            journalId: 'j1',
            title: 'Journal',
            content: 'original',
            kind: RevisionKind.manual,
          );

      // Entry is rewritten (date/updatedAt preserved, as the editor does).
      await store.into(store.journals).insert(
            (await (store.select(store.journals)..where((j) => j.id.equals('j1')))
                    .getSingle())
                .copyWith(content: 'rewritten'),
            mode: InsertMode.replace,
          );

      final manual = (await _liveRevisions(store, 'j1'))
          .firstWhere((r) => r.kind == RevisionKind.manual);
      await container
          .read(journalRevisionActionProvider)
          .restoreRevision(manual.id);

      final journal = await (store.select(store.journals)
            ..where((j) => j.id.equals('j1')))
          .getSingle();
      expect(journal.content, 'original');
      // Restoring does not re-date the entry.
      expect(journal.updatedAt, 100);

      final restoreSnaps = (await _liveRevisions(store, 'j1'))
          .where((r) => r.kind == RevisionKind.restore)
          .toList();
      expect(restoreSnaps, hasLength(1));
      expect(restoreSnaps.single.content, 'rewritten');
    });

    test('automatic revisions are pruned to the cap; manual ones are kept',
        () async {
      await _insertJournal(store, id: 'j1', content: 'x', updatedAt: 100);
      await container.read(journalRevisionActionProvider).saveRevision(
            journalId: 'j1',
            title: 'Journal',
            content: 'manual-keep',
            kind: RevisionKind.manual,
          );
      for (var i = 0; i < kMaxAutoRevisions + 5; i++) {
        await container.read(journalRevisionActionProvider).saveRevision(
              journalId: 'j1',
              title: 'Journal',
              content: 'auto-$i',
              kind: RevisionKind.conflict,
            );
      }

      final revs = await _liveRevisions(store, 'j1');
      expect(revs.where((r) => r.kind != RevisionKind.manual),
          hasLength(kMaxAutoRevisions));
      final manual = revs.where((r) => r.kind == RevisionKind.manual).toList();
      expect(manual, hasLength(1));
      expect(manual.single.content, 'manual-keep');
    });
  });

  group('Sync conflict backstop (journals)', () {
    test('snapshots the losing local journal before a remote edit overwrites it',
        () async {
      final tmpDir =
          await Directory.systemTemp.createTemp('journal_revisions_sync');
      addTearDown(() => tmpDir.delete(recursive: true));

      final store = UserStore(NativeDatabase.memory());
      addTearDown(store.close);

      await _insertJournal(store,
          id: 'j1', content: 'my local work', updatedAt: 100, device: 'A');

      final remoteLine = jsonEncode({
        'id': 'j1',
        'updatedAt': 200,
        'deviceId': 'B',
        'deleted': false,
        'type': 'journal',
        'title': 'Journal',
        'content': 'edit from other device',
        'tags': null,
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

      final journal = await (store.select(store.journals)
            ..where((j) => j.id.equals('j1')))
          .getSingle();
      expect(journal.content, 'edit from other device');

      final revs = await _liveRevisions(store, 'j1');
      expect(revs, hasLength(1));
      expect(revs.single.kind, RevisionKind.conflict);
      expect(revs.single.content, 'my local work');
    });
  });

  group('JournalRevisionsDialog', () {
    testWidgets('saving a labelled revision does not crash on dialog dismiss',
        (tester) async {
      final store = UserStore(NativeDatabase.memory());
      addTearDown(store.close);
      await _insertJournal(store, id: 'j1', content: 'draft', updatedAt: 100);

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
                  onPressed: () => JournalRevisionsDialog.show(
                    context,
                    journalId: 'j1',
                    currentTitle: 'My Entry',
                    currentContent: 'draft',
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
      await tester.tap(find.text('Save current version'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Morning entry');
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

      final revs = await _liveRevisions(store, 'j1');
      expect(revs, hasLength(1));
      expect(revs.single.label, 'Morning entry');
    });
  });
}
