import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/content_manager_providers.dart';
import '../../app/content_providers.dart';
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
  String _ph4SearchQuery = '';
  String _osisSearchQuery = '';
  final Set<String> _expandedOsisLanguages = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Installed'),
            Tab(text: 'ph4.org Catalog'),
            Tab(text: 'OSIS Catalog'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInstalledTab(), _buildPh4Tab(), _buildOsisTab()],
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
    final commentaries = commentariesAsync.value ?? [];
    final dictionaries = dictionariesAsync.value ?? [];
    final devotionals = devotionalsAsync.value ?? [];
    
    final bibleVersionIds = (bibleVersionsAsync.value ?? []).map((v) => v.id).toSet();
    final subheadingSourceIds = (subheadingSourcesAsync.value ?? []).map((v) => v.id).toSet();

    final bibles = versions.where((v) => bibleVersionIds.contains(v.id)).toList();
    final subheadings = versions.where((v) => subheadingSourceIds.contains(v.id) && !bibleVersionIds.contains(v.id)).toList();

    if (versions.isEmpty && commentaries.isEmpty && dictionaries.isEmpty && devotionals.isEmpty) {
      return const Center(child: Text('No content installed.'));
    }

    return ListView(
      children: [
        if (bibles.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Bibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...bibles.map((v) => ListTile(
            title: Text(v.name),
            subtitle: Text(v.id),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete ${v.name}',
              onPressed: () async {
                await ref.read(contentStoreProvider).deleteVersion(v.id);
                ref.invalidate(versionsProvider);
                ref.invalidate(bibleVersionsProvider);
                ref.invalidate(subheadingSourcesProvider);
                ref.invalidate(installedModuleIdsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${v.name}')));
                }
              },
            ),
          )),
        ],
        if (subheadings.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Subheadings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...subheadings.map((v) => ListTile(
            title: Text(v.name),
            subtitle: Text(v.id),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete ${v.name}',
              onPressed: () async {
                await ref.read(contentStoreProvider).deleteVersion(v.id);
                ref.invalidate(versionsProvider);
                ref.invalidate(subheadingSourcesProvider);
                ref.invalidate(installedModuleIdsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${v.name}')));
                }
              },
            ),
          )),
        ],
        if (commentaries.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Commentaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...commentaries.map((c) => ListTile(
            title: Text(c.abbreviation),
            subtitle: const Text('Commentary'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete ${c.abbreviation}',
              onPressed: () async {
                await ref.read(contentStoreProvider).deleteCommentary(c.id);
                ref.invalidate(commentariesProvider);
                ref.invalidate(installedModuleIdsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${c.abbreviation}')));
                }
              },
            ),
          )),
        ],
        if (dictionaries.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Dictionaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...dictionaries.map((d) => ListTile(
            title: Text(d.abbreviation),
            subtitle: const Text('Dictionary'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete ${d.abbreviation}',
              onPressed: () async {
                await ref.read(contentStoreProvider).deleteDictionary(d.id);
                ref.invalidate(dictionariesProvider);
                ref.invalidate(installedModuleIdsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${d.abbreviation}')));
                }
              },
            ),
          )),
        ],
        if (devotionals.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Devotionals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...devotionals.map((d) => ListTile(
            title: Text(d.name),
            subtitle: Text(d.abbreviation),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete ${d.abbreviation}',
              onPressed: () async {
                await ref.read(contentStoreProvider).deleteDevotional(d.id);
                ref.invalidate(devotionalsProvider);
                ref.invalidate(installedModuleIdsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${d.abbreviation}')));
                }
              },
            ),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search modules...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) =>
                setState(() => _ph4SearchQuery = val.toLowerCase()),
          ),
        ),
        Expanded(
          child: catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (modules) {
              final filtered = modules
                  .where(
                    (m) =>
                        m.title.toLowerCase().contains(_ph4SearchQuery) ||
                        m.abbr.toLowerCase().contains(_ph4SearchQuery) ||
                        m.author.toLowerCase().contains(_ph4SearchQuery),
                  )
                  .toList();

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final m = filtered[index];
                  final dlState = downloadStates[m.abbr];

                  Widget trailing;
                  final isInstalled = installedIds.contains(m.abbr.toUpperCase());

                  if (dlState != null) {
                    if (dlState.status == 'Done') {
                      trailing = const Icon(Icons.check, color: Colors.green);
                    } else if (dlState.status.startsWith('Error')) {
                      trailing = IconButton(
                        icon: const Icon(Icons.error, color: Colors.red),
                        tooltip: dlState.status,
                        onPressed: () {},
                      );
                    } else {
                      trailing = SizedBox(
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
                  } else if (isInstalled) {
                    trailing = Row(
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
                  } else {
                    trailing = IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Download',
                      onPressed: () {
                        ref
                            .read(contentManagerControllerProvider.notifier)
                            .downloadAndImportPh4(m);
                      },
                    );
                  }

                  return ListTile(
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
                              color: Colors.orange.withOpacity(0.2),
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
          ),
        ),
      ],
    );
  }

  Widget _buildOsisTab() {
    final languagesAsync = ref.watch(osisLanguagesProvider);
    final downloadStates = ref.watch(contentManagerControllerProvider);
    final installedIdsAsync = ref.watch(installedModuleIdsProvider);
    final installedIds = installedIdsAsync.value ?? {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search languages...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) =>
                setState(() => _osisSearchQuery = val.toLowerCase()),
          ),
        ),
        Expanded(
          child: languagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (languages) {
              final filtered = languages
                  .where(
                    (l) =>
                        l.name.toLowerCase().contains(_osisSearchQuery) ||
                        l.code.toLowerCase().contains(_osisSearchQuery),
                  )
                  .toList();

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
                                if (translations.isEmpty)
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No translations found.'),
                                  );
                                return Column(
                                  children: translations.map((t) {
                                    final stateKey = 'osis_${t.basename}';
                                    final dlState = downloadStates[stateKey];

                                    Widget trailing;
                                    final isInstalled = installedIds.contains(t.basename.toUpperCase());

                                    if (dlState != null) {
                                      if (dlState.status == 'Done') {
                                        trailing = const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        );
                                      } else if (dlState.status.startsWith(
                                        'Error',
                                      )) {
                                        trailing = IconButton(
                                          icon: const Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                          tooltip: dlState.status,
                                          onPressed: () {},
                                        );
                                      } else {
                                        trailing = SizedBox(
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
                                    } else if (isInstalled) {
                                      trailing = Row(
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
                                    } else {
                                      trailing = IconButton(
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

                                    return ListTile(
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
          ),
        ),
      ],
    );
  }
}
