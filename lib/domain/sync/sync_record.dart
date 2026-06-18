/// Represents the base metadata required for any synchronized record.
abstract class SyncRecord {
  String get id;
  int get updatedAt;
  String get deviceId;
  bool get deleted;
}
