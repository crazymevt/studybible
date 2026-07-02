// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/highlight_palette.dart';
import '../../app/shared_prefs.dart';
import '../../domain/scripture/verse_share_format.dart';
import '../../app/sync_service.dart';
import '../../app/dashboard_providers.dart';
import '../../data/logging.dart';
import '../../theme/app_themes.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../whats_new_dialog.dart';
import 'dart:io';
import 'dart:convert';
import 'package:saf_util/saf_util.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'acknowledgments_screen.dart';

/// Human-readable name for a "Text Weight" slider value (a [FontWeight] numeric
/// value, 400–700).
String _textWeightLabel(int value) {
  switch (value) {
    case 500:
      return 'Medium';
    case 600:
      return 'Semibold';
    case 700:
      return 'Bold';
    default:
      return 'Regular';
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? draftLightSeed;
  int? draftLightSurface;
  int? draftLightText;
  int? draftLightJesus;
  int? draftLightAppBar;
  int? draftDarkSeed;
  int? draftDarkSurface;
  int? draftDarkText;
  int? draftDarkJesus;
  int? draftDarkAppBar;
  bool _isDraftInitialized = false;
  bool _rebuildingSearchIndex = false;

  Future<void> _rebuildSearchIndex() async {
    setState(() => _rebuildingSearchIndex = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(contentStoreProvider).rebuildSearchIndex();
      // A manual rebuild also resolves the upgrade prompt in the What's New
      // dialog (marks the current generation), so the user isn't nudged again.
      await ref
          .read(sharedPreferencesProvider)
          .setInt(kSearchIndexRebuiltGenKey, kSearchIndexGeneration);
      messenger.showSnackBar(
        const SnackBar(content: Text('Search index rebuilt.')),
      );
    } catch (e, stack) {
      logError(e, stack, context: 'SettingsScreen.rebuildSearchIndex');
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to rebuild search index: $e')),
      );
    } finally {
      if (mounted) setState(() => _rebuildingSearchIndex = false);
    }
  }

  void _initDraftState() {
    draftLightSeed = ref.read(customLightSeedColorProvider);
    draftLightSurface = ref.read(customLightSurfaceColorProvider);
    draftLightText = ref.read(customLightTextColorProvider);
    draftLightJesus = ref.read(customLightJesusWordsColorProvider);
    draftLightAppBar = ref.read(customLightAppBarColorProvider);
    draftDarkSeed = ref.read(customDarkSeedColorProvider);
    draftDarkSurface = ref.read(customDarkSurfaceColorProvider);
    draftDarkText = ref.read(customDarkTextColorProvider);
    draftDarkJesus = ref.read(customDarkJesusWordsColorProvider);
    draftDarkAppBar = ref.read(customDarkAppBarColorProvider);
    _isDraftInitialized = true;
  }

  void _applyDraftState() {
    ref.read(customLightSeedColorProvider.notifier).setColor(draftLightSeed);
    ref.read(customLightSurfaceColorProvider.notifier).setColor(draftLightSurface);
    ref.read(customLightTextColorProvider.notifier).setColor(draftLightText);
    ref.read(customLightJesusWordsColorProvider.notifier).setColor(draftLightJesus);
    ref.read(customLightAppBarColorProvider.notifier).setColor(draftLightAppBar);
    ref.read(customDarkSeedColorProvider.notifier).setColor(draftDarkSeed);
    ref.read(customDarkSurfaceColorProvider.notifier).setColor(draftDarkSurface);
    ref.read(customDarkTextColorProvider.notifier).setColor(draftDarkText);
    ref.read(customDarkJesusWordsColorProvider.notifier).setColor(draftDarkJesus);
    ref.read(customDarkAppBarColorProvider.notifier).setColor(draftDarkAppBar);
  }

  void _revertDraftState() {
    setState(() {
      _initDraftState();
    });
  }

  Future<void> _exportTheme() async {
    final Map<String, int?> themeData = {
      'lightSeed': draftLightSeed,
      'lightSurface': draftLightSurface,
      'lightText': draftLightText,
      'lightJesus': draftLightJesus,
      'lightAppBar': draftLightAppBar,
      'darkSeed': draftDarkSeed,
      'darkSurface': draftDarkSurface,
      'darkText': draftDarkText,
      'darkJesus': draftDarkJesus,
      'darkAppBar': draftDarkAppBar,
    };
    final jsonStr = jsonEncode(themeData);
    
    if (Platform.isIOS || Platform.isAndroid) {
      final box = context.findRenderObject() as RenderBox?;
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/custom_theme.json');
      await tempFile.writeAsString(jsonStr);
      
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path, name: 'custom_theme.json')],
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );
      await tempFile.delete();
      return;
    }

    const XTypeGroup jsonGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
    final FileSaveLocation? saveLocation = await getSaveLocation(
      acceptedTypeGroups: const [jsonGroup],
      suggestedName: 'custom_theme.json',
    );
    final String? outputFile = saveLocation?.path;

    if (outputFile != null) {
      await File(outputFile).writeAsString(jsonStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Theme exported successfully.')),
        );
      }
    }
  }

  Future<void> _importTheme() async {
    // Do not use acceptedTypeGroups as it can cause PlatformExceptions on iOS/Android
    // if the specific extension UTIs are not registered in Info.plist.
    final XFile? picked = await openFile();

    if (picked != null) {
      try {
        final jsonStr = await picked.readAsString();
        final Map<String, dynamic> themeData = jsonDecode(jsonStr);
        
        setState(() {
          draftLightSeed = themeData['lightSeed'] as int?;
          draftLightSurface = themeData['lightSurface'] as int?;
          draftLightText = themeData['lightText'] as int?;
          draftLightJesus = themeData['lightJesus'] as int?;
          draftLightAppBar = themeData['lightAppBar'] as int?;
          draftDarkSeed = themeData['darkSeed'] as int?;
          draftDarkSurface = themeData['darkSurface'] as int?;
          draftDarkText = themeData['darkText'] as int?;
          draftDarkJesus = themeData['darkJesus'] as int?;
          draftDarkAppBar = themeData['darkAppBar'] as int?;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Theme imported to draft! Click Apply to save.')),
          );
        }
      } catch (e, stack) {
        logError(e, stack, context: 'SettingsScreen.importTheme');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to import theme. Invalid format.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDraftInitialized) {
      _initDraftState();
    }

    final startupModule = ref.watch(startupModuleProvider);
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            title: const Text('Landing Page'),
            subtitle: const Text(
              'Which screen the app opens to on startup',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SegmentedButton<AppModule>(
              segments: const [
                ButtonSegment(
                  value: AppModule.dashboard,
                  icon: Icon(Icons.dashboard_outlined),
                  label: Text('Dashboard'),
                ),
                ButtonSegment(
                  value: AppModule.reader,
                  icon: Icon(Icons.menu_book_outlined),
                  label: Text('Reader'),
                ),
                ButtonSegment(
                  value: AppModule.journalsPrayers,
                  icon: Icon(Icons.edit_note),
                  label: Text('Journal'),
                ),
              ],
              selected: {startupModule},
              onSelectionChanged: (Set<AppModule> newSelection) {
                ref.read(startupModuleProvider.notifier).set(newSelection.first);
              },
            ),
          ),
          const SizedBox(height: 8),
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
          ListTile(
            title: const Text('Replay Tutorial'),
            subtitle: const Text('View the introductory tutorial again'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // The tutorial is an overlay on the live shell; switch to the
              // reader (where its spotlight targets live), clear the flag, and
              // return there so it replays in context.
              ref.read(appModuleProvider.notifier).setModule(AppModule.reader);
              ref.read(hasSeenTutorialProvider.notifier).setSeen(false);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          ListTile(
            title: const Text('Acknowledgments'),
            subtitle: const Text('Credits and open source licenses'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AcknowledgmentsScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // ── Dashboard ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Dashboard Widgets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          SwitchListTile(
            title: const Text('Quick Stats'),
            subtitle: const Text('Top row showing active streak and stats'),
            value: ref.watch(dashboardPrefsProvider)['showQuickStats'] ?? true,
            onChanged: (val) => ref.read(dashboardPrefsProvider.notifier).toggle('showQuickStats', val),
          ),
          SwitchListTile(
            title: const Text('Verse of the Day'),
            value: ref.watch(dashboardPrefsProvider)['showVerseOfTheDay'] ?? true,
            onChanged: (val) => ref.read(dashboardPrefsProvider.notifier).toggle('showVerseOfTheDay', val),
          ),
          SwitchListTile(
            title: const Text('Reading Progress'),
            value: ref.watch(dashboardPrefsProvider)['showReadingProgress'] ?? true,
            onChanged: (val) => ref.read(dashboardPrefsProvider.notifier).toggle('showReadingProgress', val),
          ),
          SwitchListTile(
            title: const Text('Reading Plans'),
            value: ref.watch(dashboardPrefsProvider)['showReadingPlans'] ?? true,
            onChanged: (val) => ref.read(dashboardPrefsProvider.notifier).toggle('showReadingPlans', val),
          ),
          SwitchListTile(
            title: const Text('Action Items'),
            value: ref.watch(dashboardPrefsProvider)['showActionItems'] ?? true,
            onChanged: (val) => ref.read(dashboardPrefsProvider.notifier).toggle('showActionItems', val),
          ),
          SwitchListTile(
            title: const Text('Time Analytics'),
            value: ref.watch(dashboardPrefsProvider)['showTimeAnalytics'] ?? true,
            onChanged: (val) => ref.read(dashboardPrefsProvider.notifier).toggle('showTimeAnalytics', val),
          ),
          SwitchListTile(
            title: const Text('Achievements'),
            value: ref.watch(dashboardPrefsProvider)['showAchievements'] ?? true,
            onChanged: (val) => ref.read(dashboardPrefsProvider.notifier).toggle('showAchievements', val),
          ),
          const Divider(),

          // ── Theme ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
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
            title: const Text('Study tools panel'),
            subtitle: const Text(
                'Which side the tools navigation rail sits on (wide layouts)'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SegmentedButton<NavRailSide>(
              segments: const [
                ButtonSegment(
                  value: NavRailSide.left,
                  icon: Icon(Icons.view_sidebar_outlined),
                  label: Text('Left'),
                ),
                ButtonSegment(
                  value: NavRailSide.right,
                  icon: Icon(Icons.view_sidebar),
                  label: Text('Right'),
                ),
              ],
              selected: {ref.watch(navRailSideProvider)},
              onSelectionChanged: (Set<NavRailSide> newSelection) {
                ref.read(navRailSideProvider.notifier).set(newSelection.first);
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
          _buildColorThemeOption(context, ref, appColorTheme,
              value: 'custom',
              title: 'Custom',
              subtitle: 'Build your own fully custom theme'),
          if (appColorTheme == 'custom')
            Padding(
              padding: const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThemePreview(
                    context, 
                    lightSeed: draftLightSeed, lightSurface: draftLightSurface, lightText: draftLightText, lightJesus: draftLightJesus, lightAppBar: draftLightAppBar,
                    darkSeed: draftDarkSeed, darkSurface: draftDarkSurface, darkText: draftDarkText, darkJesus: draftDarkJesus, darkAppBar: draftDarkAppBar,
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'App Bar (Light)',
                    subtitle: 'Default is light purple',
                    currentColor: draftLightAppBar,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftLightAppBar = c?.toARGB32(); }
                        catch (e) { draftLightAppBar = c?.value; }
                      });
                    },
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'Primary Accent (Light)',
                    subtitle: 'Default is purple',
                    currentColor: draftLightSeed,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftLightSeed = c?.toARGB32(); }
                        catch (e) { draftLightSeed = c?.value; }
                      });
                    },
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'Background (Light)',
                    subtitle: 'Default is light gray',
                    currentColor: draftLightSurface,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftLightSurface = c?.toARGB32(); }
                        catch (e) { draftLightSurface = c?.value; }
                      });
                    },
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'Text Color (Light)',
                    subtitle: 'Default is black',
                    currentColor: draftLightText,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftLightText = c?.toARGB32(); }
                        catch (e) { draftLightText = c?.value; }
                      });
                    },
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'Jesus Words (Light)',
                    subtitle: 'Default is red',
                    currentColor: draftLightJesus,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftLightJesus = c?.toARGB32(); }
                        catch (e) { draftLightJesus = c?.value; }
                      });
                    },
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'App Bar (Dark)',
                    subtitle: 'Default is deep purple',
                    currentColor: draftDarkAppBar,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftDarkAppBar = c?.toARGB32(); }
                        catch (e) { draftDarkAppBar = c?.value; }
                      });
                    },
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'Primary Accent (Dark)',
                    subtitle: 'Default is purple',
                    currentColor: draftDarkSeed,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftDarkSeed = c?.toARGB32(); }
                        catch (e) { draftDarkSeed = c?.value; }
                      });
                    },
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'Background (Dark)',
                    subtitle: 'Default is very dark blue',
                    currentColor: draftDarkSurface,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftDarkSurface = c?.toARGB32(); }
                        catch (e) { draftDarkSurface = c?.value; }
                      });
                    },
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'Text Color (Dark)',
                    subtitle: 'Default is light gray',
                    currentColor: draftDarkText,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftDarkText = c?.toARGB32(); }
                        catch (e) { draftDarkText = c?.value; }
                      });
                    },
                  ),
                  _buildColorPickerTile(
                    context,
                    title: 'Jesus Words (Dark)',
                    subtitle: 'Default is light red',
                    currentColor: draftDarkJesus,
                    onColorChanged: (c) {
                      setState(() {
                        try { draftDarkJesus = c?.toARGB32(); }
                        catch (e) { draftDarkJesus = c?.value; }
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _importTheme,
                              icon: const Icon(Icons.upload, size: 16),
                              label: const Text('Import'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _exportTheme,
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Export'),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _revertDraftState,
                              child: const Text('Revert'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _applyDraftState();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Custom theme applied!')),
                                );
                              },
                              child: const Text('Apply Theme'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),

          // ── Appearance ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Reader',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
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
          _buildHighlightColorsSection(context, ref),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Actions',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          _buildColorPickerTile(
            context,
            title: 'Due reminder banner colour',
            subtitle:
                'Shown when an action is due or overdue. Default is yellow.',
            currentColor:
                ref.watch(actionBannerColorProvider) ?? kDefaultActionBannerColor,
            onColorChanged: (c) {
              int? v;
              try {
                v = c?.toARGB32();
              } catch (_) {
                v = c?.value;
              }
              ref.read(actionBannerColorProvider.notifier).setColor(v);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Reading progress',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SwitchListTile(
            title: const Text('Mark chapters read manually'),
            subtitle: const Text(
              'Off: chapters are marked read automatically after a few seconds. '
              'On: tap "Mark Chapter Read" at the bottom of the chapter.',
            ),
            value: ref.watch(manualChapterReadProvider),
            onChanged: (bool value) {
              ref.read(manualChapterReadProvider.notifier).set(value);
            },
          ),
          SwitchListTile(
            title: const Text('Mark chapters read with audio'),
            subtitle: const Text(
              'When audio finishes a chapter and advances to the next, '
              'mark the finished chapter as read.',
            ),
            value: ref.watch(audioAdvanceMarksReadProvider),
            onChanged: (bool value) {
              ref.read(audioAdvanceMarksReadProvider.notifier).set(value);
            },
          ),
          ListTile(
            title: const Text('Week starts on'),
            subtitle: const Text(
              'First day of the week for the dashboard\'s "This Week" stats',
            ),
            trailing: DropdownButton<int>(
              value: ref.watch(weekStartDayProvider),
              onChanged: (int? value) {
                if (value != null) {
                  ref.read(weekStartDayProvider.notifier).set(value);
                }
              },
              items: const [
                DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
                DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                DropdownMenuItem(value: DateTime.tuesday, child: Text('Tuesday')),
                DropdownMenuItem(
                    value: DateTime.wednesday, child: Text('Wednesday')),
                DropdownMenuItem(
                    value: DateTime.thursday, child: Text('Thursday')),
                DropdownMenuItem(value: DateTime.friday, child: Text('Friday')),
                DropdownMenuItem(
                    value: DateTime.saturday, child: Text('Saturday')),
              ],
            ),
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
            title: const Text('Text Weight'),
            subtitle: const Text(
              'Make all text throughout the app heavier for easier reading',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.format_bold, size: 16),
                Expanded(
                  child: Slider(
                    value: ref.watch(appTextWeightProvider).toDouble(),
                    min: 400,
                    max: 700,
                    divisions: 3,
                    label: _textWeightLabel(ref.watch(appTextWeightProvider)),
                    onChanged: (double value) {
                      ref
                          .read(appTextWeightProvider.notifier)
                          .set(value.round());
                    },
                  ),
                ),
                const Icon(Icons.format_bold, size: 28),
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

          // ── Copy & Share ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Copy & Share',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          _buildCopyShareSection(context, ref),
          const Divider(),

          // ── Sync ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Sync',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          _buildGoogleDriveSync(context, ref),
          const Divider(),
          _buildSyncFolderSelector(context, ref),
          const Divider(),

          // ── Maintenance ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Maintenance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.manage_search),
            title: const Text('Rebuild search index'),
            subtitle: const Text(
              'Re-indexes installed content to remove markup and junk tokens from search suggestions.',
            ),
            trailing: _rebuildingSearchIndex
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _rebuildingSearchIndex ? null : _rebuildSearchIndex,
          ),
          const Divider(),

          // ── Support ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
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

  Widget _buildCopyShareSection(BuildContext context, WidgetRef ref) {
    final format = ref.watch(verseShareFormatProvider);
    final notifier = ref.read(verseShareFormatProvider.notifier);

    // Live preview so the toggles have a visible, immediate effect.
    final preview = VerseShareFormatter.format(
      bookName: 'John',
      chapter: 3,
      verses: const [
        (number: 16, text: 'For God so loved the world.'),
        (number: 17, text: 'For God sent not his Son to condemn the world.'),
      ],
      versionAbbreviation: 'ESV',
      format: format,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Include verse numbers'),
          subtitle: const Text('Prefix each verse with its number'),
          value: format.includeVerseNumbers,
          onChanged: notifier.setIncludeVerseNumbers,
        ),
        SwitchListTile(
          title: const Text('Include version abbreviation'),
          subtitle: const Text('Cite the source version, e.g. "John 3:16 (ESV)"'),
          value: format.includeVersionAbbreviation,
          onChanged: notifier.setIncludeVersionAbbreviation,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Expanded(child: Text('Reference position')),
              SegmentedButton<VerseReferencePosition>(
                segments: const [
                  ButtonSegment(
                    value: VerseReferencePosition.top,
                    label: Text('Top'),
                  ),
                  ButtonSegment(
                    value: VerseReferencePosition.bottom,
                    label: Text('Bottom'),
                  ),
                ],
                selected: {format.referencePosition},
                onSelectionChanged: (s) =>
                    notifier.setReferencePosition(s.first),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              preview,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleDriveSync(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(googleDriveEnabledProvider);
    final account = ref.watch(googleDriveAccountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.cloud),
              SizedBox(width: 8),
              Text('Google Drive', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            enabled
                ? (account != null && account.isNotEmpty
                    ? 'Connected as $account'
                    : 'Connected')
                : 'Sync your notes, highlights, sermons and reading progress to '
                    'a private app folder in your Google Drive, shared across '
                    'all your devices.',
            style:
                TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (enabled)
            OutlinedButton.icon(
              onPressed: () => _disconnectGoogleDrive(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Disconnect'),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _connectGoogleDrive(context, ref),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Connect Google Drive'),
            ),
        ],
      ),
    );
  }

  Future<void> _connectGoogleDrive(BuildContext context, WidgetRef ref) async {
    try {
      final conn = await ref.read(googleDriveAuthProvider).signIn();
      if (conn == null) return; // user cancelled
      // The sync service restores its own client from the now-persisted
      // credentials, so we don't hand this one through — close it.
      conn.client.close();
      ref.read(googleDriveAccountProvider.notifier).setAccount(conn.email);
      ref.read(googleDriveEnabledProvider.notifier).setEnabled(true);
      await ref.read(syncServiceProvider).sync();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Connected to Google Drive and synced.')),
        );
      }
    } catch (e, stack) {
      logError(e, stack, context: 'SettingsScreen.connectGoogleDrive');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect Google Drive: $e')),
        );
      }
    }
  }

  Future<void> _disconnectGoogleDrive(
      BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(googleDriveAuthProvider).signOut();
    } catch (e, stack) {
      logError(e, stack, context: 'SettingsScreen.disconnectGoogleDrive');
    }
    ref.read(googleDriveEnabledProvider.notifier).setEnabled(false);
    ref.read(googleDriveAccountProvider.notifier).setAccount(null);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected from Google Drive.')),
      );
    }
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
                  String? selectedDirectory;
                  if (Platform.isAndroid) {
                    // Use the Storage Access Framework folder picker, which
                    // grants persistable access to the chosen tree without any
                    // storage permission. The returned content:// URI is what
                    // we persist and sync against.
                    final dir = await SafUtil().pickDirectory(
                      writePermission: true,
                      persistablePermission: true,
                      initialUri: '',
                    );
                    selectedDirectory = dir?.uri;
                  } else if (Platform.isIOS) {
                    final docs = await getApplicationDocumentsDirectory();
                    final syncDir = Directory('${docs.path}/Sync');
                    if (!await syncDir.exists()) {
                      await syncDir.create();
                    }
                    selectedDirectory = syncDir.path;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('On iOS, sync uses your app Documents folder.')),
                      );
                    }
                  } else {
                    selectedDirectory = await getDirectoryPath();
                  }

                  if (selectedDirectory != null) {
                    ref.read(syncFolderPathProvider.notifier).setPath(selectedDirectory);
                    
                    if (Platform.isMacOS) {
                      try {
                        final secureBookmarks = SecureBookmarks();
                        final bookmark = await secureBookmarks.bookmark(File(selectedDirectory));
                        ref.read(syncFolderBookmarkProvider.notifier).setBookmark(bookmark);
                      } catch (e, stack) {
                        logError(e, stack,
                            context: 'SettingsScreen.secureBookmark');
                      }
                    }

                    try {
                      await ref.read(syncServiceProvider).sync();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sync folder updated and synced successfully!')),
                        );
                      }
                    } catch (e, stack) {
                      logError(e, stack,
                          context: 'SettingsScreen.syncToNewFolder');
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

  Widget _buildThemePreview(
    BuildContext context, {
    required int? lightSeed, required int? lightSurface, required int? lightText, required int? lightJesus, required int? lightAppBar,
    required int? darkSeed, required int? darkSurface, required int? darkText, required int? darkJesus, required int? darkAppBar,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme Preview', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPreviewCard(
                  context,
                  brightness: Brightness.light,
                  seedColor: lightSeed != null ? Color(lightSeed) : null,
                  surfaceColor: lightSurface != null ? Color(lightSurface) : null,
                  textColor: lightText != null ? Color(lightText) : null,
                  jesusWordsColor: lightJesus != null ? Color(lightJesus) : null,
                  appBarColor: lightAppBar != null ? Color(lightAppBar) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPreviewCard(
                  context,
                  brightness: Brightness.dark,
                  seedColor: darkSeed != null ? Color(darkSeed) : null,
                  surfaceColor: darkSurface != null ? Color(darkSurface) : null,
                  textColor: darkText != null ? Color(darkText) : null,
                  jesusWordsColor: darkJesus != null ? Color(darkJesus) : null,
                  appBarColor: darkAppBar != null ? Color(darkAppBar) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context, {
    required Brightness brightness,
    Color? seedColor,
    Color? surfaceColor,
    Color? textColor,
    Color? jesusWordsColor,
    Color? appBarColor,
  }) {
    // Generate a miniature ThemeData
    final theme = AppThemes.buildTheme(
      brightness: brightness,
      themeScheme: 'custom',
      fontFamily: null,
      fontSizeDelta: 0.0,
      customTextColor: textColor,
      customJesusWordsColor: jesusWordsColor,
      customSeedColor: seedColor,
      customSurfaceColor: surfaceColor,
      customAppBarColor: appBarColor,
    );
    final isDark = brightness == Brightness.dark;
    final fallbackJesus = isDark ? Colors.red.shade300 : Colors.red.shade700;
    final jWordsColor = theme.extension<CustomAppColors>()?.jesusWordsColor ?? fallbackJesus;

    return Theme(
      data: theme,
      child: Card(
        color: theme.colorScheme.surface,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.menu, size: 16, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text('John 3', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(Icons.search, size: 16, color: theme.colorScheme.onPrimaryContainer),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nicodemus', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                      children: [
                        TextSpan(text: '16 ', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 8)),
                        TextSpan(text: 'For God so loved the world, '),
                        TextSpan(text: '"that he gave his only Son..."', style: TextStyle(color: jWordsColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 24),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        textStyle: const TextStyle(fontSize: 10),
                      ),
                      child: const Text('Notes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightColorsSection(BuildContext context, WidgetRef ref) {
    final overrides = ref.watch(highlightColorOverridesProvider);
    final customized = overrides.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Highlight colours',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Customise the four verse-highlight colours. Light and dark mode '
            'are set independently; tap a swatch to change it.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        for (final slot in highlightSlots)
          ListTile(
            title: Text(slot.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _highlightSwatch(context, ref, overrides, slot.id, 'light'),
                const SizedBox(width: 16),
                _highlightSwatch(context, ref, overrides, slot.id, 'dark'),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: TextButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset highlight colours'),
              onPressed: customized
                  ? () => ref
                      .read(highlightColorOverridesProvider.notifier)
                      .resetAll()
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _highlightSwatch(
    BuildContext context,
    WidgetRef ref,
    Map<String, int> overrides,
    String slotId,
    String mode,
  ) {
    final override = overrides['${slotId}_$mode'];
    final effective =
        override ?? defaultHighlightColorArgb(slotId, dark: mode == 'dark');
    final label = mode == 'dark' ? 'Dark' : 'Light';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _pickHighlightColor(
            context,
            ref,
            slotId: slotId,
            mode: mode,
            initial: Color(effective),
          ),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color(effective),
              shape: BoxShape.circle,
              border: Border.all(
                color: override != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: override != null ? 2 : 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  void _pickHighlightColor(
    BuildContext context,
    WidgetRef ref, {
    required String slotId,
    required String mode,
    required Color initial,
  }) {
    final slotName = highlightSlots.firstWhere((s) => s.id == slotId).name;
    final modeLabel = mode == 'dark' ? 'dark mode' : 'light mode';
    Color picked = initial;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$slotName — $modeLabel'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initial,
              enableAlpha: false,
              onColorChanged: (color) => picked = color,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Default'),
              onPressed: () {
                ref
                    .read(highlightColorOverridesProvider.notifier)
                    .setOverride(slotId, mode, null);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                int argb;
                try {
                  argb = picked.toARGB32();
                } catch (_) {
                  argb = picked.value;
                }
                ref
                    .read(highlightColorOverridesProvider.notifier)
                    .setOverride(slotId, mode, argb);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorPickerTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int? currentColor,
    required ValueChanged<Color?> onColorChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentColor != null)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(currentColor),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.palette),
        ],
      ),
      onTap: () {
        Color pickerColor = currentColor != null ? Color(currentColor) : Colors.black;
        final originalColor = currentColor;
        
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Pick a color: $title'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickerColor,
                  enableAlpha: false,
                  onColorChanged: (color) {
                    pickerColor = color;
                    onColorChanged(color);
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Default'),
                  onPressed: () {
                    onColorChanged(null);
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    onColorChanged(originalColor != null ? Color(originalColor) : null);
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    onColorChanged(pickerColor);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
