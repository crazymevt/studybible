import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/logging.dart';
import '../data/user_store.dart';
import 'reader_state.dart';
import 'sync_service.dart';
import 'user_providers.dart';

/// Keeps this device's row in [ReadingPositions] current: whenever the reader
/// moves to a different book or chapter, the row (keyed by this device's id)
/// is rewritten with the new position. Watched by the reader screen so the
/// listeners live exactly as long as the reader does.
final readingPositionTrackerProvider = Provider<void>((ref) {
  Future<void> record() async {
    try {
      final store = ref.read(userStoreProvider);
      final deviceId = await ref.read(deviceIdProvider.future);
      await store.into(store.readingPositions).insert(
            ReadingPosition(
              id: deviceId,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
              deviceId: deviceId,
              deleted: false,
              bookName: ref.read(selectedBookNameProvider),
              chapter: ref.read(selectedChapterProvider),
              verse: null,
              platform: Platform.operatingSystem,
            ),
            mode: InsertMode.replace,
          );
    } catch (e, stack) {
      logError(e, stack, context: 'readingPositionTracker: record');
    }
  }

  ref.listen(selectedBookNameProvider, (prev, next) {
    if (prev != next) record();
  });
  ref.listen(selectedChapterProvider, (prev, next) {
    if (prev != next) record();
  });
});

final _readingPositionsProvider = StreamProvider<List<ReadingPosition>>((ref) {
  final store = ref.watch(userStoreProvider);
  return store.select(store.readingPositions).watch();
});

/// The reading position to offer as a cross-device handoff, or null when
/// there is nothing to resume. A candidate must come from a *different*
/// device, be newer than anything this device has read, and point somewhere
/// other than where the reader already is — so the card disappears on its own
/// once the user catches up or reads past it.
final continueReadingProvider = FutureProvider<ReadingPosition?>((ref) async {
  final deviceId = await ref.watch(deviceIdProvider.future);
  final rows = await ref.watch(_readingPositionsProvider.future);

  ReadingPosition? mine;
  ReadingPosition? best;
  for (final row in rows) {
    if (row.deleted) continue;
    if (row.id == deviceId) {
      mine = row;
    } else if (best == null || row.updatedAt > best.updatedAt) {
      best = row;
    }
  }
  if (best == null) return null;
  if (mine != null && mine.updatedAt >= best.updatedAt) return null;

  final currentBook = ref.watch(selectedBookNameProvider);
  final currentChapter = ref.watch(selectedChapterProvider);
  if (best.bookName == currentBook && best.chapter == currentChapter) {
    return null;
  }
  return best;
});

/// A friendly name for the device a [ReadingPosition] was written on, from
/// its recorded Platform.operatingSystem.
String readingPositionDeviceLabel(String platform) {
  switch (platform) {
    case 'android':
      return 'your Android device';
    case 'ios':
      return 'your iPhone or iPad';
    case 'macos':
      return 'your Mac';
    case 'windows':
      return 'your Windows PC';
    case 'linux':
      return 'your Linux PC';
    default:
      return 'another device';
  }
}
