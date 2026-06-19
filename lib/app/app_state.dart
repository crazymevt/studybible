import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs.dart';

enum ActiveTool {
  none,
  crossReference,
  notes,
  search,
  dictionary,
  library,
  commentaries,
  history,
  media,
  readingPlans,
  compare,
  sermons,
}

class ActiveToolNotifier extends Notifier<ActiveTool> {
  @override
  ActiveTool build() => ActiveTool.none;

  void setTool(ActiveTool tool) {
    if (state == tool) {
      state = ActiveTool.none;
    } else {
      state = tool;
    }
  }

  void close() {
    state = ActiveTool.none;
  }
}

final activeToolProvider = NotifierProvider<ActiveToolNotifier, ActiveTool>(
  () => ActiveToolNotifier(),
);

enum AppModule {
  reader,
  journalsPrayers,
  dashboard,
  contentManager,
  backupRestore,
}

class ShowDashboardOnStartNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('showDashboardOnStart') ?? false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('showDashboardOnStart', value);
  }
}

final showDashboardOnStartProvider =
    NotifierProvider<ShowDashboardOnStartNotifier, bool>(
      () => ShowDashboardOnStartNotifier(),
    );

class AppFontFamilyNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('appFontFamily') ?? 'System Default';
  }

  void set(String value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString('appFontFamily', value);
  }
}

final appFontFamilyProvider = NotifierProvider<AppFontFamilyNotifier, String>(
  () => AppFontFamilyNotifier(),
);

class AppFontSizeDeltaNotifier extends Notifier<double> {
  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getDouble('appFontSizeDelta') ?? 0.0;
  }

  void set(double value) {
    state = value;
    ref.read(sharedPreferencesProvider).setDouble('appFontSizeDelta', value);
  }
}

final appFontSizeDeltaProvider =
    NotifierProvider<AppFontSizeDeltaNotifier, double>(
      () => AppFontSizeDeltaNotifier(),
    );

class AppVerseSpacingNotifier extends Notifier<double> {
  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getDouble('appVerseSpacing') ?? 8.0;
  }

  void set(double value) {
    state = value;
    ref.read(sharedPreferencesProvider).setDouble('appVerseSpacing', value);
  }
}

final appVerseSpacingProvider =
    NotifierProvider<AppVerseSpacingNotifier, double>(
      () => AppVerseSpacingNotifier(),
    );

class AppModuleNotifier extends Notifier<AppModule> {
  AppModule build() {
    final showDashboard = ref.watch(showDashboardOnStartProvider);
    return showDashboard ? AppModule.dashboard : AppModule.reader;
  }

  void setModule(AppModule module) {
    state = module;
  }
}

final appModuleProvider = NotifierProvider<AppModuleNotifier, AppModule>(
  () => AppModuleNotifier(),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final value = prefs.getString('themeMode') ?? 'system';
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setMode(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString('themeMode', mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  () => ThemeModeNotifier(),
);

class AppColorThemeNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('appColorTheme') ?? 'default';
  }

  void setTheme(String theme) {
    state = theme;
    ref.read(sharedPreferencesProvider).setString('appColorTheme', theme);
  }
}

final appColorThemeProvider = NotifierProvider<AppColorThemeNotifier, String>(
  () => AppColorThemeNotifier(),
);
