import 'package:flutter/material.dart';

// Charte graphique de l'application SoundBox Studio.
//
// US 2.4 : l'application propose un mode clair et un mode sombre. Les couleurs
// ne sont donc plus des constantes figées : [AppColors] expose des accesseurs
// qui renvoient la teinte du mode courant. Le mode est choisi par l'employé
// depuis les paramètres, mémorisé sur l'appareil (ThemeController) puis rappelé
// au lancement.
//
//   Fond d'écran .......... clair #f3f4f6   / sombre #10171b
//   Couleur principale .... clair #344d59   / sombre #8fb6c9
//   Couleur secondaire .... clair #7a90a4   / sombre #9cb0be
//   Couleur de texte ...... clair #1a1a1a   / sombre #e8edf1

/// Palette de couleurs de SoundBox Studio, résolue selon le mode courant.
class AppColors {
  AppColors._();

  /// Vrai lorsque le thème sombre est actif.
  static bool _sombre = false;

  /// Vrai lorsque le thème sombre est actif.
  static bool get estSombre => _sombre;

  /// Applique le mode indiqué à toute la palette.
  static void definirMode(bool sombre) {
    _sombre = sombre;
  }

  /// Synchronise la palette avec la luminosité du thème courant.
  ///
  /// À appeler en tête de `build()` des écrans : l'appel inscrit l'écran comme
  /// dépendant du [Theme] et provoque donc son redessin lorsqu'on change de
  /// mode (US 2.4).
  static void suivreTheme(BuildContext context) {
    _sombre = Theme.of(context).brightness == Brightness.dark;
  }

  // ---------------------------------------------------------------------------
  // Teintes du mode clair (charte d'origine)
  // ---------------------------------------------------------------------------

  static const Color _fondClair = Color(0xFFf3f4f6);
  static const Color _surfaceClaire = Color(0xFFFFFFFF);
  static const Color _principalClair = Color(0xFF344d59);
  static const Color _principalClairClair = Color(0xFF4a6b7a);
  static const Color _principalVoileClair = Color(0xFFE7ECEF);
  static const Color _secondaireClair = Color(0xFF7a90a4);
  static const Color _texteClair = Color(0xFF1A1A1A);
  static const Color _bordureClaire = Color(0xFFDCE1E5);
  static const Color _enregistreTexteClair = Color(0xFF1F6B4F);
  static const Color _enregistreFondClair = Color(0xFFE2F1EA);
  static const Color _nonEnregistreTexteClair = Color(0xFF9A4A1E);
  static const Color _nonEnregistreFondClair = Color(0xFFFBEBE1);

  // ---------------------------------------------------------------------------
  // Teintes du mode sombre
  // ---------------------------------------------------------------------------

  static const Color _fondSombre = Color(0xFF10171B);
  static const Color _surfaceSombre = Color(0xFF1A2329);
  static const Color _principalSombre = Color(0xFF8FB6C9);
  static const Color _principalClairSombre = Color(0xFF6E9CB0);
  static const Color _principalVoileSombre = Color(0xFF22313A);
  static const Color _secondaireSombre = Color(0xFF9CB0BE);
  static const Color _texteSombre = Color(0xFFE8EDF1);
  static const Color _bordureSombre = Color(0xFF2C3A43);
  static const Color _enregistreTexteSombre = Color(0xFF79D3A9);
  static const Color _enregistreFondSombre = Color(0xFF16302A);
  static const Color _nonEnregistreTexteSombre = Color(0xFFF0A87A);
  static const Color _nonEnregistreFondSombre = Color(0xFF33231A);

  /// Fond d'écran.
  static Color get fond => _sombre ? _fondSombre : _fondClair;

  /// Fond des cartes et des champs de saisie.
  static Color get surface => _sombre ? _surfaceSombre : _surfaceClaire;

  /// Couleur principale de la charte : titres, boutons, accents.
  static Color get principal => _sombre ? _principalSombre : _principalClair;

  /// Teinte plus claire dérivée de [principal], utilisée dans les dégradés.
  static Color get principalClair =>
      _sombre ? _principalClairSombre : _principalClairClair;

  /// Voile très clair dérivé de [principal], utilisé comme fond de carte.
  static Color get principalVoile =>
      _sombre ? _principalVoileSombre : _principalVoileClair;

  /// Couleur secondaire : sous-titres, légendes, textes d'appui.
  static Color get secondaire =>
      _sombre ? _secondaireSombre : _secondaireClair;

  /// Couleur du texte courant.
  static Color get texte => _sombre ? _texteSombre : _texteClair;

  /// Bordures fines et séparateurs.
  static Color get bordure => _sombre ? _bordureSombre : _bordureClaire;

  /// Texte et icônes posés sur un aplat [principal] (ou un badge coloré).
  static Color get surAccent => _sombre ? const Color(0xFF0E171C) : blanc;

  /// Blanc pur : texte sur les dégradés de marque et les fonds très foncés.
  static const Color blanc = Color(0xFFFFFFFF);

  /// Dégradé de marque (bannière, logo). Il reste sombre dans les deux modes
  /// afin que le texte blanc y demeure lisible.
  static List<Color> get degradePrincipal => const <Color>[
        Color(0xFF344d59),
        Color(0xFF4a6b7a),
      ];

  // ---------------------------------------------------------------------------
  // Code couleur de l'état d'enregistrement du client sur un rendez-vous
  // (US 1.3). Un client enregistré et un client non enregistré sont distingués
  // à la fois par la couleur et par la graisse de la police.
  // ---------------------------------------------------------------------------

  /// Texte et liseré d'une séance dont le client est enregistré.
  static Color get enregistreTexte =>
      _sombre ? _enregistreTexteSombre : _enregistreTexteClair;

  /// Fond d'une séance dont le client est enregistré.
  static Color get enregistreFond =>
      _sombre ? _enregistreFondSombre : _enregistreFondClair;

  /// Texte et liseré d'une séance dont le client n'est pas enregistré.
  static Color get nonEnregistreTexte =>
      _sombre ? _nonEnregistreTexteSombre : _nonEnregistreTexteClair;

  /// Fond d'une séance dont le client n'est pas enregistré.
  static Color get nonEnregistreFond =>
      _sombre ? _nonEnregistreFondSombre : _nonEnregistreFondClair;

  /// Semis interdit, utilisé par la validation du nom et du prénom (US 1.4.3).
  static final RegExp chiffres = RegExp(r'[0-9]');

  /// Format d'adresse email accepté par l'API (US 1.4.3).
  static final RegExp formatEmail = RegExp(
    r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$",
  );
}

/// Thème Material de l'application, décliné en clair et en sombre (US 2.4).
class AppTheme {
  AppTheme._();

  /// Thème clair, construit à partir de la palette d'origine.
  static ThemeData get light => _construire(
        brightness: Brightness.light,
        fond: AppColors._fondClair,
        surface: AppColors._surfaceClaire,
        principal: AppColors._principalClair,
        principalVoile: AppColors._principalVoileClair,
        secondaire: AppColors._secondaireClair,
        texte: AppColors._texteClair,
        bordure: AppColors._bordureClaire,
        surAccent: Colors.white,
        snackFond: AppColors._principalClair,
        snackTexte: Colors.white,
      );

  /// Thème sombre, appliqué lorsque l'employé l'a choisi dans les paramètres.
  static ThemeData get dark => _construire(
        brightness: Brightness.dark,
        fond: AppColors._fondSombre,
        surface: AppColors._surfaceSombre,
        principal: AppColors._principalSombre,
        principalVoile: AppColors._principalVoileSombre,
        secondaire: AppColors._secondaireSombre,
        texte: AppColors._texteSombre,
        bordure: AppColors._bordureSombre,
        surAccent: const Color(0xFF0E171C),
        snackFond: AppColors._surfaceSombre,
        snackTexte: AppColors._texteSombre,
      );

  /// Construit un thème à partir de la palette d'un mode.
  static ThemeData _construire({
    required Brightness brightness,
    required Color fond,
    required Color surface,
    required Color principal,
    required Color principalVoile,
    required Color secondaire,
    required Color texte,
    required Color bordure,
    required Color surAccent,
    required Color snackFond,
    required Color snackTexte,
  }) {
    final bool sombre = brightness == Brightness.dark;
    final ColorScheme palette = sombre
        ? ColorScheme.dark(
            primary: principal,
            onPrimary: surAccent,
            primaryContainer: principalVoile,
            onPrimaryContainer: texte,
            secondary: secondaire,
            onSecondary: surface,
            secondaryContainer: principalVoile,
            onSecondaryContainer: texte,
            surface: surface,
            onSurface: texte,
            onSurfaceVariant: secondaire,
            outline: bordure,
            outlineVariant: bordure,
            error: AppColors._nonEnregistreTexteSombre,
            onError: const Color(0xFF0E171C),
          )
        : ColorScheme.light(
            primary: principal,
            onPrimary: surAccent,
            primaryContainer: principalVoile,
            onPrimaryContainer: principal,
            secondary: secondaire,
            onSecondary: Colors.white,
            secondaryContainer: principalVoile,
            onSecondaryContainer: principal,
            surface: surface,
            onSurface: texte,
            onSurfaceVariant: secondaire,
            outline: bordure,
            outlineVariant: bordure,
            error: AppColors._nonEnregistreTexteClair,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: palette,
      scaffoldBackgroundColor: fond,
      appBarTheme: AppBarTheme(
        backgroundColor: fond,
        foregroundColor: principal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: principal,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: bordure),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fond,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bordure),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bordure),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: principal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error, width: 2),
        ),
        labelStyle: TextStyle(color: secondaire),
        hintStyle: TextStyle(color: secondaire),
        prefixIconColor: secondaire,
        suffixIconColor: secondaire,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: principal,
          foregroundColor: surAccent,
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
          foregroundColor: principal,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: principal, width: 1.5),
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
          foregroundColor: principal,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: bordure,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: principalVoile,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> etats) => TextStyle(
            fontSize: 12,
            fontWeight: etats.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: etats.contains(WidgetState.selected) ? principal : secondaire,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> etats) => IconThemeData(
            color: etats.contains(WidgetState.selected) ? principal : secondaire,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackFond,
        contentTextStyle: TextStyle(
          color: snackTexte,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: principal,
        foregroundColor: surAccent,
        elevation: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
