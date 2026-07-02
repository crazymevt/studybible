import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/scripture/verse_share_format.dart';
import 'highlight_palette.dart';
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
  places,
  highlights,
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

enum JournalsActiveTab {
  journals,
  prayers,
  actions,
}

class JournalsActiveTabNotifier extends Notifier<JournalsActiveTab> {
  @override
  JournalsActiveTab build() => JournalsActiveTab.journals;

  void setTab(JournalsActiveTab tab) {
    state = tab;
  }
}

final journalsActiveTabProvider =
    NotifierProvider<JournalsActiveTabNotifier, JournalsActiveTab>(
  () => JournalsActiveTabNotifier(),
);

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

/// The module the app launches into. Limited to the modules that make sense as
/// a landing page: the reader, the dashboard, or journals & prayers.
const startupModuleChoices = [
  AppModule.reader,
  AppModule.dashboard,
  AppModule.journalsPrayers,
];

class StartupModuleNotifier extends Notifier<AppModule> {
  @override
  AppModule build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString('startupModule');
    if (stored != null) {
      for (final module in startupModuleChoices) {
        if (module.name == stored) return module;
      }
    }
    // Migrate from the legacy boolean preference.
    final legacyDashboard = prefs.getBool('showDashboardOnStart') ?? false;
    return legacyDashboard ? AppModule.dashboard : AppModule.reader;
  }

  void set(AppModule module) {
    state = module;
    ref.read(sharedPreferencesProvider).setString('startupModule', module.name);
  }
}

final startupModuleProvider =
    NotifierProvider<StartupModuleNotifier, AppModule>(
      () => StartupModuleNotifier(),
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

/// The minimum weight applied to all app text, as a [FontWeight] value
/// (400 = regular … 700 = bold). A legibility aid for readers who find the
/// regular weight too faint: unlike a color change, weight visibly increases
/// the perceived darkness of near-black light-mode text. Applied as a floor,
/// so text that is already heavier than this is left untouched. Defaults to
/// 400 (no change).
class AppTextWeightNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('appTextWeight') ?? 400;
  }

  void set(int value) {
    state = value;
    ref.read(sharedPreferencesProvider).setInt('appTextWeight', value);
  }
}

final appTextWeightProvider = NotifierProvider<AppTextWeightNotifier, int>(
  () => AppTextWeightNotifier(),
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

/// The day the "this week" window starts on for the dashboard's reading-time
/// and chapters-this-week stats. Stored as a [DateTime.weekday] value
/// (1 = Monday … 7 = Sunday); defaults to Monday, matching the original
/// hard-coded behaviour.
class WeekStartDayNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getInt('weekStartDay');
    if (stored != null && stored >= DateTime.monday && stored <= DateTime.sunday) {
      return stored;
    }
    return DateTime.monday;
  }

  void set(int weekday) {
    state = weekday;
    ref.read(sharedPreferencesProvider).setInt('weekStartDay', weekday);
  }
}

final weekStartDayProvider = NotifierProvider<WeekStartDayNotifier, int>(
  () => WeekStartDayNotifier(),
);

/// Number of days to subtract from [day] to reach the most recent occurrence of
/// [firstWeekday] (inclusive), using the [DateTime.weekday] convention.
DateTime startOfWeekFor(DateTime day, int firstWeekday) {
  final offset = (day.weekday - firstWeekday) % 7;
  return day.subtract(Duration(days: offset));
}

class AppModuleNotifier extends Notifier<AppModule> {
  @override
  AppModule build() {
    return ref.watch(startupModuleProvider);
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

/// Whether sync should use the user's Google Drive (hidden app-data folder)
/// instead of a local/SAF folder. When true, [SyncService] builds a Drive-backed
/// storage from the connected account.
class GoogleDriveEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('googleDriveEnabled') ?? false;
  }

  void setEnabled(bool enabled) {
    state = enabled;
    ref.read(sharedPreferencesProvider).setBool('googleDriveEnabled', enabled);
  }
}

final googleDriveEnabledProvider =
    NotifierProvider<GoogleDriveEnabledNotifier, bool>(
  () => GoogleDriveEnabledNotifier(),
);

/// The connected Google account email, kept only for display in settings.
class GoogleDriveAccountNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('googleDriveAccount');
  }

  void setAccount(String? email) {
    state = email;
    if (email == null) {
      ref.read(sharedPreferencesProvider).remove('googleDriveAccount');
    } else {
      ref.read(sharedPreferencesProvider).setString('googleDriveAccount', email);
    }
  }
}

final googleDriveAccountProvider =
    NotifierProvider<GoogleDriveAccountNotifier, String?>(
  () => GoogleDriveAccountNotifier(),
);

/// Default background colour for the action-due reminder banner — a noticeable
/// yellow. Used when the user hasn't picked a custom colour.
const int kDefaultActionBannerColor = 0xFFFFEB3B;

/// User-chosen background colour (ARGB int) for the action-due reminder banner,
/// or null to use [kDefaultActionBannerColor].
class ActionBannerColorNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('actionBannerColor');
  }

  void setColor(int? color) {
    state = color;
    final prefs = ref.read(sharedPreferencesProvider);
    if (color == null) {
      prefs.remove('actionBannerColor');
    } else {
      prefs.setInt('actionBannerColor', color);
    }
  }
}

final actionBannerColorProvider =
    NotifierProvider<ActionBannerColorNotifier, int?>(
  () => ActionBannerColorNotifier(),
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

/// User overrides for the highlight-colour slots, keyed `'<slotId>_light'` /
/// `'<slotId>_dark'` -> ARGB int. Absent keys fall back to the built-in default
/// for that slot and mode (see [resolveHighlightColors]). Each override is
/// persisted under its own `highlightColor_<slot>_<mode>` pref so a slot's light
/// and dark colours are independent.
class HighlightColorOverridesNotifier extends Notifier<Map<String, int>> {
  static String _key(String slotId, String mode) =>
      'highlightColor_${slotId}_$mode';

  @override
  Map<String, int> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final map = <String, int>{};
    for (final slot in highlightSlots) {
      for (final mode in const ['light', 'dark']) {
        final value = prefs.getInt(_key(slot.id, mode));
        if (value != null) map['${slot.id}_$mode'] = value;
      }
    }
    return map;
  }

  /// Sets (or clears, when [argb] is null) the override for [slotId] in [mode]
  /// (`'light'` or `'dark'`).
  void setOverride(String slotId, String mode, int? argb) {
    final prefs = ref.read(sharedPreferencesProvider);
    final prefKey = _key(slotId, mode);
    final mapKey = '${slotId}_$mode';
    final next = {...state};
    if (argb == null) {
      prefs.remove(prefKey);
      next.remove(mapKey);
    } else {
      prefs.setInt(prefKey, argb);
      next[mapKey] = argb;
    }
    state = next;
  }

  /// Clears every override, restoring all slots to their built-in defaults.
  void resetAll() {
    final prefs = ref.read(sharedPreferencesProvider);
    for (final slot in highlightSlots) {
      for (final mode in const ['light', 'dark']) {
        prefs.remove(_key(slot.id, mode));
      }
    }
    state = {};
  }
}

final highlightColorOverridesProvider =
    NotifierProvider<HighlightColorOverridesNotifier, Map<String, int>>(
  () => HighlightColorOverridesNotifier(),
);

/// How selected verses are rendered when copied or shared. Backed by three
/// SharedPreferences keys so each toggle is independently persisted; exposed as
/// a single immutable [VerseShareFormat] the verse action bar and settings read.
class VerseShareFormatNotifier extends Notifier<VerseShareFormat> {
  static const _numbersKey = 'shareIncludeVerseNumbers';
  static const _versionKey = 'shareIncludeVersionAbbreviation';
  static const _positionKey = 'shareReferencePosition';

  @override
  VerseShareFormat build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return VerseShareFormat(
      includeVerseNumbers: prefs.getBool(_numbersKey) ?? true,
      includeVersionAbbreviation: prefs.getBool(_versionKey) ?? false,
      referencePosition:
          VerseReferencePosition.fromName(prefs.getString(_positionKey)),
    );
  }

  void setIncludeVerseNumbers(bool value) {
    state = state.copyWith(includeVerseNumbers: value);
    ref.read(sharedPreferencesProvider).setBool(_numbersKey, value);
  }

  void setIncludeVersionAbbreviation(bool value) {
    state = state.copyWith(includeVersionAbbreviation: value);
    ref.read(sharedPreferencesProvider).setBool(_versionKey, value);
  }

  void setReferencePosition(VerseReferencePosition position) {
    state = state.copyWith(referencePosition: position);
    ref.read(sharedPreferencesProvider).setString(_positionKey, position.name);
  }
}

final verseShareFormatProvider =
    NotifierProvider<VerseShareFormatNotifier, VerseShareFormat>(
  () => VerseShareFormatNotifier(),
);
