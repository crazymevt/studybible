import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs.dart';

enum ActiveTool {
  none,
  crossReference,
  notes,
  search,
  dictionary,
  commentaries,
  history,
  media,
  readingPlans,
  compare,
  sermons,
  devotionals,
  topics,
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

  void openTool(ActiveTool tool) {
    state = tool;
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

/// Which side of the desktop layout the study-tools navigation rail sits on.
enum NavRailSide { left, right }

/// Persisted preference for the navigation rail side. Defaults to [right],
/// matching the original layout.
class NavRailSideNotifier extends Notifier<NavRailSide> {
  @override
  NavRailSide build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('navRailSide') == 'left'
        ? NavRailSide.left
        : NavRailSide.right;
  }

  void set(NavRailSide side) {
    state = side;
    ref.read(sharedPreferencesProvider).setString('navRailSide', side.name);
  }
}

final navRailSideProvider = NotifierProvider<NavRailSideNotifier, NavRailSide>(
  () => NavRailSideNotifier(),
);

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

class AppShowStrongNumbersNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('appShowStrongNumbers') ?? false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('appShowStrongNumbers', value);
  }
}

final appShowStrongNumbersProvider =
    NotifierProvider<AppShowStrongNumbersNotifier, bool>(
      () => AppShowStrongNumbersNotifier(),
    );

/// When true (the default), chapters are only marked read when the user taps
/// the "Mark Chapter Read" button. When false, a chapter is marked read
/// automatically after it has been on screen for a few seconds.
class ManualChapterReadNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('manualChapterRead') ?? true;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('manualChapterRead', value);
  }
}

final manualChapterReadProvider =
    NotifierProvider<ManualChapterReadNotifier, bool>(
      () => ManualChapterReadNotifier(),
    );

/// When true (the default), a chapter is marked read when audio playback
/// completes and automatically advances to the next chapter.
class AudioAdvanceMarksReadNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('audioAdvanceMarksRead') ?? true;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('audioAdvanceMarksRead', value);
  }
}

final audioAdvanceMarksReadProvider =
    NotifierProvider<AudioAdvanceMarksReadNotifier, bool>(
      () => AudioAdvanceMarksReadNotifier(),
    );

class AppModuleNotifier extends Notifier<AppModule> {
  @override
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

class SubheadingsSourceNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('subheadingsSourceVersionId');
  }

  void setSource(String? versionId) {
    state = versionId;
    if (versionId == null) {
      ref.read(sharedPreferencesProvider).remove('subheadingsSourceVersionId');
    } else {
      ref.read(sharedPreferencesProvider).setString('subheadingsSourceVersionId', versionId);
    }
  }
}

final subheadingsSourceProvider = NotifierProvider<SubheadingsSourceNotifier, String?>(
  () => SubheadingsSourceNotifier(),
);

class SyncFolderPathNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('syncFolderPath');
  }

  void setPath(String? path) {
    state = path;
    if (path == null) {
      ref.read(sharedPreferencesProvider).remove('syncFolderPath');
    } else {
      ref.read(sharedPreferencesProvider).setString('syncFolderPath', path);
    }
  }
}

final syncFolderPathProvider = NotifierProvider<SyncFolderPathNotifier, String?>(
  () => SyncFolderPathNotifier(),
);

class SyncFolderBookmarkNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('syncFolderBookmark');
  }

  void setBookmark(String? bookmark) {
    state = bookmark;
    if (bookmark == null) {
      ref.read(sharedPreferencesProvider).remove('syncFolderBookmark');
    } else {
      ref.read(sharedPreferencesProvider).setString('syncFolderBookmark', bookmark);
    }
  }
}

final syncFolderBookmarkProvider = NotifierProvider<SyncFolderBookmarkNotifier, String?>(
  () => SyncFolderBookmarkNotifier(),
);

class CustomLightTextColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customLightTextColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customLightTextColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customLightTextColor', color);
    }
  }
}

final customLightTextColorProvider = NotifierProvider<CustomLightTextColorNotifier, int?>(
  () => CustomLightTextColorNotifier(),
);

class CustomDarkTextColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customDarkTextColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customDarkTextColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customDarkTextColor', color);
    }
  }
}

final customDarkTextColorProvider = NotifierProvider<CustomDarkTextColorNotifier, int?>(
  () => CustomDarkTextColorNotifier(),
);

class CustomLightJesusWordsColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customLightJesusWordsColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customLightJesusWordsColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customLightJesusWordsColor', color);
    }
  }
}

final customLightJesusWordsColorProvider = NotifierProvider<CustomLightJesusWordsColorNotifier, int?>(
  () => CustomLightJesusWordsColorNotifier(),
);

class CustomDarkJesusWordsColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customDarkJesusWordsColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customDarkJesusWordsColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customDarkJesusWordsColor', color);
    }
  }
}

final customDarkJesusWordsColorProvider = NotifierProvider<CustomDarkJesusWordsColorNotifier, int?>(
  () => CustomDarkJesusWordsColorNotifier(),
);

class CustomLightSeedColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customLightSeedColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customLightSeedColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customLightSeedColor', color);
    }
  }
}

final customLightSeedColorProvider = NotifierProvider<CustomLightSeedColorNotifier, int?>(
  () => CustomLightSeedColorNotifier(),
);

class CustomDarkSeedColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customDarkSeedColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customDarkSeedColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customDarkSeedColor', color);
    }
  }
}

final customDarkSeedColorProvider = NotifierProvider<CustomDarkSeedColorNotifier, int?>(
  () => CustomDarkSeedColorNotifier(),
);

class CustomLightSurfaceColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customLightSurfaceColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customLightSurfaceColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customLightSurfaceColor', color);
    }
  }
}

final customLightSurfaceColorProvider = NotifierProvider<CustomLightSurfaceColorNotifier, int?>(
  () => CustomLightSurfaceColorNotifier(),
);

class CustomDarkSurfaceColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customDarkSurfaceColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customDarkSurfaceColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customDarkSurfaceColor', color);
    }
  }
}

final customDarkSurfaceColorProvider = NotifierProvider<CustomDarkSurfaceColorNotifier, int?>(
  () => CustomDarkSurfaceColorNotifier(),
);

class CustomLightAppBarColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customLightAppBarColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customLightAppBarColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customLightAppBarColor', color);
    }
  }
}

final customLightAppBarColorProvider = NotifierProvider<CustomLightAppBarColorNotifier, int?>(
  () => CustomLightAppBarColorNotifier(),
);

class CustomDarkAppBarColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('customDarkAppBarColor');
  }

  void setColor(int? color) {
    state = color;
    if (color == null) {
      ref.read(sharedPreferencesProvider).remove('customDarkAppBarColor');
    } else {
      ref.read(sharedPreferencesProvider).setInt('customDarkAppBarColor', color);
    }
  }
}

final customDarkAppBarColorProvider = NotifierProvider<CustomDarkAppBarColorNotifier, int?>(
  () => CustomDarkAppBarColorNotifier(),
);
