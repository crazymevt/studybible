import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/content_store.dart';
import 'verse_list_view.dart';
import 'flowing_paragraph_view.dart';

class ParallelView extends ConsumerWidget {
  final Map<String, List<Verse>> versesMap;
  final bool isFlowing;
  final Set<int> selectedVerses;
  final ValueChanged<int> onVerseTap;

  const ParallelView({
    super.key,
    required this.versesMap,
    required this.isFlowing,
    required this.selectedVerses,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (versesMap.isEmpty) {
      return const Center(child: Text('No active versions.'));
    }

    final keys = versesMap.keys.toList();

    return Row(
      children: keys.map((versionId) {
        final verses = versesMap[versionId] ?? [];
        return Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    versionId,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: isFlowing
                    ? FlowingParagraphView(
                        verses: verses,
                        selectedVerses: selectedVerses,
                        onVerseTap: onVerseTap,
                      )
                    : VerseListView(
                        verses: verses,
                        selectedVerses: selectedVerses,
                        onVerseTap: onVerseTap,
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
