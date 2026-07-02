import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_paths.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../data/user_store.dart';
import '../data/fts_text.dart';

import 'package:http/http.dart' as http;

import '../data/sync/file_sync_engine.dart';
import '../data/sync/sync_storage.dart';
import '../data/sync/saf_sync_storage.dart';
import '../data/sync/google_drive_auth.dart';
import '../data/sync/google_drive_sync_storage.dart';
import '../domain/sync/lww_merge.dart';
import 'user_providers.dart';
import 'app_state.dart';
import 'achievement_service.dart';
import 'revision_common.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';

final deviceIdProvider = FutureProvider<String>((ref) async {
  final docs = await appDataDir();
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

/// The platform-appropriate Google Drive auth handler (loopback on desktop,
/// google_sign_in on mobile).
final googleDriveAuthProvider = Provider<GoogleDriveAuth>(
  (ref) => GoogleDriveAuth(),
);

class SyncService {
  final UserStore _store;
  final Ref _ref;
  FileSyncEngine? _engine;
  FileSystemEntity? _resolvedBookmarkEntity;
  http.Client? _driveClient;

  SyncService(this._store, this._ref);

  Future<void> _ensureInit() async {
    final deviceId = await _ref.read(deviceIdProvider.future);

    final customPath = _ref.read(syncFolderPathProvider);
    final customBookmark = _ref.read(syncFolderBookmarkProvider);
    _resolvedBookmarkEntity = null;
    SyncStorage storage;

    final driveEnabled = _ref.read(googleDriveEnabledProvider);
    if (!driveEnabled && _driveClient != null) {
      _driveClient!.close();
      _driveClient = null;
    }
    if (driveEnabled) {
      // Reuse a connected client across syncs; only re-restore if we lost it.
      _driveClient ??= await _ref.read(googleDriveAuthProvider).restore();
      if (_driveClient != null) {
        final account = _ref.read(googleDriveAccountProvider) ?? 'connected';
        storage = GoogleDriveSyncStorage(_driveClient!, accountId: account);
      } else {
        // Drive is enabled but we have no usable credentials (revoked, or this
        // build lacks OAuth config). Fall back to the default local folder so
        // local data is still captured rather than silently dropped.
        final docs = await appDataDir();
        storage = IoSyncStorage(Directory(p.join(docs.path, 'StudyBibleSync')));
      }
    } else if (Platform.isAndroid &&
        customPath != null &&
        customPath.startsWith('content://')) {
      // On Android a custom folder is a persisted SAF tree URI, accessed
      // without any storage permission.
      storage = SafSyncStorage(customPath);
    } else if (Platform.isMacOS &&
        customBookmark != null &&
        customBookmark.isNotEmpty) {
      final secureBookmarks = SecureBookmarks();
      _resolvedBookmarkEntity = await secureBookmarks.resolveBookmark(
        customBookmark,
        isDirectory: true,
      );
      storage = IoSyncStorage(Directory(_resolvedBookmarkEntity!.path));
    } else if (!Platform.isAndroid &&
        customPath != null &&
        customPath.isNotEmpty) {
      // Desktop platforms address folders by plain filesystem path.
      storage = IoSyncStorage(Directory(customPath));
    } else {
      // Default: the app-private support directory — no permission needed.
      final docs = await appDataDir();
      storage = IoSyncStorage(Directory(p.join(docs.path, 'StudyBibleSync')));
    }

    // Only re-initialize if the configured target changed.
    if (_engine != null && _engine!.storage.id == storage.id) {
      return;
    }

    _engine = FileSyncEngine(storage: storage, localDeviceId: deviceId);
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
      final localJournalRevisions = await _store
          .select(_store.journalRevisions)
          .get();
      final localSermons = await _store.select(_store.sermons).get();
      final localSermonRevisions = await _store
          .select(_store.sermonRevisions)
          .get();
      final localPrayers = await _store.select(_store.prayers).get();
      final localActionItems = await _store.select(_store.actionItems).get();
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
              'pinned': item.pinned,
            },
          ),
        ),
      );
      localRecords.addAll(
        localJournalRevisions.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'journalRevision',
              'journalId': item.journalId,
              'createdAt': item.createdAt,
              'title': item.title,
              'content': item.content,
              'tags': item.tags,
              'label': item.label,
              'kind': item.kind,
            },
          ),
        ),
      );
      localRecords.addAll(
        localSermonRevisions.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'sermonRevision',
              'sermonId': item.sermonId,
              'createdAt': item.createdAt,
              'title': item.title,
              'series': item.series,
              'content': item.content,
              'label': item.label,
              'kind': item.kind,
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
        localActionItems.map(
          (item) => GenericSyncRecord(
            id: item.id,
            updatedAt: item.updatedAt,
            deviceId: item.deviceId,
            deleted: item.deleted,
            payload: {
              'type': 'actionItem',
              'title': item.title,
              'description': item.description,
              'createdAt': item.createdAt,
              'dueAt': item.dueAt,
              'completedAt': item.completedAt,
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
      final deviceId = await _ref.read(deviceIdProvider.future);
      // Sermons / journals whose local content this merge overwrote with a
      // different device's version; we snapshot the losing content (below) and
      // prune those snapshots after the transaction.
      final conflictedSermonIds = <String>{};
      final conflictedJournalIds = <String>{};
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
            final content = rec.payload['content'] as String;
            // Failsafe (mirrors sermons): snapshot the local losing content
            // before a different winning version overwrites it. This matters
            // more for journals — their updatedAt is the entry's date, so
            // same-day edits on two devices tie and break on deviceId.
            final localJournal = await (_store.select(
              _store.journals,
            )..where((t) => t.id.equals(rec.id))).getSingleOrNull();
            if (localJournal != null &&
                !localJournal.deleted &&
                localJournal.content != content) {
              final already =
                  await (_store.select(_store.journalRevisions)..where(
                        (t) =>
                            t.journalId.equals(rec.id) &
                            t.deleted.equals(false) &
                            t.content.equals(localJournal.content),
                      ))
                      .getSingleOrNull();
              if (already == null) {
                await _store
                    .into(_store.journalRevisions)
                    .insert(
                      JournalRevisionsCompanion.insert(
                        id: const Uuid().v4(),
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                        deviceId: deviceId,
                        createdAt: localJournal.updatedAt,
                        journalId: rec.id,
                        title: localJournal.title,
                        content: localJournal.content,
                        tags: Value(localJournal.tags),
                        label: const Value('Overwritten by another device'),
                        kind: RevisionKind.conflict,
                      ),
                    );
                conflictedJournalIds.add(rec.id);
              }
            }
            final item = Journal(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              title: rec.payload['title'] as String,
              content: content,
              // content_plain is not synced (derived); recompute it locally so
              // the search index for synced journals is plain text too.
              contentPlain: deltaToPlainText(content),
              tags: rec.payload['tags'] as String?,
            );
            await _store
                .into(_store.journals)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'sermon') {
            final content = rec.payload['content'] as String;
            // Failsafe: if this merge is about to replace a locally-stored
            // sermon's content with a different (winning) version, snapshot the
            // local losing content first so a cross-device clobber can never
            // silently destroy work. See lib/domain/sync/lww_merge.dart.
            final localSermon = await (_store.select(
              _store.sermons,
            )..where((t) => t.id.equals(rec.id))).getSingleOrNull();
            if (localSermon != null &&
                !localSermon.deleted &&
                localSermon.content != content) {
              // Dedupe: don't re-snapshot content we've already preserved for
              // this sermon (e.g. across repeated syncs).
              final already =
                  await (_store.select(_store.sermonRevisions)..where(
                        (t) =>
                            t.sermonId.equals(rec.id) &
                            t.deleted.equals(false) &
                            t.content.equals(localSermon.content),
                      ))
                      .getSingleOrNull();
              if (already == null) {
                await _store
                    .into(_store.sermonRevisions)
                    .insert(
                      SermonRevisionsCompanion.insert(
                        id: const Uuid().v4(),
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                        deviceId: deviceId,
                        // Stamp with when the losing version was actually
                        // written locally, not "now".
                        createdAt: localSermon.updatedAt,
                        sermonId: rec.id,
                        title: localSermon.title,
                        series: Value(localSermon.series),
                        content: localSermon.content,
                        label: const Value('Overwritten by another device'),
                        kind: RevisionKind.conflict,
                      ),
                    );
                conflictedSermonIds.add(rec.id);
              }
            }
            final item = Sermon(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              createdAt: (rec.payload['createdAt'] as num).toInt(),
              title: rec.payload['title'] as String,
              series: rec.payload['series'] as String?,
              content: content,
              // content_plain is not synced (derived); recompute it locally so
              // the search index for synced sermons is plain text too.
              contentPlain: deltaToPlainText(content),
              // Older peers won't send 'pinned'; default to unpinned.
              pinned: (rec.payload['pinned'] as bool?) ?? false,
            );
            await _store
                .into(_store.sermons)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'sermonRevision') {
            final item = SermonRevision(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              sermonId: rec.payload['sermonId'] as String,
              createdAt: (rec.payload['createdAt'] as num).toInt(),
              title: rec.payload['title'] as String,
              series: rec.payload['series'] as String?,
              content: rec.payload['content'] as String,
              label: rec.payload['label'] as String?,
              kind: rec.payload['kind'] as String,
            );
            await _store
                .into(_store.sermonRevisions)
                .insert(item, mode: InsertMode.replace);
          } else if (type == 'journalRevision') {
            final item = JournalRevision(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              journalId: rec.payload['journalId'] as String,
              createdAt: (rec.payload['createdAt'] as num).toInt(),
              title: rec.payload['title'] as String,
              content: rec.payload['content'] as String,
              tags: rec.payload['tags'] as String?,
              label: rec.payload['label'] as String?,
              kind: rec.payload['kind'] as String,
            );
            await _store
                .into(_store.journalRevisions)
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
          } else if (type == 'actionItem') {
            final item = ActionItem(
              id: rec.id,
              updatedAt: rec.updatedAt,
              deviceId: rec.deviceId,
              deleted: rec.deleted,
              title: rec.payload['title'] as String,
              description: (rec.payload['description'] as String?) ?? '',
              createdAt: (rec.payload['createdAt'] as num).toInt(),
              dueAt: (rec.payload['dueAt'] as num?)?.toInt(),
              completedAt: (rec.payload['completedAt'] as num?)?.toInt(),
            );
            await _store
                .into(_store.actionItems)
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

      // 4b. Prune the conflict-backup revisions just created to the per-entity
      // retention cap (manual revisions are excluded and never pruned).
      for (final sermonId in conflictedSermonIds) {
        final auto =
            await (_store.select(_store.sermonRevisions)
                  ..where(
                    (t) =>
                        t.sermonId.equals(sermonId) &
                        t.deleted.equals(false) &
                        t.kind.equals(RevisionKind.manual).not(),
                  )
                  ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
                .get();
        if (auto.length <= kMaxAutoRevisions) continue;
        final pruneTs = DateTime.now().millisecondsSinceEpoch;
        for (final stale in auto.skip(kMaxAutoRevisions)) {
          await (_store.update(
            _store.sermonRevisions,
          )..where((t) => t.id.equals(stale.id))).write(
            SermonRevisionsCompanion(
              deleted: const Value(true),
              updatedAt: Value(pruneTs),
            ),
          );
        }
      }
      for (final journalId in conflictedJournalIds) {
        final auto =
            await (_store.select(_store.journalRevisions)
                  ..where(
                    (t) =>
                        t.journalId.equals(journalId) &
                        t.deleted.equals(false) &
                        t.kind.equals(RevisionKind.manual).not(),
                  )
                  ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
                .get();
        if (auto.length <= kMaxAutoRevisions) continue;
        final pruneTs = DateTime.now().millisecondsSinceEpoch;
        for (final stale in auto.skip(kMaxAutoRevisions)) {
          await (_store.update(
            _store.journalRevisions,
          )..where((t) => t.id.equals(stale.id))).write(
            JournalRevisionsCompanion(
              deleted: const Value(true),
              updatedAt: Value(pruneTs),
            ),
          );
        }
      }

      // 5. Push the resulting state
      await _engine!.push(merged);

      // 6. Evaluate achievements locally in case new progress was synced
      _ref.read(achievementServiceProvider).evaluateAchievements();
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
