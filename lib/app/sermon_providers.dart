import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../data/user_store.dart';
import '../data/fts_text.dart';
import 'tag_providers.dart';
import 'user_providers.dart';
import 'sync_service.dart';
import 'achievement_service.dart';

final allSermonsProvider = StreamProvider<List<Sermon>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.sermons)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)]))
      .watch();
});

class SelectedSermonIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) {
    state = id;
  }
}

final selectedSermonIdProvider = NotifierProvider<SelectedSermonIdNotifier, String?>(
  () => SelectedSermonIdNotifier(),
);

class SermonActionNotifier {
  final Ref _ref;
  final UserStore _store;

  SermonActionNotifier(this._ref, this._store);

  Future<Sermon> createSermon(String title, {String? series, String? content}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deviceId = await _ref.read(deviceIdProvider.future);
    final effectiveContent = content ?? '[{"insert":"\\n"}]';
    final sermon = SermonsCompanion.insert(
      id: const Uuid().v4(),
      createdAt: now,
      updatedAt: now,
      deviceId: deviceId,
      title: title,
      series: drift.Value(series),
      content: effectiveContent,
      contentPlain: drift.Value(deltaToPlainText(effectiveContent)),
    );
    await _store.into(_store.sermons).insert(sermon);
    _ref.read(achievementServiceProvider).evaluateAchievements();
    return (await (_store.select(_store.sermons)..where((t) => t.id.equals(sermon.id.value))).getSingle());
  }

  Future<void> updateSermon(String id, {String? title, String? series, String? content}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.sermons)..where((t) => t.id.equals(id))).write(
      SermonsCompanion(
        updatedAt: drift.Value(now),
        title: title != null ? drift.Value(title) : const drift.Value.absent(),
        series: series != null ? drift.Value(series) : const drift.Value.absent(),
        content: content != null ? drift.Value(content) : const drift.Value.absent(),
        contentPlain: content != null
            ? drift.Value(deltaToPlainText(content))
            : const drift.Value.absent(),
      ),
    );
  }

  Future<void> deleteSermon(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_store.update(_store.sermons)..where((t) => t.id.equals(id))).write(
      SermonsCompanion(
        deleted: const drift.Value(true),
        updatedAt: drift.Value(now),
      ),
    );
    await _ref.read(tagControllerProvider).removeAllTagsFromEntity(id);
  }
}

final sermonActionProvider = Provider<SermonActionNotifier>((ref) {
  final store = ref.watch(userStoreProvider);
  return SermonActionNotifier(ref, store);
});
