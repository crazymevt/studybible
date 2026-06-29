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
import '../data/importer/sword/sword_commentary_importer.dart';
import '../data/importer/sword/sword_config.dart';
import '../data/importer/sword/sword_dictionary_importer.dart';
import '../data/logging.dart';
import 'app_state.dart'; // To get subheadingsSourceProvider
import 'content_providers.dart'; // To get contentStoreProvider

final contentManagerApiProvider = Provider((ref) => ContentManagerApi());

final ph4CatalogProvider = FutureProvider<List<Ph4Module>>((ref) async {
  return ref.read(contentManagerApiProvider).fetchPh4Modules();
});

final crosswireCatalogProvider = FutureProvider<List<CrosswireModule>>((ref) async {
  return ref.read(contentManagerApiProvider).fetchCrosswireModules();
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

/// A curated starter set of free MyBible resources from ph4.org, installed by
/// the onboarding "recommended downloads" action. Listed in install order
/// (the Bible first so commentaries/dictionaries have a translation to anchor
/// to). Resolved against the live ph4.org catalog at download time by [abbr];
/// any entry no longer in the catalog is skipped rather than failing the run.
const recommendedPh4Modules = <({String abbr, String label})>[
  (abbr: 'AV', label: 'King James Version (with cross references)'),
  // ph4 spells the Berean abbr with a curly apostrophe (U+2019); match it
  // exactly so the catalog lookup resolves.
  (abbr: 'BSB\u{2019}22', label: 'Berean Standard Bible (2022)'),
  (abbr: 'ESVGSB', label: 'ESV Global Study Bible'),
  (abbr: 'MHWBC.commentaries', label: "Matthew Henry's Whole Bible Commentary"),
  (abbr: 'Pool-c.commentaries', label: "Matthew Poole's Commentary"),
  (abbr: 'KJV-s.subheadings', label: 'King James subheadings'),
  (abbr: 'KJVD.dictionary', label: 'King James Dictionary'),
  (abbr: 'VineOT.dictionary', label: "Vine's Expository Dictionary (Old Testament)"),
  (abbr: 'VineNT.dictionary', label: "Vine's Expository Dictionary (New Testament)"),
  (abbr: 'Noah.dictionary', label: "Noah Webster's 1828 Dictionary"),
  (abbr: 'Webster.dictionary', label: "Webster's Unabridged Dictionary"),
];

/// State-map key under which [ContentManagerController.downloadRecommended]
/// publishes its aggregate progress.
const recommendedDownloadKey = 'recommended';

class ContentManagerController extends Notifier<Map<String, DownloadProgress>> {
  @override
  Map<String, DownloadProgress> build() => {};

  /// Download and import a single ph4.org MyBible [module]. When [onProgress]
  /// is supplied (e.g. by [downloadRecommended]) it receives the download
  /// fraction (0–1) so a caller can fold it into an aggregate bar; the module's
  /// own progress is published under its abbr regardless.
  Future<void> downloadAndImportPh4(
    Ph4Module module, {
    void Function(double downloadFraction)? onProgress,
  }) async {
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
            onProgress?.call(received / total);
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
      ref.read(versionsProvider.notifier).reload();
      ref.read(bibleVersionsProvider.notifier).reload();
      ref.read(subheadingSourcesProvider.notifier).reload();
      ref.read(commentariesProvider.notifier).reload();
      ref.read(dictionariesProvider.notifier).reload();
      ref.read(devotionalsProvider.notifier).reload();
      ref.read(installedModuleIdsProvider.notifier).reload();
    } catch (e, stack) {
      logError(e, stack, context: 'ContentManager.downloadAndImport');
      state = {...state, stateKey: DownloadProgress(0, 'Error: $e')};
    }
  }

  /// Download and import the curated [recommendedPh4Modules] set, one after
  /// another. Aggregate progress (overall fraction + the current item) is
  /// published under [recommendedDownloadKey]; each module's own progress is
  /// still mirrored under its abbr by [downloadAndImportPh4]. Individual
  /// failures are collected and reported at the end rather than aborting the
  /// run, so one unavailable module doesn't block the rest.
  Future<void> downloadRecommended() async {
    const aggKey = recommendedDownloadKey;
    state = {...state, aggKey: DownloadProgress(0, 'Preparing…')};

    final List<Ph4Module> catalog;
    try {
      // Fetch fresh so a retry after a transient network failure isn't served
      // the provider's cached error.
      ref.invalidate(ph4CatalogProvider);
      catalog = await ref.read(ph4CatalogProvider.future);
    } catch (e, stack) {
      logError(e, stack, context: 'ContentManager.downloadRecommended');
      state = {
        ...state,
        aggKey: DownloadProgress(0, 'Error: could not reach ph4.org'),
      };
      return;
    }

    final byAbbr = {for (final m in catalog) m.abbr: m};
    final targets = <Ph4Module>[];
    for (final rec in recommendedPh4Modules) {
      final module = byAbbr[rec.abbr];
      if (module != null) {
        targets.add(module);
      } else {
        logError(
          'Recommended module "${rec.abbr}" not found in the ph4 catalog',
          StackTrace.current,
          context: 'ContentManager.downloadRecommended',
        );
      }
    }

    final total = targets.length;
    if (total == 0) {
      state = {
        ...state,
        aggKey: DownloadProgress(0, 'Error: no recommended modules available'),
      };
      return;
    }

    final failed = <String>[];
    for (var i = 0; i < total; i++) {
      final module = targets[i];
      void setAgg(double moduleFraction) {
        state = {
          ...state,
          aggKey: DownloadProgress(
            (i + moduleFraction) / total,
            '(${i + 1} of $total) ${module.title}…',
          ),
        };
      }

      setAgg(0);
      await downloadAndImportPh4(module, onProgress: setAgg);
      final result = state[module.abbr];
      if (result == null || result.status.startsWith('Error')) {
        failed.add(module.title);
      }
    }

    // Default the reader's subheadings source to the King James subheadings,
    // if that module installed successfully. The MyBible importer keys a
    // subheadings version by its uppercased abbr, so resolve against the
    // freshly-reloaded source list to confirm it's actually present.
    const kjvSubheadingsAbbr = 'KJV-s.subheadings';
    final kjvSubheadingsId = kjvSubheadingsAbbr.toUpperCase();
    try {
      final sources = await ref.read(subheadingSourcesProvider.future);
      if (sources.any((v) => v.id == kjvSubheadingsId)) {
        ref.read(subheadingsSourceProvider.notifier).setSource(kjvSubheadingsId);
      }
    } catch (e, stack) {
      logError(e, stack,
          context: 'ContentManager.downloadRecommended:setSubheadings');
    }

    state = {
      ...state,
      aggKey: failed.isEmpty
          ? DownloadProgress(1.0, 'Done')
          : DownloadProgress(
              1.0, 'Finished — ${failed.length} of $total could not be installed'),
    };
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
      ref.read(versionsProvider.notifier).reload();
      ref.read(bibleVersionsProvider.notifier).reload();
      ref.read(subheadingSourcesProvider.notifier).reload();
      ref.read(commentariesProvider.notifier).reload();
      ref.read(dictionariesProvider.notifier).reload();
      ref.read(devotionalsProvider.notifier).reload();
      ref.read(installedModuleIdsProvider.notifier).reload();
    } catch (e, stack) {
      logError(e, stack, context: 'ContentManager.downloadAndImportOsis');
      state = {...state, stateKey: DownloadProgress(0, 'Error: $e')};
    }
  }

  Future<void> downloadAndImportCrosswire(CrosswireModule module) async {
    final stateKey = 'cw_${module.config.name}';
    state = {...state, stateKey: DownloadProgress(0, 'Downloading...')};

    try {
      final api = ref.read(contentManagerApiProvider);
      final tempDir = await getTemporaryDirectory();
      await tempDir.create(recursive: true);

      final dlFile = File(p.join(tempDir.path, '${module.config.name}.zip'));

      // Construct the URL. Usually packages/rawzip/<NAME>.zip
      // If repoPath ends with /raw, we typically replace it with /packages/rawzip for CrossWire.
      String zipPath = module.repoPath.endsWith('/raw')
          ? module.repoPath.replaceAll(RegExp(r'/raw$'), '/packages/rawzip')
          : '${module.repoPath}/packages/rawzip';
      
      String dlUrl = 'https://${module.repoDomain}$zipPath/${module.config.name}.zip';

      try {
        await api.downloadFile(
          dlUrl,
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
      } catch (e) {
        // Fallback: try without the /packages/rawzip replacement if it failed
        if (module.repoPath.endsWith('/raw')) {
          dlUrl = 'https://${module.repoDomain}${module.repoPath}/packages/rawzip/${module.config.name}.zip';
          await api.downloadFile(
            dlUrl,
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
        } else {
          rethrow;
        }
      }

      state = {...state, stateKey: DownloadProgress(1.0, 'Importing...')};

      // Reuse the existing local zip importer
      await importSwordModuleFile(dlFile);
      
      // Cleanup
      await dlFile.delete();

      state = {...state, stateKey: DownloadProgress(1.0, 'Done')};
    } catch (e, stack) {
      logError(e, stack, context: 'ContentManager.downloadAndImportCrosswire');
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
      } else if (config.modDrv.isCommentary) {
        await SwordCommentaryImporter(store)
            .importFromDirectory(extractDir, config);
      } else if (config.modDrv.isDictionary) {
        await SwordDictionaryImporter(store)
            .importFromDirectory(extractDir, config);
      } else {
        throw Exception(
          'SWORD module "${config.name}" is a '
          '${config.value('ModDrv') ?? 'non-Bible'} module; only Bible texts, '
          'commentaries, and dictionaries are supported so far.',
        );
      }

      state = {...state, stateKey: DownloadProgress(1.0, 'Done')};

      ref.read(versionsProvider.notifier).reload();
      ref.read(bibleVersionsProvider.notifier).reload();
      ref.read(commentariesProvider.notifier).reload();
      ref.read(dictionariesProvider.notifier).reload();
      ref.read(installedModuleIdsProvider.notifier).reload();

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
