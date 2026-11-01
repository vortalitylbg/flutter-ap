import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// US 2.4 : choix du mode clair / sombre.
//
// Le mode retenu est mémorisé sur l'appareil (shared_preferences) afin d'être
// réappliqué au lancement suivant de l'application. La valeur est exposée par
// un ValueNotifier : MyApp l'écoute pour reconstruire le thème, et l'écran des
// paramètres s'en sert pour afficher et modifier le choix courant.

class ThemeController {
  ThemeController._();

  /// Clé de mémorisation du mode dans les préférences de l'appareil.
  static const String _cle = 'mode_sombre';

  /// Mode courant de l'application (clair par défaut).
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  /// Vrai lorsque le mode sombre est sélectionné.
  static bool get sombre => mode.value == ThemeMode.dark;

  /// Relit le mode mémorisé. Appelée au démarrage, avant `runApp`.
  static Future<void> charger() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      mode.value = (prefs.getBool(_cle) ?? false)
          ? ThemeMode.dark
          : ThemeMode.light;
    } catch (_) {
      // Préférences illisibles : on reste sur le mode clair, l'application
      // doit pouvoir démarrer malgré tout.
      mode.value = ThemeMode.light;
    }
  }

  /// Applique le mode et le mémorise pour le prochain lancement.
  static Future<void> definirSombre(bool sombre) async {
    mode.value = sombre ? ThemeMode.dark : ThemeMode.light;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cle, sombre);
    } catch (_) {
      // L'échec d'écriture ne doit pas empêcher le changement de thème
      // pendant la session en cours.
    }
  }
}
