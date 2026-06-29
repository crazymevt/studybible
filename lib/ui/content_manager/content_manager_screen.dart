import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_state.dart';
import '../../app/content_manager_providers.dart';
import '../../app/content_providers.dart';
import '../../app/search_providers.dart';
import '../../data/importer/sword/sword_versification.dart';
import '../app_drawer.dart';

class ContentManagerScreen extends ConsumerStatefulWidget {
  const ContentManagerScreen({super.key});

  @override
  ConsumerState<ContentManagerScreen> createState() =>
      _ContentManagerScreenState();
}

class _ContentManagerScreenState extends ConsumerState<ContentManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // A single filter shared by every tab. The prominent AppBar field drives it
  // live; the per-tab list filters against it. Global library search is a
  // separate, explicit action (see _searchEntireLibrary).
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';
  final Set<String> _expandedOsisLanguages = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Rebuild so the search field's hint reflects the active tab.
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Escalate the current filter text to a full-library search (Bible &
  /// commentary text), navigating to the reader's search tool. Mirrors
  /// GlobalSearchBar so behaviour is identical to the global search field.
  void _searchEntireLibrary() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    ref.read(globalSearchQueryProvider.notifier).setQuery(query);
    ref.read(activeToolProvider.notifier).openTool(ActiveTool.search);
    ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
  }

  /// Pick a local SWORD module archive (.zip) and import it. Desktop/iOS use
  /// the file_selector dialog; Android picks via SAF and streams the file to a
  /// temp copy first (file_selector has no Android backend here).
  Future<void> _importSwordModule() async {
    File? file;
    var isAndroidTemp = false;
    try {
      if (Platform.isAndroid) {
        final doc = await SafUtil().pickFile(
          mimeTypes: ['application/zip', 'application/octet-stream', '*/*'],
        );
        if (doc == null) return;
        final stream = await SafStream().readFileStream(doc.uri);
        final tempDir = await getTemporaryDirectory();
        final tmp = File(p.join(tempDir.path,
            'sword_pick_${DateTime.now().microsecondsSinceEpoch}.zip'));
        final sink = tmp.openWrite();
        await for (final chunk in stream) {
          sink.add(chunk);
        }
        await sink.close();
        file = tmp;
        isAndroidTemp = true;
      } else {
        // Do not use acceptedTypeGroups as it can cause PlatformExceptions on iOS
        // if the specific extension UTIs are not registered in Info.plist.
        final picked = await openFile();
        if (picked == null) return;
        file = File(picked.path);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Importing SWORD module…')),
      );
      try {
        final result = await ref
            .read(contentManagerControllerProvider.notifier)
            .importSwordModuleFile(file);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(result)));
      } catch (e) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (isAndroidTemp && file != null && await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }

  String get _filterHint {
    switch (_tabController.index) {
      case 1:
        return 'Filter ph4.org catalog…';
      case 2:
        return 'Filter OSIS languages…';
      case 3:
        return 'Filter CrossWire catalog…';
      default:
        return 'Filter installed content…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        centerTitle: true,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            height: 40,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _filterQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: _filterHint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                prefixIcon: Icon(
                  Icons.filter_list,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 36, minHeight: 0),
                // Explicit escape hatch: search Bible & commentary text across
                // the whole library, rather than filtering this list.
                suffixIcon: IconButton(
                  icon: const Icon(Icons.travel_explore, size: 20),
                  tooltip: 'Search entire library',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  onPressed: _searchEntireLibrary,
                ),
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 40, minHeight: 0),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open_outlined),
            tooltip: 'Import SWORD module (.zip)…',
            onPressed: _importSwordModule,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Installed'),
            Tab(text: 'ph4.org Catalog'),
            Tab(text: 'OSIS Catalog'),
            Tab(text: 'CrossWire Catalog'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInstalledTab(), _buildPh4Tab(), _buildOsisTab(), _buildCrosswireTab()],
      ),
    );
  }

  Widget _buildInstalledTab() {
    final versionsAsync = ref.watch(versionsProvider);
    final commentariesAsync = ref.watch(commentariesProvider);
    final dictionariesAsync = ref.watch(dictionariesProvider);
    final devotionalsAsync = ref.watch(devotionalsProvider);
    final bibleVersionsAsync = ref.watch(bibleVersionsProvider);
    final subheadingSourcesAsync = ref.watch(subheadingSourcesProvider);

    if (versionsAsync.isLoading || commentariesAsync.isLoading || dictionariesAsync.isLoading || devotionalsAsync.isLoading || bibleVersionsAsync.isLoading || subheadingSourcesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (versionsAsync.hasError) return Center(child: Text('Error: ${versionsAsync.error}'));
    if (commentariesAsync.hasError) return Center(child: Text('Error: ${commentariesAsync.error}'));
    if (dictionariesAsync.hasError) return Center(child: Text('Error: ${dictionariesAsync.error}'));
    if (devotionalsAsync.hasError) return Center(child: Text('Error: ${devotionalsAsync.error}'));

    final versions = versionsAsync.value ?? [];
    final allCommentaries = commentariesAsync.value ?? [];
    final allDictionaries = dictionariesAsync.value ?? [];
    final allDevotionals = devotionalsAsync.value ?? [];

    if (versions.isEmpty && allCommentaries.isEmpty && allDictionaries.isEmpty && allDevotionals.isEmpty) {
      return const Center(child: Text('No content installed.'));
    }

    final bibleVersionIds = (bibleVersionsAsync.value ?? []).map((v) => v.id).toSet();
    final subheadingSourceIds = (subheadingSourcesAsync.value ?? []).map((v) => v.id).toSet();

    final q = _filterQuery;
    final bibles = versions
        .where((v) =>
            bibleVersionIds.contains(v.id) &&
            (q.isEmpty ||
                v.name.toLowerCase().contains(q) ||
                v.id.toLowerCase().contains(q)))
        .toList();
    final subheadings = versions
        .where((v) =>
            subheadingSourceIds.contains(v.id) &&
            !bibleVersionIds.contains(v.id) &&
            (q.isEmpty ||
                v.name.toLowerCase().contains(q) ||
                v.id.toLowerCase().contains(q)))
        .toList();
    final commentaries = allCommentaries
        .where((c) =>
            q.isEmpty ||
            c.abbreviation.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q))
        .toList();
    final dictionaries = allDictionaries
        .where((d) =>
            q.isEmpty ||
            d.abbreviation.toLowerCase().contains(q) ||
            d.name.toLowerCase().contains(q))
        .toList();
    final devotionals = allDevotionals
        .where((d) =>
            q.isEmpty ||
            d.name.toLowerCase().contains(q) ||
            d.abbreviation.toLowerCase().contains(q))
        .toList();

    if (q.isNotEmpty &&
        bibles.isEmpty &&
        subheadings.isEmpty &&
        commentaries.isEmpty &&
        dictionaries.isEmpty &&
        devotionals.isEmpty) {
      return Center(
        child: Text('No installed content matches "${_searchController.text}".'),
      );
    }

    Widget buildInstalledTrailing(String id, String name, String? about, VoidCallback onDelete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (about != null && about.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'About $name',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(name),
                    content: SingleChildScrollView(
                      child: Text(about),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete $name',
            onPressed: onDelete,
          ),
        ],
      );
    }

    return ListView(
      children: [
        if (bibles.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Bibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...bibles.map((v) => ListTile(
            onTap: () {},
            title: Text(v.name),
            subtitle: Text(v.id),
            trailing: buildInstalledTrailing(v.id, v.name, v.about, () async {
              await ref.read(contentStoreProvider).deleteVersion(v.id);
              ref.read(versionsProvider.notifier).reload();
              ref.read(bibleVersionsProvider.notifier).reload();
              ref.read(subheadingSourcesProvider.notifier).reload();
              ref.read(installedModuleIdsProvider.notifier).reload();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${v.name}')));
              }
            }),
          )),
        ],
        if (subheadings.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Subheadings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...subheadings.map((v) => ListTile(
            onTap: () {},
            title: Text(v.name),
            subtitle: Text(v.id),
            trailing: buildInstalledTrailing(v.id, v.name, v.about, () async {
              await ref.read(contentStoreProvider).deleteVersion(v.id);
              ref.read(versionsProvider.notifier).reload();
              ref.read(subheadingSourcesProvider.notifier).reload();
              ref.read(installedModuleIdsProvider.notifier).reload();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${v.name}')));
              }
            }),
          )),
        ],
        if (commentaries.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Commentaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...commentaries.map((c) => ListTile(
            onTap: () {},
            title: Text(c.abbreviation),
            subtitle: const Text('Commentary'),
            trailing: buildInstalledTrailing(c.abbreviation, c.name, c.about, () async {
              await ref.read(contentStoreProvider).deleteCommentary(c.id);
              ref.read(commentariesProvider.notifier).reload();
              ref.read(installedModuleIdsProvider.notifier).reload();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${c.abbreviation}')));
              }
            }),
          )),
        ],
        if (dictionaries.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Dictionaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...dictionaries.map((d) => ListTile(
            onTap: () {},
            title: Text(d.abbreviation),
            subtitle: const Text('Dictionary'),
            trailing: buildInstalledTrailing(d.abbreviation, d.name, d.about, () async {
              await ref.read(contentStoreProvider).deleteDictionary(d.id);
              ref.read(dictionariesProvider.notifier).reload();
              ref.read(installedModuleIdsProvider.notifier).reload();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${d.abbreviation}')));
              }
            }),
          )),
        ],
        if (devotionals.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Devotionals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...devotionals.map((d) => ListTile(
            onTap: () {},
            title: Text(d.name),
            subtitle: Text(d.abbreviation),
            trailing: buildInstalledTrailing(d.abbreviation, d.name, d.about, () async {
              await ref.read(contentStoreProvider).deleteDevotional(d.id);
              ref.read(devotionalsProvider.notifier).reload();
              ref.read(installedModuleIdsProvider.notifier).reload();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${d.abbreviation}')));
              }
            }),
          )),
        ],
      ],
    );
  }

  Widget _buildPh4Tab() {
    final catalogAsync = ref.watch(ph4CatalogProvider);
    final downloadStates = ref.watch(contentManagerControllerProvider);
    final installedIdsAsync = ref.watch(installedModuleIdsProvider);
    final installedIds = installedIdsAsync.value ?? {};

    return catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (modules) {
              final filtered = modules
                  .where(
                    (m) =>
                        m.title.toLowerCase().contains(_filterQuery) ||
                        m.abbr.toLowerCase().contains(_filterQuery) ||
                        m.author.toLowerCase().contains(_filterQuery),
                  )
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(_filterQuery.isEmpty
                      ? 'No modules available.'
                      : 'No modules match "${_searchController.text}".'),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final m = filtered[index];
                  final dlState = downloadStates[m.abbr];

                  Widget downloadWidget;
                  final isInstalled = installedIds.contains(m.abbr.toUpperCase());

                  // A redownload of an already-installed module must still show
                  // its progress/error: let an active download state win over
                  // the static "installed" check, otherwise the button looks dead.
                  if (isInstalled &&
                      (dlState == null || dlState.status == 'Done')) {
                    downloadWidget = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Redownload',
                          onPressed: () {
                            ref
                                .read(contentManagerControllerProvider.notifier)
                                .downloadAndImportPh4(m);
                          },
                        ),
                      ],
                    );
                  } else if (dlState != null && dlState.status != 'Done') {
                    if (dlState.status.startsWith('Error')) {
                      downloadWidget = IconButton(
                        icon: const Icon(Icons.error, color: Colors.red),
                        tooltip: dlState.status,
                        onPressed: () {},
                      );
                    } else {
                      downloadWidget = SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LinearProgressIndicator(value: dlState.percent),
                            const SizedBox(height: 4),
                            Text(
                              dlState.status,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    }
                  } else {
                    downloadWidget = IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Download',
                      onPressed: () {
                        ref
                            .read(contentManagerControllerProvider.notifier)
                            .downloadAndImportPh4(m);
                      },
                    );
                  }
                  
                  Widget trailing = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (m.infoUrl.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'Info',
                          onPressed: () async {
                            final uri = Uri.parse(m.infoUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      downloadWidget,
                    ],
                  );

                  return ListTile(
                    onTap: () {},
                    title: Row(
                      children: [
                        Expanded(child: Text(m.title)),
                        if (m.isPartial)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Text(
                              'PARTIAL',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text('${m.abbr} • ${m.type.name} • ${m.author}'),
                    trailing: trailing,
                  );
                },
              );
            },
          );
  }

  Widget _buildOsisTab() {
    final languagesAsync = ref.watch(osisLanguagesProvider);
    final downloadStates = ref.watch(contentManagerControllerProvider);
    final installedIdsAsync = ref.watch(installedModuleIdsProvider);
    final installedIds = installedIdsAsync.value ?? {};

    return languagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (languages) {
              final filtered = languages
                  .where(
                    (l) =>
                        l.name.toLowerCase().contains(_filterQuery) ||
                        l.code.toLowerCase().contains(_filterQuery),
                  )
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(_filterQuery.isEmpty
                      ? 'No languages available.'
                      : 'No languages match "${_searchController.text}".'),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final l = filtered[index];
                  return ExpansionTile(
                    title: Text(l.name),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        if (expanded) {
                          _expandedOsisLanguages.add(l.code);
                        }
                      });
                    },
                    children: [
                      if (_expandedOsisLanguages.contains(l.code))
                        Consumer(
                          builder: (context, ref, child) {
                            final translationsAsync = ref.watch(
                              osisTranslationsProvider(l.code),
                            );
                            return translationsAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                              error: (err, _) => Text('Error: $err'),
                              data: (translations) {
                                if (translations.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No translations found.'),
                                  );
                                }
                                return Column(
                                  children: translations.map((t) {
                                    final stateKey = 'osis_${t.basename}';
                                    final dlState = downloadStates[stateKey];

                                    Widget downloadWidget;
                                    final isInstalled = installedIds.contains(t.basename.toUpperCase());

                                    if (isInstalled &&
                                        (dlState == null ||
                                            dlState.status == 'Done')) {
                                      downloadWidget = Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.green),
                                          IconButton(
                                            icon: const Icon(Icons.refresh),
                                            tooltip: 'Redownload',
                                            onPressed: () {
                                              ref
                                                  .read(
                                                    contentManagerControllerProvider
                                                        .notifier,
                                                  )
                                                  .downloadAndImportOsis(t, l.code);
                                            },
                                          ),
                                        ],
                                      );
                                    } else if (dlState != null && dlState.status != 'Done') {
                                      if (dlState.status.startsWith('Error')) {
                                        downloadWidget = IconButton(
                                          icon: const Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                          tooltip: dlState.status,
                                          onPressed: () {},
                                        );
                                      } else {
                                        downloadWidget = SizedBox(
                                          width: 100,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              LinearProgressIndicator(
                                                value: dlState.percent,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                dlState.status,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    } else {
                                      downloadWidget = IconButton(
                                        icon: const Icon(Icons.download),
                                        tooltip: 'Download',
                                        onPressed: () {
                                          ref
                                              .read(
                                                contentManagerControllerProvider
                                                    .notifier,
                                              )
                                              .downloadAndImportOsis(t, l.code);
                                        },
                                      );
                                    }
                                    
                                    Widget trailing = Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (t.infoUrl.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(Icons.info_outline),
                                            tooltip: 'Info',
                                            onPressed: () async {
                                              final uri = Uri.parse(t.infoUrl);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri);
                                              }
                                            },
                                          ),
                                        downloadWidget,
                                      ],
                                    );

                                    return ListTile(
                                      onTap: () {},
                                      title: Text(t.title),
                                      subtitle: Text(
                                        '${(t.size / 1024 / 1024).toStringAsFixed(1)} MB',
                                      ),
                                      trailing: trailing,
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  );
                },
              );
            },
          );
  }

  Widget _buildCrosswireTab() {
    final catalogAsync = ref.watch(crosswireCatalogProvider);
    final downloadStates = ref.watch(contentManagerControllerProvider);
    final installedIdsAsync = ref.watch(installedModuleIdsProvider);
    final installedIds = installedIdsAsync.value ?? {};

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (modules) {
        final filtered = modules.where((m) {
          final desc = m.config.description?.toLowerCase() ?? '';
          final name = m.config.name.toLowerCase();
          return desc.contains(_filterQuery) || name.contains(_filterQuery);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(_filterQuery.isEmpty
                ? 'No modules available.'
                : 'No modules match "${_searchController.text}".'),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final m = filtered[index];
            final stateKey = 'cw_${m.config.name}';
            final dlState = downloadStates[stateKey];

            Widget downloadWidget;
            final isInstalled = installedIds.contains(m.config.name.toUpperCase());
            // Only freely-distributable Bible/commentary/dictionary modules can
            // be installed today, and only in a supported versification (KJV
            // for now — Bibles/commentaries map verses through it; dictionaries
            // are key-based and exempt). Anything else stays visible but greyed
            // out with the reason.
            final drv = m.config.modDrv;
            final usesVersification = drv.isBible || drv.isCommentary;
            final String? blockReason =
                !(drv.isBible || drv.isCommentary || drv.isDictionary)
                    ? 'Only Bible, commentary, and dictionary modules are '
                        'currently supported'
                    : usesVersification &&
                            swordVersificationByName(m.config.versification) ==
                                null
                        ? 'Versification "${m.config.versification}" is not yet '
                            'supported'
                        : !m.config.isFreelyDistributable
                            ? 'License does not permit redistribution'
                            : null;
            final canInstall = blockReason == null;

            if (isInstalled &&
                (dlState == null || dlState.status == 'Done')) {
              downloadWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: canInstall ? 'Redownload' : blockReason,
                    onPressed: canInstall ? () {
                      ref
                          .read(contentManagerControllerProvider.notifier)
                          .downloadAndImportCrosswire(m);
                    } : null,
                  ),
                ],
              );
            } else if (dlState != null && dlState.status != 'Done') {
              if (dlState.status.startsWith('Error')) {
                downloadWidget = IconButton(
                  icon: const Icon(Icons.error, color: Colors.red),
                  tooltip: dlState.status,
                  onPressed: () {},
                );
              } else {
                downloadWidget = SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(value: dlState.percent),
                      const SizedBox(height: 4),
                      Text(dlState.status, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              }
            } else {
              downloadWidget = IconButton(
                icon: const Icon(Icons.download),
                tooltip: canInstall ? 'Download' : blockReason,
                onPressed: canInstall ? () {
                  ref
                      .read(contentManagerControllerProvider.notifier)
                      .downloadAndImportCrosswire(m);
                } : null,
              );
            }

            final aboutText = m.config.about;
            final license = m.config.distributionLicense;
            final copyright = m.config.copyright;
            final shortCopyright = m.config.shortCopyright;

            Widget trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (aboutText != null ||
                    license != null ||
                    copyright != null ||
                    shortCopyright != null)
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'Info',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(m.config.description ?? m.config.name),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (license != null) ...[
                                  Text('License: $license', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                ],
                                if (copyright != null) ...[
                                  Text('Copyright: $copyright', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                ],
                                // Only show the short copyright when it isn't
                                // already covered by the full notice above.
                                if (shortCopyright != null && shortCopyright != copyright) ...[
                                  Text('Copyright: $shortCopyright', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                ],
                                if (aboutText != null) Text(aboutText),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                downloadWidget,
              ],
            );

            final dimmed = !canInstall && !isInstalled;
            return ListTile(
              onTap: dimmed ? null : () {},
              enabled: !dimmed,
              title: Text(m.config.description ?? m.config.name),
              subtitle: Text(
                '${m.config.name} • ${m.config.value('ModDrv') ?? 'Unknown'} • ${m.config.lang ?? 'Unknown'}'
                '${blockReason != null ? '\n$blockReason' : ''}',
              ),
              isThreeLine: blockReason != null,
              trailing: trailing,
            );
          },
        );
      },
    );
  }
}
