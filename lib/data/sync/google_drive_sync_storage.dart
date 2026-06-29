import 'dart:convert';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'sync_storage.dart';

/// A [SyncStorage] backed by Google Drive's hidden, per-application
/// `appDataFolder`.
///
/// The `appDataFolder` is a special folder Drive scopes to this app alone: the
/// user never sees it in their Drive UI and our [drive.DriveApi] (granted only
/// the `drive.appdata` scope) cannot read or write any of the user's other
/// files. Each device writes a single `state-<deviceId>.jsonl` document there,
/// exactly like the filesystem backends — which is what makes this an
/// "app-specific sync folder" that works across every platform.
class GoogleDriveSyncStorage implements SyncStorage {
  /// The Drive special-folder alias usable as both a parent and a search space.
  static const _appDataFolder = 'appDataFolder';

  final drive.DriveApi _api;

  /// A stable id for the configured target, used by [SyncService] to detect
  /// when the account changed. Typically `gdrive:<email>`.
  final String _id;

  GoogleDriveSyncStorage(http.Client authClient, {required String accountId})
      : _api = drive.DriveApi(authClient),
        _id = 'gdrive:$accountId';

  /// Test seam: construct directly from a [drive.DriveApi].
  GoogleDriveSyncStorage.withApi(this._api, {required String accountId})
      : _id = 'gdrive:$accountId';

  @override
  String get id => _id;

  Future<String?> _findFileId(String name) async {
    final result = await _api.files.list(
      spaces: _appDataFolder,
      q: "name = '${name.replaceAll("'", r"\'")}'",
      $fields: 'files(id,name)',
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }

  @override
  Future<void> writeDocument(String name, String contents) async {
    final bytes = utf8.encode(contents);
    final media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'application/octet-stream',
    );

    final existingId = await _findFileId(name);
    if (existingId != null) {
      await _api.files.update(drive.File(), existingId, uploadMedia: media);
    } else {
      final metadata = drive.File()
        ..name = name
        ..parents = [_appDataFolder];
      await _api.files.create(metadata, uploadMedia: media);
    }
  }

  @override
  Future<List<String>> listDocuments(String suffix) async {
    final names = <String>[];
    String? pageToken;
    // Drive's query language has no "ends with", so we page through the folder
    // and filter by suffix client-side. The folder only holds our per-device
    // state files, so this stays small.
    do {
      final result = await _api.files.list(
        spaces: _appDataFolder,
        pageToken: pageToken,
        $fields: 'nextPageToken,files(name)',
      );
      for (final file in result.files ?? const <drive.File>[]) {
        final name = file.name;
        if (name != null && name.endsWith(suffix)) names.add(name);
      }
      pageToken = result.nextPageToken;
    } while (pageToken != null);
    return names;
  }

  @override
  Future<List<String>> readLines(String name) async {
    final fileId = await _findFileId(name);
    if (fileId == null) return [];
    final media = await _api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return const LineSplitter().convert(utf8.decode(builder.takeBytes()));
  }
}
