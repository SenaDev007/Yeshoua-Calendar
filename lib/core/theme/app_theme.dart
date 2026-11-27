/// Thème global Horloge Céleste — clair, lumineux, premium (§10). Fond ivoire,
/// cartes blanches, bleu céleste en couleur principale, or solaire en
/// signature (aiguilles, Shabbats, repères du nouveau jour).
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ivoire,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.bleuCiel,
        onPrimary: AppColors.blanc,
        secondary: AppColors.orSolaire,
        onSecondary: AppColors.ardoise,
        surface: AppColors.blanc,
        onSurface: AppColors.ardoise,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blanc,
        foregroundColor: AppColors.ardoise,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ardoise,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.blanc,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.ardoisePastel.withValues(alpha: 0.6)),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.blanc,
        indicatorColor: AppColors.bleuCielPastel,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.bleuCiel
                  : AppColors.grisSecondaire,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11.5,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? AppColors.bleuCiel
                  : AppColors.grisSecondaire,
            )),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.ardoisePastel.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.blanc
                : AppColors.blanc),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.bleuCiel
                : AppColors.ardoisePastel),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.bleuCiel,
          foregroundColor: AppColors.blanc,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.bleuCiel,
          side: const BorderSide(color: AppColors.bleuCiel),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanc,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.ardoisePastel),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.ardoisePastel),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bleuCiel, width: 1.6),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ardoise,
        contentTextStyle: TextStyle(color: AppColors.blanc),
      ),
    );
  }
}
