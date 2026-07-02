import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/highlight_palette.dart';

class AppThemes {
  static ThemeData buildTheme({
    required Brightness brightness,
    required String themeScheme,
    required String? fontFamily,
    required double fontSizeDelta,
    FontWeight textWeight = FontWeight.w400,
    Color? customTextColor,
    Color? customJesusWordsColor,
    Color? customSeedColor,
    Color? customSurfaceColor,
    Color? customAppBarColor,
    Map<String, Color>? highlightColors,
  }) {
    Color seedColor;
    ColorScheme? customColorScheme;

    switch (themeScheme) {
      case 'softIndiglow':
        seedColor = const Color(0xFF5C6BC0);
        if (brightness == Brightness.dark) {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFF1E1E2C),
          );
        } else {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFFF8F9FF),
          );
        }
        break;
      case 'modernIndigo':
        seedColor = const Color(0xFF4F46E5);
        if (brightness == Brightness.dark) {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFF1E1B2E),
          );
        } else {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFFF7F8FA),
          );
        }
        break;
      case 'quietSage':
        seedColor = const Color(0xFF0E7C66);
        if (brightness == Brightness.dark) {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFF1F2A26),
          );
        } else {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFFF8F9F6),
          );
        }
        break;
      case 'onyx':
        seedColor = const Color(0xFF5FD0C5);
        if (brightness == Brightness.dark) {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFF15171C),
          );
        } else {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFFF4F5F7), // Neutral light equivalent
          );
        }
        break;
      case 'ocean':
        seedColor = const Color(0xFF0EA5E9);
        if (brightness == Brightness.dark) {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFF09111C),
          );
        } else {
          customColorScheme = ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
            surface: const Color(0xFFF0F6FA), // Light blue-tinted equivalent
          );
        }
        break;
      case 'custom':
        seedColor = customSeedColor ?? const Color(0xFF6750A4);
        customColorScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
          surface: customSurfaceColor,
        );
        break;
      case 'default':
      default:
        seedColor = brightness == Brightness.light
            ? const Color(0xFF6750A4)
            : const Color(0xFFD0BCFF);
        break;
    }

    var colorScheme = customColorScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        );

    if (customAppBarColor != null && themeScheme == 'custom') {
      colorScheme = colorScheme.copyWith(
        primaryContainer: customAppBarColor,
      );
    }

    final typography = Typography.material2021(
      platform: defaultTargetPlatform,
    );
    var colorTextTheme = brightness == Brightness.light
        ? typography.black
        : typography.white.apply(
            bodyColor: const Color(0xFFD4D4D8), // Muted off-white for body text
            displayColor: const Color(0xFFE4E4E7), // Slightly brighter for headings
          );

    colorTextTheme = colorTextTheme.apply(
      bodyColor: customTextColor,
      displayColor: colorScheme.primary,
    );

    var textTheme = typography.englishLike
        .apply(fontSizeDelta: fontSizeDelta)
        .merge(colorTextTheme);

    final String? actualFontFamily =
        (fontFamily == null || fontFamily == 'System Default')
            ? null
            : fontFamily;

    if (actualFontFamily != null) {
      // The family is bundled and registered in pubspec (see the `fonts:`
      // section); applying it by name uses the local font with no network
      // fetch. Flutter resolves the nearest bundled weight per text style.
      textTheme = textTheme.apply(fontFamily: actualFontFamily);
    }

    // Raise every text style to at least [textWeight] (the "Text Weight"
    // accessibility setting). Applied as a floor so already-bold styles keep
    // their emphasis; at the default w400 this is a no-op.
    if (textWeight.value > FontWeight.w400.value) {
      textTheme = _applyMinWeight(textTheme, textWeight);
    }

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      // A consistent fade-through page transition on every platform, so pushing
      // screens (settings, sermons, journals, reading-plan generator) animates
      // the same way everywhere instead of defaulting to each OS's stock route
      // animation (or none on desktop/web).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      extensions: [
        CustomAppColors(
          jesusWordsColor: customJesusWordsColor,
        ),
        HighlightColors(
          highlightColors ?? _defaultHighlightColors(brightness),
        ),
      ],
    );
  }

  static Map<String, Color> _defaultHighlightColors(Brightness brightness) {
    final argb = resolveHighlightColors(
      dark: brightness == Brightness.dark,
      overrides: const {},
    );
    return {for (final e in argb.entries) e.key: Color(e.value)};
  }

  /// Returns [style] with its weight raised to at least [floor], leaving styles
  /// that are already heavier (e.g. bold headings) untouched.
  static TextStyle? _atLeast(TextStyle? style, FontWeight floor) {
    if (style == null) return null;
    final current = style.fontWeight ?? FontWeight.w400;
    return current.value >= floor.value
        ? style
        : style.copyWith(fontWeight: floor);
  }

  /// Applies [floor] as a minimum weight across every style in [t].
  static TextTheme _applyMinWeight(TextTheme t, FontWeight floor) => t.copyWith(
        displayLarge: _atLeast(t.displayLarge, floor),
        displayMedium: _atLeast(t.displayMedium, floor),
        displaySmall: _atLeast(t.displaySmall, floor),
        headlineLarge: _atLeast(t.headlineLarge, floor),
        headlineMedium: _atLeast(t.headlineMedium, floor),
        headlineSmall: _atLeast(t.headlineSmall, floor),
        titleLarge: _atLeast(t.titleLarge, floor),
        titleMedium: _atLeast(t.titleMedium, floor),
        titleSmall: _atLeast(t.titleSmall, floor),
        bodyLarge: _atLeast(t.bodyLarge, floor),
        bodyMedium: _atLeast(t.bodyMedium, floor),
        bodySmall: _atLeast(t.bodySmall, floor),
        labelLarge: _atLeast(t.labelLarge, floor),
        labelMedium: _atLeast(t.labelMedium, floor),
        labelSmall: _atLeast(t.labelSmall, floor),
      );
}

/// The resolved highlight-slot colours for the active theme: `slotId -> Color`,
/// already merged from per-mode defaults and any user overrides.
class HighlightColors extends ThemeExtension<HighlightColors> {
  final Map<String, Color> bySlot;

  const HighlightColors(this.bySlot);

  /// The colour for [slotId], or null when the slot is unknown.
  Color? forSlotId(String? slotId) => slotId == null ? null : bySlot[slotId];

  @override
  ThemeExtension<HighlightColors> copyWith({Map<String, Color>? bySlot}) =>
      HighlightColors(bySlot ?? this.bySlot);

  @override
  ThemeExtension<HighlightColors> lerp(
    ThemeExtension<HighlightColors>? other,
    double t,
  ) {
    if (other is! HighlightColors) return this;
    final keys = {...bySlot.keys, ...other.bySlot.keys};
    return HighlightColors({
      for (final k in keys)
        k: Color.lerp(bySlot[k], other.bySlot[k], t) ??
            bySlot[k] ??
            other.bySlot[k]!,
    });
  }
}

/// The colour a stored highlight `colorHex` should render as in the current
/// theme: the user-tuned slot colour when known, falling back to parsing the
/// (canonicalised) hex directly for anything the theme doesn't map.
Color resolveHighlightDisplayColor(BuildContext context, String storedHex) {
  final themed = Theme.of(context)
      .extension<HighlightColors>()
      ?.forSlotId(slotIdForHex(storedHex));
  if (themed != null) return themed;
  return Color(
    int.parse(canonicalHighlightHex(storedHex).replaceFirst('#', '0xFF')),
  );
}

class CustomAppColors extends ThemeExtension<CustomAppColors> {
  final Color? jesusWordsColor;

  const CustomAppColors({this.jesusWordsColor});

  @override
  ThemeExtension<CustomAppColors> copyWith({Color? jesusWordsColor}) {
    return CustomAppColors(
      jesusWordsColor: jesusWordsColor ?? this.jesusWordsColor,
    );
  }

  @override
  ThemeExtension<CustomAppColors> lerp(ThemeExtension<CustomAppColors>? other, double t) {
    if (other is! CustomAppColors) {
      return this;
    }
    return CustomAppColors(
      jesusWordsColor: Color.lerp(jesusWordsColor, other.jesusWordsColor, t),
    );
  }
}
