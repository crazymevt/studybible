import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:study_bible/data/sync/google_drive_sync_storage.dart';

/// Builds a [GoogleDriveSyncStorage] whose Drive API talks to a [MockClient]
/// emulating just the handful of REST endpoints the storage uses.
GoogleDriveSyncStorage storageWith(
  Future<http.Response> Function(http.Request req) handler,
) {
  final api = drive.DriveApi(MockClient(handler));
  return GoogleDriveSyncStorage.withApi(api, accountId: 'tester@example.com');
}

http.Response json(Object body) => http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('id encodes the account so SyncService can detect account changes', () {
    final storage = storageWith((_) async => json({'files': []}));
    expect(storage.id, 'gdrive:tester@example.com');
  });

  test('listDocuments returns only names matching the suffix', () async {
    final storage = storageWith((req) async {
      expect(req.method, 'GET');
      expect(req.url.queryParameters['spaces'], 'appDataFolder');
      return json({
        'files': [
          {'name': 'state-a.jsonl'},
          {'name': 'state-b.jsonl'},
          {'name': 'notes.txt'},
        ],
      });
    });

    final names = await storage.listDocuments('.jsonl');
    expect(names, ['state-a.jsonl', 'state-b.jsonl']);
  });

  test('readLines finds the file then downloads and splits its media',
      () async {
    final storage = storageWith((req) async {
      // Media download: GET .../files/<id> with alt=media.
      if (req.url.queryParameters['alt'] == 'media') {
        expect(req.url.path, endsWith('/files/file-1'));
        return http.Response('line one\nline two', 200,
            headers: {'content-type': 'application/octet-stream'});
      }
      // Otherwise it's the name lookup (files.list with a q filter).
      expect(req.url.queryParameters['q'], contains("name = 'state-a.jsonl'"));
      return json({
        'files': [
          {'id': 'file-1', 'name': 'state-a.jsonl'},
        ],
      });
    });

    final lines = await storage.readLines('state-a.jsonl');
    expect(lines, ['line one', 'line two']);
  });

  test('readLines returns empty when the document is absent', () async {
    final storage = storageWith((_) async => json({'files': []}));
    expect(await storage.readLines('missing.jsonl'), isEmpty);
  });

  test('writeDocument creates a new file when none exists', () async {
    final uploads = <String>[];
    final storage = storageWith((req) async {
      if (req.url.path.contains('/upload/')) {
        uploads.add(req.method);
        return json({'id': 'new-id', 'name': 'state-a.jsonl'});
      }
      // Lookup finds nothing -> create path.
      return json({'files': []});
    });

    await storage.writeDocument('state-a.jsonl', 'hello');
    expect(uploads, ['POST']); // create == POST to the upload endpoint
  });

  test('writeDocument updates the existing file when one is found', () async {
    final uploads = <String>[];
    final storage = storageWith((req) async {
      if (req.url.path.contains('/upload/')) {
        uploads.add(req.method);
        expect(req.url.path, contains('/files/file-1'));
        return json({'id': 'file-1', 'name': 'state-a.jsonl'});
      }
      return json({
        'files': [
          {'id': 'file-1', 'name': 'state-a.jsonl'},
        ],
      });
    });

    await storage.writeDocument('state-a.jsonl', 'updated');
    expect(uploads, ['PATCH']); // update == PATCH to the upload endpoint
  });
}
