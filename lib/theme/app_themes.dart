import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData buildTheme({
    required Brightness brightness,
    required String themeScheme,
    required String? fontFamily,
    required double fontSizeDelta,
    Color? customTextColor,
    Color? customJesusWordsColor,
    Color? customSeedColor,
    Color? customSurfaceColor,
    Color? customAppBarColor,
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

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      extensions: [
        CustomAppColors(
          jesusWordsColor: customJesusWordsColor,
        ),
      ],
    );
  }
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
