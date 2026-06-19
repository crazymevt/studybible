import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_providers.dart';
import '../../app/reader_state.dart';
import '../../app/user_providers.dart';
import '../../app/sync_service.dart';
import 'verse_list_view.dart';
import 'flowing_paragraph_view.dart';
import 'parallel_view.dart';
import 'verse_action_bar.dart';
import 'book_chooser_sheet.dart';
import 'study_pane.dart';
import 'history_panel.dart';
import 'media_panel.dart';
import 'audio_player_widget.dart';
import '../../app/app_state.dart';
import '../app_drawer.dart';
import '../../app/dashboard_providers.dart';
import 'dart:async';

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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
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
        return Consumer(builder: (context, ref, child) {
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
                  ref.read(activeVersionsProvider.notifier).toggle(version.id);
                },
              );
            },
          );
        });
      },
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
    final activeVersions = ref.watch(activeVersionsProvider);

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

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$bookName $chapter'),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const Expanded(child: AudioPlayerWidget()),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Highlights',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sync failed: $e')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              if (MediaQuery.sizeOf(context).width <= 800) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 1.0,
                    expand: false,
                    builder: (_, scrollController) => const HistoryPanel(),
                  ),
                );
              } else {
                ref.read(activeToolProvider.notifier).setTool(ActiveTool.history);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_library),
            tooltip: 'Media',
            onPressed: () {
              if (MediaQuery.sizeOf(context).width <= 800) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 1.0,
                    expand: false,
                    builder: (_, scrollController) => Consumer(
                      builder: (context, ref, _) {
                        final bookName = ref.watch(selectedBookNameProvider);
                        final chapter = ref.watch(selectedChapterProvider);
                        return MediaPanel(bookName: bookName, chapter: chapter);
                      },
                    ),
                  ),
                );
              } else {
                ref.read(activeToolProvider.notifier).setTool(ActiveTool.media);
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
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu_book),
                tooltip: 'Study Pane',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            }
          ),
        ],
      ),
      endDrawer: const StudyPane(),
      body: parallelVersesAsync.when(
        data: (versesMap) {
          if (versesMap.isEmpty) {
            return const Center(child: Text('No verses found.'));
          }

          Widget content;
          if (activeVersions.length == 1) {
            final versionId = activeVersions.first;
            final verses = versesMap[versionId] ?? [];
            content = _isFlowing
                ? FlowingParagraphView(
                    verses: verses,
                    selectedVerses: selectedVerses,
                    savedHighlights: savedHighlights,
                    onVerseTap: (verseId) => ref.read(selectedVersesProvider.notifier).toggle(verseId),
                  )
                : VerseListView(
                    verses: verses,
                    selectedVerses: selectedVerses,
                    savedHighlights: savedHighlights,
                    onVerseTap: (verseId) => ref.read(selectedVersesProvider.notifier).toggle(verseId),
                  );
          } else {
            content = ParallelView(
              versesMap: versesMap,
              isFlowing: _isFlowing,
              selectedVerses: selectedVerses,
              savedHighlights: savedHighlights,
              onVerseTap: (verseId) => ref.read(selectedVersesProvider.notifier).toggle(verseId),
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: content),
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
    );
  }
}
