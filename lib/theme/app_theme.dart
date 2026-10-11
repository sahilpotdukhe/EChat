import 'package:echat/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// Styles the plain Material widgets EChat still uses — app bars, the bottom
/// navigation bar / side rail, the "New chat" button, and dialogs or snack
/// bars on screens not yet moved to shadcn — from the shared shadcn theme, so
/// they match the shadcn components. Plugged into
/// `ShadcnApp.materialThemeBuilder`.
class AppTheme {
  static ThemeData get light => build(
        ThemeData(brightness: Brightness.light, extensions: [AppColors.shadcnLight]),
        AppColors.shadcnLight,
      );
  static ThemeData get dark => build(
        ThemeData(brightness: Brightness.dark, extensions: [AppColors.shadcnDark]),
        AppColors.shadcnDark,
      );

  static ThemeData build(ThemeData base, ShadcnTheme t) {
    final brightness = base.brightness;
    final extras = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: t.primary,
      brightness: brightness,
    ).copyWith(
      primary: t.primary,
      onPrimary: t.primaryForeground,
      surface: t.card,
      onSurface: t.foreground,
      onSurfaceVariant: t.mutedForeground,
      outline: t.border,
      outlineVariant: t.border,
      error: t.destructive,
    );

    // Flutter's defaults (font family, sizes) recolored with shadcn tokens,
    // for Material widgets that read the text theme (app bar titles etc.).
    final defaults = ThemeData(brightness: brightness, useMaterial3: true)
        .textTheme
        .apply(bodyColor: t.foreground, displayColor: t.foreground);
    // copyWith on the default style keeps its font family.
    final text = defaults.copyWith(
      titleLarge: defaults.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
    );
    final labelStyle = TextStyle(fontSize: 12, color: t.mutedForeground);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      pageTransitionsTheme: base.pageTransitionsTheme,
      scaffoldBackgroundColor: t.background,
      textTheme: text,
      extensions: [t, extras],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      // Inputs are ShadcnInput and buttons ShadcnButton, both styled by the
      // shadcn theme, so there are no input or button themes here.
      dialogTheme: DialogThemeData(
        backgroundColor: t.popover,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusXl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: TextStyle(fontSize: 14, color: t.mutedForeground),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.foreground,
        contentTextStyle: TextStyle(fontSize: 14, color: t.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusLg)),
      ),
      cardTheme: CardThemeData(
        color: t.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          side: BorderSide(color: t.border),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.primary,
        foregroundColor: t.primaryForeground,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusXl)),
        extendedTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: t.accent,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? t.primary : t.mutedForeground,
              size: 24,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => labelStyle.copyWith(
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? t.primary : t.mutedForeground,
            )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: t.card,
        indicatorColor: t.accent,
        selectedIconTheme: IconThemeData(color: t.primary),
        unselectedIconTheme: IconThemeData(color: t.mutedForeground),
        selectedLabelTextStyle: labelStyle.copyWith(fontWeight: FontWeight.w700, color: t.primary),
        unselectedLabelTextStyle: labelStyle.copyWith(fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.primary),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(t.radiusXl + 8)),
        ),
      ),
    );
  }
}
