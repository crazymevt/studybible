import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../app_paths.dart';

/// Metadata about a backup file.
class BackupManifest {
  final String appVersion;
  final String createdAt;
  final bool includesContent;
  final String? deviceId;

  BackupManifest({
    required this.appVersion,
    required this.createdAt,
    required this.includesContent,
    this.deviceId,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      appVersion: json['appVersion'] as String? ?? 'unknown',
      createdAt: json['createdAt'] as String? ?? 'unknown',
      includesContent: json['includesContent'] as bool? ?? false,
      deviceId: json['deviceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'appVersion': appVersion,
    'createdAt': createdAt,
    'includesContent': includesContent,
    if (deviceId != null) 'deviceId': deviceId,
  };
}

/// Result of inspecting a backup file before restore.
class BackupInfo {
  final BackupManifest manifest;
  final int fileSizeBytes;
  final bool hasUserDb;
  final bool hasContentDb;

  BackupInfo({
    required this.manifest,
    required this.fileSizeBytes,
    required this.hasUserDb,
    required this.hasContentDb,
  });
}

class BackupRestoreService {
  static const String _backupExtension = 'studybible';

  /// Returns the path to the documents directory where the databases live.
  Future<String> _getDbDir() async {
    final dir = await appDataDir();
    return dir.path;
  }

  /// Read the local device ID (if it exists).
  Future<String?> _readDeviceId() async {
    final dbDir = await _getDbDir();
    final file = File(p.join(dbDir, 'device_id.txt'));
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// Create a backup archive.
  ///
  /// Returns the path to the generated `.studybible` file in temp.
  /// The caller is responsible for moving/saving this file.
  Future<File> createBackup({
    required bool includeContent,
    Future<void> Function()? checkpoint,
    void Function(String status)? onProgress,
  }) async {
    final dbDir = await _getDbDir();
    final userDbFile = File(p.join(dbDir, 'user.db'));
    final contentDbFile = File(p.join(dbDir, 'content.db'));

    onProgress?.call('Preparing backup...');

    // The databases run in WAL mode, so the newest commits live in the
    // `*.db-wal` sidecar until they are checkpointed into the main file. We
    // archive only the main `.db` files, so flush the WAL first — otherwise a
    // backup taken while the app is live silently omits the user's most recent
    // notes, highlights, reading progress, etc.
    await checkpoint?.call();

    // Build the archive
    final archive = Archive();

    // Always include user.db
    if (await userDbFile.exists()) {
      onProgress?.call('Adding user data...');
      final userBytes = await userDbFile.readAsBytes();
      archive.addFile(ArchiveFile('user.db', userBytes.length, userBytes));
    }

    // Optionally include content.db
    if (includeContent && await contentDbFile.exists()) {
      onProgress?.call('Adding downloaded content...');
      final contentBytes = await contentDbFile.readAsBytes();
      archive.addFile(
        ArchiveFile('content.db', contentBytes.length, contentBytes),
      );
    }

    // Write manifest
    final deviceId = await _readDeviceId();
    final manifest = BackupManifest(
      appVersion: '1.0.0',
      createdAt: DateTime.now().toIso8601String(),
      includesContent: includeContent,
      deviceId: deviceId,
    );
    final manifestJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(manifest.toJson());
    final manifestBytes = utf8.encode(manifestJson);
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    // Encode as zip
    onProgress?.call('Compressing...');
    final zipBytes = ZipEncoder().encode(archive);

    // Write to temp directory
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final backupFile = File(
      p.join(tempDir.path, 'studybible_backup_$timestamp.$_backupExtension'),
    );
    await backupFile.parent.create(recursive: true);
    await backupFile.writeAsBytes(zipBytes);

    onProgress?.call('Backup created successfully');
    return backupFile;
  }

  Future<BackupInfo> inspectBackup(File backupFile) async {
    final inputStream = InputFileStream(backupFile.path);
    final archive = ZipDecoder().decodeStream(inputStream);

    BackupManifest manifest;
    bool hasUserDb = false;
    bool hasContentDb = false;

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile != null) {
      final json = jsonDecode(utf8.decode(manifestFile.content as List<int>));
      manifest = BackupManifest.fromJson(json);
    } else {
      manifest = BackupManifest(
        appVersion: 'unknown',
        createdAt: 'unknown',
        includesContent: false,
      );
    }

    for (final file in archive) {
      if (file.name == 'user.db') hasUserDb = true;
      if (file.name == 'content.db') hasContentDb = true;
    }

    inputStream.close();

    return BackupInfo(
      manifest: manifest,
      fileSizeBytes: await backupFile.length(),
      hasUserDb: hasUserDb,
      hasContentDb: hasContentDb,
    );
  }

  /// Restore from a backup file.
  ///
  /// This is destructive — it overwrites the current databases.
  /// The caller should close database connections before calling this,
  /// and reopen/restart after.
  Future<void> restoreBackup(
    File backupFile, {
    void Function(String status)? onProgress,
  }) async {
    final dbDir = await _getDbDir();

    onProgress?.call('Reading backup file...');
    final inputStream = InputFileStream(backupFile.path);
    final archive = ZipDecoder().decodeStream(inputStream);

    for (final file in archive) {
      if (file.name == 'user.db') {
        onProgress?.call('Restoring user data...');
        final targetFile = File(p.join(dbDir, 'user.db'));
        
        final wal = File('${targetFile.path}-wal');
        final shm = File('${targetFile.path}-shm');
        if (await wal.exists()) await wal.delete();
        if (await shm.exists()) await shm.delete();

        await targetFile.parent.create(recursive: true);
        final outStream = OutputFileStream(targetFile.path);
        file.writeContent(outStream);
        outStream.close();
      } else if (file.name == 'content.db') {
        onProgress?.call('Restoring downloaded content...');
        final targetFile = File(p.join(dbDir, 'content.db'));
        
        final wal = File('${targetFile.path}-wal');
        final shm = File('${targetFile.path}-shm');
        if (await wal.exists()) await wal.delete();
        if (await shm.exists()) await shm.delete();

        await targetFile.parent.create(recursive: true);
        final outStream = OutputFileStream(targetFile.path);
        file.writeContent(outStream);
        outStream.close();
      }
      // Skip manifest.json and anything else
    }

    inputStream.close();
    onProgress?.call('Restore complete. Please restart the app.');
  }

  /// Generate a default filename for the backup.
  String get defaultFilename {
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    return 'studybible_backup_$timestamp.$_backupExtension';
  }
}
