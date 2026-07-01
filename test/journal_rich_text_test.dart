import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/journal_providers.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/common/quill_content.dart';

void main() {
  group('documentFromStoredContent (migration safety net)', () {
    test('imports legacy plain text / markdown without dropping characters', () {
      const legacy = '# Prayer\n\nLord, today I am grateful for **grace**.';
      final doc = documentFromStoredContent(legacy);
      // Every character survives — the literal markdown becomes plain text.
      expect(doc.toPlainText().trim(), legacy);
    });

    test('reads Quill Delta JSON back as its rich text', () {
      final deltaJson = jsonEncode([
        {'insert': 'Hello '},
        {'insert': 'world', 'attributes': {'bold': true}},
        {'insert': '\n'},
      ]);
      final doc = documentFromStoredContent(deltaJson);
      expect(doc.toPlainText().trim(), 'Hello world');
    });

    test('an empty entry yields an empty document', () {
      expect(documentFromStoredContent('').toPlainText().trim(), '');
    });

    test('a bare-array-looking string that is not a Delta is not lost', () {
      // Valid JSON array, but not Quill ops — must import literally, not throw.
      final doc = documentFromStoredContent('[1, 2, 3]');
      expect(doc.toPlainText().trim(), '[1, 2, 3]');
    });
  });

  group('JournalAction writes a plain-text search projection', () {
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

    test('saveJournal stores content_plain derived from the Delta', () async {
      final deltaJson = jsonEncode([
        {'insert': 'Search me\n'},
      ]);
      final id = await container
          .read(journalActionProvider)
          .saveJournal(null, 'Title', deltaJson);

      final row = await (store.select(store.journals)
            ..where((j) => j.id.equals(id)))
          .getSingle();
      expect(row.content, deltaJson);
      expect(row.contentPlain, 'Search me');

      // And the FTS index carries the plain text, not the raw JSON.
      final hits = await store
          .customSelect(
            "SELECT reference_id FROM user_search "
            "WHERE type = 'journal' AND user_search MATCH 'Search'",
          )
          .get();
      expect(hits.map((r) => r.read<String>('reference_id')), contains(id));
    });
  });
}
