import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../app/tag_providers.dart';
import '../../app/search_providers.dart';
import '../../app/sync_service.dart';
import 'verse_list_view.dart';
import 'flowing_paragraph_view.dart';
import 'parallel_view.dart';
import 'verse_action_bar.dart';
import 'book_chooser_sheet.dart';
import 'study_pane.dart';
import 'mobile_tools_drawer.dart';
import 'audio_player_widget.dart';
import 'commentary_panel.dart';
import 'dictionary_panel.dart';
import '../app_drawer.dart';
import '../../app/dashboard_providers.dart';
import '../../app/app_state.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();

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
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();
    super.dispose();
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
                return CheckboxListTile(
                  title: Text('${version.name} (${version.id})'),
                  value: isActive,
                  onChanged: (checked) {
                    ref
                        .read(activeVersionsProvider.notifier)
                        .toggle(version.id);
                  },
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
    if (MediaQuery.sizeOf(context).width > 800) {
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
    final showStrongNumbers = ref.watch(appShowStrongNumbersProvider);
    final savedHighlightsAsync = ref.watch(chapterHighlightsProvider);
    final savedHighlights = savedHighlightsAsync.value ?? <int, String>{};
    final selectedVerses = ref.watch(selectedVersesProvider);
    
    final versesWithNotesAsync = ref.watch(chapterVersesWithNotesProvider);
    final versesWithNotes = versesWithNotesAsync.value ?? <int>{};
    
    final versesWithTagsAsync = ref.watch(chapterVersesWithTagsProvider);
    final versesWithTags = versesWithTagsAsync.value ?? <int>{};

    final subheadingsAsync = ref.watch(chapterSubheadingsProvider((bookName: bookName, chapter: chapter)));
    final subheadings = subheadingsAsync.value ?? <int, List<String>>{};

    // Auto-tracking logic
    ref.listen<String>(selectedBookNameProvider, (prev, next) {
      _updateChapterTracking(next, ref.read(selectedChapterProvider));
    });
    ref.listen<int>(selectedChapterProvider, (prev, next) {
      _updateChapterTracking(ref.read(selectedBookNameProvider), next);
    });

    // Trigger initial tracking if not already tracking
    if (_trackingBook == null) {
      _updateChapterTracking(bookName, chapter);
    }

    List<int> matchVerses = [];
    if (_searchQuery.isNotEmpty && parallelVersesAsync.hasValue) {
      final versesMap = parallelVersesAsync.value!;
      final lowerQuery = _searchQuery.toLowerCase();
      final Set<int> matches = {};
      for (final verses in versesMap.values) {
        for (final v in verses) {
          if (v.textContent.toLowerCase().contains(lowerQuery)) {
            matches.add(v.verse);
          }
        }
      }
      matchVerses = matches.toList()..sort();
      
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
        
        if (event is KeyDownEvent) {
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
          centerTitle: true,
          title: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(Icons.search, size: 20, color: Colors.grey),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search entire library...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          ref.read(globalSearchQueryProvider.notifier).setQuery(value);
                          if (MediaQuery.sizeOf(context).width > 800) {
                            ref.read(activeToolProvider.notifier).openTool(ActiveTool.search);
                            Scaffold.of(context).openEndDrawer();
                          } else {
                            Scaffold.of(context).openEndDrawer();
                            Future.delayed(const Duration(milliseconds: 100), () {
                              ref.read(activeToolProvider.notifier).openTool(ActiveTool.search);
                            });
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.headphones),
              tooltip: 'Audio Player',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => const AudioPlayerWidget(),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Data',
            onPressed: () async {
              try {
                await ref.read(syncServiceProvider).sync();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync complete!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
                }
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Versions',
            onPressed: _showVersionPicker,
          ),
          IconButton(
            icon: Icon(_isFlowing ? Icons.format_list_numbered : Icons.notes),
            tooltip: 'Toggle View Mode',
            onPressed: () {
              setState(() {
                _isFlowing = !_isFlowing;
              });
            },
          ),
          if (MediaQuery.sizeOf(context).width <= 800)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.build),
                tooltip: 'Tools',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            )
          else
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu_book),
                  tooltip: 'Study Pane',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                );
              },
            ),
        ],
      ),
      endDrawer: MediaQuery.sizeOf(context).width <= 800
          ? const MobileToolsDrawer()
          : const StudyPane(),
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
                        if (value.isNotEmpty && parallelVersesAsync.hasValue) {
                          final versesMap = parallelVersesAsync.value!;
                          final lowerQuery = value.toLowerCase();
                          final Set<int> matches = {};
                          for (final verses in versesMap.values) {
                            for (final v in verses) {
                              if (v.textContent.toLowerCase().contains(lowerQuery)) {
                                matches.add(v.verse);
                              }
                            }
                          }
                          final newMatchVerses = matches.toList()..sort();
                          if (newMatchVerses.isNotEmpty) {
                            ref.read(targetVerseToScrollProvider.notifier).set(newMatchVerses[0]);
                          }
                        }
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
                      });
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
            child: parallelVersesAsync.when(
        data: (versesMap) {
          if (versesMap.isEmpty) {
            return const Center(child: Text('No verses found.'));
          }

          final headerWidget = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 16.0),
                child: Text(
                  '$bookName $chapter',
                  style: GoogleFonts.lora(
                    textStyle: Theme.of(context).textTheme.displaySmall,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                width: 250,
                height: 1,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                margin: const EdgeInsets.only(bottom: 32.0),
              ),
            ],
          );

          Widget content;
          final trueActiveVersions = versesMap.keys.toList();
          if (trueActiveVersions.length == 1) {
            final versionId = trueActiveVersions.first;
            final verses = versesMap[versionId] ?? [];
            content = _isFlowing
                ? FlowingParagraphView(
                    verses: verses,
                    selectedVerses: selectedVerses,
                    savedHighlights: savedHighlights,
                    versesWithNotes: versesWithNotes,
                    versesWithTags: versesWithTags,
                    subheadings: subheadings,
                    onVerseTap: (verseId) => ref
                        .read(selectedVersesProvider.notifier)
                        .toggle(verseId),
                    onFootnoteTap: (verseId) => _openCommentaryPanel(),
                    onStrongTap: _openStrongDictionary,
                    showStrongNumbers: showStrongNumbers,
                    searchQuery: _searchQuery,
                    headerWidget: headerWidget,
                  )
                : VerseListView(
                    verses: verses,
                    selectedVerses: selectedVerses,
                    savedHighlights: savedHighlights,
                    versesWithNotes: versesWithNotes,
                    versesWithTags: versesWithTags,
                    subheadings: subheadings,
                    onVerseTap: (verseId) => ref
                        .read(selectedVersesProvider.notifier)
                        .toggle(verseId),
                    onFootnoteTap: (verseId) => _openCommentaryPanel(),
                    onStrongTap: _openStrongDictionary,
                    showStrongNumbers: showStrongNumbers,
                    searchQuery: _searchQuery,
                    headerWidget: headerWidget,
                  );
          } else {
            content = ParallelView(
              versesMap: versesMap,
              isFlowing: _isFlowing,
              selectedVerses: selectedVerses,
              savedHighlights: savedHighlights,
              versesWithNotes: versesWithNotes,
              versesWithTags: versesWithTags,
              subheadings: subheadings,
              onVerseTap: (verseId) =>
                  ref.read(selectedVersesProvider.notifier).toggle(verseId),
              onFootnoteTap: (verseId) => _openCommentaryPanel(),
              onStrongTap: _openStrongDictionary,
              showStrongNumbers: showStrongNumbers,
              searchQuery: _searchQuery,
              headerWidget: headerWidget,
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    if (MediaQuery.sizeOf(context).width <= 800)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withAlpha(128),
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: const AudioPlayerWidget(),
                      ),
                    Expanded(child: content),
                  ],
                ),
              ),
              if (selectedVerses.isNotEmpty)
                const Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(child: VerseActionBar()),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    ),
        ],
      ),
    ));
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

    // Get chapter count via the existing provider
    final chapterCount = await ref.read(chapterCountProvider(bookId).future);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Text('$bookName — Select Chapter'),
          content: SizedBox(
            width: 320,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: chapterCount,
              itemBuilder: (context, index) {
                final ch = index + 1;
                final isSelected = ch == ref.read(selectedChapterProvider);
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    ref.read(selectedChapterProvider.notifier).set(ch);
                    ref.read(navigationControllerProvider).recordHistory();
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$ch',
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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
          InkWell(
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
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          InkWell(
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
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Chapter',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => ref.read(navigationControllerProvider).previousChapter(),
          ),
          const SizedBox(width: 8),
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
    );
  }
}
