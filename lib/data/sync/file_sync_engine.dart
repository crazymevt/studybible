import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/sync/sync_record.dart';
import 'sync_engine.dart';

class GenericSyncRecord implements SyncRecord {
  @override
  final String id;
  @override
  final int updatedAt;
  @override
  final String deviceId;
  @override
  final bool deleted;
  
  final Map<String, dynamic> payload;

  GenericSyncRecord({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    required this.payload,
  });

  factory GenericSyncRecord.fromJson(Map<String, dynamic> json) {
    return GenericSyncRecord(
      id: json['id'] as String,
      updatedAt: json['updatedAt'] as int,
      deviceId: json['deviceId'] as String,
      deleted: json['deleted'] == true,
      payload: Map<String, dynamic>.from(json)..remove('id')..remove('updatedAt')..remove('deviceId')..remove('deleted'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'updatedAt': updatedAt,
      'deviceId': deviceId,
      'deleted': deleted,
      ...payload,
    };
  }
}

class FileSyncEngine implements SyncEngine {
  final Directory syncFolder;
  final String localDeviceId;

  FileSyncEngine({required this.syncFolder, required this.localDeviceId});

  File get _localFile => File(p.join(syncFolder.path, 'state-$localDeviceId.jsonl'));

  @override
  Future<void> push(List<SyncRecord> localRecords) async {
    if (!await syncFolder.exists()) {
      await syncFolder.create(recursive: true);
    }
    
    final sink = _localFile.openWrite();
    for (final record in localRecords) {
      if (record is GenericSyncRecord) {
        sink.writeln(jsonEncode(record.toJson()));
      }
    }
    await sink.close();
  }

  @override
  Future<List<SyncRecord>> pull() async {
    if (!await syncFolder.exists()) {
      return [];
    }

    final List<GenericSyncRecord> allRemoteRecords = [];

    final files = syncFolder.listSync().whereType<File>().where((f) => f.path.endsWith('.jsonl'));
    for (final file in files) {
      if (p.basename(file.path) == 'state-$localDeviceId.jsonl') continue;

      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line);
          allRemoteRecords.add(GenericSyncRecord.fromJson(data));
        } catch (e) {
          // Ignore malformed json
        }
      }
    }

    return allRemoteRecords;
  }
}
