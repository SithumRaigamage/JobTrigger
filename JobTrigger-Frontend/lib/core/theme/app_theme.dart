import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Light/dark `ThemeData` for the P14 redesign (`UI-UX/README.md`).
///
/// One accent for the whole app ([AppColors.accent]) instead of re-seeding
/// from the active CI tool's brand colour (P14 decision 4). The scheme is
/// still generated with `ColorScheme.fromSeed` for the slots nothing here
/// sets, but every slot a screen visibly paints — primary, surfaces, text,
/// outlines, error — is pinned to a measured token, and the component
/// themes below give buttons, inputs, sheets and the nav bar the
/// redesign's shapes so screens don't restyle them one by one.
///
/// `primary` is pinned to the accent in both themes with white on it
/// (5.2:1). The rule from AUD-62 still holds: anything painting on a
/// `primary` background uses `onPrimary`, never a literal white.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppTokens.light);

  static ThemeData dark() => _build(Brightness.dark, AppTokens.dark);

  static ThemeData _build(Brightness brightness, AppTokens t) {
    final isDark = brightness == Brightness.dark;
    // Links and text buttons: the accent itself on light (5.2:1 on white),
    // a lighter blue on dark where the accent would sit at 4.0:1.
    final link = isDark ? const Color(0xFF93C5FD) : AppColors.accent;
    final focus = isDark ? const Color(0xFF60A5FA) : AppColors.accent;
    final outline = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.accent,
          onPrimary: Colors.white,
          surface: t.card,
          onSurface: t.text,
          onSurfaceVariant: t.textMuted,
          surfaceContainerLowest: t.background,
          surfaceContainerLow: t.card,
          surfaceContainer: t.card,
          surfaceContainerHigh: t.raised,
          surfaceContainerHighest: t.raised,
          outline: outline,
          outlineVariant: t.cardBorder,
          error: t.failure.foreground,
          errorContainer: t.failure.background,
          onErrorContainer: t.failure.foreground,
          surfaceTint: Colors.transparent,
        );

    final text = AppTypography.textTheme(t);
    const fieldRadius = BorderRadius.all(Radius.circular(12));
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.sans,
      textTheme: text,
      scaffoldBackgroundColor: t.background,
      canvasColor: t.background,
      dividerColor: t.cardBorder,
      extensions: [t],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: t.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium?.copyWith(fontSize: 17),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: buttonShape,
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.raised,
          foregroundColor: t.text,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.text,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: t.cardBorder),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: link,
          minimumSize: const Size(44, 44),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: t.textSecondary,
          minimumSize: const Size(44, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: t.textMuted),
        labelStyle: text.bodyMedium?.copyWith(color: t.textSecondary),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: focus),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: t.failure.foreground),
        prefixIconColor: t.textMuted,
        suffixIconColor: t.textMuted,
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: t.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: t.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: focus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: t.failure.dot),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: t.failure.dot, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.chrome,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.accent,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : t.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? t.text : t.textMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: t.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: t.cardBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          side: BorderSide(color: t.cardBorder),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: t.textMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0xB8020617),
        dragHandleColor: outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : t.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : t.raised,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : outline,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? t.raised
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? t.text
                : t.textSecondary,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: t.cardBorder)),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.card,
        selectedColor: t.text,
        side: BorderSide(color: t.cardBorder),
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium?.copyWith(color: t.textSecondary),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: t.background),
        checkmarkColor: t.background,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.textSecondary,
        textColor: t.text,
        titleTextStyle: text.bodyLarge?.copyWith(fontSize: 15),
        subtitleTextStyle: text.bodySmall,
        minVerticalPadding: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      dividerTheme: DividerThemeData(
        color: t.cardBorder,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.running.dot,
        linearTrackColor: t.raised,
        circularTrackColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: t.cardBorder),
        ),
        textStyle: text.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.raised,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: text.bodySmall?.copyWith(color: t.text),
      ),
    );
  }
}
