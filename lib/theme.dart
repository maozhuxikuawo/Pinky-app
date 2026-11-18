import 'package:material_ui/material_ui.dart';

const appBackground = Color(0xFFFFF9FB);

ThemeData buildTheme(Color seed) {
  final hsl = HSLColor.fromColor(seed);
  final primary = hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
  final tertiary = hsl.withHue((hsl.hue + 35) % 360).withLightness((hsl.lightness + 0.05).clamp(0.0, 1.0)).toColor();
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light, surface: Colors.white)
      .copyWith(primary: primary, onPrimary: Colors.white, tertiary: tertiary);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: appBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: appBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4A4A5A)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF6F3F7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: seed.withValues(alpha: 0.25),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}

const textDark = Color(0xFF4A4A5A);
const textGrey = Color(0xFF9A98A6);
