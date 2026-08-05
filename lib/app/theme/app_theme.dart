import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 应用亮色与暗色 Material 主题工厂。
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _gray1000,
      onPrimary: _gray0,
      secondary: _gray700,
      onSecondary: _gray0,
      error: _error,
      onError: _gray0,
      surface: _gray0,
      onSurface: _gray1000,
      primaryContainer: _gray100,
      onPrimaryContainer: _gray1000,
      secondaryContainer: _gray100,
      onSecondaryContainer: _gray1000,
      surfaceContainerLowest: _gray0,
      surfaceContainerLow: _gray25,
      surfaceContainer: _gray50,
      surfaceContainerHigh: _gray75,
      surfaceContainerHighest: _gray100,
      outline: _gray200,
      outlineVariant: _gray150,
      onSurfaceVariant: _gray550,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _gray1000,
      onInverseSurface: _gray0,
      inversePrimary: _gray0,
    );

    return _build(colorScheme);
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimary,
      onPrimary: _darkGray0,
      secondary: _darkSecondary,
      onSecondary: _darkGray0,
      error: _errorDark,
      onError: _darkGray0,
      surface: _darkGray0,
      onSurface: _darkOnSurface,
      primaryContainer: _darkGray300,
      onPrimaryContainer: _darkOnSurface,
      secondaryContainer: _darkGray250,
      onSecondaryContainer: _darkOnSurface,
      surfaceContainerLowest: _darkGray0,
      surfaceContainerLow: _darkGray25,
      surfaceContainer: _darkGray50,
      surfaceContainerHigh: _darkGray75,
      surfaceContainerHighest: _darkGray100,
      outline: _darkOutline,
      outlineVariant: _darkOutlineVariant,
      onSurfaceVariant: _darkOnSurfaceVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _gray0,
      onInverseSurface: _gray1000,
      inversePrimary: _gray1000,
    );

    return _build(colorScheme);
  }

  static ThemeData _build(ColorScheme colorScheme) {
    final textTheme = _textTheme(colorScheme);
    final softRadius = BorderRadius.circular(AppRadii.sm);
    final cardRadius = BorderRadius.circular(AppRadii.md);
    final modalRadius = BorderRadius.circular(AppRadii.pill);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    );
    const buttonMinimumSize = Size(64, 48);

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.7),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        toolbarHeight: 56,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) =>
            Icon(LucideIcons.chevronLeft, size: 28),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: modalRadius),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxl,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.pill),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: modalRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: softRadius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: softRadius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: softRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: softRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: softRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: softRadius,
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(
            alpha: 0.12,
          ),
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          minimumSize: buttonMinimumSize,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: softRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          minimumSize: buttonMinimumSize,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: softRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: buttonMinimumSize,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: softRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          minimumSize: const Size.square(AppSpacing.floatingControl),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurfaceVariant,
          selectedBackgroundColor: colorScheme.primaryContainer,
          selectedForegroundColor: colorScheme.onPrimaryContainer,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: softRadius),
          textStyle: textTheme.labelLarge,
          visualDensity: VisualDensity.standard,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        minVerticalPadding: AppSpacing.sm,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.page,
          vertical: AppSpacing.sm,
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        indicatorColor: colorScheme.surfaceContainerHighest,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
    );
  }

  /// Mobile-first type scale (phone-friendly hierarchy + reading sizes).
  static TextTheme _textTheme(ColorScheme colorScheme) {
    const base = TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        height: 44 / 40,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
      ),
      displayMedium: TextStyle(
        fontSize: 34,
        height: 40 / 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        height: 32 / 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );

    return base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
      fontFamily: 'Inter',
    );
  }
}

const _gray0 = Color(0xFFFFFFFF);
const _gray25 = Color(0xFFFCFCFC);
const _gray50 = Color(0xFFF9F9F9);
const _gray75 = Color(0xFFF3F3F3);
const _gray100 = Color(0xFFEDEDED);
const _gray150 = Color(0xFFDFDFDF);
const _gray200 = Color(0xFFC4C4C4);
const _gray550 = Color(0xFF4F4F4F);
const _gray700 = Color(0xFF303030);
const _gray1000 = Color(0xFF0D0D0D);

/// Dark surfaces: clearer elevation steps than near-black stacking.
const _darkGray0 = Color(0xFF121212);
const _darkGray25 = Color(0xFF161616);
const _darkGray50 = Color(0xFF1C1C1C);
const _darkGray75 = Color(0xFF222222);
const _darkGray100 = Color(0xFF2A2A2A);
const _darkGray250 = Color(0xFF333333);
const _darkGray300 = Color(0xFF3D3D3D);

const _darkPrimary = Color(0xFFF5F5F5);
const _darkSecondary = Color(0xFFBDBDBD);
const _darkOnSurface = Color(0xFFEDEDED);
const _darkOnSurfaceVariant = Color(0xFFB0B0B0);
const _darkOutline = Color(0xFF5A5A5A);
const _darkOutlineVariant = Color(0xFF3A3A3A);

const _error = Color(0xFFC7352A);
const _errorDark = Color(0xFFFFB4AB);
