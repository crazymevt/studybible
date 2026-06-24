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
import 'reader/topics_panel.dart';
import 'reader/places_panel.dart';
import '../ui/sermons/sermons_panel.dart';
import '../app/reader_state.dart';
import 'journals/journals_prayers_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'content_manager/content_manager_screen.dart';
import 'settings/backup_restore_screen.dart';
import 'reader/reading_plan_panel.dart';

import 'onboarding/onboarding_screen.dart';
import 'common/breakpoints.dart';
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

    // Fresh install: nothing is "new" to a first-time user, and the dialog
    // would collide with onboarding. Record the current version silently so
    // the next genuine upgrade is what triggers the dialog. A fresh install
    // indexes cleanly, so the search-index rebuild prompt never applies.
    if (lastSeen == null) {
      await prefs.setString('lastSeenVersion', appVersion);
      await prefs.setInt(kSearchIndexRebuiltGenKey, kSearchIndexGeneration);
      return;
    }

    if (lastSeen != appVersion) {
      // Existing users may carry a search index built before the current
      // indexing generation; offer a one-tap rebuild in the dialog until they
      // run it (re-fires when kSearchIndexGeneration is bumped).
      final rebuiltGen = prefs.getInt(kSearchIndexRebuiltGenKey) ?? 0;
      final showRebuildPrompt = rebuiltGen < kSearchIndexGeneration;
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) =>
              WhatsNewDialog(showRebuildPrompt: showRebuildPrompt),
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
        if (constraints.maxWidth > Breakpoints.compact) {
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
    final railSide = ref.watch(navRailSideProvider);
    final theme = Theme.of(context);

    final mainContent = Expanded(
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
                  if (activeTool == ActiveTool.topics) {
                    return const TopicsPanel();
                  }
                  if (activeTool == ActiveTool.places) {
                    return const PlacesPanel();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );

    final navRail = _ScrollFadeColumn(
      fadeColor: theme.colorScheme.surfaceContainer,
      child: NavigationRail(
      backgroundColor: theme.colorScheme.surfaceContainer,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: IconThemeData(color: theme.colorScheme.onSecondaryContainer),
      unselectedIconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      indicatorColor: theme.colorScheme.secondaryContainer,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.compare_arrows),
          label: Text('Cross-Ref'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.note),
          label: Text('Notes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search),
          label: Text('Search'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.import_contacts),
          label: Text('Dictionary'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book),
          label: Text('Commentaries'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history),
          label: Text('History'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.video_library),
          label: Text('Media'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.event_note),
          label: Text('Plans'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.co_present),
          label: Text('Sermons'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.calendar_today),
          label: Text('Devotionals'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.topic),
          label: Text('Topics'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.map),
          label: Text('Places'),
        ),
      ],
      selectedIndex: _getSelectedIndex(activeTool),
      onDestinationSelected: (index) {
        final tool = _getToolFromIndex(index);
        ref.read(activeToolProvider.notifier).setTool(tool);
      },
      ),
    );

    return Scaffold(
      body: Row(
        children: railSide == NavRailSide.left
            ? [navRail, mainContent]
            : [mainContent, navRail],
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
      case ActiveTool.topics:
        return 10;
      case ActiveTool.places:
        return 11;
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
      case 10:
        return ActiveTool.topics;
      case 11:
        return ActiveTool.places;
      default:
        return ActiveTool.none;
    }
  }
}

/// Wraps a fixed-height [child] (e.g. the tools [NavigationRail]) in a vertical
/// scroll view that fills the available height, and draws a subtle fade at
/// whichever edge still has content off-screen — the scroll affordance a bare
/// SingleChildScrollView lacks, so users on short windows can tell the rail
/// scrolls. Both fades are absent when the child fits without scrolling.
class _ScrollFadeColumn extends StatefulWidget {
  final Widget child;
  final Color fadeColor;

  const _ScrollFadeColumn({required this.child, required this.fadeColor});

  @override
  State<_ScrollFadeColumn> createState() => _ScrollFadeColumnState();
}

class _ScrollFadeColumnState extends State<_ScrollFadeColumn> {
  final ScrollController _controller = ScrollController();
  bool _atTop = true;
  bool _atBottom = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final atTop = pos.pixels <= pos.minScrollExtent + 0.5;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 0.5;
    if (atTop != _atTop || atBottom != _atBottom) {
      setState(() {
        _atTop = atTop;
        _atBottom = atBottom;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  Widget _fade({required bool top}) => IgnorePointer(
        child: Container(
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                widget.fadeColor,
                widget.fadeColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Re-evaluate the edge flags after this layout, since a resize can
        // change whether the child overflows.
        WidgetsBinding.instance.addPostFrameCallback((_) => _update());
        return Stack(
          children: [
            SingleChildScrollView(
              controller: _controller,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(child: widget.child),
              ),
            ),
            if (!_atTop)
              Positioned(top: 0, left: 0, right: 0, child: _fade(top: true)),
            if (!_atBottom)
              Positioned(
                  bottom: 0, left: 0, right: 0, child: _fade(top: false)),
          ],
        );
      },
    );
  }
}
