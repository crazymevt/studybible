import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/media_providers.dart';
import '../../app/app_state.dart';
import 'dart:io';
import 'media_player_dialog.dart';
import 'web_player_dialog.dart';

class MediaPanel extends ConsumerWidget {
  final String bookName;
  final int chapter;

  const MediaPanel({super.key, required this.bookName, required this.chapter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaList = ref.watch(
      chapterMediaProvider((book: bookName, chapter: chapter)),
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Media',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(activeToolProvider.notifier).close();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: mediaList.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No media available for this chapter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: mediaList.length,
                    itemBuilder: (context, index) {
                      final group = mediaList[index];
                      final collection = group.collection;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Collection Header
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  collection.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                                if (collection.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    collection.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                                if (collection.copyright.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    collection.copyright,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ],
                                if (collection.url.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      launchUrl(
                                        Uri.parse(collection.url),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    child: Text(
                                      'Learn More',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Collection Items
                          ...group.items.map((item) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 80,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(4),
                                  image: item.id != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            'https://img.youtube.com/vi/${item.id}/hqdefault.jpg',
                                          ),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) {
                                            // Ignore image loading errors
                                          },
                                        )
                                      : null,
                                ),
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(item.title),
                              subtitle: item.description != null
                                  ? Text(
                                      item.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: Text(
                                item.duration ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              onTap: () {
                                if (item.id != null) {
                                  if (Platform.isWindows || Platform.isLinux) {
                                    launchUrl(
                                      Uri.parse('https://www.youtube.com/watch?v=${item.id}'),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          MediaPlayerDialog(videoId: item.id!),
                                    );
                                  }
                                } else if (item.url != null) {
                                  if (Platform.isWindows || Platform.isLinux) {
                                    launchUrl(
                                      Uri.parse(item.url!),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          WebPlayerDialog(url: item.url!),
                                    );
                                  }
                                }
                              },
                            );
                          }),
                          const Divider(height: 32),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
