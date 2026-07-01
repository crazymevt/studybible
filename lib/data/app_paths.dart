import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Files that live in the app data directory and should be carried over from
/// the legacy location on first run (desktop platforms).
const _migratableFiles = ['content.db', 'user.db', 'device_id.txt'];

Future<void>? _migration;

/// Directory for app-internal data: the content and user databases, the device
/// id, and the default sync folder.
///
/// **Desktop platforms** (Linux, Windows, macOS) use
/// [getApplicationSupportDirectory] so app-internal databases stay out of the
/// user's Documents root, where they were previously dumped alongside personal
/// files:
///   * Linux — `XDG_DATA_HOME`, persistent and working inside the Flatpak
///     sandbox (Documents relies on the optional `xdg-user-dir` tool and is not
///     a stable, persistent location under Flatpak, so a downloaded bible
///     vanished on restart).
///   * Windows — `%APPDATA%\<org>\<app>`.
///   * macOS — `~/Library/Application Support/<bundle id>`.
///
/// Existing desktop installs are migrated from the old Documents location on
/// first run.
///
/// **Mobile** (Android, iOS) keeps [getApplicationDocumentsDirectory] — it is
/// already app-private and sandboxed there, and is where existing installs
/// store their data, so no migration is needed and nothing moves.
///
/// **Debug builds** (i.e. `flutter run`) on desktop are redirected to a sibling
/// `<app-data>-dev` directory so development sessions never read or write the
/// real installed app's databases, notes, or sync state. The dev directory
/// starts empty and legacy migration is skipped for it; to seed it with real
/// content, copy the release directory's contents across manually.
Future<Directory> appDataDir() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return getApplicationDocumentsDirectory();
  }
  final dir = await getApplicationSupportDirectory();
  if (kDebugMode) {
    final devDir = Directory('${dir.path}-dev');
    if (!await devDir.exists()) {
      await devDir.create(recursive: true);
    }
    // Deliberately no _migrateLegacyData: the dev tree stays isolated from the
    // installed app's data.
    return devDir;
  }
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  await _migrateLegacyData(dir);
  return dir;
}

// Cache the migration as a single Future so concurrent callers (the content
// store and user store both open at startup) await the *same* completion rather
// than the second caller seeing a "done" flag and racing ahead before the
// files have actually been copied.
Future<void> _migrateLegacyData(Directory target) =>
    _migration ??= _doMigrateLegacyData(target);

Future<void> _doMigrateLegacyData(Directory target) async {
  // Windows relocation must run first: it repopulates the new app-data dir from
  // the old com.example path, after which the Documents fallback below is a
  // no-op for those users.
  await _migrateWindowsAppDataRelocation(target);
  try {
    final legacy = await getApplicationDocumentsDirectory();
    if (legacy.path == target.path) return;
    for (final name in _migratableFiles) {
      // Copy the db plus its WAL/SHM sidecars so the migrated copy is consistent.
      for (final suffix in ['', '-wal', '-shm']) {
        final src = File(p.join(legacy.path, '$name$suffix'));
        final dst = File(p.join(target.path, '$name$suffix'));
        if (await src.exists() && !await dst.exists()) {
          await src.copy(dst.path);
        }
      }
    }
  } catch (_) {
    // getApplicationDocumentsDirectory can be unavailable (e.g. in the Flatpak
    // sandbox). A fresh install there has nothing to migrate.
  }
}

/// `path_provider_windows` derives the app-data directory as
/// `%APPDATA%\<CompanyName>\<ProductName>`, reading both fields from the EXE's
/// VERSIONINFO resource. Those used to be the Flutter scaffold defaults
/// (`com.example` / `study_bible`), so existing data lives in
/// `%APPDATA%\com.example\study_bible`. Correcting them to `StudyBible Team` /
/// `Study Bible` moves the directory, which would otherwise strand every
/// Windows user's notes, modules, and sync state. Copy the old tree across on
/// first run.
///
/// Copy (not move) and skip files that already exist, so a fresh install that
/// happens to share a machine with an old one isn't clobbered, and the old data
/// remains as an untouched backup.
Future<void> _migrateWindowsAppDataRelocation(Directory target) async {
  if (!Platform.isWindows) return;
  final appData = Platform.environment['APPDATA'];
  if (appData == null) return;
  final legacy = Directory(p.join(appData, 'com.example', 'study_bible'));
  try {
    if (!await legacy.exists() || legacy.path == target.path) return;
    await for (final entity
        in legacy.list(recursive: true, followLinks: false)) {
      final rel = p.relative(entity.path, from: legacy.path);
      final destPath = p.join(target.path, rel);
      if (entity is Directory) {
        await Directory(destPath).create(recursive: true);
      } else if (entity is File) {
        final dst = File(destPath);
        if (!await dst.exists()) {
          await dst.parent.create(recursive: true);
          await entity.copy(dst.path);
        }
      }
    }
  } catch (_) {
    // Best-effort: a partial copy beats none, and a failure here must never
    // block app startup.
  }
}
