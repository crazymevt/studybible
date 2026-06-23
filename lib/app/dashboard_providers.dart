import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../data/user_store.dart';
import 'user_providers.dart';
import 'sync_service.dart';
import 'achievement_service.dart';

// --- DATA STREAMS ---

final readingProgressProvider = StreamProvider<List<ReadingProgress>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.readingProgresses)
        ..where((r) => r.deleted.equals(false))
        ..orderBy([
          (r) => OrderingTerm(expression: r.readAt, mode: OrderingMode.desc),
        ]))
      .watch();
});

final timeTrackerProvider = StreamProvider<List<TimeTracker>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.timeTrackers)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([
          (t) => OrderingTerm(expression: t.endTime, mode: OrderingMode.desc),
        ]))
      .watch();
});

final achievementsProvider = StreamProvider<List<Achievement>>((ref) {
  final store = ref.watch(userStoreProvider);
  return (store.select(
    store.achievements,
  )..where((a) => a.deleted.equals(false))).watch();
});

// --- AGGREGATES & DERIVATIVES ---

final bibleCoverageProvider = Provider<Map<String, List<int>>>((ref) {
  final progress = ref.watch(readingProgressProvider).value ?? [];
  final coverage = <String, Set<int>>{};

  for (final p in progress) {
    if (p.iteration == 1) {
      coverage.putIfAbsent(p.bookName, () => {}).add(p.chapter);
    }
  }

  return coverage.map((key, value) => MapEntry(key, value.toList()..sort()));
});

final timeAnalyticsProvider = Provider<Map<String, int>>((ref) {
  final trackers = ref.watch(timeTrackerProvider).value ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
  final startOfYearAgo = today.subtract(const Duration(days: 365));

  int thisWeekMs = 0;
  int lastWeekMs = 0;
  int yearAgoMs = 0;

  for (final t in trackers) {
    final d = DateTime.fromMillisecondsSinceEpoch(t.endTime).toLocal();
    if (d.isAfter(startOfWeek) || d.isAtSameMomentAs(startOfWeek)) {
      thisWeekMs += t.durationMs;
    } else if (d.isAfter(startOfLastWeek) ||
        d.isAtSameMomentAs(startOfLastWeek)) {
      lastWeekMs += t.durationMs;
    }

    // Rough year ago estimation
    final yearAgoWeekEnd = startOfYearAgo.add(const Duration(days: 7));
    if (d.isAfter(startOfYearAgo) && d.isBefore(yearAgoWeekEnd)) {
      yearAgoMs += t.durationMs;
    }
  }

  return {
    'thisWeekMs': thisWeekMs,
    'lastWeekMs': lastWeekMs,
    'yearAgoMs': yearAgoMs,
  };
});

final readingPaceProvider = Provider<Map<String, int>>((ref) {
  final progressRaw = ref.watch(readingProgressProvider).value ?? [];
  final trackers = ref.watch(timeTrackerProvider).value ?? [];

  final uniqueProgressMap = <String, ReadingProgress>{};
  for (final p in progressRaw) {
    final key = '${p.bookName}_${p.chapter}_${p.iteration}';
    if (!uniqueProgressMap.containsKey(key)) {
      uniqueProgressMap[key] = p;
    }
  }
  final progress = uniqueProgressMap.values.toList();

  final daysActive = <DateTime>{};
  for (final p in progress) {
    final d = DateTime.fromMillisecondsSinceEpoch(p.readAt).toLocal();
    daysActive.add(DateTime(d.year, d.month, d.day));
  }
  for (final t in trackers) {
    final d = DateTime.fromMillisecondsSinceEpoch(t.endTime).toLocal();
    daysActive.add(DateTime(d.year, d.month, d.day));
  }

  final sortedDays = daysActive.toList()..sort((a, b) => b.compareTo(a));

  int currentStreak = 0;
  int longestStreak = 0;
  int currentRun = 0;
  DateTime? prevDate;

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final yesterdayDate = todayDate.subtract(const Duration(days: 1));

  final ascDays = daysActive.toList()..sort((a, b) => a.compareTo(b));
  for (final d in ascDays) {
    if (prevDate == null) {
      currentRun = 1;
    } else {
      final diff = d.difference(prevDate).inDays;
      if (diff == 1) {
        currentRun++;
      } else if (diff > 1) {
        currentRun = 1;
      }
    }
    if (currentRun > longestStreak) longestStreak = currentRun;
    prevDate = d;
  }

  if (sortedDays.isNotEmpty) {
    if (sortedDays[0] == todayDate || sortedDays[0] == yesterdayDate) {
      currentStreak = 1;
      for (int i = 0; i < sortedDays.length - 1; i++) {
        final diff = sortedDays[i].difference(sortedDays[i + 1]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }
  }

  final startOfWeek = todayDate.subtract(Duration(days: today.weekday - 1));
  int chaptersThisWeek = 0;
  for (final p in progress) {
    final d = DateTime.fromMillisecondsSinceEpoch(p.readAt).toLocal();
    if (d.isAfter(startOfWeek) || d.isAtSameMomentAs(startOfWeek)) {
      chaptersThisWeek++;
    }
  }

  return {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'daysActive': daysActive.length,
    'chaptersThisWeek': chaptersThisWeek,
    'totalChaptersRead': progress.length,
  };
});

// --- ACTIONS ---

final dashboardActionProvider = Provider((ref) => DashboardAction(ref));

class DashboardAction {
  final Ref ref;
  DashboardAction(this.ref);

  Future<void> markChapterRead(String bookName, int chapter) async {
    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if it already exists for the current iteration.
    // For now, we assume iteration 1 unless we implement complex iteration logic later.
    final existing =
        await (store.select(store.readingProgresses)
              ..where((r) => r.bookName.equals(bookName))
              ..where((r) => r.chapter.equals(chapter))
              ..where((r) => r.deleted.equals(false)))
            .get();

    if (existing.isEmpty) {
      final newProgress = ReadingProgress(
        id: '${bookName}_${chapter}_1',
        updatedAt: now,
        deviceId: deviceId,
        deleted: false,
        bookName: bookName,
        chapter: chapter,
        readAt: now,
        iteration: 1,
      );
      // insertOrIgnore guards against a race: two paths (e.g. the auto-read
      // timer and audio auto-advance) can both observe an empty `existing`
      // and try to insert the same deterministic primary key. The second
      // write is silently dropped instead of throwing a unique-constraint
      // error, and the original readAt is preserved.
      await store
          .into(store.readingProgresses)
          .insert(newProgress, mode: InsertMode.insertOrIgnore);

      // Evaluate achievements. In the rare double-insert race this runs
      // twice, but achievement evaluation is idempotent.
      ref.read(achievementServiceProvider).evaluateAchievements();
    }
  }

  Future<void> logTime(int startTime, int endTime, String activityType) async {
    if (endTime - startTime < 1000) return; // Ignore less than 1 second

    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;

    final tracker = TimeTracker(
      id: const Uuid().v4(),
      updatedAt: now,
      deviceId: deviceId,
      deleted: false,
      startTime: startTime,
      endTime: endTime,
      durationMs: endTime - startTime,
      activityType: activityType,
    );
    await store.into(store.timeTrackers).insert(tracker);

    ref.read(achievementServiceProvider).evaluateAchievements();
  }

  Future<void> generateDummyTimeData() async {
    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    final now = DateTime.now();

    for (int i = 0; i < 200; i++) {
      // Spread across the last 365 days
      final d = now.subtract(Duration(days: (i * 1.8).toInt()));
      // Duration between 5 and 60 minutes
      final duration = (5 + (i % 55)) * 60000;

      final tracker = TimeTracker(
        id: const Uuid().v4(),
        updatedAt: now.millisecondsSinceEpoch,
        deviceId: deviceId,
        deleted: false,
        startTime: d.millisecondsSinceEpoch - duration,
        endTime: d.millisecondsSinceEpoch,
        durationMs: duration,
        activityType: 'reading',
      );
      await store.into(store.timeTrackers).insert(tracker);
    }
  }
}
