import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'ui/main_shell.dart';
import 'app/shared_prefs.dart';
import 'app/app_state.dart';
import 'app/action_providers.dart';
import 'app/highlight_palette.dart';
import 'data/app_paths.dart';
import 'data/user_store.dart';
import 'data/logging.dart';
import 'theme/app_themes.dart';
import 'dart:ui';
import 'package:auto_updater/auto_updater.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}


final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Maps the stored "Text Weight" value (a [FontWeight] numeric value, 400–700)
/// to its [FontWeight]. Unknown values fall back to regular.
FontWeight _fontWeightFromValue(int value) {
  switch (value) {
    case 500:
      return FontWeight.w500;
    case 600:
      return FontWeight.w600;
    case 700:
      return FontWeight.w700;
    default:
      return FontWeight.w400;
  }
}

void main() {
  // Run the whole app inside a guarded zone so uncaught async errors (and the
  // async startup work below, which runs before any Flutter error handler is
  // installed) are reported rather than silently lost.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Surface the bundled fonts' SIL Open Font License in the in-app "Open
    // Source Licenses" page. Pub package licenses are collected automatically;
    // bundled asset fonts must be registered explicitly. Noto Sans backs PDF
    // output; the rest are the reader's selectable UI font families.
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        const ['Noto Sans'],
        await rootBundle.loadString('assets/fonts/OFL.txt'),
      );
      const uiFonts = <String, String>{
        'Roboto': 'Roboto',
        'Lora': 'Lora',
        'Open Sans': 'OpenSans',
        'Lato': 'Lato',
        'Source Code Pro': 'SourceCodePro',
        'Merriweather': 'Merriweather',
        'Playfair Display': 'PlayfairDisplay',
      };
      for (final entry in uiFonts.entries) {
        yield LicenseEntryWithLineBreaks(
          [entry.key],
          await rootBundle
              .loadString('assets/google_fonts/licenses/${entry.value}-LICENSE.txt'),
        );
      }
    });

    // Errors caught by the Flutter framework (build/layout/paint, gestures).
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logError(details.exception, details.stack, context: 'FlutterError');
    };

    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      await windowManager.ensureInitialized();
    }

    // Debug desktop builds share an application id — and thus a
    // shared_preferences store — with the installed app. Namespace the key
    // space so dev sessions get their own settings (theme, fonts, window
    // geometry, sync config) instead of reading and mutating the real
    // install's, matching appDataDir()'s `-dev` isolation. Must run before the
    // first getInstance(). The dev space starts empty; no migration is done.
    if (useDevDataIsolation) {
      SharedPreferences.setPrefix('flutter_dev.');
    }

    final prefs = await SharedPreferences.getInstance();

    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      final width = prefs.getDouble('window_width') ?? 1200;
      final height = prefs.getDouble('window_height') ?? 800;
      final x = prefs.getDouble('window_x');
      final y = prefs.getDouble('window_y');

      WindowOptions windowOptions = WindowOptions(
        size: Size(width, height),
        center: x == null || y == null,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (x != null && y != null) {
          await windowManager.setPosition(Offset(x, y));
        }
        await windowManager.show();
        await windowManager.focus();
      });
    }

    if (!kIsWeb && Platform.isWindows) {
      String feedURL = 'https://crazymevt.github.io/StudyBible/appcast.xml';
      await autoUpdater.setFeedURL(feedURL);
      await autoUpdater.checkForUpdates(inBackground: true);
      await autoUpdater.setScheduledCheckInterval(3600);
    }

    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StudyBibleApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    logError(error, stack, context: 'Uncaught');
  });
}

class StudyBibleApp extends ConsumerStatefulWidget {
  const StudyBibleApp({super.key});

  @override
  ConsumerState<StudyBibleApp> createState() => _StudyBibleAppState();
}

class _StudyBibleAppState extends ConsumerState<StudyBibleApp>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  void _saveWindowBounds() async {
    if (kIsWeb ||
        (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) {
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final size = await windowManager.getSize();
    final position = await windowManager.getPosition();

    await prefs.setDouble('window_width', size.width);
    await prefs.setDouble('window_height', size.height);
    await prefs.setDouble('window_x', position.dx);
    await prefs.setDouble('window_y', position.dy);
  }

  @override
  void onWindowResized() {
    _saveWindowBounds();
  }

  @override
  void onWindowMoved() {
    _saveWindowBounds();
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = ref.watch(appFontFamilyProvider);
    final fontSizeDelta = ref.watch(appFontSizeDeltaProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appColorTheme = ref.watch(appColorThemeProvider);
    final textWeight = _fontWeightFromValue(ref.watch(appTextWeightProvider));

    final lightTextColor = ref.watch(customLightTextColorProvider);
    final darkTextColor = ref.watch(customDarkTextColorProvider);
    final lightJesusWordsColor = ref.watch(customLightJesusWordsColorProvider);
    final darkJesusWordsColor = ref.watch(customDarkJesusWordsColorProvider);
    
    final lightSeedColor = ref.watch(customLightSeedColorProvider);
    final darkSeedColor = ref.watch(customDarkSeedColorProvider);
    final lightSurfaceColor = ref.watch(customLightSurfaceColorProvider);
    final darkSurfaceColor = ref.watch(customDarkSurfaceColorProvider);
    
    final lightAppBarColor = ref.watch(customLightAppBarColorProvider);
    final darkAppBarColor = ref.watch(customDarkAppBarColorProvider);

    final highlightOverrides = ref.watch(highlightColorOverridesProvider);
    Map<String, Color> highlightColorsFor(bool dark) => {
          for (final e in resolveHighlightColors(
            dark: dark,
            overrides: highlightOverrides,
          ).entries)
            e.key: Color(e.value),
        };

    return MaterialApp(
      title: 'Study Bible',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppThemes.buildTheme(
        brightness: Brightness.light,
        themeScheme: appColorTheme,
        fontFamily: fontFamily,
        fontSizeDelta: fontSizeDelta,
        textWeight: textWeight,
        customTextColor: lightTextColor != null ? Color(lightTextColor) : null,
        customJesusWordsColor: lightJesusWordsColor != null ? Color(lightJesusWordsColor) : null,
        customSeedColor: lightSeedColor != null ? Color(lightSeedColor) : null,
        customSurfaceColor: lightSurfaceColor != null ? Color(lightSurfaceColor) : null,
        customAppBarColor: lightAppBarColor != null ? Color(lightAppBarColor) : null,
        highlightColors: highlightColorsFor(false),
      ),
      darkTheme: AppThemes.buildTheme(
        brightness: Brightness.dark,
        themeScheme: appColorTheme,
        fontFamily: fontFamily,
        fontSizeDelta: fontSizeDelta,
        textWeight: textWeight,
        customTextColor: darkTextColor != null ? Color(darkTextColor) : null,
        customJesusWordsColor: darkJesusWordsColor != null ? Color(darkJesusWordsColor) : null,
        customSeedColor: darkSeedColor != null ? Color(darkSeedColor) : null,
        customSurfaceColor: darkSurfaceColor != null ? Color(darkSurfaceColor) : null,
        customAppBarColor: darkAppBarColor != null ? Color(darkAppBarColor) : null,
        highlightColors: highlightColorsFor(true),
      ),
      themeMode: themeMode,
      scrollBehavior: AppScrollBehavior(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      home: const MainShell(),
      // Render the action-due banner above the whole app (not via a Scaffold's
      // ScaffoldMessenger) so it appears in the exact same place on every
      // screen, including the reader (which nests its own Scaffold).
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        return Column(
          children: [
            const ActionDueBanner(),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  // When the banner is showing it has already consumed the top
                  // (status-bar) inset, so strip it from the app below to avoid
                  // a double gap above each screen's app bar.
                  final showing =
                      ref.watch(actionDueControllerProvider).isNotEmpty;
                  return showing
                      ? MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: content,
                        )
                      : content;
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// App-wide controller for the action-due reminder. Exposes the action items
/// currently within their lead window or overdue and not yet dismissed; the
/// banner widget watches this. Dismissals are remembered per action until it
/// stops alerting (completed/deleted) or a new action comes due.
class ActionDueController extends Notifier<List<ActionItem>> {
  final Set<String> _dismissed = {};
  Timer? _timer;

  @override
  List<ActionItem> build() {
    // Recompute when the action list changes (add/edit/complete/delete/sync)…
    ref.listen(actionItemsProvider, (_, _) => recompute());
    // …and periodically, so actions crossing their lead/due time alert even
    // when nothing else changes.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => recompute());
    ref.onDispose(() => _timer?.cancel());
    return _compute();
  }

  List<ActionItem> _compute() {
    final actions = ref.read(actionItemsProvider).value ?? const <ActionItem>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    final alerting = actionsNeedingAlert(actions, now);
    final ids = alerting.map((a) => a.id).toSet();
    _dismissed.removeWhere((id) => !ids.contains(id));
    return alerting.where((a) => !_dismissed.contains(a.id)).toList();
  }

  void recompute() => state = _compute();

  void dismiss() {
    _dismissed.addAll(state.map((a) => a.id));
    state = const [];
  }
}

final actionDueControllerProvider =
    NotifierProvider<ActionDueController, List<ActionItem>>(
  ActionDueController.new,
);

/// The action-due reminder banner. Rendered at the very top of the app (above
/// every screen's app bar) so its placement is identical everywhere. Shows
/// nothing when no action is due. Colour is user-configurable
/// ([actionBannerColorProvider]); text/icon auto-contrast for legibility.
class ActionDueBanner extends ConsumerStatefulWidget {
  const ActionDueBanner({super.key});

  @override
  ConsumerState<ActionDueBanner> createState() => _ActionDueBannerState();
}

class _ActionDueBannerState extends ConsumerState<ActionDueBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(actionDueControllerProvider.notifier).recompute();
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = ref.watch(actionDueControllerProvider);
    if (due.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now().millisecondsSinceEpoch;
    final bg = Color(
        ref.watch(actionBannerColorProvider) ?? kDefaultActionBannerColor);
    final fg = bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    final overdue = due.where((a) => now >= a.dueAt!).length;
    final String message;
    if (due.length == 1) {
      final a = due.first;
      message = '${now >= a.dueAt! ? 'Overdue' : 'Due soon'}: "${a.title}"';
    } else if (overdue > 0) {
      message = '${due.length} actions need attention ($overdue overdue).';
    } else {
      message = '${due.length} actions are due soon.';
    }

    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Row(
                children: [
                  Icon(Icons.alarm, color: fg, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message, style: TextStyle(color: fg))),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: fg),
                    onPressed: () =>
                        ref.read(actionDueControllerProvider.notifier).dismiss(),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: fg.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }
}
