import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/version.dart';

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  Future<List<Map<String, dynamic>>> _loadChangelog() async {
    final String response = await rootBundle.loadString('assets/changelog.json');
    final List<dynamic> data = json.decode(response);
    return data.cast<Map<String, dynamic>>();
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
      future: _loadChangelog(),
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
              children: sortedCategories.expand((category) {
                final catFeatures = groupedFeatures[category]!;
                return [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  }).toList(),
                ];
              }).toList(),
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
