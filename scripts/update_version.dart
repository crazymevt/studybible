import 'dart:io';
import 'dart:convert';

void main() async {
  // Read commits from stdin
  String commitsStr = '';
  String? line;
  while ((line = stdin.readLineSync(encoding: utf8)) != null) {
    commitsStr += line! + '\n';
  }
  
  final List<String> commits = commitsStr
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && !s.toLowerCase().startsWith('chore')) // filter out chore commits like releases
      .toList();

  final now = DateTime.now();
  final year = now.year % 100;
  final month = now.month;
  final day = now.day;
  final baseVersion = '$year.$month.$day';

  // Read current version from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print("Error: pubspec.yaml not found");
    exit(1);
  }
  
  String pubspecContent = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(r'^version:\s*([0-9\.]+)\+([0-9]+)', multiLine: true);
  final match = versionRegex.firstMatch(pubspecContent);
  
  int buildNumber = 1;
  if (match != null) {
    final currentBase = match.group(1);
    final currentBuild = match.group(2);
    if (currentBase == baseVersion && currentBuild != null) {
      buildNumber = int.parse(currentBuild) + 1;
    }
  }
  
  final newVersion = '$baseVersion+$buildNumber';
  
  // Update pubspec.yaml
  pubspecContent = pubspecContent.replaceAll(versionRegex, 'version: $newVersion');
  pubspecFile.writeAsStringSync(pubspecContent);
  
  // Update lib/app/version.dart
  final versionDartFile = File('lib/app/version.dart');
  if (versionDartFile.existsSync()) {
    versionDartFile.writeAsStringSync('''// This file is the global version tracker.
// It can be easily parsed or updated by build scripts.

const String appVersion = '$baseVersion';
const int buildNumber = $buildNumber;
''');
  }
  
  // Update assets/changelog.json
  final changelogFile = File('assets/changelog.json');
  List<dynamic> changelog = [];
  if (changelogFile.existsSync()) {
    final content = changelogFile.readAsStringSync();
    if (content.isNotEmpty) {
      changelog = json.decode(content);
    }
  }
  
  final features = commits.map((c) {
    String category = 'Updates';
    String icon = 'update';
    String title = c;
    
    final lowerC = c.toLowerCase();
    if (lowerC.startsWith('feat:') || lowerC.startsWith('feat ')) {
      category = 'New Features';
      icon = 'star';
      title = c.substring(c.indexOf(':') + 1).trim();
    } else if (lowerC.startsWith('fix:') || lowerC.startsWith('fix ')) {
      category = 'Bugfixes';
      icon = 'bug_report';
      title = c.substring(c.indexOf(':') + 1).trim();
    } else if (lowerC.startsWith('update:') || lowerC.startsWith('refactor:')) {
      category = 'Updates';
      icon = 'update';
      title = c.substring(c.indexOf(':') + 1).trim();
    }
    
    // Fallback if no colon was used but the word exists
    if (title == c) {
      if (lowerC.startsWith('add ') || lowerC.startsWith('implement ')) {
        category = 'New Features';
        icon = 'star';
      } else if (lowerC.startsWith('fix ') || lowerC.startsWith('resolve ')) {
        category = 'Bugfixes';
        icon = 'bug_report';
      }
    }

    return {
      "category": category,
      "title": title,
      "description": "",
      "icon": icon
    };
  }).toList();
  
  final newRelease = {
    "version": newVersion,
    "date": "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
    "features": features.isEmpty ? [{"title": "Minor bug fixes and improvements.", "description": "", "icon": "new_releases"}] : features
  };
  
  changelog.insert(0, newRelease);
  changelogFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(changelog));
  
  // Output new version so bash script can use it
  print(newVersion);
}
