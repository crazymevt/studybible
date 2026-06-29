import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../app/tag_providers.dart';
import '../../app/audio_providers.dart';
import 'verse_list_view.dart';
import 'flowing_paragraph_view.dart';
import 'parallel_view.dart';
import 'verse_action_bar.dart';
import 'book_chooser_sheet.dart';
import '../common/breakpoints.dart';

import 'mobile_tools_drawer.dart';
import 'history_panel.dart';
import 'audio_player_widget.dart';
import 'tts_player_widget.dart';
import '../../app/tts_providers.dart';
import '../../data/tts_service.dart';
import 'commentary_panel.dart';
import 'dictionary_panel.dart';
import '../common/search_title_bar.dart';
import '../onboarding/tutorial_keys.dart';
import '../common/sync_button.dart';
import '../app_drawer.dart';
import '../../app/dashboard_providers.dart';
import '../../app/app_state.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _isFlowing = false;

  // Tracking
  int _sessionStartTime = 0;
  late final AppLifecycleListener _lifecycleListener;
  Timer? _chapterReadTimer;
  String? _trackingBook;
  int? _trackingChapter;
  late final DashboardAction _dashboardAction;

  bool _showSearchBox = false;
  String _searchQuery = '';
  int _currentMatchIndex = -1;
  Timer? _searchDebounce;
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // Swipe navigation: pages the single-version reader through the flat
  // [chapterIndexProvider] address space. Created lazily once the chapter
  // index is available so we can seed it with the correct initial page.
  PageController? _pageController;

  /// Returns the sorted list of verse numbers whose text contains [query]
  /// (case-insensitive) across all displayed versions. Single source of truth
  /// for the in-page find — used by both the input handler and build().
  List<int> _computeMatchVerses(
    Map<String, List<dynamic>> versesMap,
    String query,
  ) {
    if (query.isEmpty) return const [];
    final lowerQuery = query.toLowerCase();
    final matches = <int>{};
    for (final verses in versesMap.values) {
      for (final v in verses) {
        if (v.textContent.toLowerCase().contains(lowerQuery)) {
          matches.add(v.verse as int);
        }
      }
    }
    return matches.toList()..sort();
  }

  /// Whether a text field (e.g. the find bar) currently holds focus — used to
  /// suppress global arrow-key chapter navigation while the user is typing.
  bool get _isEditingText {
    if (_searchFocusNode.hasFocus) return true;
    final focus = FocusManager.instance.primaryFocus;
    return focus?.context?.widget is EditableText;
  }

  void _onVerseTap(int verseId) {
    HapticFeedback.selectionClick();
    ref.read(selectedVersesProvider.notifier).toggle(verseId);
  }

  @override
  void initState() {
    super.initState();
    _dashboardAction = ref.read(dashboardActionProvider);
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _handleLifecycleState,
    );
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (!mounted) return false;
    final isCmdOrCtrl = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                        HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight) ||
                        HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                        HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight);
    
    if (isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
       if (event is KeyDownEvent) {
         setState(() {
           _showSearchBox = true;
         });
         _searchFocusNode.requestFocus();
       }
       return true; // handled
    }
    return false; // ignored
  }

  void _handleLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _logSession();
    } else if (state == AppLifecycleState.resumed) {
      _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void _logSession() {
    if (_sessionStartTime > 0) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      _dashboardAction.logTime(_sessionStartTime, endTime, 'reading');
      _sessionStartTime = 0; // Prevent duplicate logging
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    _logSession();
    _lifecycleListener.dispose();
    _chapterReadTimer?.cancel();
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();
    _searchController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  /// Moves the swipe [PageView] to [targetIndex] when the chapter selection
  /// changes from outside the PageView (book chooser, search, history, etc.).
  /// Adjacent moves animate like a swipe; longer jumps are instant. A no-op
  /// when the controller is already on the target page, which is what keeps
  /// user swipes (whose [onPageChanged] sets the selection) from looping.
  void _syncPageController(int targetIndex) {
    final c = _pageController;
    if (c == null || !c.hasClients) return;
    // Never fight an in-progress gesture or settle animation. Syncing while the
    // user is mid-drag is what made the page snap to the wrong chapter: a
    // rebuild would see the fractional drag position round back to the old
    // chapter and animate forward against the finger. onPageChanged already
    // records the destination once the swipe settles.
    if (c.position.isScrollingNotifier.value) return;
    final current = (c.page ?? c.initialPage.toDouble()).round();
    if (current == targetIndex) return;
    if ((targetIndex - current).abs() == 1) {
      c.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      c.jumpToPage(targetIndex);
    }
  }

  /// Applies a user swipe: records the chapter the PageView settled on as the
  /// new global selection. Guarded against re-applying the current selection so
  /// programmatic page moves don't double-record history.
  void _onPageSettled(int i) {
    final index = ref.read(chapterIndexProvider).value;
    if (index == null || i < 0 || i >= index.length) return;
    final entry = index[i];
    if (entry.bookName == ref.read(selectedBookNameProvider) &&
        entry.chapter == ref.read(selectedChapterProvider)) {
      return;
    }
    ref.read(selectedBookNameProvider.notifier).set(entry.bookName);
    ref.read(selectedChapterProvider.notifier).set(entry.chapter);
    ref.read(navigationControllerProvider).recordHistory();
  }

  void _nextMatch(List<int> matchVerses) {
    if (matchVerses.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % matchVerses.length;
    });
    ref.read(targetVerseToScrollProvider.notifier).set(matchVerses[_currentMatchIndex]);
  }

  void _prevMatch(List<int> matchVerses) {
    if (matchVerses.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1) < 0 ? matchVerses.length - 1 : _currentMatchIndex - 1;
    });
    ref.read(targetVerseToScrollProvider.notifier).set(matchVerses[_currentMatchIndex]);
  }

  void _updateChapterTracking(String book, int chapter) {
    if (_trackingBook == book && _trackingChapter == chapter) return;

    _trackingBook = book;
    _trackingChapter = chapter;
    _chapterReadTimer?.cancel();

    // In manual mode the chapter is marked read via the button in
    // ChapterNavigationFooter, so skip the auto timer.
    if (ref.read(manualChapterReadProvider)) return;

    // Start a 5-second timer to mark the chapter as read
    _chapterReadTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        ref.read(dashboardActionProvider).markChapterRead(book, chapter);
      }
    });
  }

  void _showVersionPicker() async {
    final availableVersions = await ref.read(bibleVersionsProvider.future);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final activeVersions = ref.watch(activeVersionsProvider);
            return ListView.builder(
              itemCount: availableVersions.length,
              itemBuilder: (context, index) {
                final version = availableVersions[index];
                final isActive = activeVersions.contains(version.id);
                return ListTile(
                  title: Text(
                    '${version.name} (${version.id})',
                    style: TextStyle(
                      fontWeight: isActive && activeVersions.length == 1 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Parallel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Checkbox(
                        value: isActive,
                        onChanged: (checked) {
                          ref
                              .read(activeVersionsProvider.notifier)
                              .toggle(version.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Replace active versions with ONLY this version
                    ref.read(activeVersionsProvider.notifier).set([version.id]);
                    Navigator.of(context).pop();
                  },
                  selected: isActive && activeVersions.length == 1,
                  selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                );
              },
            );
          },
        );
      },
    );
  }

  void _openCommentaryPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, scrollController) => CommentaryPanel(),
      ),
    );
  }

  void _openStrongDictionary(String strongNumber) {
    ref.read(dictionarySearchQueryProvider.notifier).setQuery(strongNumber);
    if (MediaQuery.sizeOf(context).width > Breakpoints.compact) {
      ref.read(activeToolProvider.notifier).openTool(ActiveTool.dictionary);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.sizeOf(context).height * 0.8,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const DictionaryPanel(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parallelVersesAsync = ref.watch(parallelVersesProvider);
    final bookName = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final selectedVerses = ref.watch(selectedVersesProvider);

    // Per-chapter verse decorations (highlights, notes, tags, subheadings) are
    // now watched per page by _ChapterPage so the swipe PageView can load each
    // chapter independently.
    final audioData = ref.watch(chapterAudioProvider);

    // Auto-tracking logic
    ref.listen<String>(selectedBookNameProvider, (prev, next) {
      _updateChapterTracking(next, ref.read(selectedChapterProvider));
    });
    ref.listen<int>(selectedChapterProvider, (prev, next) {
      _updateChapterTracking(ref.read(selectedBookNameProvider), next);
    });

    ref.listen<String?>(findInPageQueryProvider, (prev, next) {
      if (next != null) {
        setState(() {
          _showSearchBox = true;
          _searchQuery = next;
          _currentMatchIndex = -1;
          _searchController.text = next;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _searchFocusNode.requestFocus();
          }
        });

        _searchDebounce?.cancel();
        _searchDebounce = Timer(
          const Duration(milliseconds: 100),
          () {
            if (!mounted || !parallelVersesAsync.hasValue) return;
            final newMatchVerses = _computeMatchVerses(
              parallelVersesAsync.value!,
              next,
            );
            if (newMatchVerses.isNotEmpty) {
              ref
                  .read(targetVerseToScrollProvider.notifier)
                  .set(newMatchVerses.first);
            }
          },
        );
      }
    });

    // Trigger initial tracking if not already tracking
    if (_trackingBook == null) {
      _updateChapterTracking(bookName, chapter);
    }

    List<int> matchVerses = [];
    if (_searchQuery.isNotEmpty && parallelVersesAsync.hasValue) {
      matchVerses = _computeMatchVerses(parallelVersesAsync.value!, _searchQuery);

      // Keep index in bounds if search results shrink
      if (_currentMatchIndex >= matchVerses.length) {
        _currentMatchIndex = matchVerses.isEmpty ? -1 : 0;
      }
    } else {
      _currentMatchIndex = -1;
    }

    return Focus(
      focusNode: _mainFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (_showSearchBox) {
            setState(() {
              _showSearchBox = false;
              _searchQuery = '';
              _currentMatchIndex = -1;
            });
            _mainFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
          if (ref.read(selectedVersesProvider).isNotEmpty) {
            ref.read(selectedVersesProvider.notifier).clear();
            return KeyEventResult.handled;
          }
        }
        
        // Don't hijack arrow keys while the user is typing in a text field
        // (e.g. the find bar) — let them move the cursor instead.
        if (event is KeyDownEvent && !_isEditingText) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            ref.read(navigationControllerProvider).previousChapter();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            ref.read(navigationControllerProvider).nextChapter();
            return KeyEventResult.handled;
          }
        }
        
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          centerTitle: true,
          // Explicit drawer button (mirrors Scaffold's auto leading) so the
          // tutorial can spotlight it for the Journals and Content steps.
          leading: Builder(
            builder: (context) => IconButton(
              key: tutorialMenuKey,
              icon: const Icon(Icons.menu),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: SearchTitleBar(key: tutorialSearchKey),
          // Pack the action buttons with shrink-wrapped tap targets and
          // compact density so the full set (history, audio, TTS, sync,
          // versions, view-toggle, tools) still fits on narrow phones without
          // a RenderFlex overflow.
          actions: [
            IconButtonTheme(
              data: IconButtonThemeData(
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'History',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.9,
                          minChildSize: 0.5,
                          maxChildSize: 1.0,
                          expand: false,
                          builder: (_, _) => const HistoryPanel(),
                        ),
                      );
                    },
                  ),
                  if (audioData != null)
                    IconButton(
                      icon: const Icon(Icons.headphones),
                      tooltip: 'Audio Player',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => const AudioPlayerWidget(),
                        );
                      },
                    ),
                  if (TtsService.isSupported)
                    IconButton(
                      icon: Icon(
                        ref.watch(ttsControllerProvider).status ==
                                TtsStatus.playing
                            ? Icons.record_voice_over
                            : Icons.record_voice_over_outlined,
                      ),
                      tooltip: 'Read aloud',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => const TtsPlayerWidget(),
                        );
                      },
                    ),
                  const SyncButton(),
                  IconButton(
                    icon: const Icon(Icons.library_books),
                    tooltip: 'Versions',
                    onPressed: _showVersionPicker,
                  ),
                  IconButton(
                    icon: Icon(_isFlowing
                        ? Icons.format_list_numbered
                        : Icons.article_outlined),
                    tooltip: _isFlowing
                        ? 'Switch to verse-by-verse view'
                        : 'Switch to paragraph view',
                    onPressed: () {
                      setState(() {
                        _isFlowing = !_isFlowing;
                      });
                    },
                  ),
                  if (MediaQuery.sizeOf(context).width <= Breakpoints.compact)
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.build),
                        tooltip: 'Tools',
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      endDrawer: MediaQuery.sizeOf(context).width <= Breakpoints.compact
          ? const MobileToolsDrawer()
          : null,
      body: Column(
        children: [
          // Breadcrumb navigation bar
          _BreadcrumbBar(
            onVersionTap: _showVersionPicker,
            onBookTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const BookChooserSheet(),
              );
            },
          ),
          if (_showSearchBox)
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Find in page...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _currentMatchIndex = value.isEmpty ? -1 : 0;
                        });
                        // Debounce the scan-and-scroll so a fast typist doesn't
                        // trigger a full chapter scan on every keystroke.
                        _searchDebounce?.cancel();
                        if (value.isEmpty) return;
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 200),
                          () {
                            if (!mounted || !parallelVersesAsync.hasValue) return;
                            final newMatchVerses = _computeMatchVerses(
                              parallelVersesAsync.value!,
                              value,
                            );
                            if (newMatchVerses.isNotEmpty) {
                              ref
                                  .read(targetVerseToScrollProvider.notifier)
                                  .set(newMatchVerses.first);
                            }
                          },
                        );
                      },
                      onSubmitted: (_) => _nextMatch(matchVerses),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    Text(
                      matchVerses.isEmpty
                          ? '0/0'
                          : '${_currentMatchIndex + 1}/${matchVerses.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up),
                      onPressed: matchVerses.isEmpty ? null : () => _prevMatch(matchVerses),
                      tooltip: 'Previous match',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: matchVerses.isEmpty ? null : () => _nextMatch(matchVerses),
                      tooltip: 'Next match',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showSearchBox = false;
                        _searchQuery = '';
                        _currentMatchIndex = -1;
                        _searchController.clear();
                      });
                      ref.read(findInPageQueryProvider.notifier).set(null);
                      _mainFocusNode.requestFocus();
                    },
                    tooltip: 'Close search',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildReaderBody(context, bookName, chapter),
                ),
                if (selectedVerses.isNotEmpty)
                  Positioned(
                    // Lift the bar above the system navigation bar / gesture
                    // area so it isn't clipped by the Android nav buttons.
                    bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
                    left: 0,
                    right: 0,
                    child: const Center(child: VerseActionBar()),
                  ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  /// Builds the scrollable reading area. On touch devices showing a single
  /// version it pages through every chapter via a [PageView] (smooth swipe
  /// navigation, with adjacent chapters pre-built). Parallel view, desktop, and
  /// the pre-index window fall back to rendering just the current chapter.
  Widget _buildReaderBody(BuildContext context, String bookName, int chapter) {
    final currentChapterAsync = ref.watch(parallelVersesProvider);

    return currentChapterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ReaderMessage(
        icon: Icons.error_outline,
        title: 'Couldn\'t load this chapter',
        message: 'Something went wrong while loading $bookName $chapter.',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(parallelVersesProvider),
      ),
      data: (versesMap) {
        final isSingleVersion = versesMap.length <= 1;

        // Parallel view renders only the current chapter — no swipe paging
        // (arrow keys / footer still navigate). Single-version pages through
        // chapters via the PageView on every platform: the global
        // AppScrollBehavior enables touch, trackpad, and mouse drag, so
        // desktop touchscreens (and trackpad swipes) work too. Vertical list
        // scrolling is unaffected — the gesture arena routes vertical drags to
        // the verse list and only horizontal drags flip chapters.
        if (!isSingleVersion) {
          return _ChapterPage(
            bookName: bookName,
            chapter: chapter,
            isFlowing: _isFlowing,
            searchQuery: _searchQuery,
            onVerseTap: _onVerseTap,
            onFootnoteTap: (_) => _openCommentaryPanel(),
            onStrongTap: _openStrongDictionary,
            onChooseVersion: _showVersionPicker,
            onRetry: () => ref.invalidate(parallelVersesProvider),
          );
        }

        final chapterIndex = ref.watch(chapterIndexProvider).value;
        if (chapterIndex == null || chapterIndex.isEmpty) {
          return _ChapterPage(
            bookName: bookName,
            chapter: chapter,
            isFlowing: _isFlowing,
            searchQuery: _searchQuery,
            onVerseTap: _onVerseTap,
            onFootnoteTap: (_) => _openCommentaryPanel(),
            onStrongTap: _openStrongDictionary,
            onChooseVersion: _showVersionPicker,
            onRetry: () => ref.invalidate(parallelVersesProvider),
          );
        }

        final currentIndex = chapterIndex.indexWhere(
          (e) => e.bookName == bookName && e.chapter == chapter,
        );
        final safeIndex = currentIndex < 0 ? 0 : currentIndex;
        _pageController ??= PageController(initialPage: safeIndex);

        // Realign the controller when the chapter changes from outside the
        // PageView (book chooser, search, history, arrow keys, footer).
        if (currentIndex >= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncPageController(currentIndex);
          });
        }

        // Commit the new chapter only once scrolling fully stops — NOT via
        // onPageChanged, which fires the moment the drag crosses 50% and would
        // rebuild the heavy chapter pages mid-settle, collapsing the animation
        // into an instant snap. depth == 0 ignores the inner verse list's own
        // scroll-end notifications.
        return NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) {
              final page = _pageController?.page;
              if (page != null) _onPageSettled(page.round());
            }
            return false;
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: chapterIndex.length,
            // Pre-build the adjacent chapters so a swipe animates smoothly
            // instead of flashing a loading spinner mid-drag.
            allowImplicitScrolling: true,
            itemBuilder: (context, i) {
              final e = chapterIndex[i];
              return _ChapterPage(
                bookName: e.bookName,
                chapter: e.chapter,
                isFlowing: _isFlowing,
                searchQuery: _searchQuery,
                onVerseTap: _onVerseTap,
                onFootnoteTap: (_) => _openCommentaryPanel(),
                onStrongTap: _openStrongDictionary,
                onChooseVersion: _showVersionPicker,
                onRetry: () => ref.invalidate(
                  chapterVersesProvider(
                    (bookName: e.bookName, chapter: e.chapter),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Renders a single chapter's verses (single-version or parallel) for the
/// reader. Self-contained: it watches its own chapter's verses and decorations
/// via the `(bookName, chapter)` provider families, so several instances can be
/// kept alive side-by-side inside the reader's swipe [PageView].
class _ChapterPage extends ConsumerWidget {
  final String bookName;
  final int chapter;
  final bool isFlowing;
  final String searchQuery;
  final void Function(int verseId) onVerseTap;
  final void Function(int verseId) onFootnoteTap;
  final void Function(String strongNumber) onStrongTap;
  final VoidCallback onChooseVersion;
  final VoidCallback onRetry;

  const _ChapterPage({
    required this.bookName,
    required this.chapter,
    required this.isFlowing,
    required this.searchQuery,
    required this.onVerseTap,
    required this.onFootnoteTap,
    required this.onStrongTap,
    required this.onChooseVersion,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (bookName: bookName, chapter: chapter);
    final versesAsync = ref.watch(chapterVersesProvider(key));
    final showStrongNumbers = ref.watch(appShowStrongNumbersProvider);
    final selectedVerses = ref.watch(selectedVersesProvider);
    final savedHighlights =
        ref.watch(chapterHighlightsFamilyProvider(key)).value ?? <int, String>{};
    final versesWithNotes =
        ref.watch(chapterVersesWithNotesFamilyProvider(key)).value ?? <int>{};
    final versesWithTags =
        ref.watch(chapterVersesWithTagsFamilyProvider(key)).value ?? <int>{};
    final subheadings = ref.watch(chapterSubheadingsProvider(key)).value ??
        <int, List<String>>{};

    return versesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ReaderMessage(
        icon: Icons.error_outline,
        title: 'Couldn\'t load this chapter',
        message: 'Something went wrong while loading $bookName $chapter.',
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
      data: (versesMap) {
        if (versesMap.isEmpty) {
          return _ReaderMessage(
            icon: Icons.menu_book_outlined,
            title: 'Nothing to show here',
            message:
                'No verses were found for $bookName $chapter in the selected version.',
            actionLabel: 'Choose another version',
            onAction: onChooseVersion,
          );
        }

        final headerWidget = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 16.0),
              child: Text(
                '$bookName $chapter',
                // Always Lora for the chapter header, regardless of the user's
                // selected UI font. Lora is bundled (see pubspec `fonts:`), so
                // this resolves locally with no network fetch.
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontFamily: 'Lora',
                  fontFamilyFallback: const <String>[],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              width: 250,
              height: 1,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              margin: const EdgeInsets.only(bottom: 32.0),
            ),
          ],
        );

        final versionIds = versesMap.keys.toList();
        if (versionIds.length == 1) {
          final verses = versesMap[versionIds.first] ?? [];
          final Widget view = isFlowing
              ? FlowingParagraphView(
                  verses: verses,
                  selectedVerses: selectedVerses,
                  savedHighlights: savedHighlights,
                  versesWithNotes: versesWithNotes,
                  versesWithTags: versesWithTags,
                  subheadings: subheadings,
                  onVerseTap: onVerseTap,
                  onFootnoteTap: onFootnoteTap,
                  onStrongTap: onStrongTap,
                  showStrongNumbers: showStrongNumbers,
                  searchQuery: searchQuery,
                  headerWidget: headerWidget,
                )
              : VerseListView(
                  verses: verses,
                  selectedVerses: selectedVerses,
                  savedHighlights: savedHighlights,
                  versesWithNotes: versesWithNotes,
                  versesWithTags: versesWithTags,
                  subheadings: subheadings,
                  onVerseTap: onVerseTap,
                  onFootnoteTap: onFootnoteTap,
                  onStrongTap: onStrongTap,
                  showStrongNumbers: showStrongNumbers,
                  searchQuery: searchQuery,
                  headerWidget: headerWidget,
                );
          // Cap the single-column reading measure so verse text doesn't
          // stretch the full pane width on desktop; centered with margins.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: view,
            ),
          );
        }

        return ParallelView(
          versesMap: versesMap,
          isFlowing: isFlowing,
          selectedVerses: selectedVerses,
          savedHighlights: savedHighlights,
          versesWithNotes: versesWithNotes,
          versesWithTags: versesWithTags,
          subheadings: subheadings,
          onVerseTap: onVerseTap,
          onFootnoteTap: onFootnoteTap,
          onStrongTap: onStrongTap,
          showStrongNumbers: showStrongNumbers,
          searchQuery: searchQuery,
          headerWidget: headerWidget,
        );
      },
    );
  }
}

/// A centered, friendly placeholder for the reader's empty and error states,
/// with an icon, message, and an optional recovery action.
class _ReaderMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ReaderMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbBar extends ConsumerWidget {
  final VoidCallback onVersionTap;
  final VoidCallback onBookTap;

  const _BreadcrumbBar({
    required this.onVersionTap,
    required this.onBookTap,
  });

  void _showChapterPicker(BuildContext context, WidgetRef ref) async {
    final store = ref.read(contentStoreProvider);
    final bookName = ref.read(selectedBookNameProvider);
    final activeVersions = ref.read(activeVersionsProvider);
    if (activeVersions.isEmpty) return;

    // Find the book to get its ID
    final books = await (store.select(store.books)
          ..where((b) => b.name.equals(bookName)))
        .get();
    if (books.isEmpty) return;
    final bookId = books.first.id;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookChooserSheet(
        initialBookId: bookId,
        initialBookName: bookName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVersions = ref.watch(activeVersionsProvider);
    final bookName = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final theme = Theme.of(context);
    final versionLabel = activeVersions.isNotEmpty
        ? activeVersions.join(', ')
        : 'No Version';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: onVersionTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Text(
                        versionLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                Flexible(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: onBookTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Text(
                        bookName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _showChapterPicker(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Chapter $chapter',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down, size: 16, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                // Chapter prev/next sit immediately after the chapter selector
                // so chapter navigation reads as a single grouped unit rather
                // than being stranded at the far edge of the bar.
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Chapter',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => ref.read(navigationControllerProvider).previousChapter(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Chapter',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => ref.read(navigationControllerProvider).nextChapter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
