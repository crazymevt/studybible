import 'sync_record.dart';

/// Merges an incoming list of records into an existing list using Last-Writer-Wins.
///
/// Rules:
/// 1. Newer `updatedAt` wins.
/// 2. If `updatedAt` is identical, `deleted == true` wins.
/// 3. If both timestamps and deleted flags are identical, it falls back to a stable
///    tie-breaker (comparing deviceIds lexically) to ensure determinism across all peers.
List<T> mergeRecords<T extends SyncRecord>(List<T> existing, List<T> incoming) {
  final Map<String, T> merged = { for (var e in existing) e.id: e };

  for (final inc in incoming) {
    final ex = merged[inc.id];
    if (ex == null) {
      merged[inc.id] = inc;
    } else {
      if (inc.updatedAt > ex.updatedAt) {
        merged[inc.id] = inc;
      } else if (inc.updatedAt == ex.updatedAt) {
        if (inc.deleted && !ex.deleted) {
          merged[inc.id] = inc;
        } else if (!inc.deleted && ex.deleted) {
          // Keep existing tombstone
        } else {
          // Tie-break on deviceId to ensure determinism
          if (inc.deviceId.compareTo(ex.deviceId) > 0) {
            merged[inc.id] = inc;
          }
        }
      }
    }
  }

  return merged.values.toList();
}
