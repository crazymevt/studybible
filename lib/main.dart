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

    return MaterialApp(
      title: 'Study Bible',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppThemes.buildTheme(
        brightness: Brightness.light,
        themeScheme: appColorTheme,
        fontFamily: fontFamily,
        fontSizeDelta: fontSizeDelta,
        customTextColor: lightTextColor != null ? Color(lightTextColor) : null,
        customJesusWordsColor: lightJesusWordsColor != null ? Color(lightJesusWordsColor) : null,
        customSeedColor: lightSeedColor != null ? Color(lightSeedColor) : null,
        customSurfaceColor: lightSurfaceColor != null ? Color(lightSurfaceColor) : null,
        customAppBarColor: lightAppBarColor != null ? Color(lightAppBarColor) : null,
      ),
      darkTheme: AppThemes.buildTheme(
        brightness: Brightness.dark,
        themeScheme: appColorTheme,
        fontFamily: fontFamily,
        fontSizeDelta: fontSizeDelta,
        customTextColor: darkTextColor != null ? Color(darkTextColor) : null,
        customJesusWordsColor: darkJesusWordsColor != null ? Color(darkJesusWordsColor) : null,
        customSeedColor: darkSeedColor != null ? Color(darkSeedColor) : null,
        customSurfaceColor: darkSurfaceColor != null ? Color(darkSurfaceColor) : null,
        customAppBarColor: darkAppBarColor != null ? Color(darkAppBarColor) : null,
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
    );
  }
}
