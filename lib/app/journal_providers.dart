import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../data/user_store.dart';
import 'user_providers.dart';
import 'sync_service.dart';

// JOURNALS
final journalsProvider = StreamProvider<List<Journal>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.journals)
        ..where((j) => j.deleted.equals(false))
        ..orderBy([(j) => OrderingTerm(expression: j.updatedAt, mode: OrderingMode.desc)]))
      .watch();
});

final journalActionProvider = Provider((ref) => JournalAction(ref));

class JournalAction {
  final Ref ref;
  JournalAction(this.ref);

  Future<String> saveJournal(String? id, String title, String content, {String? tags, DateTime? dateOverride}) async {
    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    
    final journalId = id ?? const Uuid().v4();
    final existing = id != null 
        ? await (store.select(store.journals)..where((j) => j.id.equals(id))).getSingleOrNull()
        : null;

    final updateTime = dateOverride?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

    if (existing != null) {
      await store.into(store.journals).insert(
        existing.copyWith(
          title: title, 
          content: content, 
          tags: Value(tags),
          // We don't overwrite updatedAt with a backdate if it's already an existing entry, unless we specifically want to.
          // Since the user is editing it *now*, we might want to keep its original date if it's backdated, 
          // or update to now. Let's keep it simple: use the override if provided.
          updatedAt: updateTime
        ),
        mode: InsertMode.replace,
      );
    } else {
      final newJournal = Journal(
        id: journalId,
        updatedAt: updateTime,
        deviceId: deviceId,
        deleted: false,
        title: title,
        content: content,
        tags: tags,
      );
      await store.into(store.journals).insert(newJournal);
    }
    return journalId;
  }
  
  Future<void> deleteJournal(String id) async {
    final store = ref.read(userStoreProvider);
    final existing = await (store.select(store.journals)..where((j) => j.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store.into(store.journals).insert(
        existing.copyWith(deleted: true, updatedAt: DateTime.now().millisecondsSinceEpoch),
        mode: InsertMode.replace,
      );
    }
  }
}

// PRAYERS
final prayersProvider = StreamProvider<List<Prayer>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.prayers)
        ..where((p) => p.deleted.equals(false))
        ..orderBy([(p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.desc)]))
      .watch();
});

final prayerActionProvider = Provider((ref) => PrayerAction(ref));

class PrayerAction {
  final Ref ref;
  PrayerAction(this.ref);

  Future<String> savePrayer(String? id, String name, String description) async {
    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final prayerId = id ?? const Uuid().v4();
    final existing = id != null 
        ? await (store.select(store.prayers)..where((p) => p.id.equals(id))).getSingleOrNull()
        : null;

    if (existing != null) {
      await store.into(store.prayers).insert(
        existing.copyWith(
          name: name, 
          description: description, 
          updatedAt: now
        ),
        mode: InsertMode.replace,
      );
    } else {
      final newPrayer = Prayer(
        id: prayerId,
        updatedAt: now,
        deviceId: deviceId,
        deleted: false,
        name: name,
        description: description,
        createdAt: now,
        answeredAt: null,
      );
      await store.into(store.prayers).insert(newPrayer);
    }
    return prayerId;
  }

  Future<void> toggleAnswered(String id, bool answered) async {
    final store = ref.read(userStoreProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final existing = await (store.select(store.prayers)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store.into(store.prayers).insert(
        existing.copyWith(
          answeredAt: Value(answered ? now : null),
          updatedAt: now,
        ),
        mode: InsertMode.replace,
      );
    }
  }
  
  Future<void> deletePrayer(String id) async {
    final store = ref.read(userStoreProvider);
    final existing = await (store.select(store.prayers)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await store.into(store.prayers).insert(
        existing.copyWith(deleted: true, updatedAt: DateTime.now().millisecondsSinceEpoch),
        mode: InsertMode.replace,
      );
    }
  }
}
