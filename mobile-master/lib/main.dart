import 'package:flutter/material.dart';
import 'package:resachev/screens/screen_login/log_user.dart';
import 'package:resachev/services/api/config.dart';
import 'package:resachev/theme/app_theme.dart';

// Méthode principale de l'application Flutter
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Méthode de construction de l'application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // US 1.1 : identité de l'organisation affichée dans le nom de l'application.
      title: 'SoundBox Studio',
      debugShowMaterialGrid: false,
      debugShowCheckedModeBanner: false,
      // Thème construit à partir de la palette de la page de connexion
      // afin de garantir la cohérence visuelle sur l'ensemble de l'application.
      theme: AppTheme.light,
      home: const LoginUtilisateur(),
    );
  }
}