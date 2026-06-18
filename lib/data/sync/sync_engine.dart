import '../../domain/sync/sync_record.dart';

abstract class SyncEngine {
  /// Pushes local changes to the sync transport.
  Future<void> push(List<SyncRecord> localChanges);

  /// Pulls the latest records from the sync transport.
  Future<List<SyncRecord>> pull();
}
