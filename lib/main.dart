import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'ui/main_shell.dart';
import 'app/shared_prefs.dart';
import 'app/app_state.dart';

import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();
  }
  
  final prefs = await SharedPreferences.getInstance();
  
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    final width = prefs.getDouble('window_width') ?? 1200;
    final height = prefs.getDouble('window_height') ?? 800;
    final x = prefs.getDouble('window_x');
    final y = prefs.getDouble('window_y');
    
    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      center: x == null || y == null,
      backgroundColor: Colors.transparent,
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
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const StudyBibleApp(),
    ),
  );
}

class StudyBibleApp extends ConsumerStatefulWidget {
  const StudyBibleApp({super.key});

  @override
  ConsumerState<StudyBibleApp> createState() => _StudyBibleAppState();
}

class _StudyBibleAppState extends ConsumerState<StudyBibleApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }
  
  void _saveWindowBounds() async {
    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) return;
    
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

    final String? actualFontFamily = fontFamily == 'System Default' ? null : fontFamily;

    ThemeData buildTheme(Brightness brightness, Color seedColor) {
      final typography = Typography.material2021(platform: defaultTargetPlatform);
      final colorTextTheme = brightness == Brightness.light ? typography.black : typography.white;
      
      var textTheme = typography.englishLike.apply(
        fontSizeDelta: fontSizeDelta,
      ).merge(colorTextTheme);

      if (actualFontFamily != null) {
        textTheme = GoogleFonts.getTextTheme(actualFontFamily, textTheme);
      }

      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        ),
        useMaterial3: true,
        textTheme: textTheme,
      );
    }

    return MaterialApp(
      title: 'Study Bible',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, const Color(0xFF6750A4)),
      darkTheme: buildTheme(Brightness.dark, const Color(0xFFD0BCFF)),
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}
