import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/app_state.dart';
import '../app/sermon_providers.dart';
import 'reader/reader_screen.dart';
import 'reader/cross_reference_panel.dart';
import 'reader/commentary_panel.dart';
import 'reader/notes_panel.dart';
import 'reader/dictionary_panel.dart';
import 'reader/search_panel.dart';
import 'reader/media_panel.dart';
import 'reader/compare_panel.dart';
import 'reader/devotionals_panel.dart';
import 'reader/topics_panel.dart';
import 'reader/places_panel.dart';
import 'reader/highlights_panel.dart';
import 'reader/scratch_panel.dart';
import '../ui/sermons/sermons_panel.dart';
import '../app/reader_state.dart';
import 'journals/journals_prayers_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'content_manager/content_manager_screen.dart';
import 'settings/backup_restore_screen.dart';
import 'reader/reading_plan_panel.dart';

import 'onboarding/onboarding_screen.dart';
import 'onboarding/tutorial_overlay.dart';
import 'onboarding/tutorial_keys.dart';
import 'common/breakpoints.dart';
import '../app/content_providers.dart';
import '../app/content_manager_providers.dart';
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

    // Android system back / gesture: rather than pop the shell (which would exit
    // the app), unwind whatever in-app state is on top. The shell can already be
    // popped only when we're on the reader home with nothing open.
    //
    // The tool panel is only a persistent, on-screen surface on wide layouts; on
    // phones tools are bottom sheets/drawers (their own routes, so back already
    // dismisses them) and activeTool can even be a stale value that never showed
    // a panel. So only treat a tool as "open" — and worth intercepting back for
    // — on wide layouts.
    final isWideLayout =
        MediaQuery.sizeOf(context).width > Breakpoints.compact;
    final activeTool = ref.watch(activeToolProvider);
    final hasVerseSelection = ref.watch(selectedVersesProvider).isNotEmpty;
    final panelOpen = isWideLayout && activeTool != ActiveTool.none;
    final canPopShell = currentModule == AppModule.reader &&
        !panelOpen &&
        !hasVerseSelection;
    Widget wrapBack(Widget child) => PopScope(
          canPop: canPopShell,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _handleSystemBack();
          },
          child: child,
        );

    // Ensure we can still access these modules even if database is empty
    if (currentModule == AppModule.contentManager) {
      return wrapBack(const ContentManagerScreen());
    } else if (currentModule == AppModule.backupRestore) {
      return wrapBack(const BackupRestoreScreen());
    }

    // Intercept with OnboardingScreen if no bibles are installed. On *error*
    // the content DB is unreadable (e.g. a corrupt or half-written store, such
    // as an uninstall/reinstall that happened while the app held the DB open) —
    // route to onboarding so the user can re-download content, which recreates
    // the store. Otherwise the shell would render the reader and strand the
    // user on its "Couldn't load this chapter" error with no way to install or
    // repair content ("Try again" just re-runs the failing query). Loading
    // stays false so we don't flash onboarding during a normal cold start.
    final hasNoBibles = versionsAsync.when(
      data: (versions) => versions.isEmpty,
      loading: () => false,
      error: (_, _) => true,
    );

    // The "recommended resources" batch installs a Bible first, which would
    // otherwise flip the shell to the reader and hide the still-running
    // progress for the remaining commentaries/dictionaries. Keep onboarding up
    // until the whole batch settles.
    final recProgress =
        ref.watch(contentManagerControllerProvider)[recommendedDownloadKey];
    final recInProgress = recProgress != null &&
        recProgress.status != 'Done' &&
        !recProgress.status.startsWith('Error') &&
        !recProgress.status.startsWith('Finished');

    if (hasNoBibles || recInProgress) {
      return const OnboardingScreen();
    }

    // The interactive tutorial spotlights real shell elements, so it renders
    // over the live shell rather than replacing it. Marking it seen rebuilds
    // here and drops the overlay. Only show it once a Bible is positively
    // installed — otherwise, while versions are still loading (e.g. a fresh
    // install), it would cover the reader before onboarding can offer a
    // download, trapping the user behind a tap-absorbing overlay.
    final hasBibles = versionsAsync.maybeWhen(
      data: (versions) => versions.isNotEmpty,
      orElse: () => false,
    );
    final hasSeenTutorial = ref.watch(hasSeenTutorialProvider);
    final showTutorial = !hasSeenTutorial && hasBibles;

    final readerLayout = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > Breakpoints.compact) {
          return const _DesktopLayout();
        } else {
          return const ReaderScreen();
        }
      },
    );

    final Widget shell;
    if (showTutorial) {
      // Render the reader behind the tour so its spotlight targets exist,
      // *without* mutating the module. Switching the module mid-tour would swap
      // the shell (e.g. dashboard→reader), reparenting the GlobalKey'd search
      // bar while its label animation is dirty and crashing with "wrong build
      // scope". The module is set to reader when the tour finishes instead, so
      // the user simply stays on the reader (see TutorialOverlay._finish).
      shell = readerLayout;
    } else if (currentModule == AppModule.journalsPrayers) {
      shell = const JournalsPrayersScreen();
    } else if (currentModule == AppModule.dashboard) {
      shell = const DashboardScreen();
    } else {
      shell = readerLayout;
    }

    if (showTutorial) {
      return wrapBack(Stack(
        fit: StackFit.expand,
        children: [shell, const TutorialOverlay()],
      ));
    }

    return wrapBack(shell);
  }

  /// Handle a system back press that the shell declined to pop, unwinding the
  /// most-nested in-app state one level:
  ///   * reader tool panel with an open sermon/devotional editor → its list
  ///   * any open reader tool panel → close it
  ///   * an active verse selection → clear it
  ///   * any non-reader module (dashboard, journals, content, backup) → reader
  /// State is read fresh here so it reflects the moment of the back press.
  void _handleSystemBack() {
    if (ref.read(appModuleProvider) != AppModule.reader) {
      ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
      return;
    }

    // Tool panels are only an on-screen surface on wide layouts (see build).
    if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
      final tool = ref.read(activeToolProvider);
      // Step an open detail editor back to its panel's list first.
      if (tool == ActiveTool.sermons &&
          ref.read(selectedSermonIdProvider) != null) {
        ref.read(selectedSermonIdProvider.notifier).set(null);
        return;
      }
      if (tool == ActiveTool.devotionals &&
          ref.read(selectedDevotionalIdProvider) != null) {
        ref.read(selectedDevotionalIdProvider.notifier).set(null);
        return;
      }
      if (tool != ActiveTool.none) {
        ref.read(activeToolProvider.notifier).close();
        return;
      }
    }
    if (ref.read(selectedVersesProvider).isNotEmpty) {
      ref.read(selectedVersesProvider.notifier).clear();
    }
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
          Expanded(
            flex: 5,
            child: KeyedSubtree(
              key: tutorialReaderKey,
              child: const ReaderScreen(),
            ),
          ),
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
                  if (activeTool == ActiveTool.highlights) {
                    return const HighlightsPanel();
                  }
                  if (activeTool == ActiveTool.scratch) {
                    return const ScratchPanel();
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
        NavigationRailDestination(
          icon: Icon(Icons.format_color_fill),
          label: Text('Highlights'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.edit_note),
          label: Text('Scratch'),
        ),
      ],
      selectedIndex: _getSelectedIndex(activeTool),
      onDestinationSelected: (index) {
        final tool = _getToolFromIndex(index);
        ref.read(activeToolProvider.notifier).setTool(tool);
      },
      ),
    );

    final keyedRail = KeyedSubtree(key: tutorialToolsRailKey, child: navRail);

    // Back-button handling for the tool panel lives centrally in
    // _MainShellState (system back steps back through / closes the panel).
    return Scaffold(
      body: Row(
        children: railSide == NavRailSide.left
            ? [keyedRail, mainContent]
            : [mainContent, keyedRail],
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
      case ActiveTool.media:
        return 5;
      case ActiveTool.readingPlans:
        return 6;
      case ActiveTool.sermons:
        return 7;
      case ActiveTool.devotionals:
        return 8;
      case ActiveTool.topics:
        return 9;
      case ActiveTool.places:
        return 10;
      case ActiveTool.highlights:
        return 11;
      case ActiveTool.scratch:
        return 12;
      case ActiveTool.history:
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
        return ActiveTool.media;
      case 6:
        return ActiveTool.readingPlans;
      case 7:
        return ActiveTool.sermons;
      case 8:
        return ActiveTool.devotionals;
      case 9:
        return ActiveTool.topics;
      case 10:
        return ActiveTool.places;
      case 11:
        return ActiveTool.highlights;
      case 12:
        return ActiveTool.scratch;
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
