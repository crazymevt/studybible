import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/dashboard_providers.dart';
import '../../app/update_checker.dart';
import '../../data/logging.dart';
import '../app_drawer.dart';
import 'reading_progress_dialog.dart';
import 'time_analytics_dialog.dart';
import 'achievements_dialog.dart';
import '../../data/models/achievement_def.dart';
import '../../app/reading_plan_providers.dart';
import '../../app/app_state.dart';
import '../../data/verse_of_the_day_list.dart';
import '../../app/reader_state.dart';
import '../../app/content_providers.dart';
import '../common/search_title_bar.dart';
import '../../app/sync_service.dart';
import '../common/breakpoints.dart';
import 'action_items_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pace = ref.watch(readingPaceProvider);
    final timeData = ref.watch(timeAnalyticsProvider);
    final coverage = ref.watch(bibleCoverageProvider);
    final biblesCompleted = ref.watch(biblesCompletedProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final updateCheckAsync = ref.watch(updateCheckerProvider);
    final prefs = ref.watch(dashboardPrefsProvider);

    int chaptersRead = 0;
    for (final chapters in coverage.values) {
      chaptersRead += chapters.length;
    }
    final double percent = (chaptersRead / 1189) * 100;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        centerTitle: true,
        title: const SearchTitleBar(),
        actions: [
          const _SyncButton(),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              icon: const Icon(Icons.menu_book),
              label: const Text('Read Bible'),
              onPressed: () {
                ref
                    .read(appModuleProvider.notifier)
                    .setModule(AppModule.reader);
              },
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > Breakpoints.compact;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (updateCheckAsync.value != null &&
                    ref.watch(dismissedUpdateVersionProvider) !=
                        updateCheckAsync.value!.latestVersion)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: MaterialBanner(
                      elevation: 1,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      leading: const Icon(Icons.system_update),
                      content: Text('A new version of Study Bible (${updateCheckAsync.value!.latestVersion}) is available!'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            ref
                                .read(dismissedUpdateVersionProvider.notifier)
                                .dismiss(updateCheckAsync.value!.latestVersion);
                          },
                          child: const Text('Dismiss'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final uri =
                                Uri.parse(updateCheckAsync.value!.releaseUrl);
                            if (!await launchUrl(uri,
                                mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open the release page.'),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('View Release'),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Your Study Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Top Row: Quick Stats
                if (prefs['showQuickStats'] ?? true) ...[
                  if (isDesktop)
                    Row(
                      children: [
                      Expanded(
                        child: _buildPaceCard(
                          context,
                          'Day Streak',
                          pace['currentStreak'].toString(),
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPaceCard(
                          context,
                          'Longest Streak',
                          pace['longestStreak'].toString(),
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPaceCard(
                          context,
                          'Days Active',
                          pace['daysActive'].toString(),
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPaceCard(
                          context,
                          'Chapters This Week',
                          pace['chaptersThisWeek'].toString(),
                          Icons.menu_book,
                          Colors.green,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildPaceCard(
                              context,
                              'Day Streak',
                              pace['currentStreak'].toString(),
                              Icons.local_fire_department,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPaceCard(
                              context,
                              'Longest Streak',
                              pace['longestStreak'].toString(),
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPaceCard(
                              context,
                              'Days Active',
                              pace['daysActive'].toString(),
                              Icons.calendar_today,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPaceCard(
                              context,
                              'Chapters This Week',
                              pace['chaptersThisWeek'].toString(),
                              Icons.menu_book,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                // Main Content Area
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Progress and Plans
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (prefs['showVerseOfTheDay'] ?? true) ...[
                              _buildVerseOfTheDayCard(context, ref),
                              const SizedBox(height: 16),
                            ],
                            if (prefs['showReadingProgress'] ?? true) ...[
                              _buildReadingProgressCard(
                                context,
                                percent,
                                chaptersRead,
                                coverage,
                                biblesCompleted,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (prefs['showReadingPlans'] ?? true)
                              _buildReadingPlansSection(context, ref),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: Analytics and Achievements
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (prefs['showActionItems'] ?? true) ...[
                              const DashboardActionItemsWidget(),
                              const SizedBox(height: 16),
                            ],
                            if (prefs['showTimeAnalytics'] ?? true) ...[
                              _buildTimeAnalyticsCard(context, timeData, ref),
                              const SizedBox(height: 16),
                            ],
                            if (prefs['showAchievements'] ?? true)
                              _buildAchievementsCard(context, achievementsAsync),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (prefs['showVerseOfTheDay'] ?? true) ...[
                        _buildVerseOfTheDayCard(context, ref),
                        const SizedBox(height: 16),
                      ],
                      if (prefs['showReadingProgress'] ?? true) ...[
                        _buildReadingProgressCard(
                          context,
                          percent,
                          chaptersRead,
                          coverage,
                          biblesCompleted,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (prefs['showReadingPlans'] ?? true) ...[
                        _buildReadingPlansSection(context, ref),
                        const SizedBox(height: 16),
                      ],
                      if (prefs['showActionItems'] ?? true) ...[
                        const DashboardActionItemsWidget(),
                        const SizedBox(height: 16),
                      ],
                      if (prefs['showTimeAnalytics'] ?? true) ...[
                        _buildTimeAnalyticsCard(context, timeData, ref),
                        const SizedBox(height: 16),
                      ],
                      if (prefs['showAchievements'] ?? true)
                        _buildAchievementsCard(context, achievementsAsync),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadingProgressCard(
    BuildContext context,
    double percent,
    int totalChapters,
    Map<String, List<int>> coverage,
    int biblesCompleted,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => ReadingProgressDialog(coverage: coverage),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biblesCompleted > 0 ? 'Bible Progress (Pass ${biblesCompleted + 1})' : 'Bible Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalChapters / 1189 Chapters Read',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap to view complete coverage details',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.withAlpha(50),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$biblesCompleted×',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAnalyticsCard(
    BuildContext context,
    Map<String, int> timeData,
    WidgetRef ref,
  ) {
    final thisWeekMins = (timeData['thisWeekMs'] ?? 0) ~/ 60000;
    final lastWeekMins = (timeData['lastWeekMs'] ?? 0) ~/ 60000;
    final yearAgoMins = (timeData['yearAgoMs'] ?? 0) ~/ 60000;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final trackers = ref.read(timeTrackerProvider).value ?? [];
          showDialog(
            context: context,
            builder: (_) => TimeAnalyticsDialog(trackers: trackers),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Time in the Word',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildTimeRow('This Week', thisWeekMins, Colors.blue),
              const SizedBox(height: 16),
              _buildTimeRow('Last Week', lastWeekMins, Colors.grey),
              const SizedBox(height: 16),
              _buildTimeRow(
                'A Year Ago',
                yearAgoMins,
                Colors.grey.withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, int mins, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: mins / 120, // Example scale: 2 hours is 100% width
              color: color,
              backgroundColor: color.withAlpha(50),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          child: Text(
            '${mins}m',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPaceCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withAlpha(20), color.withAlpha(5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(
    BuildContext context,
    AsyncValue achievementsAsync,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          achievementsAsync.whenData((unlockedList) {
            showDialog(
              context: context,
              builder: (_) =>
                  AchievementsDialog(unlockedAchievements: unlockedList),
            );
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Achievements',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              achievementsAsync.when(
                data: (unlockedList) {
                  final totalCount = allAchievements.length;
                  final unlockedCount = unlockedList.length;
                  final percent = totalCount > 0
                      ? (unlockedCount / totalCount)
                      : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$unlockedCount / $totalCount Unlocked',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${(percent * 100).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey.withAlpha(50),
                          color: Colors.amber,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (unlockedList.isEmpty)
                        const Text(
                          'Keep reading to unlock badges!',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: unlockedList.take(6).map<Widget>((a) {
                            final def = allAchievements.firstWhere(
                              (d) => d.id == a.id,
                              orElse: () => AchievementDef(
                                category: '',
                                id: a.id,
                                name: a.id,
                                description: '',
                                icon: Icons.star,
                                color: Colors.blue,
                              ),
                            );
                            return Tooltip(
                              message: def.name,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: def.color.withAlpha(30),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: def.color.withAlpha(100),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  def.icon,
                                  size: 24,
                                  color: def.color,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      if (unlockedList.length > 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '+${unlockedList.length - 6} more',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('Error: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingPlansSection(BuildContext context, WidgetRef ref) {
    final activePlansAsync = ref.watch(activeReadingPlansProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading Plans',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                  tooltip: 'Go to Reading Plans',
                  onPressed: () {
                    ref
                        .read(appModuleProvider.notifier)
                        .setModule(AppModule.reader);
                    ref
                        .read(activeToolProvider.notifier)
                        .setTool(ActiveTool.readingPlans);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            activePlansAsync.when(
              data: (plans) {
                if (plans.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withAlpha(50)),
                    ),
                    child: const Center(
                      child: Text(
                        'No active reading plans. Create one in the Reader sidebar!',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return Column(
                  children: plans
                      .map((plan) => _ReadingPlanProgressItem(plan: plan))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingPlanProgressItem extends ConsumerWidget {
  final dynamic plan; // ReadingPlan

  const _ReadingPlanProgressItem({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(readingPlanDaysProvider(plan.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: daysAsync.when(
        data: (days) {
          if (days.isEmpty) return const SizedBox.shrink();

          final totalDays = days.length;
          final completedDays = days.where((d) => d.completed).length;
          final percent = totalDays > 0 ? completedDays / totalDays : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(percent * 100).toInt()}%'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey.withAlpha(50),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 4),
              Text(
                '$completedDays / $totalDays days',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (err, _) => const SizedBox.shrink(),
      ),
    );
  }
}

extension on DashboardScreen {
  Widget _buildVerseOfTheDayCard(BuildContext context, WidgetRef ref) {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final verse = versesOfTheDay[dayOfYear % versesOfTheDay.length];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final reference = verse.reference;
          final lastSpaceIdx = reference.lastIndexOf(' ');
          if (lastSpaceIdx == -1) return;

          final bookName = reference.substring(0, lastSpaceIdx);
          final chapterVerse = reference.substring(lastSpaceIdx + 1);

          final colonIdx = chapterVerse.indexOf(':');
          if (colonIdx == -1) return;

          final chapterStr = chapterVerse.substring(0, colonIdx);
          final chapter = int.tryParse(chapterStr);

          if (chapter != null) {
            ref.read(selectedBookNameProvider.notifier).set(bookName);
            ref.read(selectedChapterProvider.notifier).set(chapter);

            final verseStr = chapterVerse.substring(colonIdx + 1);
            final dashIdx = verseStr.indexOf('-');
            final startVerseStr = dashIdx == -1
                ? verseStr
                : verseStr.substring(0, dashIdx);
            final verseNum = int.tryParse(startVerseStr);

            if (verseNum != null) {
              ref.read(targetVerseToScrollProvider.notifier).set(verseNum);
              ref.read(selectedVersesProvider.notifier).clear();
              ref.read(selectedVersesProvider.notifier).toggle(verseNum);
            }

            ref.read(navigationControllerProvider).recordHistory(verse: verseNum);

            ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withAlpha(40),
                Theme.of(context).colorScheme.primary.withAlpha(5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verse of the Day',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '"${verse.text}"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                verse.reference,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncButton extends ConsumerStatefulWidget {
  const _SyncButton();

  @override
  ConsumerState<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<_SyncButton> {
  bool _isSyncing = false;

  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
    });
    try {
      await ref.read(syncServiceProvider).sync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully')),
        );
      }
    } catch (e, stack) {
      logError(e, stack, context: 'DashboardScreen.sync');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSyncing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.sync),
      tooltip: 'Sync Now',
      onPressed: _performSync,
    );
  }
}
