import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/logging.dart';
import 'version.dart';

part 'update_checker.g.dart';

class UpdateCheckResult {
  final String latestVersion;
  final String releaseUrl;

  UpdateCheckResult({required this.latestVersion, required this.releaseUrl});
}

/// The update version the user has dismissed for this session. The banner stays
/// hidden while this matches the available update; a newer version re-shows it.
class DismissedUpdateVersionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void dismiss(String version) => state = version;
}

final dismissedUpdateVersionProvider =
    NotifierProvider<DismissedUpdateVersionNotifier, String?>(
  DismissedUpdateVersionNotifier.new,
);

@riverpod
Future<UpdateCheckResult?> updateChecker(Ref ref) async {
  // Cache the result for the session so we don't re-hit the GitHub API on
  // every dashboard visit (unauthenticated requests are rate-limited).
  ref.keepAlive();

  // Only check on desktop platforms. Mobile apps should use their respective app stores.
  if (kIsWeb || !(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    return null;
  }

  try {
    final dio = Dio();
    final response = await dio.get(
      'https://api.github.com/repos/crazymevt/StudyBible/releases/latest',
      options: Options(
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
        // A short timeout so we don't delay anything if the network is bad
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final String tagName = response.data['tag_name'] as String;
      final String htmlUrl = response.data['html_url'] as String;

      // Extract the numeric version (e.g. from "v1.2.3+4" -> "1.2.3")
      // Remove everything after '+' if it exists to ignore build numbers for the update check
      final String latestClean = tagName.split('+').first.replaceAll(RegExp(r'[^0-9.]'), '');
      final String currentClean = appVersion.split('+').first.replaceAll(RegExp(r'[^0-9.]'), '');

      final latestParts = latestClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) {
          return UpdateCheckResult(latestVersion: latestClean, releaseUrl: htmlUrl);
        } else if (l < c) {
          return null;
        }
      }
    }
  } catch (e, stack) {
    logError(e, stack, context: 'updateChecker');
  }
  return null;
}
