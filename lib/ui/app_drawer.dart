import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/app_state.dart';

import 'settings/settings_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModule = ref.watch(appModuleProvider);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Study Bible',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Bible Reader'),
            selected: currentModule == AppModule.reader,
            onTap: () {
              ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Journals & Prayers'),
            selected: currentModule == AppModule.journalsPrayers,
            onTap: () {
              ref.read(appModuleProvider.notifier).setModule(AppModule.journalsPrayers);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: currentModule == AppModule.dashboard,
            onTap: () {
              ref.read(appModuleProvider.notifier).setModule(AppModule.dashboard);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Content Manager'),
            selected: currentModule == AppModule.contentManager,
            onTap: () {
              ref.read(appModuleProvider.notifier).setModule(AppModule.contentManager);
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            selected: currentModule == AppModule.backupRestore,
            onTap: () {
              ref.read(appModuleProvider.notifier).setModule(AppModule.backupRestore);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop(); // close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
