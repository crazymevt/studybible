import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/shared_prefs.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _finishTutorial() {
    ref.read(hasSeenTutorialProvider.notifier).setSeen(true);
    // If we were pushed onto the stack (from settings), pop.
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pages = [
      const _TutorialPage(
        icon: Icons.menu_book,
        title: 'Bible Reader',
        description: 'Read multiple Bible versions side-by-side in parallel or interleaved mode. Long press or right-click any word to see definitions from installed dictionaries, and click a verse to see actionable items such as adding notes, comparing verses, and seeing cross-references.',
      ),
      const _TutorialPage(
        icon: Icons.view_sidebar,
        title: 'Study Tools',
        description: 'Access a powerful suite of tools from the side panel: Commentaries, Dictionaries, Reading Plans, Devotionals, and Media.',
      ),
      const _TutorialPage(
        icon: Icons.search,
        title: 'Powerful Search',
        description: 'Search across all your Bibles and journals in milliseconds. Use `ot:` or `nt:` to filter by testament. Use `~10` between words to find them near each other (e.g. `faith ~10 works`).',
      ),
      const _TutorialPage(
        icon: Icons.edit_document,
        title: 'Journals & Prayers',
        description: 'Track your daily walk with God. Write rich-text journal entries with clickable verse references, and keep a running list of your active and answered prayers.',
      ),
      const _TutorialPage(
        icon: Icons.cloud_download,
        title: 'Content Manager & Sync',
        description: 'Download dozens of free Bibles and dictionaries from the CrossWire library. Use the Backup & Restore feature to safely sync your data across devices.',
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishTutorial,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: pages[index],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                  // Next / Finish button
                  FilledButton(
                    onPressed: () {
                      if (_currentPage < pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishTutorial();
                      }
                    },
                    child: Text(_currentPage < pages.length - 1 ? 'Next' : 'Finish'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 100,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
