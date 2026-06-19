import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../data/content_manager_api.dart';
import '../domain/importer/archive_extractor.dart';
import '../domain/importer/mybible_importer.dart';
import '../domain/importer/osis_importer.dart';
import 'content_providers.dart'; // To get contentStoreProvider

final contentManagerApiProvider = Provider((ref) => ContentManagerApi());

final ph4CatalogProvider = FutureProvider<List<Ph4Module>>((ref) async {
  return ref.read(contentManagerApiProvider).fetchPh4Modules();
});

final osisLanguagesProvider = FutureProvider<List<OsisLanguage>>((ref) async {
  return ref.read(contentManagerApiProvider).fetchOsisLanguages();
});

final osisTranslationsProvider = FutureProvider.family<List<OsisTranslation>, String>((ref, langCode) async {
  return ref.read(contentManagerApiProvider).fetchOsisTranslations(langCode);
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
      
      final filename = module.url.split('=').last;
      final dlFile = File(p.join(tempDir.path, '$filename.zip.bz2'));

      await api.downloadFile(module.url, dlFile.path, onReceiveProgress: (received, total) {
        if (total != -1) {
          state = {...state, stateKey: DownloadProgress(received / total, 'Downloading...')};
        }
      });

      state = {...state, stateKey: DownloadProgress(1.0, 'Extracting...')};
      
      final extractDir = Directory(p.join(tempDir.path, 'extract_${module.abbr}'));
      final extractedFiles = await ArchiveExtractor.extractArchive(dlFile, extractDir);

      state = {...state, stateKey: DownloadProgress(1.0, 'Importing...')};

      final sqliteFiles = extractedFiles.where(
        (f) => f.path.toLowerCase().endsWith('.sqlite3') || f.path.toLowerCase().endsWith('.sqlite')
      ).toList();
      
      if (sqliteFiles.isEmpty) {
        final fileNames = extractedFiles.map((f) => p.basename(f.path)).join(', ');
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

    } catch (e) {
      state = {...state, stateKey: DownloadProgress(0, 'Error: $e')};
    }
  }

  Future<void> downloadAndImportOsis(OsisTranslation translation, String langCode) async {
    final stateKey = 'osis_${translation.basename}';
    state = {...state, stateKey: DownloadProgress(0, 'Downloading...')};

    try {
      final api = ref.read(contentManagerApiProvider);
      final tempDir = await getTemporaryDirectory();

      final dlFile = File(p.join(tempDir.path, translation.name));

      await api.downloadFile(translation.downloadUrl, dlFile.path, onReceiveProgress: (received, total) {
        if (total != -1) {
          state = {...state, stateKey: DownloadProgress(received / total, 'Downloading...')};
        }
      });

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

    } catch (e) {
      state = {...state, stateKey: DownloadProgress(0, 'Error: $e')};
    }
  }
}

final contentManagerControllerProvider = NotifierProvider<ContentManagerController, Map<String, DownloadProgress>>(() {
  return ContentManagerController();
});
