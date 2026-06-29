// ignore_for_file: avoid_print
//
// Renders GitHub Release notes from assets/changelog.json.
//
// This reuses the exact same data that drives the in-app "What's New" screen,
// so the published release notes can never drift from what users see in the
// app. By default it renders the most recent (top) entry; pass a version
// string to render a specific release instead:
//
//   dart scripts/release_notes.dart            # latest entry
//   dart scripts/release_notes.dart 26.6.29+1  # a specific version
//
// Markdown is written to stdout (grouped by category), ready to be handed to
// the GitHub release as a body file.
import 'dart:io';
import 'dart:convert';

// Categories are emitted in this order; any category not listed here is
// appended afterwards in first-seen order so nothing is silently dropped.
const categoryOrder = ['New Features', 'Updates', 'Bugfixes'];

void main(List<String> args) {
  final file = File('assets/changelog.json');
  if (!file.existsSync()) {
    stderr.writeln('Error: assets/changelog.json not found');
    exit(1);
  }

  final content = file.readAsStringSync();
  if (content.trim().isEmpty) {
    stderr.writeln('Error: assets/changelog.json is empty');
    exit(1);
  }

  final List<dynamic> changelog = json.decode(content) as List<dynamic>;
  if (changelog.isEmpty) {
    stderr.writeln('Error: changelog has no entries');
    exit(1);
  }

  // Pick the requested version, or fall back to the most recent entry.
  final wanted = args.isNotEmpty ? args.first : null;
  final Map<String, dynamic> entry = (wanted == null
      ? changelog.first
      : changelog.firstWhere(
          (e) => (e as Map)['version'] == wanted,
          orElse: () {
            stderr.writeln('Error: version "$wanted" not found in changelog');
            exit(1);
          },
        )) as Map<String, dynamic>;

  final features = (entry['features'] as List<dynamic>? ?? []);

  // Bucket feature titles by category, preserving order of appearance.
  final byCategory = <String, List<String>>{};
  for (final f in features) {
    final m = f as Map<String, dynamic>;
    final category = (m['category'] as String?)?.trim();
    final title = (m['title'] as String?)?.trim();
    if (title == null || title.isEmpty) continue;
    byCategory.putIfAbsent(category == null || category.isEmpty ? 'Updates' : category, () => []).add(title);
  }

  final buffer = StringBuffer();

  if (byCategory.isEmpty) {
    buffer.writeln('Minor bug fixes and improvements.');
  } else {
    final ordered = [
      ...categoryOrder.where(byCategory.containsKey),
      ...byCategory.keys.where((c) => !categoryOrder.contains(c)),
    ];
    for (final category in ordered) {
      buffer.writeln('## $category');
      buffer.writeln();
      for (final title in byCategory[category]!) {
        buffer.writeln('- $title');
      }
      buffer.writeln();
    }
  }

  stdout.write(buffer.toString().trimRight());
  stdout.writeln();
}
