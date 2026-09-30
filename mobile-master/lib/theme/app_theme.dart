import 'package:flutter/material.dart';

// Charte graphique de l'application SoundBox Studio.
//
// Les couleurs de base sont reprises à l'identique de la page de connexion
// (lib/screens/screen_login/log_user.dart) afin de respecter la règle métier
// US 1.1.2 : la charte graphique doit être cohérente d'un écran à l'autre.
//
//   Fond d'écran .......... #f3f4f6
//   Couleur principale .... #344d59  (titres, boutons, barre d'application)
//   Couleur secondaire .... #7a90a4  (sous-titres, textes d'appui)
//   Couleur de texte ...... #1A1A1A  (contenu des champs de saisie)

/// Palette de couleurs de SoundBox Studio.
class AppColors {
  AppColors._();

  /// Fond d'écran, identique à celui de la page de connexion.
  static const Color fond = Color(0xFFf3f4f6);

  /// Couleur principale de la charte (bleu ardoise).
  static const Color principal = Color(0xFF344d59);

  /// Teinte plus claire dérivée de [principal], utilisée dans les dégradés.
  static const Color principalClair = Color(0xFF4a6b7a);

  /// Voile très clair dérivé de [principal], utilisé comme fond de carte.
  static const Color principalVoile = Color(0xFFE7ECEF);

  /// Couleur secondaire : sous-titres, légendes, textes d'appui.
  static const Color secondaire = Color(0xFF7a90a4);

  /// Couleur du texte courant.
  static const Color texte = Color(0xFF1A1A1A);

  /// Bordures fines et séparateurs.
  static const Color bordure = Color(0xFFDCE1E5);

  /// Blanc pur, utilisé sur les aplats de couleur principale.
  static const Color blanc = Color(0xFFFFFFFF);

  /// Dégradé principal, du bleu ardoise vers sa teinte claire.
  static const List<Color> degradePrincipal = <Color>[
    Color(0xFF344d59),
    Color(0xFF4a6b7a),
  ];

  // ---------------------------------------------------------------------------
  // US 1.3 : code couleur de l'état d'enregistrement du client sur un rendez-vous.
  // Un client enregistré (identité renseignée) et un client non enregistré
  // (aucune identité) doivent être distingués à la fois par la couleur et par
  // la graisse de la police.
  // ---------------------------------------------------------------------------

  /// Texte et liseré d'une séance dont le client est enregistré.
  static const Color enregistreTexte = Color(0xFF1F6B4F);

  /// Fond d'une séance dont le client est enregistré.
  static const Color enregistreFond = Color(0xFFE2F1EA);

  /// Texte et liseré d'une séance dont le client n'est pas enregistré.
  static const Color nonEnregistreTexte = Color(0xFF9A4A1E);

  /// Fond d'une séance dont le client n'est pas enregistré.
  static const Color nonEnregistreFond = Color(0xFFFBEBE1);

  /// Semis interdit, utilisé par la validation du nom et du prénom (US 1.4.3).
  static final RegExp chiffres = RegExp(r'[0-9]');

  /// Format d'adresse email accepté par l'API (US 1.4.3).
  static final RegExp formatEmail = RegExp(
    r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$",
  );
}

/// Thème Material de l'application, construit à partir de [AppColors].
class AppTheme {
  AppTheme._();

  static const ColorScheme _palette = ColorScheme.light(
    primary: AppColors.principal,
    onPrimary: AppColors.blanc,
    primaryContainer: AppColors.principalVoile,
    onPrimaryContainer: AppColors.principal,
    secondary: AppColors.secondaire,
    onSecondary: AppColors.blanc,
    secondaryContainer: AppColors.principalVoile,
    onSecondaryContainer: AppColors.principal,
    surface: AppColors.blanc,
    onSurface: AppColors.texte,
    onSurfaceVariant: AppColors.secondaire,
    outline: AppColors.bordure,
    outlineVariant: AppColors.bordure,
    error: AppColors.nonEnregistreTexte,
    onError: AppColors.blanc,
  );

  /// Appliqué une seule fois sur le [MaterialApp] de `main.dart`.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _palette,
      scaffoldBackgroundColor: AppColors.fond,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fond,
        foregroundColor: AppColors.principal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.principal,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.blanc,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.bordure),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fond,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bordure),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bordure),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.principal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.nonEnregistreTexte),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.nonEnregistreTexte, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.secondaire),
        hintStyle: const TextStyle(color: AppColors.secondaire),
        prefixIconColor: AppColors.secondaire,
        suffixIconColor: AppColors.secondaire,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.principal,
          foregroundColor: AppColors.blanc,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.principal,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.principal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.principal,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.bordure,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.blanc,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.principalVoile,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> etats) => TextStyle(
            fontSize: 12,
            fontWeight: etats.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: etats.contains(WidgetState.selected)
                ? AppColors.principal
                : AppColors.secondaire,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> etats) => IconThemeData(
            color: etats.contains(WidgetState.selected)
                ? AppColors.principal
                : AppColors.secondaire,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.principal,
        contentTextStyle: TextStyle(
          color: AppColors.blanc,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.principal,
        foregroundColor: AppColors.blanc,
        elevation: 2,
      ),
    );
  }
}
