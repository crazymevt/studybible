import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../data/user_store.dart';

import '../data/sync/file_sync_engine.dart';
import '../domain/sync/lww_merge.dart';
import 'user_providers.dart';
import 'app_state.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';

final deviceIdProvider = FutureProvider<String>((ref) async {
  final docs = await getApplicationDocumentsDirectory();
  final file = File(p.join(docs.path, 'device_id.txt'));
  if (await file.exists()) {
    return await file.readAsString();
  } else {
    final newId = const Uuid().v4();
    await file.writeAsString(newId);
    return newId;
  }
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final userStore = ref.watch(userStoreProvider);
  return SyncService(userStore, ref);
});

class SyncService {
  final UserStore _store;
  final Ref _ref;
  FileSyncEngine? _engine;
  FileSystemEntity? _resolvedBookmarkEntity;

  SyncService(this._store, this._ref);

  Future<void> _ensureInit() async {
    if (_engine != null) return;

    final deviceId = await _ref.read(deviceIdProvider.future);

    final customPath = _ref.read(syncFolderPathProvider);
    final customBookmark = _ref.read(syncFolderBookmarkProvider);
    Directory syncDir;

    if (Platform.isMacOS &&
        customBookmark != null &&
        customBookmark.isNotEmpty) {
      final secureBookmarks = SecureBookmarks();
      _resolvedBookmarkEntity = await secureBookmarks.resolveBookmark(
        customBookmark,
        isDirectory: true,
      );
      syncDir = Directory(_resolvedBookmarkEntity!.path);
    } else if (customPath != null && customPath.isNotEmpty) {
      syncDir = Directory(customPath);
    } else {
      final docs = await getApplicationDocumentsDirectory();
      syncDir = Directory(p.join(docs.path, 'StudyBibleSync'));
    }

    // Only re-initialize if the path changed
    if (_engine != null && _engine!.syncFolder.path == syncDir.path) {
      return;
    }

    _engine = FileSyncEngine(syncFolder: syncDir, localDeviceId: deviceId);
  }

  Future<void> sync() async {
    await _ensureInit();

    if (_resolvedBookmarkEntity != null) {
      final secureBookmarks = SecureBookmarks();
      await secureBookmarks.startAccessingSecurityScopedResource(
        _resolvedBookmarkEntity!,
      );
    }

    try {
      // 1. Get all local records
      final localHighlights = await _store.select(_store.highlights).get();
      final localNotes = await _store.select(_store.notes).get();
      final localBookmarks = await _store.select(_store.bookmarks).get();
      final localJournals = await _store.select(_store.journals).get();
      final localSermons = await _store.select(_store.sermons).get();
      final localPrayers = await _store.select(_store.prayers).get();
      final localReadingprogresses = await _store
          .select(_store.readingProgresses)
          .get();
      final localTimetrackers = await _store.select(_store.timeTrackers).get();
      final localAchievements = await _store.select(_store.achievements).get();
      final localNavigationhistories = await _store
          .select(_store.navigationHistories)
          .get();
      final localReadingplans = await _store.select(_store.readingPlans).get();
      final localReadingplandays = await _store
          .select(_store.readingPlanDays)
          .get();
      final localReadingplanitems = await _store
          .select(_store.readingPlanItems)
          .get();
      final localTags = await _store.select(_store.tags).get();
      final localEntitytags = await _store.select(_store.entityTags).get();

      final localRecords = <GenericSyncRecord>[];

      localRecords.addAll(
        localHighlights.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'highlight',
              'bookName': item.bookName,
              'chapter': item.chapter,
              'verse': item.verse,
              'colorHex': item.colorHex,
            },
          ),
        ),
      );
      localRecords.addAll(
        localNotes.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'note',
              'bookName': item.bookName,
              'chapter': item.chapter,
              'verse': item.verse,
              'selectedVerses': item.selectedVerses,
              'content': item.content,
            },
          ),
        ),
      );
      localRecords.addAll(
        localBookmarks.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'bookmark',
              'bookName': item.bookName,
              'chapter': item.chapter,
              'verse': item.verse,
              'label': item.label,
            },
          ),
        ),
      );
      localRecords.addAll(
        localJournals.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'journal',
              'title': item.title,
              'content': item.content,
              'tags': item.tags,
            },
          ),
        ),
      );
      localRecords.addAll(
        localSermons.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'sermon',
              'createdAt': item.createdAt,
              'title': item.title,
              'series': item.series,
              'content': item.content,
            },
          ),
        ),
      );
      localRecords.addAll(
        localPrayers.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'prayer',
              'name': item.name,
              'description': item.description,
              'createdAt': item.createdAt,
              'answeredAt': item.answeredAt,
            },
          ),
        ),
      );
      localRecords.addAll(
        localReadingprogresses.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'readingProgress',
              'bookName': item.bookName,
              'chapter': item.chapter,
              'readAt': item.readAt,
              'iteration': item.iteration,
            },
          ),
        ),
      );
      localRecords.addAll(
        localTimetrackers.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'timeTracker',
              'startTime': item.startTime,
              'endTime': item.endTime,
              'durationMs': item.durationMs,
              'activityType': item.activityType,
            },
          ),
        ),
      );
      localRecords.addAll(
        localAchievements.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {'type': 'achievement', 'unlockedAt': item.unlockedAt},
          ),
        ),
      );
      localRecords.addAll(
        localNavigationhistories.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'navigationHistory',
              'bookName': item.bookName,
              'chapter': item.chapter,
              'verse': item.verse,
              'verseText': item.verseText,
            },
          ),
        ),
      );
      localRecords.addAll(
        localReadingplans.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'readingPlan',
              'title': item.title,
              'description': item.description,
              'startDate': item.startDate,
              'targetEndDate': item.targetEndDate,
            },
          ),
        ),
      );
      localRecords.addAll(
        localReadingplandays.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'readingPlanDay',
              'planId': item.planId,
              'dayNumber': item.dayNumber,
              'date': item.date,
              'completed': item.completed,
            },
          ),
        ),
      );
      localRecords.addAll(
        localReadingplanitems.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'readingPlanItem',
              'dayId': item.dayId,
              'bookName': item.bookName,
              'startChapter': item.startChapter,
              'endChapter': item.endChapter,
              'startVerse': item.startVerse,
              'endVerse': item.endVerse,
              'completed': item.completed,
            },
          ),
        ),
      );
      localRecords.addAll(
        localTags.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'tag',
              'name': item.name,
              'colorHex': item.colorHex,
            },
          ),
        ),
      );
      localRecords.addAll(
        localEntitytags.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'entityTag',
              'tagId': item.tagId,
              'entityId': item.entityId,
              'entityType': item.entityType,
            },
          ),
        ),
      );

      // 2. Pull remote records
      final remoteRecordsRaw = await _engine!.pull();
      final remoteRecords = remoteRecordsRaw.cast<GenericSyncRecord>();

      // 3. Merge
      final merged = mergeRecords(localRecords, remoteRecords);

      // 4. Update local DB
      await _store.transaction(() async {
        for (final rec in merged) {
          final type = rec.payload['type'] as String?;
          if (type == 'highlight') {
            final item = Highlight(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              bookName: rec.payload['bookName'] as String,
              chapter: (rec.payload['chapter'] as num).toInt(),
              verse: (rec.payload['verse'] as num).toInt(),
              colorHex: rec.payload['colorHex'] as String,
            );
            await _store
                .into(_store.highlights)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'note') {
            final item = Note(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              bookName: rec.payload['bookName'] as String,
              chapter: (rec.payload['chapter'] as num).toInt(),
              verse: (rec.payload['verse'] as num?)?.toInt(),
              selectedVerses: rec.payload['selectedVerses'] as String?,
              content: rec.payload['content'] as String,
            );
            await _store
                .into(_store.notes)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'bookmark') {
            final item = Bookmark(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              bookName: rec.payload['bookName'] as String,
              chapter: (rec.payload['chapter'] as num).toInt(),
              verse: (rec.payload['verse'] as num).toInt(),
              label: rec.payload['label'] as String,
            );
            await _store
                .into(_store.bookmarks)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'journal') {
            final item = Journal(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              title: rec.payload['title'] as String,
              content: rec.payload['content'] as String,
              tags: rec.payload['tags'] as String?,
            );
            await _store
                .into(_store.journals)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'sermon') {
            final item = Sermon(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              createdAt: (rec.payload['createdAt'] as num).toInt(),
              title: rec.payload['title'] as String,
              series: rec.payload['series'] as String?,
              content: rec.payload['content'] as String,
            );
            await _store
                .into(_store.sermons)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'prayer') {
            final item = Prayer(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              name: rec.payload['name'] as String,
              description: rec.payload['description'] as String,
              createdAt: (rec.payload['createdAt'] as num).toInt(),
              answeredAt: (rec.payload['answeredAt'] as num?)?.toInt(),
            );
            await _store
                .into(_store.prayers)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'readingProgress') {
            final item = ReadingProgress(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              bookName: rec.payload['bookName'] as String,
              chapter: (rec.payload['chapter'] as num).toInt(),
              readAt: (rec.payload['readAt'] as num).toInt(),
              iteration: (rec.payload['iteration'] as num).toInt(),
            );
            await _store
                .into(_store.readingProgresses)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'timeTracker') {
            final item = TimeTracker(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              startTime: (rec.payload['startTime'] as num).toInt(),
              endTime: (rec.payload['endTime'] as num).toInt(),
              durationMs: (rec.payload['durationMs'] as num).toInt(),
              activityType: rec.payload['activityType'] as String,
            );
            await _store
                .into(_store.timeTrackers)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'achievement') {
            final item = Achievement(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              unlockedAt: (rec.payload['unlockedAt'] as num).toInt(),
            );
            await _store
                .into(_store.achievements)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'navigationHistory') {
            final item = NavigationHistory(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              bookName: rec.payload['bookName'] as String,
              chapter: (rec.payload['chapter'] as num).toInt(),
              verse: (rec.payload['verse'] as num?)?.toInt(),
              verseText: rec.payload['verseText'] as String?,
            );
            await _store
                .into(_store.navigationHistories)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'readingPlan') {
            final item = ReadingPlan(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              title: rec.payload['title'] as String,
              description: rec.payload['description'] as String?,
              startDate: (rec.payload['startDate'] as num).toInt(),
              targetEndDate: (rec.payload['targetEndDate'] as num?)?.toInt(),
            );
            await _store
                .into(_store.readingPlans)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'readingPlanDay') {
            final item = ReadingPlanDay(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              planId: rec.payload['planId'] as String,
              dayNumber: (rec.payload['dayNumber'] as num).toInt(),
              date: (rec.payload['date'] as num?)?.toInt(),
              completed: rec.payload['completed'] == true,
            );
            await _store
                .into(_store.readingPlanDays)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'readingPlanItem') {
            final item = ReadingPlanItem(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              dayId: rec.payload['dayId'] as String,
              bookName: rec.payload['bookName'] as String,
              startChapter: (rec.payload['startChapter'] as num).toInt(),
              endChapter: (rec.payload['endChapter'] as num).toInt(),
              startVerse: (rec.payload['startVerse'] as num?)?.toInt(),
              endVerse: (rec.payload['endVerse'] as num?)?.toInt(),
              completed: rec.payload['completed'] == true,
            );
            await _store
                .into(_store.readingPlanItems)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'tag') {
            final item = Tag(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              name: rec.payload['name'] as String,
              colorHex: rec.payload['colorHex'] as String?,
            );
            await _store
                .into(_store.tags)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'entityTag') {
            final item = EntityTag(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              tagId: rec.payload['tagId'] as String,
              entityId: rec.payload['entityId'] as String,
              entityType: rec.payload['entityType'] as String,
            );
            await _store
                .into(_store.entityTags)
                .insert(item, mode: InsertMode.replace);
          }
        }
      });

      // 5. Push the resulting state
      await _engine!.push(merged);
    } finally {
      if (_resolvedBookmarkEntity != null) {
        final secureBookmarks = SecureBookmarks();
        await secureBookmarks.stopAccessingSecurityScopedResource(
          _resolvedBookmarkEntity!,
        );
      }
    }
  }
}
