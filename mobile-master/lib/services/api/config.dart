//Classe pour la configuration de l'application (adresses de l'API et lecture du fichier .env.dev.json 
//présent dans assets car Flutter ne sait pas lire les fichiers .env directement)

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  static late final String apiBaseUrl;
  static late final String appVersion;

  // Méthode pour lire la configuration depuis le fichier .env
  static Future<void> load() async {
    //CHANGER ICI POUR Utiliser le fichier .env.prod.json et donc passer EN PRODUCTION
    // final jsonString = await rootBundle.loadString('assets/env.prod.json');
    final jsonString = await rootBundle.loadString('assets/env.dev.json');
    final Map<String, dynamic> config = jsonDecode(jsonString);

    if (kIsWeb) {
      apiBaseUrl = config['API_URL_WEB'];
    } else if (Platform.isAndroid) {
      apiBaseUrl = config['API_URL_ANDROID'];
    } else if (Platform.isIOS) {
      apiBaseUrl = config['API_URL_IOS'];
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      apiBaseUrl = config['API_URL_DESKTOP'] ?? config['API_URL_WEB'];
    } else {
      apiBaseUrl = config['API_URL_WEB'] ?? 'http://localhost:8000/api';
    }

    appVersion = config['APP_VERSION'] ?? '1.0.0';
  }
}
