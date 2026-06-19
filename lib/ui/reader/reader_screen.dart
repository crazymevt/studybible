import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../app/tag_providers.dart';
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
import '../app_drawer.dart';
import '../../app/dashboard_providers.dart';
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

  @override
  void initState() {
    super.initState();
    _dashboardAction = ref.read(dashboardActionProvider);
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _handleLifecycleState,
    );
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
    _logSession();
    _lifecycleListener.dispose();
    _chapterReadTimer?.cancel();
    super.dispose();
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
    final availableVersions = await ref.read(versionsProvider.future);

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

  @override
  Widget build(BuildContext context) {
    final parallelVersesAsync = ref.watch(parallelVersesProvider);
    final bookName = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final savedHighlightsAsync = ref.watch(chapterHighlightsProvider);
    final savedHighlights = savedHighlightsAsync.value ?? <int, String>{};
    final selectedVerses = ref.watch(selectedVersesProvider);
    
    final versesWithNotesAsync = ref.watch(chapterVersesWithNotesProvider);
    final versesWithNotes = versesWithNotesAsync.value ?? <int>{};
    
    final versesWithTagsAsync = ref.watch(chapterVersesWithTagsProvider);
    final versesWithTags = versesWithTagsAsync.value ?? <int>{};

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

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (ref.read(selectedVersesProvider).isNotEmpty) {
            ref.read(selectedVersesProvider.notifier).clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Chapter',
                onPressed: () =>
                    ref.read(navigationControllerProvider).previousChapter(),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const BookChooserSheet(),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$bookName $chapter'),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Chapter',
              onPressed: () =>
                  ref.read(navigationControllerProvider).nextChapter(),
            ),
            if (MediaQuery.sizeOf(context).width > 800)
              const Expanded(child: AudioPlayerWidget()),
          ],
        ),
        actions: [
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
          Expanded(
            child: parallelVersesAsync.when(
        data: (versesMap) {
          if (versesMap.isEmpty) {
            return const Center(child: Text('No verses found.'));
          }

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
                    onVerseTap: (verseId) => ref
                        .read(selectedVersesProvider.notifier)
                        .toggle(verseId),
                    onFootnoteTap: (verseId) => _openCommentaryPanel(),
                  )
                : VerseListView(
                    verses: verses,
                    selectedVerses: selectedVerses,
                    savedHighlights: savedHighlights,
                    versesWithNotes: versesWithNotes,
                    versesWithTags: versesWithTags,
                    onVerseTap: (verseId) => ref
                        .read(selectedVersesProvider.notifier)
                        .toggle(verseId),
                    onFootnoteTap: (verseId) => _openCommentaryPanel(),
                  );
          } else {
            content = ParallelView(
              versesMap: versesMap,
              isFlowing: _isFlowing,
              selectedVerses: selectedVerses,
              savedHighlights: savedHighlights,
              versesWithNotes: versesWithNotes,
              versesWithTags: versesWithTags,
              onVerseTap: (verseId) =>
                  ref.read(selectedVersesProvider.notifier).toggle(verseId),
              onFootnoteTap: (verseId) => _openCommentaryPanel(),
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
        ],
      ),
    );
  }
}
