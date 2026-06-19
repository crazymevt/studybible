import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/app_state.dart';
import 'reader/reader_screen.dart';
import 'reader/cross_reference_panel.dart';
import 'reader/commentary_panel.dart';
import 'reader/notes_panel.dart';
import 'reader/dictionary_panel.dart';
import 'reader/search_panel.dart';
import 'journals/journals_prayers_screen.dart';
import 'dashboard/dashboard_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModule = ref.watch(appModuleProvider);
    if (currentModule == AppModule.journalsPrayers) {
      return const JournalsPrayersScreen();
    } else if (currentModule == AppModule.dashboard) {
      return const DashboardScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return const _DesktopLayout();
        } else {
          return const ReaderScreen();
        }
      },
    );
  }
}

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);

    return Scaffold(
      body: Row(
        children: [
          // Main Content Area
          Expanded(
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: ReaderScreen(),
                ),
                if (activeTool != ActiveTool.none)
                  const VerticalDivider(width: 1, thickness: 1),
                if (activeTool == ActiveTool.crossReference)
                  const Expanded(
                    flex: 4,
                    child: CrossReferencePanel(),
                  ),
                if (activeTool == ActiveTool.commentaries)
                  const Expanded(
                    flex: 4,
                    child: CommentaryPanel(),
                  ),
                if (activeTool == ActiveTool.notes)
                  const Expanded(
                    flex: 4,
                    child: NotesPanel(),
                  ),
                if (activeTool == ActiveTool.dictionary)
                  const Expanded(
                    flex: 4,
                    child: DictionaryPanel(),
                  ),
                if (activeTool == ActiveTool.search)
                  const Expanded(
                    flex: 4,
                    child: SearchPanel(),
                  ),
                // Add other tools here...
              ],
            ),
          ),
          
          // Far right Navigation Rail
          NavigationRail(
            backgroundColor: const Color(0xFF2D2B3B),
            unselectedIconTheme: const IconThemeData(color: Colors.white54),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            indicatorColor: Colors.white24,
            destinations: const [
              NavigationRailDestination(
                icon: Tooltip(message: 'Library', child: Icon(Icons.library_books)),
                label: Text('Library'),
              ),
              NavigationRailDestination(
                icon: Tooltip(message: 'Cross-References', child: Icon(Icons.compare_arrows)),
                label: Text('Cross-Ref'),
              ),
              NavigationRailDestination(
                icon: Tooltip(message: 'Notes', child: Icon(Icons.note)),
                label: Text('Notes'),
              ),
              NavigationRailDestination(
                icon: Tooltip(message: 'Search', child: Icon(Icons.search)),
                label: Text('Search'),
              ),
              NavigationRailDestination(
                icon: Tooltip(message: 'Dictionary', child: Icon(Icons.import_contacts)),
                label: Text('Dictionary'),
              ),
              NavigationRailDestination(
                icon: Tooltip(message: 'Commentaries', child: Icon(Icons.menu_book)),
                label: Text('Commentaries'),
              ),
            ],
            selectedIndex: _getSelectedIndex(activeTool),
            onDestinationSelected: (index) {
              final tool = _getToolFromIndex(index);
              ref.read(activeToolProvider.notifier).setTool(tool);
            },
          ),
        ],
      ),
    );
  }

  int? _getSelectedIndex(ActiveTool tool) {
    switch (tool) {
      case ActiveTool.library: return 0;
      case ActiveTool.crossReference: return 1;
      case ActiveTool.notes: return 2;
      case ActiveTool.search: return 3;
      case ActiveTool.dictionary: return 4;
      case ActiveTool.commentaries: return 5;
      case ActiveTool.none: return null;
    }
  }

  ActiveTool _getToolFromIndex(int index) {
    switch (index) {
      case 0: return ActiveTool.library;
      case 1: return ActiveTool.crossReference;
      case 2: return ActiveTool.notes;
      case 3: return ActiveTool.search;
      case 4: return ActiveTool.dictionary;
      case 5: return ActiveTool.commentaries;
      default: return ActiveTool.none;
    }
  }
}
