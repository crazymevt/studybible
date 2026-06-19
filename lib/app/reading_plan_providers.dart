import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_store.dart';
import 'user_providers.dart';
import '../domain/reading_plan/reading_plan_generator.dart';

final readingPlanGeneratorProvider = Provider<ReadingPlanGenerator>((ref) {
  final userStore = ref.watch(userStoreProvider);
  return ReadingPlanGenerator(userStore);
});

final activeReadingPlansProvider = StreamProvider<List<ReadingPlan>>((ref) {
  final userStore = ref.watch(userStoreProvider);
  return (userStore.select(userStore.readingPlans)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
      .watch();
});

final readingPlanDaysProvider = StreamProvider.family<List<ReadingPlanDay>, String>((ref, planId) {
  final userStore = ref.watch(userStoreProvider);
  return (userStore.select(userStore.readingPlanDays)
        ..where((t) => t.planId.equals(planId) & t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.dayNumber, mode: OrderingMode.asc)]))
      .watch();
});

final readingPlanItemsProvider = StreamProvider.family<List<ReadingPlanItem>, String>((ref, dayId) {
  final userStore = ref.watch(userStoreProvider);
  return (userStore.select(userStore.readingPlanItems)
        ..where((t) => t.dayId.equals(dayId) & t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc)])) // Fallback ordering
      .watch();
});

final readingPlanControllerProvider = Provider<ReadingPlanController>((ref) {
  return ReadingPlanController(ref);
});

class ReadingPlanController {
  final Ref _ref;

  ReadingPlanController(this._ref);

  UserStore get _userStore => _ref.read(userStoreProvider);

  /// Toggle completion status of a specific item.
  /// Also checks and updates the parent day's completion status.
  Future<void> toggleItemComplete(ReadingPlanItem item, bool complete) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await _userStore.update(_userStore.readingPlanItems).replace(
      item.copyWith(completed: complete, updatedAt: now),
    );

    // Re-check parent day status
    await _updateDayCompletionStatus(item.dayId);
  }

  /// Mark all items in a day as complete or incomplete.
  Future<void> toggleDayComplete(ReadingPlanDay day, bool complete) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _userStore.batch((batch) {
      batch.update(_userStore.readingPlanDays, day.copyWith(completed: complete, updatedAt: now));
    });

    final items = await (_userStore.select(_userStore.readingPlanItems)
          ..where((t) => t.dayId.equals(day.id) & t.deleted.equals(false)))
        .get();

    await _userStore.batch((batch) {
      for (final item in items) {
        batch.update(_userStore.readingPlanItems, item.copyWith(completed: complete, updatedAt: now));
      }
    });
  }

  Future<void> deletePlan(String planId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Soft delete the plan
    await (_userStore.update(_userStore.readingPlans)
          ..where((t) => t.id.equals(planId)))
        .write(ReadingPlansCompanion(
      deleted: const Value(true),
      updatedAt: Value(now),
    ));

    // Soft delete all its days
    await (_userStore.update(_userStore.readingPlanDays)
          ..where((t) => t.planId.equals(planId)))
        .write(ReadingPlanDaysCompanion(
      deleted: const Value(true),
      updatedAt: Value(now),
    ));

    // Soft delete all its items
    // (Join through days is tricky in drift updates, so we select days first)
    final days = await (_userStore.select(_userStore.readingPlanDays)
          ..where((t) => t.planId.equals(planId)))
        .get();
        
    for (final day in days) {
      await (_userStore.update(_userStore.readingPlanItems)
            ..where((t) => t.dayId.equals(day.id)))
          .write(ReadingPlanItemsCompanion(
        deleted: const Value(true),
        updatedAt: Value(now),
      ));
    }
  }

  Future<void> _updateDayCompletionStatus(String dayId) async {
    final items = await (_userStore.select(_userStore.readingPlanItems)
          ..where((t) => t.dayId.equals(dayId) & t.deleted.equals(false)))
        .get();

    final allComplete = items.isNotEmpty && items.every((item) => item.completed);
    
    final day = await (_userStore.select(_userStore.readingPlanDays)
          ..where((t) => t.id.equals(dayId)))
        .getSingleOrNull();

    if (day != null && day.completed != allComplete) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _userStore.update(_userStore.readingPlanDays).replace(
        day.copyWith(completed: allComplete, updatedAt: now),
      );
    }
  }
}
