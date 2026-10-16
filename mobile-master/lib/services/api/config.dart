//Classe pour la configuration de l'application (adresses de l'API et lecture du fichier .env.dev.json 
//présent dans assets car Flutter ne sait pas lire les fichiers .env directement)

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  // Valeurs de repli utilisées tant que load() n'a pas été exécuté.
  // Elles évitent une LateInitializationError si un écran lit la
  // configuration avant la fin du chargement (tests, ouverture rapide).
  static String apiBaseUrl = 'http://localhost:8000/api';
  static String appVersion = '1.0.0';

  // Méthode pour lire la configuration depuis le fichier .env
  static Future<void> load() async {
    //CHANGER ICI POUR Utiliser le fichier .env.prod.json et donc passer EN PRODUCTION
    // final jsonString = await rootBundle.loadString('assets/env.prod.json');
    final jsonString = await rootBundle.loadString('assets/env.dev.json');
    final Map<String, dynamic> config = jsonDecode(jsonString);

    final String? parsedWeb = config['API_URL_WEB']?.toString();
    final String? parsedAndroid = config['API_URL_ANDROID']?.toString();
    final String? parsedIos = config['API_URL_IOS']?.toString();
    final String? parsedDesktop = config['API_URL_DESKTOP']?.toString();

    if (kIsWeb) {
      apiBaseUrl = (parsedWeb?.isNotEmpty ?? false) ? parsedWeb! : apiBaseUrl;
    } else if (Platform.isAndroid) {
      apiBaseUrl = (parsedAndroid?.isNotEmpty ?? false) ? parsedAndroid! : apiBaseUrl;
    } else if (Platform.isIOS) {
      apiBaseUrl = (parsedIos?.isNotEmpty ?? false) ? parsedIos! : apiBaseUrl;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      apiBaseUrl = (parsedDesktop?.isNotEmpty ?? false)
          ? parsedDesktop!
          : (parsedWeb?.isNotEmpty ?? false)
              ? parsedWeb!
              : apiBaseUrl;
    } else {
      apiBaseUrl = (parsedWeb?.isNotEmpty ?? false) ? parsedWeb! : apiBaseUrl;
    }

    appVersion = config['APP_VERSION'] ?? appVersion;
  }
}
