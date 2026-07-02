import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cross_reference_panel.dart';
import 'notes_panel.dart';
import 'search_panel.dart';
import 'dictionary_panel.dart';
import 'commentary_panel.dart';
import 'media_panel.dart';
import 'reading_plan_panel.dart';
import '../sermons/sermons_panel.dart';
import 'devotionals_panel.dart';
import 'topics_panel.dart';
import 'harmony_panel.dart';
import 'places_panel.dart';
import 'highlights_panel.dart';
import 'scratch_panel.dart';
import '../common/tool_groups.dart';
import '../../app/app_state.dart';
import '../../app/reader_state.dart';

class MobileToolsDrawer extends ConsumerWidget {
  const MobileToolsDrawer({super.key});

  void _openTool(BuildContext context, Widget panel) {
    Navigator.of(context).pop(); // Close the drawer
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, scrollController) => panel,
      ),
    );
  }

  Widget _panelFor(ActiveTool tool, WidgetRef ref) {
    switch (tool) {
      case ActiveTool.crossReference:
        return const CrossReferencePanel();
      case ActiveTool.notes:
        return const NotesPanel();
      case ActiveTool.search:
        return const SearchPanel();
      case ActiveTool.dictionary:
        return const DictionaryPanel();
      case ActiveTool.commentaries:
        return const CommentaryPanel();
      case ActiveTool.media:
        return MediaPanel(
          bookName: ref.read(selectedBookNameProvider),
          chapter: ref.read(selectedChapterProvider),
        );
      case ActiveTool.readingPlans:
        return const ReadingPlanPanel();
      case ActiveTool.sermons:
        return const SermonsPanel();
      case ActiveTool.devotionals:
        return const DevotionalsPanel();
      case ActiveTool.topics:
        return const TopicsPanel();
      case ActiveTool.harmony:
        return const HarmonyPanel();
      case ActiveTool.places:
        return const PlacesPanel();
      case ActiveTool.highlights:
        return const HighlightsPanel();
      case ActiveTool.scratch:
        return const ScratchPanel();
      case ActiveTool.compare:
      case ActiveTool.history:
      case ActiveTool.none:
        // Not offered by toolGroups; unreachable from this drawer.
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Study Tools',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            // Same groups and order as the desktop tools rail (toolGroups),
            // so the tools live in one place in the user's mental map.
            for (final group in toolGroups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  group.label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              for (final item in group.items)
                ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  onTap: () => _openTool(context, _panelFor(item.tool, ref)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
