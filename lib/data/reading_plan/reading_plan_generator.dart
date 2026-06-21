import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:drift/drift.dart';

import '../user_store.dart';
import 'package:study_bible/domain/reading_plan/reference_parser.dart';

class ReadingPlanGenerator {
  static const _uuid = Uuid();
  final UserStore _userStore;

  ReadingPlanGenerator(this._userStore);

  /// Generates a reading plan from a predefined JSON file in assets.
  Future<void> generateFromJsonAsset({
    required String assetPath,
    required String planTitle,
    required String planDescription,
    required DateTime startDate,
    required String deviceId,
  }) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final data = jsonDecode(jsonString);
    final daysList = data['data2'] as List<dynamic>;

    final planId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Create the plan
    final plan = ReadingPlansCompanion.insert(
      id: planId,
      updatedAt: now,
      deviceId: deviceId,
      title: planTitle,
      description: planDescription == ""
          ? const Value.absent()
          : Value(planDescription),
      startDate: startDate.millisecondsSinceEpoch,
      targetEndDate: Value(
        startDate
            .add(Duration(days: daysList.length - 1))
            .millisecondsSinceEpoch,
      ),
    );

    await _userStore.into(_userStore.readingPlans).insert(plan);

    // 2. Create the days and items
    await _userStore.batch((batch) {
      for (int i = 0; i < daysList.length; i++) {
        final passages = daysList[i] as List<dynamic>;
        final dayNumber = i + 1;
        final dayDate = startDate.add(Duration(days: i));
        final dayId = _uuid.v4();

        batch.insert(
          _userStore.readingPlanDays,
          ReadingPlanDaysCompanion.insert(
            id: dayId,
            updatedAt: now,
            deviceId: deviceId,
            planId: planId,
            dayNumber: dayNumber,
            date: Value(dayDate.millisecondsSinceEpoch),
          ),
        );

        for (final passageStr in passages) {
          final parsed = ReferenceParser.parse(passageStr.toString());
          batch.insert(
            _userStore.readingPlanItems,
            ReadingPlanItemsCompanion.insert(
              id: _uuid.v4(),
              updatedAt: now,
              deviceId: deviceId,
              dayId: dayId,
              bookName: parsed.bookName,
              startChapter: parsed.startChapter,
              endChapter: parsed.endChapter,
              startVerse: parsed.startVerse == null
                  ? const Value.absent()
                  : Value(parsed.startVerse),
              endVerse: parsed.endVerse == null
                  ? const Value.absent()
                  : Value(parsed.endVerse),
            ),
          );
        }
      }
    });
  }

  /// Generates a custom reading plan by dividing a set of chapters across a number of days.
  Future<void> generateCustomPlan({
    required String planTitle,
    required String planDescription,
    required List<String> bookNames,
    required int durationDays,
    required DateTime startDate,
    required String deviceId,
  }) async {
    final planId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Create the plan
    final plan = ReadingPlansCompanion.insert(
      id: planId,
      updatedAt: now,
      deviceId: deviceId,
      title: planTitle,
      description: planDescription == ""
          ? const Value.absent()
          : Value(planDescription),
      startDate: startDate.millisecondsSinceEpoch,
      targetEndDate: Value(
        startDate.add(Duration(days: durationDays - 1)).millisecondsSinceEpoch,
      ),
    );

    await _userStore.into(_userStore.readingPlans).insert(plan);

    // 2. Gather all chapters
    final allChapters = <_ChapterRef>[];
    for (final book in bookNames) {
      final count =
          _bibleChapterCounts[ReferenceParser.normalizeBookName(book)] ?? 1;
      for (int c = 1; c <= count; c++) {
        allChapters.add(_ChapterRef(book, c));
      }
    }

    if (allChapters.isEmpty) return; // Nothing to do

    // 3. Divide chapters across days
    final double chaptersPerDay = allChapters.length / durationDays;

    await _userStore.batch((batch) {
      int chapterIndex = 0;
      double fractionalDay = 0.0;

      for (int dayNumber = 1; dayNumber <= durationDays; dayNumber++) {
        final dayId = _uuid.v4();
        final dayDate = startDate.add(Duration(days: dayNumber - 1));

        batch.insert(
          _userStore.readingPlanDays,
          ReadingPlanDaysCompanion.insert(
            id: dayId,
            updatedAt: now,
            deviceId: deviceId,
            planId: planId,
            dayNumber: dayNumber,
            date: Value(dayDate.millisecondsSinceEpoch),
          ),
        );

        // Determine how many chapters to assign this day
        fractionalDay += chaptersPerDay;
        int chaptersThisDay = fractionalDay.floor();
        fractionalDay -= chaptersThisDay;

        // Ensure we don't exceed the list length
        if (chapterIndex + chaptersThisDay > allChapters.length) {
          chaptersThisDay = allChapters.length - chapterIndex;
        }

        // Always ensure the last day gets the remainder if rounding missed something
        if (dayNumber == durationDays && chapterIndex < allChapters.length) {
          chaptersThisDay = allChapters.length - chapterIndex;
        }

        if (chaptersThisDay == 0) {
          continue; // It's possible for very long duration that some days have 0.
        }

        // Group continuous chapters of the same book into single items
        String? currentBook;
        int currentStartChapter = -1;
        int currentEndChapter = -1;

        void emitItem() {
          if (currentBook != null) {
            batch.insert(
              _userStore.readingPlanItems,
              ReadingPlanItemsCompanion.insert(
                id: _uuid.v4(),
                updatedAt: now,
                deviceId: deviceId,
                dayId: dayId,
                bookName: currentBook,
                startChapter: currentStartChapter,
                endChapter: currentEndChapter,
              ),
            );
          }
        }

        for (int i = 0; i < chaptersThisDay; i++) {
          final ch = allChapters[chapterIndex++];
          if (currentBook == ch.bookName &&
              ch.chapterNum == currentEndChapter + 1) {
            // Continuation
            currentEndChapter = ch.chapterNum;
          } else {
            emitItem();
            currentBook = ch.bookName;
            currentStartChapter = ch.chapterNum;
            currentEndChapter = ch.chapterNum;
          }
        }
        emitItem(); // flush remaining
      }
    });
  }

  // Canonical chapter counts for division
  static const Map<String, int> _bibleChapterCounts = {
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
}

class _ChapterRef {
  final String bookName;
  final int chapterNum;
  _ChapterRef(this.bookName, this.chapterNum);
}
