import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'cross_reference_panel.dart';
import 'notes_panel.dart';
import 'search_panel.dart';
import 'dictionary_panel.dart';
import 'commentary_panel.dart';
import 'history_panel.dart';
import 'media_panel.dart';
import 'reading_plan_panel.dart';
import '../sermons/sermons_panel.dart';
import 'devotionals_panel.dart';
import 'topics_panel.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const Divider(),

            ListTile(
              leading: const Tooltip(
                message: 'Cross-References',
                child: Icon(Icons.compare_arrows),
              ),
              title: const Text('Cross-References'),
              onTap: () => _openTool(context, const CrossReferencePanel()),
            ),
            ListTile(
              leading: const Tooltip(message: 'Notes', child: Icon(Icons.note)),
              title: const Text('Notes'),
              onTap: () => _openTool(context, const NotesPanel()),
            ),
            ListTile(
              leading: const Tooltip(
                message: 'Search',
                child: Icon(Icons.search),
              ),
              title: const Text('Search'),
              onTap: () => _openTool(context, const SearchPanel()),
            ),
            ListTile(
              leading: const Tooltip(
                message: 'Dictionary',
                child: Icon(Icons.import_contacts),
              ),
              title: const Text('Dictionary'),
              onTap: () => _openTool(context, const DictionaryPanel()),
            ),
            ListTile(
              leading: const Tooltip(
                message: 'Commentaries',
                child: Icon(Icons.menu_book),
              ),
              title: const Text('Commentaries'),
              onTap: () => _openTool(context, const CommentaryPanel()),
            ),
            ListTile(
              leading: const Tooltip(
                message: 'History',
                child: Icon(Icons.history),
              ),
              title: const Text('History'),
              onTap: () => _openTool(context, const HistoryPanel()),
            ),
            ListTile(
              leading: const Tooltip(
                message: 'Media',
                child: Icon(Icons.video_library),
              ),
              title: const Text('Media'),
              onTap: () {
                final bookName = ref.read(selectedBookNameProvider);
                final chapter = ref.read(selectedChapterProvider);
                _openTool(
                  context,
                  MediaPanel(bookName: bookName, chapter: chapter),
                );
              },
            ),
            ListTile(
              leading: const Tooltip(
                message: 'Reading Plans',
                child: Icon(Icons.event_note),
              ),
              title: const Text('Reading Plans'),
              onTap: () => _openTool(context, const ReadingPlanPanel()),
            ),
            ListTile(
              leading: const Tooltip(
                message: 'Sermons',
                child: Icon(Icons.co_present),
              ),
              title: const Text('Sermons'),
              onTap: () => _openTool(context, const SermonsPanel()),
            ),
            ListTile(
              leading: const Tooltip(
                message: 'Devotionals',
                child: Icon(Icons.calendar_today),
              ),
              title: const Text('Devotionals'),
              onTap: () => _openTool(context, const DevotionalsPanel()),
            ),
            ListTile(
              leading: const Tooltip(
                message: 'Topics',
                child: Icon(Icons.topic),
              ),
              title: const Text('Topics'),
              onTap: () => _openTool(context, const TopicsPanel()),
            ),
          ],
        ),
      ),
    );
  }
}
