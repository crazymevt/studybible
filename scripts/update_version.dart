import 'dart:io';
import 'dart:convert';

void main() async {
  // Read commits from stdin
  final commitsStr = stdin.readAsStringSync();
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
  
  final features = commits.map((c) => {
    "title": c,
    "description": "",
    "icon": "new_releases"
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
