import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/content_providers.dart';
import '../app/shared_prefs.dart';
import '../app/version.dart';
import '../data/logging.dart';

enum _RebuildStatus { idle, running, done, failed }

class WhatsNewDialog extends ConsumerStatefulWidget {
  /// Whether to surface the one-time "rebuild your search index" note at the
  /// top of the dialog. Set by `MainShell._checkWhatsNew` for upgrading users
  /// who haven't yet rebuilt their (possibly pre-markup-stripping) index.
  final bool showRebuildPrompt;

  const WhatsNewDialog({super.key, this.showRebuildPrompt = false});

  @override
  ConsumerState<WhatsNewDialog> createState() => _WhatsNewDialogState();
}

class _WhatsNewDialogState extends ConsumerState<WhatsNewDialog> {
  // Loaded once here rather than inside build(): a FutureBuilder whose future
  // is created in build() re-reads and re-parses the asset on every rebuild
  // (theme/MediaQuery changes, etc.) while the dialog is open.
  late final Future<List<Map<String, dynamic>>> _changelogFuture;

  _RebuildStatus _rebuildStatus = _RebuildStatus.idle;

  @override
  void initState() {
    super.initState();
    _changelogFuture = _loadChangelog();
  }

  Future<List<Map<String, dynamic>>> _loadChangelog() async {
    final String response = await rootBundle.loadString('assets/changelog.json');
    final List<dynamic> data = json.decode(response);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> _rebuildSearchIndex() async {
    setState(() => _rebuildStatus = _RebuildStatus.running);
    try {
      await ref.read(contentStoreProvider).rebuildSearchIndex();
      await ref
          .read(sharedPreferencesProvider)
          .setInt(kSearchIndexRebuiltGenKey, kSearchIndexGeneration);
      if (mounted) setState(() => _rebuildStatus = _RebuildStatus.done);
    } catch (e, stack) {
      logError(e, stack, context: 'WhatsNewDialog.rebuildSearchIndex');
      if (mounted) setState(() => _rebuildStatus = _RebuildStatus.failed);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'track_changes':
        return Icons.track_changes;
      case 'brightness_6':
        return Icons.brightness_6;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'bug_report':
        return Icons.bug_report;
      case 'update':
        return Icons.update;
      case 'new_releases':
      default:
        return Icons.new_releases;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _changelogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return AlertDialog(
            title: const Text("What's New"),
            content: const Text("No release notes found."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        }

        final latestRelease = snapshot.data!.first;
        final features = latestRelease['features'] as List<dynamic>;
        final releaseVersion = latestRelease['version'] ?? appVersion;

        // Group features by category
        final Map<String, List<dynamic>> groupedFeatures = {};
        for (final feature in features) {
          final category = feature['category'] ?? 'Updates';
          groupedFeatures.putIfAbsent(category, () => []).add(feature);
        }

        // Sort categories logically: New Features, Updates, Bugfixes, then others
        final sortedCategories = groupedFeatures.keys.toList()..sort((a, b) {
          int getWeight(String cat) {
            if (cat == 'New Features') return 0;
            if (cat == 'Updates') return 1;
            if (cat == 'Bugfixes') return 2;
            return 3;
          }
          return getWeight(a).compareTo(getWeight(b));
        });

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.new_releases, color: Colors.blue),
              const SizedBox(width: 12),
              Text("What's New in $releaseVersion"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showRebuildPrompt) _buildRebuildNote(context),
                ...sortedCategories.expand((category) {
                  final catFeatures = groupedFeatures[category]!;
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                      child: Text(
                        category,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ),
                    ...catFeatures.map((feature) {
                      return _buildFeature(
                        context,
                        icon: _getIconData(feature['icon'] ?? 'new_releases'),
                        title: feature['title'] ?? '',
                        description: feature['description'] ?? '',
                      );
                    }),
                  ];
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Awesome!'),
            ),
          ],
        );
      },
    );
  }

  /// An attention-grabbing caution card prompting a one-tap search-index
  /// rebuild. Shown to upgrading users whose index predates the current
  /// indexing generation. Flips to a success/retry state after the action runs.
  Widget _buildRebuildNote(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = _rebuildStatus == _RebuildStatus.done;
    final failed = _rebuildStatus == _RebuildStatus.failed;

    // Caution = amber; success = green; both tuned for light and dark themes.
    final MaterialColor swatch = done ? Colors.green : Colors.amber;
    final accent = isDark ? swatch.shade300 : swatch.shade800;
    final bg = (isDark ? swatch.shade900 : swatch.shade100)
        .withValues(alpha: isDark ? 0.28 : 0.7);
    final border = isDark ? swatch.shade700 : swatch.shade600;

    final headerText = done
        ? 'All set'
        : failed
            ? "Couldn't rebuild"
            : 'Action recommended';
    final headerIcon = done
        ? Icons.check_circle
        : Icons.warning_amber_rounded;

    final message = done
        ? 'Search index rebuilt — your searches are up to date.'
        : failed
            ? "Couldn't rebuild the index. Retry, or use "
                'Settings → Rebuild search index.'
            : 'We improved how verse search is indexed. Rebuild your search '
                'index once so existing content returns complete results.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: accent, size: 22),
              const SizedBox(width: 8),
              Text(
                headerText,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (!done) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _rebuildStatus == _RebuildStatus.running
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: _rebuildSearchIndex,
                      icon: Icon(failed ? Icons.refresh : Icons.build_outlined),
                      label: Text(failed ? 'Retry' : 'Rebuild now'),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (title.isNotEmpty && description.isNotEmpty)
                  const SizedBox(height: 2),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
