import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../data/content_manager_api.dart';
import '../data/importer/archive_extractor.dart';
import '../data/importer/mybible_importer.dart';
import '../data/importer/osis_importer.dart';
import '../data/importer/sword/sword_bible_importer.dart';
import '../data/importer/sword/sword_config.dart';
import '../data/logging.dart';
import 'content_providers.dart'; // To get contentStoreProvider

final contentManagerApiProvider = Provider((ref) => ContentManagerApi());

final ph4CatalogProvider = FutureProvider<List<Ph4Module>>((ref) async {
  return ref.read(contentManagerApiProvider).fetchPh4Modules();
});

final osisLanguagesProvider = FutureProvider<List<OsisLanguage>>((ref) async {
  return ref.read(contentManagerApiProvider).fetchOsisLanguages();
});

final osisTranslationsProvider =
    FutureProvider.family<List<OsisTranslation>, String>((ref, langCode) async {
      return ref
          .read(contentManagerApiProvider)
          .fetchOsisTranslations(langCode);
    });

class DownloadProgress {
  final double percent;
  final String status;
  DownloadProgress(this.percent, this.status);
}

class ContentManagerController extends Notifier<Map<String, DownloadProgress>> {
  @override
  Map<String, DownloadProgress> build() => {};

  Future<void> downloadAndImportPh4(Ph4Module module) async {
    final stateKey = module.abbr;
    state = {...state, stateKey: DownloadProgress(0, 'Downloading...')};

    try {
      final api = ref.read(contentManagerApiProvider);
      final tempDir = await getTemporaryDirectory();
      await tempDir.create(recursive: true);

      final safeAbbr = module.abbr.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final dlFile = File(p.join(tempDir.path, '$safeAbbr.zip.bz2'));

      await api.downloadFile(
        module.url,
        dlFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            state = {
              ...state,
              stateKey: DownloadProgress(received / total, 'Downloading...'),
            };
          }
        },
      );

      state = {...state, stateKey: DownloadProgress(1.0, 'Extracting...')};

      final extractDir = Directory(p.join(tempDir.path, 'extract_$safeAbbr'));
      final extractedFiles = await ArchiveExtractor.extractArchive(
        dlFile,
        extractDir,
      );

      state = {...state, stateKey: DownloadProgress(1.0, 'Importing...')};

      final sqliteFiles = extractedFiles
          .where(
            (f) =>
                f.path.toLowerCase().endsWith('.sqlite3') ||
                f.path.toLowerCase().endsWith('.sqlite'),
          )
          .toList();

      if (sqliteFiles.isEmpty) {
        final fileNames = extractedFiles
            .map((f) => p.basename(f.path))
            .join(', ');
        throw Exception('No SQLite file found in archive. Saw: $fileNames');
      }

      final store = ref.read(contentStoreProvider);
      final importer = MyBibleImporter(store);

      for (final sqliteFile in sqliteFiles) {
        final fname = p.basename(sqliteFile.path).toLowerCase();
        ModuleType inferredType = module.type;
        if (fname.contains('.commentaries.')) {
          inferredType = ModuleType.commentary;
        } else if (fname.contains('.dictionary.')) {
          inferredType = ModuleType.dictionary;
        } else if (fname.contains('.subheadings.')) {
          inferredType = ModuleType.subheadings;
        } else if (fname.contains('.devotions.')) {
          inferredType = ModuleType.devotional;
        }

        await importer.importModuleFile(sqliteFile, module, inferredType);
      }

      // Cleanup
      await extractDir.delete(recursive: true);
      await dlFile.delete();

      state = {...state, stateKey: DownloadProgress(1.0, 'Done')};

      // Refresh installed versions
      ref.invalidate(versionsProvider);
      ref.invalidate(bibleVersionsProvider);
      ref.invalidate(subheadingSourcesProvider);
      ref.invalidate(commentariesProvider);
      ref.invalidate(dictionariesProvider);
      ref.invalidate(devotionalsProvider);
      ref.invalidate(installedModuleIdsProvider);
    } catch (e, stack) {
      logError(e, stack, context: 'ContentManager.downloadAndImport');
      state = {...state, stateKey: DownloadProgress(0, 'Error: $e')};
    }
  }

  Future<void> downloadAndImportOsis(
    OsisTranslation translation,
    String langCode,
  ) async {
    final stateKey = 'osis_${translation.basename}';
    state = {...state, stateKey: DownloadProgress(0, 'Downloading...')};

    try {
      final api = ref.read(contentManagerApiProvider);
      final tempDir = await getTemporaryDirectory();
      await tempDir.create(recursive: true);

      final dlFile = File(p.join(tempDir.path, translation.name));

      await api.downloadFile(
        translation.downloadUrl,
        dlFile.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            state = {
              ...state,
              stateKey: DownloadProgress(received / total, 'Downloading...'),
            };
          }
        },
      );

      state = {...state, stateKey: DownloadProgress(1.0, 'Importing...')};

      final store = ref.read(contentStoreProvider);
      final importer = OsisImporter(store);

      await importer.importOsisFile(
        dlFile,
        translation.basename.toUpperCase(),
        translation.title,
        langCode,
      );

      // Cleanup
      await dlFile.delete();

      state = {...state, stateKey: DownloadProgress(1.0, 'Done')};

      // Refresh installed versions
      ref.invalidate(versionsProvider);
      ref.invalidate(bibleVersionsProvider);
      ref.invalidate(subheadingSourcesProvider);
      ref.invalidate(commentariesProvider);
      ref.invalidate(dictionariesProvider);
      ref.invalidate(devotionalsProvider);
      ref.invalidate(installedModuleIdsProvider);
    } catch (e, stack) {
      logError(e, stack, context: 'ContentManager.downloadAndImportOsis');
      state = {...state, stateKey: DownloadProgress(0, 'Error: $e')};
    }
  }

  /// Import a SWORD module from a local archive ([archiveFile], typically a
  /// CrossWire `.zip` containing `mods.d/<name>.conf` plus the `modules/…`
  /// data files). Unlike the catalog downloads above this rethrows on failure
  /// so the caller can surface it directly; it also returns a short success
  /// description. Progress is mirrored into [state] under `sword_import`.
  Future<String> importSwordModuleFile(File archiveFile) async {
    const stateKey = 'sword_import';
    state = {...state, stateKey: DownloadProgress(0, 'Extracting...')};

    Directory? extractDir;
    try {
      final tempDir = await getTemporaryDirectory();
      extractDir = Directory(
        p.join(
          tempDir.path,
          'sword_import_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      final extractedFiles =
          await ArchiveExtractor.extractArchive(archiveFile, extractDir);

      // Locate the module's .conf, preferring one under mods.d/.
      final confFiles = extractedFiles
          .where((f) => f.path.toLowerCase().endsWith('.conf'))
          .toList()
        ..sort((a, b) {
          bool inModsD(File f) => f.path.toLowerCase().contains('mods.d');
          return (inModsD(b) ? 1 : 0).compareTo(inModsD(a) ? 1 : 0);
        });
      if (confFiles.isEmpty) {
        throw Exception(
          'No .conf file found — this does not look like a SWORD module.',
        );
      }
      // Conf files are usually ASCII/UTF-8; decode leniently to be safe.
      final config = SwordConfig.parse(
        utf8.decode(await confFiles.first.readAsBytes(), allowMalformed: true),
      );

      state = {...state, stateKey: DownloadProgress(1.0, 'Importing...')};
      final store = ref.read(contentStoreProvider);

      if (config.modDrv.isBible) {
        await SwordBibleImporter(store).importFromDirectory(extractDir, config);
      } else {
        throw Exception(
          'SWORD module "${config.name}" is a '
          '${config.value('ModDrv') ?? 'non-Bible'} module; only Bible texts '
          'are supported so far.',
        );
      }

      state = {...state, stateKey: DownloadProgress(1.0, 'Done')};

      ref.invalidate(versionsProvider);
      ref.invalidate(bibleVersionsProvider);
      ref.invalidate(installedModuleIdsProvider);

      return 'Imported ${config.description ?? config.name} '
          '(${config.name.toUpperCase()})';
    } catch (e, stack) {
      logError(e, stack, context: 'ContentManager.importSwordModuleFile');
      state = {...state, stateKey: DownloadProgress(0, 'Error: $e')};
      rethrow;
    } finally {
      if (extractDir != null && await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }
}

final contentManagerControllerProvider =
    NotifierProvider<ContentManagerController, Map<String, DownloadProgress>>(
      () {
        return ContentManagerController();
      },
    );
