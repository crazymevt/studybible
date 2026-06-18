import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/sync/sync_record.dart';
import 'package:study_bible/domain/sync/lww_merge.dart';

class TestRecord implements SyncRecord {
  @override
  final String id;
  @override
  final int updatedAt;
  @override
  final String deviceId;
  @override
  final bool deleted;

  final String data;

  TestRecord({
    required this.id,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
    this.data = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestRecord &&
          id == other.id &&
          updatedAt == other.updatedAt &&
          deviceId == other.deviceId &&
          deleted == other.deleted &&
          data == other.data;

  @override
  int get hashCode => id.hashCode ^ updatedAt.hashCode ^ deviceId.hashCode ^ deleted.hashCode ^ data.hashCode;
  
  @override
  String toString() => 'TestRecord(id: $id, data: $data, updatedAt: $updatedAt, dev: $deviceId, del: $deleted)';
}

void main() {
  group('LWW Merge', () {
    test('incoming newer record replaces existing', () {
      final existing = [TestRecord(id: '1', updatedAt: 100, deviceId: 'A', deleted: false, data: 'old')];
      final incoming = [TestRecord(id: '1', updatedAt: 200, deviceId: 'B', deleted: false, data: 'new')];
      
      final merged = mergeRecords(existing, incoming);
      expect(merged.length, 1);
      expect(merged.first.data, 'new');
    });

    test('existing newer record ignores incoming', () {
      final existing = [TestRecord(id: '1', updatedAt: 200, deviceId: 'A', deleted: false, data: 'newer')];
      final incoming = [TestRecord(id: '1', updatedAt: 100, deviceId: 'B', deleted: false, data: 'older')];
      
      final merged = mergeRecords(existing, incoming);
      expect(merged.length, 1);
      expect(merged.first.data, 'newer');
    });

    test('adds new records that do not exist', () {
      final existing = [TestRecord(id: '1', updatedAt: 100, deviceId: 'A', deleted: false, data: 'old')];
      final incoming = [TestRecord(id: '2', updatedAt: 200, deviceId: 'B', deleted: false, data: 'new')];
      
      final merged = mergeRecords(existing, incoming);
      expect(merged.length, 2);
      expect(merged.any((e) => e.id == '1'), isTrue);
      expect(merged.any((e) => e.id == '2'), isTrue);
    });

    test('tie-break: deleted wins if timestamps are identical', () {
      final existing = [TestRecord(id: '1', updatedAt: 100, deviceId: 'A', deleted: false, data: 'live')];
      final incoming = [TestRecord(id: '1', updatedAt: 100, deviceId: 'B', deleted: true, data: 'dead')];
      
      final merged1 = mergeRecords(existing, incoming);
      expect(merged1.first.deleted, isTrue);

      final merged2 = mergeRecords(incoming, existing); // order should not matter
      expect(merged2.first.deleted, isTrue);
    });

    test('tie-break: deviceId lexically wins if timestamps and deleted flag are identical', () {
      // Device B > Device A lexically
      final recordA = TestRecord(id: '1', updatedAt: 100, deviceId: 'A', deleted: false, data: 'dataA');
      final recordB = TestRecord(id: '1', updatedAt: 100, deviceId: 'B', deleted: false, data: 'dataB');
      
      final merged1 = mergeRecords([recordA], [recordB]);
      expect(merged1.first.data, 'dataB');

      final merged2 = mergeRecords([recordB], [recordA]);
      expect(merged2.first.data, 'dataB');
    });
  });
}
