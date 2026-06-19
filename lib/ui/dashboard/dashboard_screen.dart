import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/dashboard_providers.dart';
import '../app_drawer.dart';
import 'reading_progress_dialog.dart';
import 'time_analytics_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pace = ref.watch(readingPaceProvider);
    final timeData = ref.watch(timeAnalyticsProvider);
    final coverage = ref.watch(bibleCoverageProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    
    int chaptersRead = 0;
    for (final chapters in coverage.values) {
      chaptersRead += chapters.length;
    }
    final double percent = (chaptersRead / 1189) * 100;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Generate Dummy Data',
            onPressed: () {
              ref.read(dashboardActionProvider).generateDummyTimeData();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.start,
          children: [
            _buildReadingProgressCard(context, percent, chaptersRead, coverage),
            _buildTimeAnalyticsCard(context, timeData, ref),
            _buildPaceCard(context, 'Day Streak', pace['currentStreak'].toString(), Icons.local_fire_department, Colors.orange),
            _buildPaceCard(context, 'Longest Streak', pace['longestStreak'].toString(), Icons.emoji_events, Colors.yellow),
            _buildPaceCard(context, 'Days Active', pace['daysActive'].toString(), Icons.calendar_today, Colors.blue),
            _buildPaceCard(context, 'Chapters This Week', pace['chaptersThisWeek'].toString(), Icons.menu_book, Colors.green),
            _buildAchievementsCard(context, achievementsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingProgressCard(BuildContext context, double percent, int totalChapters, Map<String, List<int>> coverage) {
    return Card(
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => ReadingProgressDialog(coverage: coverage),
          );
        },
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bible Progress', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  Text('${percent.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: 24),
              Text('$totalChapters / 1189 Chapters Read'),
              const SizedBox(height: 8),
              const Text('Tap to view details', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAnalyticsCard(BuildContext context, Map<String, int> timeData, WidgetRef ref) {
    final thisWeekMins = (timeData['thisWeekMs'] ?? 0) ~/ 60000;
    final lastWeekMins = (timeData['lastWeekMs'] ?? 0) ~/ 60000;
    final yearAgoMins = (timeData['yearAgoMs'] ?? 0) ~/ 60000;

    return Card(
      child: InkWell(
        onTap: () {
          final trackers = ref.read(timeTrackerProvider).value ?? [];
          showDialog(
            context: context,
            builder: (_) => TimeAnalyticsDialog(trackers: trackers),
          );
        },
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time in the Word', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              _buildTimeRow('This Week', thisWeekMins, Colors.blue),
              const SizedBox(height: 12),
              _buildTimeRow('Last Week', lastWeekMins, Colors.grey),
              const SizedBox(height: 12),
              _buildTimeRow('A Year Ago', yearAgoMins, Colors.grey.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, int mins, Color color) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: LinearProgressIndicator(
            value: mins / 120, // Example scale: 2 hours is 100% width
            color: color,
            backgroundColor: color.withOpacity(0.2),
            minHeight: 12,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 40, child: Text('${mins}m', textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildPaceCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context, AsyncValue achievementsAsync) {
    return Card(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            achievementsAsync.when(
              data: (list) {
                if (list.isEmpty) return const Text('Keep reading to unlock badges!');
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: list.map<Widget>((a) {
                    return Chip(
                      avatar: const Icon(Icons.star, size: 16, color: Colors.yellow),
                      label: Text(a.id),
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
