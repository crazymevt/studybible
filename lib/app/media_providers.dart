import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/media_collection.dart';

// Provider that holds all loaded MediaCollections
final mediaCollectionsProvider = FutureProvider<List<MediaCollection>>((
  ref,
) async {
  final fileNames = [
    'bibleproject.json',
    'bibleproject-extended.json',
    'jesus-film.json',
    'lumo.json',
  ];

  final List<MediaCollection> collections = [];

  for (final file in fileNames) {
    try {
      final jsonString = await rootBundle.loadString('assets/media/$file');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      collections.add(MediaCollection.fromJson(jsonData));
    } catch (e) {
      // Ignore missing files or parse errors to keep loading others
      debugPrint('Failed to load media collection: $file - $e');
    }
  }

  return collections;
});

class MediaGroup {
  final MediaCollection collection;
  final List<MediaItem> items;

  MediaGroup({required this.collection, required this.items});
}

// A provider that filters media for a specific book and chapter
final chapterMediaProvider =
    Provider.family<List<MediaGroup>, ({String book, int chapter})>((
      ref,
      args,
    ) {
      final collectionsAsync = ref.watch(mediaCollectionsProvider);

      return collectionsAsync.maybeWhen(
        data: (collections) {
          final List<MediaGroup> groups = [];

          for (final collection in collections) {
            final bookItems = collection.mediaByBook[args.book] ?? [];
            final List<MediaItem> relevantItems = [];

            for (final item in bookItems) {
              // If chapters array exists, check if our chapter falls within it [start, end]
              if (item.chapters != null && item.chapters!.length >= 2) {
                final start = item.chapters![0];
                final end = item.chapters![1];
                if (args.chapter >= start && args.chapter <= end) {
                  relevantItems.add(item);
                }
              }
            }

            if (relevantItems.isNotEmpty) {
              groups.add(
                MediaGroup(collection: collection, items: relevantItems),
              );
            }
          }
          return groups;
        },
        orElse: () => [],
      );
    });
