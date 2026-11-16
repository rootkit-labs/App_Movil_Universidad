import 'package:material_ui/material_ui.dart';

const Color kSeedColor = Color(0xFF4F46E5);

const List<int> kSubjectPalette = <int>[
  0xFF4F46E5,
  0xFF0EA5E9,
  0xFF10B981,
  0xFFF59E0B,
  0xFFEF4444,
  0xFFEC4899,
  0xFF8B5CF6,
  0xFF14B8A6,
];

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: brightness == Brightness.light
        ? const Color(0xFFF6F6FB)
        : null,
    appBarTheme: AppBarThemeData(
      centerTitle: false,
      backgroundColor: brightness == Brightness.light
          ? const Color(0xFFF6F6FB)
          : null,
      scrolledUnderElevation: 0,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: Color(0x14000000)),
      ),
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      filled: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    ),
  );
}
