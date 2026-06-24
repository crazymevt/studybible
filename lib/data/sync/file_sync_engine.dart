import 'dart:convert';
import '../../domain/sync/sync_record.dart';
import '../logging.dart';
import 'sync_engine.dart';
import 'sync_storage.dart';

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
      payload: Map<String, dynamic>.from(json)
        ..remove('id')
        ..remove('updatedAt')
        ..remove('deviceId')
        ..remove('deleted'),
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
  final SyncStorage storage;
  final String localDeviceId;

  FileSyncEngine({required this.storage, required this.localDeviceId});

  String get _localName => 'state-$localDeviceId.jsonl';

  @override
  Future<void> push(List<SyncRecord> localRecords) async {
    final buffer = StringBuffer();
    for (final record in localRecords) {
      if (record is GenericSyncRecord) {
        buffer.writeln(jsonEncode(record.toJson()));
      }
    }
    await storage.writeDocument(_localName, buffer.toString());
  }

  @override
  Future<List<SyncRecord>> pull() async {
    final List<GenericSyncRecord> allRemoteRecords = [];

    final names = await storage.listDocuments('.jsonl');
    for (final name in names) {
      // Skip our own state file; we only pull other devices' records.
      if (name == _localName) continue;

      final lines = await storage.readLines(name);
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line);
          allRemoteRecords.add(GenericSyncRecord.fromJson(data));
        } catch (e, stack) {
          // Drop the malformed record but log it — a silently skipped remote
          // record can otherwise hide real data loss during sync.
          logError(e, stack, context: 'FileSyncEngine: malformed remote record');
        }
      }
    }

    return allRemoteRecords;
  }
}
