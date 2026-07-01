import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../data/user_store.dart';
import '../data/models/achievement_def.dart';
import '../main.dart';
import 'user_providers.dart';
import 'sync_service.dart';

final achievementServiceProvider = Provider((ref) => AchievementService(ref));

class AchievementService {
  final Ref ref;

  AchievementService(this.ref);

  Future<void> evaluateAchievements() async {
    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Fetch current user data
    final notes = await (store.select(store.notes)..where((n) => n.deleted.equals(false))).get();
    final highlights = await (store.select(store.highlights)..where((h) => h.deleted.equals(false))).get();
    final prayers = await (store.select(store.prayers)..where((p) => p.deleted.equals(false))).get();
    final sermons = await (store.select(store.sermons)..where((s) => s.deleted.equals(false))).get();
    final readingProgressRaw = await (store.select(store.readingProgresses)..where((r) => r.deleted.equals(false))).get();
    
    final uniqueProgressMap = <String, ReadingProgress>{};
    final sortedProgress = readingProgressRaw.toList()..sort((a, b) => b.readAt.compareTo(a.readAt));
    for (final p in sortedProgress) {
      final key = '${p.bookName}_${p.chapter}_${p.iteration}';
      if (!uniqueProgressMap.containsKey(key)) {
        uniqueProgressMap[key] = p;
      }
    }
    final readingProgress = uniqueProgressMap.values.toList();
    final timeTrackers = await (store.select(store.timeTrackers)..where((t) => t.deleted.equals(false))).get();
    final plans = await (store.select(store.readingPlans)..where((p) => p.deleted.equals(false))).get();
    
    // Derived stats
    final notesCount = notes.length;
    final highlightsCount = highlights.length;
    final highlightColors = highlights.map((h) => h.colorHex).toSet();
    final prayersCount = prayers.length;
    final answeredPrayersCount = prayers.where((p) => p.answeredAt != null).length;
    final sermonsCount = sermons.length;
    
    final plansStarted = plans.isNotEmpty;
    // We assume a plan is finished if we can find any ReadingPlanDay for it that is fully complete.
    // To be precise, we query days and see if they are completed, but since we didn't query days, we can do a quick check:
    final planDays = await (store.select(store.readingPlanDays)..where((d) => d.deleted.equals(false))).get();
    // A better approach is: if there's any plan that has days, and all its days are complete.
    bool plansFinished = false;
    for (final plan in plans) {
      final daysForPlan = planDays.where((d) => d.planId == plan.id).toList();
      if (daysForPlan.isNotEmpty && daysForPlan.every((d) => d.completed)) {
        plansFinished = true;
        break;
      }
    }

    // Time tracking
    int totalTimeMs = 0;
    final daysActive = <DateTime>{};
    for (final t in timeTrackers) {
      totalTimeMs += t.durationMs;
      final d = DateTime.fromMillisecondsSinceEpoch(t.endTime).toLocal();
      daysActive.add(DateTime(d.year, d.month, d.day));
    }
    final totalHours = totalTimeMs / (1000 * 60 * 60);

    // Streaks
    int longestStreak = 0;
    int currentRun = 0;
    DateTime? prevDate;
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

    // Reading Progress
    final readSet = <String>{};
    final chaptersByDay = <DateTime, int>{};
    for (final r in readingProgress) {
      if (r.iteration == 1) {
        readSet.add('${r.bookName}|${r.chapter}');
      }
      final d = DateTime.fromMillisecondsSinceEpoch(r.readAt).toLocal();
      final day = DateTime(d.year, d.month, d.day);
      chaptersByDay[day] = (chaptersByDay[day] ?? 0) + 1;
    }

    final maxChaptersInDay = chaptersByDay.values.fold(0, (max, count) => count > max ? count : max);
    final anyRead = readSet.isNotEmpty;

    int booksCompletedCount = 0;
    bool otCompleted = true;
    bool ntCompleted = true;
    bool pentateuchCompleted = true;
    bool wisdomCompleted = true;
    bool majorProphetsCompleted = true;
    bool minorProphetsCompleted = true;
    bool paulineCompleted = true;
    bool fourfoldCompleted = true;
    bool goodNewsCompleted = false;
    
    // "In One Sitting": any book — including single-chapter ones like Jude,
    // Obadiah, Philemon, 2/3 John — fully read within a single day.
    final bookInADay = anyBookReadInOneDay(readingProgress);

    // Evaluate Book Groups
    void evaluateGroup(List<String> bookNames, void Function(bool) setGroup) {
      bool allFinished = true;
      for (final book in bookNames) {
        if (!checkBookFinished(book, readSet)) {
          allFinished = false;
        } else {
          booksCompletedCount++;
        }
      }
      setGroup(allFinished);
    }

    evaluateGroup(_pentateuch, (v) => pentateuchCompleted = v);
    evaluateGroup(_history, (v) {});
    evaluateGroup(_wisdom, (v) => wisdomCompleted = v);
    evaluateGroup(_majorProphets, (v) => majorProphetsCompleted = v);
    evaluateGroup(_minorProphets, (v) => minorProphetsCompleted = v);
    
    evaluateGroup(_gospels, (v) {
      fourfoldCompleted = v;
    });
    for (final g in _gospels) {
      if (checkBookFinished(g, readSet)) goodNewsCompleted = true;
    }

    evaluateGroup(_historyNt, (v) {});
    evaluateGroup(_pauline, (v) => paulineCompleted = v);
    evaluateGroup(_generalEpistles, (v) {});
    evaluateGroup(_prophecyNt, (v) {});

    otCompleted = pentateuchCompleted && wisdomCompleted && majorProphetsCompleted && minorProphetsCompleted && _history.every((b) => checkBookFinished(b, readSet));
    ntCompleted = fourfoldCompleted && paulineCompleted && _historyNt.every((b) => checkBookFinished(b, readSet)) && _generalEpistles.every((b) => checkBookFinished(b, readSet)) && _prophecyNt.every((b) => checkBookFinished(b, readSet));

    final wholeStory = otCompleted && ntCompleted;

    // Check earned conditions
    final earnedIds = <String>{};

    // Reading
    if (anyRead) earnedIds.add('first_steps');
    if (maxChaptersInDay >= 10) earnedIds.add('marathon');
    if (bookInADay) earnedIds.add('one_sitting');
    if (booksCompletedCount >= 1) earnedIds.add('bookworm');
    if (booksCompletedCount >= 5) earnedIds.add('five_books');
    if (booksCompletedCount >= 25) earnedIds.add('many_books');
    if (wholeStory) earnedIds.add('whole_story');
    // For thrice and well_worn, we need to check multiple iterations. Currently we only look at iteration 1. 
    // We can infer iterations by dividing total reads by 1189 if we assume they read exactly the Bible, but let's just use the store logic if we implement iteration.
    // For now, if iteration counts are available:
    final biblesCompleted = _computeBiblesCompleted(readingProgress);
    if (biblesCompleted >= 3) earnedIds.add('thrice');
    if (biblesCompleted >= 5) earnedIds.add('well_worn');

    // Scripture
    if (pentateuchCompleted) earnedIds.add('pentateuch');
    if (wisdomCompleted) earnedIds.add('wisdom');
    if (majorProphetsCompleted) earnedIds.add('major_prophets');
    if (minorProphetsCompleted) earnedIds.add('minor_prophets');
    if (goodNewsCompleted) earnedIds.add('good_news');
    if (fourfoldCompleted) earnedIds.add('fourfold');
    if (paulineCompleted) earnedIds.add('pauline');
    if (otCompleted) earnedIds.add('law_prophets');
    if (ntCompleted) earnedIds.add('new_covenant');
    if (allShortBooksFinished(readSet)) earnedIds.add('short_book_reader');

    // Habits
    if (longestStreak >= 7) earnedIds.add('consistent');
    if (longestStreak >= 30) earnedIds.add('devoted');
    if (longestStreak >= 100) earnedIds.add('centurion');
    if (longestStreak >= 365) earnedIds.add('year');
    if (totalHours >= 10) earnedIds.add('diligent');
    if (totalHours >= 50) earnedIds.add('devout');
    if (totalHours >= 100) earnedIds.add('steadfast');

    // Study
    if (notesCount >= 1) earnedIds.add('scribe');
    if (notesCount >= 25) earnedIds.add('note_taker');
    if (notesCount >= 100) earnedIds.add('commentator');
    if (highlightsCount >= 1) earnedIds.add('illuminator');
    if (highlightsCount >= 25) earnedIds.add('highlighter');
    if (highlightsCount >= 100) earnedIds.add('luminary');
    if (highlightColors.length >= 5) earnedIds.add('rainbow'); // Simplified check for "all colors"
    if (answeredPrayersCount >= 1) earnedIds.add('answered');
    if (prayersCount >= 10) earnedIds.add('prayerful');
    if (sermonsCount >= 1) earnedIds.add('expositor');
    if (sermonsCount >= 5) earnedIds.add('homilist');

    // Plans
    if (plansStarted) earnedIds.add('plan_starter');
    if (plansFinished) earnedIds.add('plan_finisher');

    // Fetch existing unlocked achievements
    final existingAchievements = await store.select(store.achievements).get();
    final existingIds = existingAchievements.where((a) => !a.deleted).map((a) => a.id).toSet();

    for (final id in earnedIds) {
      if (!existingIds.contains(id)) {
        await _unlockAchievement(id, store, deviceId, now);
      }
    }
  }

  Future<void> _unlockAchievement(String id, UserStore store, String deviceId, int now) async {
    final existing = await (store.select(store.achievements)..where((a) => a.id.equals(id))).getSingleOrNull();
    
    if (existing == null) {
      final achievement = Achievement(
        id: id,
        updatedAt: now,
        deviceId: deviceId,
        deleted: false,
        unlockedAt: now,
      );
      await store.into(store.achievements).insert(achievement);
    } else if (existing.deleted) {
      await store.into(store.achievements).insert(
        existing.copyWith(deleted: false, updatedAt: now),
        mode: InsertMode.replace,
      );
    }

    final def = allAchievements.where((a) => a.id == id).firstOrNull;
    if (def != null && scaffoldMessengerKey.currentState != null) {
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Achievement Unlocked!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(def.name),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _computeBiblesCompleted(List<ReadingProgress> progress) {
    return completedBiblePasses(chapterReadCounts(progress));
  }
}

/// Whether every chapter of [bookName] is present in [readSet] (entries of the
/// form "Book|chapter").
bool checkBookFinished(String bookName, Set<String> readSet) {
  final count = bibleChapters[bookName];
  if (count == null) return false;
  for (int i = 1; i <= count; i++) {
    if (!readSet.contains('$bookName|$i')) return false;
  }
  return true;
}

/// The five single-chapter books of the Bible.
const singleChapterBooks = ['Obadiah', 'Philemon', '2 John', '3 John', 'Jude'];

/// Whether all [singleChapterBooks] are finished — the "Short Book Reader"
/// achievement.
bool allShortBooksFinished(Set<String> readSet) =>
    singleChapterBooks.every((b) => checkBookFinished(b, readSet));

/// Per-chapter read counts ("BookName_chapter" -> times read) from a set of
/// reading-progress rows. Each row is one read of one chapter at one iteration,
/// so counting rows per chapter yields how many passes have covered it.
Map<String, int> chapterReadCounts(Iterable<ReadingProgress> progress) {
  final counts = <String, int>{};
  for (final r in progress) {
    final key = '${r.bookName}_${r.chapter}';
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

/// Number of complete passes through the whole Bible: the fewest times any
/// canonical chapter has been read. Re-reading a single chapter cannot raise
/// this until every other canonical chapter has caught up, so it can't be
/// gamed.
int completedBiblePasses(Map<String, int> readCounts) {
  int min = -1;
  bibleChapters.forEach((book, chapters) {
    for (int c = 1; c <= chapters; c++) {
      final count = readCounts['${book}_$c'] ?? 0;
      if (min == -1 || count < min) min = count;
    }
  });
  return min == -1 ? 0 : min;
}

/// Whether any book was fully read within a single calendar day, on some
/// reading iteration — the "In One Sitting" achievement. Books of every length
/// qualify, including single-chapter ones (Jude, Obadiah, Philemon, 2/3 John).
bool anyBookReadInOneDay(List<ReadingProgress> progress) {
  for (final book in bibleChapters.keys) {
    if (bookReadInOneDay(book, progress)) return true;
  }
  return false;
}

/// Whether [bookName] was fully read (every chapter) within a single calendar
/// day, on some reading iteration.
bool bookReadInOneDay(String bookName, List<ReadingProgress> progress) {
  final rows = progress.where((r) => r.bookName == bookName).toList();
  final iterations = rows.map((r) => r.iteration).toSet();
  for (final iter in iterations) {
    final chapters = rows.where((r) => r.iteration == iter).toList();
    if (chapters.length < bibleChapters[bookName]!) continue;

    final days = chapters.map((r) {
      final d = DateTime.fromMillisecondsSinceEpoch(r.readAt).toLocal();
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    if (days.length == 1) return true;
  }
  return false;
}

const _pentateuch = ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy'];
const _history = ['Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther'];
const _wisdom = ['Job', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon'];
const _majorProphets = ['Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel'];
const _minorProphets = ['Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi'];
const _gospels = ['Matthew', 'Mark', 'Luke', 'John'];
const _historyNt = ['Acts'];
const _pauline = ['Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon'];
const _generalEpistles = ['Hebrews', 'James', '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude'];
const _prophecyNt = ['Revelation'];

const bibleChapters = {
  'Genesis': 50,
  'Exodus': 40,
  'Leviticus': 27,
  'Numbers': 36,
  'Deuteronomy': 34,
  'Joshua': 24,
  'Judges': 21,
  'Ruth': 4,
  '1 Samuel': 31,
  '2 Samuel': 24,
  '1 Kings': 22,
  '2 Kings': 25,
  '1 Chronicles': 29,
  '2 Chronicles': 36,
  'Ezra': 10,
  'Nehemiah': 13,
  'Esther': 10,
  'Job': 42,
  'Psalms': 150,
  'Proverbs': 31,
  'Ecclesiastes': 12,
  'Song of Solomon': 8,
  'Isaiah': 66,
  'Jeremiah': 52,
  'Lamentations': 5,
  'Ezekiel': 48,
  'Daniel': 12,
  'Hosea': 14,
  'Joel': 3,
  'Amos': 9,
  'Obadiah': 1,
  'Jonah': 4,
  'Micah': 7,
  'Nahum': 3,
  'Habakkuk': 3,
  'Zephaniah': 3,
  'Haggai': 2,
  'Zechariah': 14,
  'Malachi': 4,
  'Matthew': 28,
  'Mark': 16,
  'Luke': 24,
  'John': 21,
  'Acts': 28,
  'Romans': 16,
  '1 Corinthians': 16,
  '2 Corinthians': 13,
  'Galatians': 6,
  'Ephesians': 6,
  'Philippians': 4,
  'Colossians': 4,
  '1 Thessalonians': 5,
  '2 Thessalonians': 3,
  '1 Timothy': 6,
  '2 Timothy': 4,
  'Titus': 3,
  'Philemon': 1,
  'Hebrews': 13,
  'James': 5,
  '1 Peter': 5,
  '2 Peter': 3,
  '1 John': 5,
  '2 John': 1,
  '3 John': 1,
  'Jude': 1,
  'Revelation': 22,
};
