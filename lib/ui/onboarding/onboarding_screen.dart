import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/content_manager_providers.dart';
import '../../app/app_state.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(crosswireCatalogProvider);
    final downloadStates = ref.watch(contentManagerControllerProvider);

    // We target KJV from CrossWire
    final kjvProgress = downloadStates['cw_KJV'];
    final isDownloadingKjv = kjvProgress != null && kjvProgress.percent < 1.0 && kjvProgress.status != 'Done';

    // Aggregate progress for the curated "recommended resources" install.
    final recProgress = downloadStates[recommendedDownloadKey];
    final isDownloadingRec = recProgress != null &&
        recProgress.status != 'Done' &&
        !recProgress.status.startsWith('Error') &&
        !recProgress.status.startsWith('Finished');

    final isDownloading = isDownloadingKjv || isDownloadingRec;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to StudyBible',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To get started, download the recommended study set — Bibles, commentaries, and dictionaries — or quickly install just the King James Version. You can always browse the Content Manager for more.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  if (isDownloading) ...[
                    Builder(builder: (context) {
                      // Show whichever install is currently running.
                      final active = isDownloadingRec ? recProgress : kjvProgress!;
                      return Column(
                        children: [
                          Text(
                            active.status,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: active.percent,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Text('${(active.percent * 100).toStringAsFixed(0)}%'),
                        ],
                      );
                    }),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text(
                          'Download Recommended Resources',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          ref
                              .read(contentManagerControllerProvider.notifier)
                              .downloadRecommended();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Includes the KJV, Berean Standard & ESV Global Study Bibles, '
                      'Matthew Henry & Poole commentaries, and Vine\'s, Webster\'s, '
                      'and King James dictionaries.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    catalogAsync.when(
                      data: (modules) {
                        final kjvModule = modules.where((m) => m.config.name == 'KJV').firstOrNull;

                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text(
                              'Quick Install KJV Bible Only',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: kjvModule == null ? null : () {
                              ref.read(contentManagerControllerProvider.notifier).downloadAndImportCrosswire(kjvModule);
                            },
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Text('Failed to load catalog: $err', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.explore),
                      label: const Text(
                        'Browse Content Manager',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isDownloading ? null : () {
                        ref.read(appModuleProvider.notifier).setModule(AppModule.contentManager);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
