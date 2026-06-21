import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/app_state.dart';
import 'reader/reader_screen.dart';
import 'reader/cross_reference_panel.dart';
import 'reader/commentary_panel.dart';
import 'reader/notes_panel.dart';
import 'reader/dictionary_panel.dart';
import 'reader/search_panel.dart';
import 'reader/history_panel.dart';
import 'reader/media_panel.dart';
import 'reader/compare_panel.dart';
import 'reader/devotionals_panel.dart';
import '../ui/sermons/sermons_panel.dart';
import '../app/reader_state.dart';
import 'journals/journals_prayers_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'content_manager/content_manager_screen.dart';
import 'settings/backup_restore_screen.dart';
import 'reader/reading_plan_panel.dart';

import 'onboarding/onboarding_screen.dart';
import '../app/content_providers.dart';
import '../app/shared_prefs.dart';
import '../app/version.dart';
import 'whats_new_dialog.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWhatsNew();
    });
  }

  Future<void> _checkWhatsNew() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final lastSeen = prefs.getString('lastSeenVersion');

    if (lastSeen != appVersion) {
      // Show dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const WhatsNewDialog(),
        );
      }
      // Update prefs
      await prefs.setString('lastSeenVersion', appVersion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentModule = ref.watch(appModuleProvider);
    final versionsAsync = ref.watch(bibleVersionsProvider);

    // Ensure we can still access these modules even if database is empty
    if (currentModule == AppModule.contentManager) {
      return const ContentManagerScreen();
    } else if (currentModule == AppModule.backupRestore) {
      return const BackupRestoreScreen();
    }

    // Intercept with OnboardingScreen if no bibles are installed
    final hasNoBibles = versionsAsync.when(
      data: (versions) => versions.isEmpty,
      loading: () => false, // Don't show while loading
      error: (_, _) => false,
    );

    if (hasNoBibles) {
      return const OnboardingScreen();
    }

    if (currentModule == AppModule.journalsPrayers) {
      return const JournalsPrayersScreen();
    } else if (currentModule == AppModule.dashboard) {
      return const DashboardScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
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
                const Expanded(flex: 5, child: ReaderScreen()),
                if (activeTool != ActiveTool.none)
                  const VerticalDivider(width: 1, thickness: 1),
                if (activeTool != ActiveTool.none)
                  Expanded(
                    flex: 4,
                    child: Builder(
                      builder: (context) {
                        if (activeTool == ActiveTool.compare) {
                          return const ComparePanel();
                        }
                        if (activeTool == ActiveTool.sermons) {
                          return const SermonsPanel();
                        }
                        if (activeTool == ActiveTool.crossReference) {
                          return const CrossReferencePanel();
                        }
                        if (activeTool == ActiveTool.commentaries) {
                          return const CommentaryPanel();
                        }
                        if (activeTool == ActiveTool.notes) {
                          return const NotesPanel();
                        }
                        if (activeTool == ActiveTool.dictionary) {
                          return const DictionaryPanel();
                        }
                        if (activeTool == ActiveTool.search) {
                          return const SearchPanel();
                        }
                        if (activeTool == ActiveTool.history) {
                          return const HistoryPanel();
                        }
                        if (activeTool == ActiveTool.media) {
                          final book = ref.watch(selectedBookNameProvider);
                          final chap = ref.watch(selectedChapterProvider);
                          return MediaPanel(bookName: book, chapter: chap);
                        }
                        if (activeTool == ActiveTool.readingPlans) {
                          return const ReadingPlanPanel();
                        }
                        if (activeTool == ActiveTool.devotionals) {
                          return const DevotionalsPanel();
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
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
                icon: Tooltip(
                  message: 'Cross-References',
                  child: Icon(Icons.compare_arrows),
                ),
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
                icon: Tooltip(
                  message: 'Dictionary',
                  child: Icon(Icons.import_contacts),
                ),
                label: Text('Dictionary'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Commentaries',
                  child: Icon(Icons.menu_book),
                ),
                label: Text('Commentaries'),
              ),
              NavigationRailDestination(
                icon: Tooltip(message: 'History', child: Icon(Icons.history)),
                label: Text('History'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Media',
                  child: Icon(Icons.video_library),
                ),
                label: Text('Media'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Reading Plans',
                  child: Icon(Icons.menu_book),
                ),
                label: Text('Plans'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Sermons',
                  child: Icon(Icons.co_present),
                ),
                label: Text('Sermons'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Devotionals',
                  child: Icon(Icons.calendar_today),
                ),
                label: Text('Devotionals'),
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
      case ActiveTool.crossReference:
        return 0;
      case ActiveTool.notes:
        return 1;
      case ActiveTool.search:
        return 2;
      case ActiveTool.dictionary:
        return 3;
      case ActiveTool.commentaries:
        return 4;
      case ActiveTool.history:
        return 5;
      case ActiveTool.media:
        return 6;
      case ActiveTool.readingPlans:
        return 7;
      case ActiveTool.sermons:
        return 8;
      case ActiveTool.devotionals:
        return 9;
      case ActiveTool.none:
      case ActiveTool.compare:
        return null;
    }
  }

  ActiveTool _getToolFromIndex(int index) {
    switch (index) {
      case 0:
        return ActiveTool.crossReference;
      case 1:
        return ActiveTool.notes;
      case 2:
        return ActiveTool.search;
      case 3:
        return ActiveTool.dictionary;
      case 4:
        return ActiveTool.commentaries;
      case 5:
        return ActiveTool.history;
      case 6:
        return ActiveTool.media;
      case 7:
        return ActiveTool.readingPlans;
      case 8:
        return ActiveTool.sermons;
      case 9:
        return ActiveTool.devotionals;
      default:
        return ActiveTool.none;
    }
  }
}
