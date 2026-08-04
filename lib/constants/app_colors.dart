import 'package:flutter/material.dart';

/// Visual language of the app: a night-flight instrument panel.
///
/// Matte black panel ground, luminous white markings, radium-green live
/// values. Amber and red are reserved for caution and failure states only —
/// the same discipline a six-pack of flight instruments follows.
abstract final class AppColors {
  // Grounds
  static const Color panel = Color(0xFF0A0D11);
  static const Color surface = Color(0xFF10151B);
  static const Color surfaceRaised = Color(0xFF161D25);
  static const Color input = Color(0xFF0D1217);

  // Hairs & hairlines
  static const Color hairline = Color(0xFF232C37);
  static const Color hairlineBright = Color(0xFF313D4B);

  // Markings
  static const Color luminous = Color(0xFFEAF1ED);
  static const Color dim = Color(0xFF8A96A2);
  static const Color faint = Color(0xFF5C6774);

  // Lamps
  static const Color radium = Color(0xFF46E39A);
  static const Color radiumDeep = Color(0xFF0A2418);
  static const Color radiumSoft = Color(0x2646E39A); // 15% radium
  static const Color amber = Color(0xFFF0B429);
  static const Color amberSoft = Color(0x26F0B429);
  static const Color red = Color(0xFFF0506E);
  static const Color redSoft = Color(0x26F0506E);
  static const Color blue = Color(0xFF6FA8DC);
  static const Color blueSoft = Color(0x266FA8DC);

  /// Material 3 dark scheme resolved from the instrument world.
  static const ColorScheme scheme = ColorScheme.dark(
    primary: radium,
    onPrimary: radiumDeep,
    secondary: blue,
    onSecondary: Color(0xFF061120),
    tertiary: amber,
    onTertiary: Color(0xFF241A02),
    error: red,
    onError: Color(0xFF2B0A12),
    surface: surface,
    onSurface: luminous,
    surfaceContainerLowest: panel,
    surfaceContainerLow: surface,
    surfaceContainer: Color(0xFF141A22),
    surfaceContainerHigh: Color(0xFF182029),
    surfaceContainerHighest: Color(0xFF1D2630),
    onSurfaceVariant: dim,
    outline: hairlineBright,
    outlineVariant: hairline,
    scrim: Color(0x99090C10),
  );

  /// Color a status lamp takes on.
  static Color forStatus(WidgetStatus status) => switch (status) {
        WidgetStatus.completed => radium,
        WidgetStatus.pending => amber,
        WidgetStatus.failed => red,
        WidgetStatus.info => blue,
        WidgetStatus.idle => faint,
      };
}

/// Semantic statuses shared by badges, lamps and tiles.
enum WidgetStatus { completed, pending, failed, info, idle }
