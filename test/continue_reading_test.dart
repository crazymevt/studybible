import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/reader_state.dart';
import 'package:study_bible/app/reading_position_providers.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';

/// The cross-device "Continue reading" handoff: the tracker that records this
/// device's position and the provider that decides whether another device's
/// position should be offered as a resume target.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserStore store;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'selectedBookName': 'John',
      'selectedChapter': 3,
    });
    final prefs = await SharedPreferences.getInstance();
    store = UserStore(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      userStoreProvider.overrideWithValue(store),
      sharedPreferencesProvider.overrideWithValue(prefs),
      deviceIdProvider.overrideWith((ref) async => 'device-A'),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  Future<void> seed({
    required String id,
    required int updatedAt,
    String bookName = 'Mark',
    int chapter = 5,
    String platform = 'android',
  }) {
    return store.into(store.readingPositions).insert(
          ReadingPosition(
            id: id,
            updatedAt: updatedAt,
            deviceId: id,
            deleted: false,
            bookName: bookName,
            chapter: chapter,
            verse: null,
            platform: platform,
          ),
          mode: InsertMode.replace,
        );
  }

  group('continueReadingProvider', () {
    test('offers another device\'s newer position', () async {
      await seed(id: 'device-A', updatedAt: 1000, bookName: 'John', chapter: 3);
      await seed(id: 'device-B', updatedAt: 2000);

      final pos = await container.read(continueReadingProvider.future);
      expect(pos, isNotNull);
      expect(pos!.bookName, 'Mark');
      expect(pos.chapter, 5);
      expect(pos.platform, 'android');
    });

    test('stays quiet when this device already read more recently', () async {
      await seed(id: 'device-A', updatedAt: 3000, bookName: 'John', chapter: 3);
      await seed(id: 'device-B', updatedAt: 2000);

      expect(await container.read(continueReadingProvider.future), isNull);
    });

    test('stays quiet when the reader is already at the remote position',
        () async {
      // Remote is newer but points at John 3, which is where the reader is.
      await seed(id: 'device-B', updatedAt: 2000, bookName: 'John', chapter: 3);

      expect(await container.read(continueReadingProvider.future), isNull);
    });

    test('picks the most recent among several other devices', () async {
      await seed(id: 'device-B', updatedAt: 2000, bookName: 'Mark', chapter: 5);
      await seed(
          id: 'device-C',
          updatedAt: 5000,
          bookName: 'Luke',
          chapter: 8,
          platform: 'windows');

      final pos = await container.read(continueReadingProvider.future);
      expect(pos!.bookName, 'Luke');
      expect(pos.platform, 'windows');
    });

    test('is empty with no rows at all', () async {
      expect(await container.read(continueReadingProvider.future), isNull);
    });
  });

  group('readingPositionTrackerProvider', () {
    test('records this device\'s row when the reader moves', () async {
      // Keep the tracker (and its listeners) alive for the test's duration.
      final sub = container.listen(readingPositionTrackerProvider, (_, _) {});

      container.read(selectedBookNameProvider.notifier).set('Mark');
      container.read(selectedChapterProvider.notifier).set(5);

      // The write is fire-and-forget; give its microtasks a moment.
      ReadingPosition? row;
      for (var i = 0; i < 20 && row?.chapter != 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        row = await (store.select(store.readingPositions)
              ..where((r) => r.id.equals('device-A')))
            .getSingleOrNull();
      }

      expect(row, isNotNull);
      expect(row!.deviceId, 'device-A');
      expect(row.bookName, 'Mark');
      expect(row.chapter, 5);
      expect(row.deleted, isFalse);
      sub.close();
    });
  });

  test('readingPositionDeviceLabel maps platforms to friendly names', () {
    expect(readingPositionDeviceLabel('android'), 'your Android device');
    expect(readingPositionDeviceLabel('macos'), 'your Mac');
    expect(readingPositionDeviceLabel('gibberish'), 'another device');
  });
}
