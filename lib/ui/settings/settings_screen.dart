// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/sync_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../whats_new_dialog.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showDashboardOnStart = ref.watch(showDashboardOnStartProvider);
    final fontFamily = ref.watch(appFontFamilyProvider);
    final fontSizeDelta = ref.watch(appFontSizeDeltaProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appColorTheme = ref.watch(appColorThemeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── General ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Show Dashboard on Startup'),
            subtitle: const Text(
              'Launch directly to the dashboard instead of the reader',
            ),
            value: showDashboardOnStart,
            onChanged: (value) {
              ref.read(showDashboardOnStartProvider.notifier).set(value);
            },
          ),
          ListTile(
            title: const Text("What's New"),
            subtitle: const Text('View the latest features and updates'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const WhatsNewDialog(),
              );
            },
          ),
          const Divider(),

          // ── Theme ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: const Text('Choose light, dark, or system default'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                ref.read(themeModeProvider.notifier).setMode(newSelection.first);
              },
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Color Scheme'),
            subtitle: const Text('Choose the color palette for the app'),
          ),
          _buildColorThemeOption(context, ref, appColorTheme,
              value: 'default',
              title: 'Default Purple',
              subtitle: 'Standard Material layout'),
          _buildColorThemeOption(context, ref, appColorTheme,
              value: 'softIndiglow',
              title: 'Soft Indiglow',
              subtitle: 'Warm indigo and soft blues'),
          _buildColorThemeOption(context, ref, appColorTheme,
              value: 'modernIndigo',
              title: 'Modern Indigo',
              subtitle: 'Clean surfaces with a confident indigo accent'),
          _buildColorThemeOption(context, ref, appColorTheme,
              value: 'quietSage',
              title: 'Quiet Sage',
              subtitle: 'Muted sage-green and stone'),
          _buildColorThemeOption(context, ref, appColorTheme,
              value: 'onyx',
              title: 'Onyx',
              subtitle: 'Neutral graphite surfaces with calm teal accent'),
          _buildColorThemeOption(context, ref, appColorTheme,
              value: 'ocean',
              title: 'Ocean',
              subtitle: 'Deep sea blue and sky accent'),
          const Divider(),

          // ── Appearance ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Reader',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Font Family'),
            subtitle: const Text('Choose the font style for the application'),
            trailing: DropdownButton<String>(
              value: fontFamily,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(appFontFamilyProvider.notifier).set(newValue);
                }
              },
              items:
                  <String>[
                    'System Default',
                    'Roboto',
                    'Lora',
                    'Open Sans',
                    'Lato',
                    'Source Code Pro',
                    'Merriweather',
                    'Playfair Display',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
          ),
          SwitchListTile(
            title: const Text('Show Strong Numbers'),
            subtitle: const Text('Display clickable Strong numbers in the text'),
            value: ref.watch(appShowStrongNumbersProvider),
            onChanged: (bool value) {
              ref.read(appShowStrongNumbersProvider.notifier).set(value);
            },
          ),
          ListTile(
            title: const Text('Subheadings Source'),
            subtitle: const Text('Select which module to use for inline subheadings'),
            trailing: ref.watch(subheadingSourcesProvider).when(
              data: (versions) {
                final source = ref.watch(subheadingsSourceProvider);
                final isValidSource = versions.any((v) => v.id == source);
                final dropdownValue = isValidSource ? source : null;
                
                return DropdownButton<String?>(
                  value: dropdownValue,
                  onChanged: (String? newValue) {
                    ref.read(subheadingsSourceProvider.notifier).setSource(newValue);
                  },
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None (Off)'),
                    ),
                    ...versions.map<DropdownMenuItem<String?>>((v) {
                      return DropdownMenuItem<String?>(
                        value: v.id,
                        child: Text(v.abbreviation),
                      );
                    }),
                  ],
                );
              },
              loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              error: (error, stack) => const Icon(Icons.error),
            ),
          ),
          ListTile(
            title: const Text('Text Size'),
            subtitle: const Text('Adjust the size of text throughout the app'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.text_fields, size: 16),
                Expanded(
                  child: Slider(
                    value: fontSizeDelta,
                    min: -4.0,
                    max: 8.0,
                    divisions: 12,
                    label: fontSizeDelta == 0.0
                        ? 'Default'
                        : '${fontSizeDelta > 0 ? '+' : ''}${fontSizeDelta.toInt()}',
                    onChanged: (double value) {
                      ref.read(appFontSizeDeltaProvider.notifier).set(value);
                    },
                  ),
                ),
                const Icon(Icons.text_fields, size: 28),
              ],
            ),
          ),
          ListTile(
            title: const Text('Verse Spacing'),
            subtitle: const Text(
              'Adjust the space between verses in the reader',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.format_line_spacing, size: 16),
                Expanded(
                  child: Slider(
                    value: ref.watch(appVerseSpacingProvider),
                    min: 0.0,
                    max: 32.0,
                    divisions: 8,
                    label: ref
                        .watch(appVerseSpacingProvider)
                        .toInt()
                        .toString(),
                    onChanged: (double value) {
                      ref.read(appVerseSpacingProvider.notifier).set(value);
                    },
                  ),
                ),
                const Icon(Icons.format_line_spacing, size: 28),
              ],
            ),
          ),
          const Divider(),

          // ── Sync ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Sync',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSyncFolderSelector(context, ref),
          const Divider(),

          // ── Support ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.redAccent),
            title: const Text('Support the Developer'),
            subtitle: const Text('Buy me a coffee on Ko-fi to support development!'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () async {
              final url = Uri.parse('https://ko-fi.com/jessiehughart');
              if (!await launchUrl(url)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open Ko-fi link')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSyncFolderSelector(BuildContext context, WidgetRef ref) {
    final syncFolderPath = ref.watch(syncFolderPathProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sync Folder', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            syncFolderPath != null && syncFolderPath.isNotEmpty
                ? syncFolderPath
                : 'Default (StudyBibleSync in Documents)',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  if (Platform.isAndroid) {
                    final status = await Permission.manageExternalStorage.request();
                    if (!status.isGranted) {
                      final storageStatus = await Permission.storage.request();
                      if (!storageStatus.isGranted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Storage permission is required to select a sync folder.')),
                        );
                        return;
                      }
                    }
                  }
                  
                  final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

                  if (selectedDirectory != null) {
                    ref.read(syncFolderPathProvider.notifier).setPath(selectedDirectory);
                    
                    if (Platform.isMacOS) {
                      try {
                        final secureBookmarks = SecureBookmarks();
                        final bookmark = await secureBookmarks.bookmark(File(selectedDirectory));
                        ref.read(syncFolderBookmarkProvider.notifier).setBookmark(bookmark);
                      } catch (e) {
                        debugPrint('Error creating secure bookmark: $e');
                      }
                    }

                    try {
                      await ref.read(syncServiceProvider).sync();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sync folder updated and synced successfully!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to sync to new folder: $e')),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose Folder'),
              ),
              if (syncFolderPath != null && syncFolderPath.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ref.read(syncFolderPathProvider.notifier).setPath(null);
                    ref.read(syncFolderBookmarkProvider.notifier).setBookmark(null);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorThemeOption(
    BuildContext context,
    WidgetRef ref,
    String currentTheme, {
    required String value,
    required String title,
    required String subtitle,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: currentTheme,
      onChanged: (val) {
        if (val != null) {
          ref.read(appColorThemeProvider.notifier).setTheme(val);
        }
      },
    );
  }
}
