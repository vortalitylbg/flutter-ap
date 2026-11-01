import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:resachev/screens/screen_login/log_user.dart';
import 'package:resachev/services/api/config.dart';
import 'package:resachev/theme/app_theme.dart';
import 'package:resachev/theme/theme_controller.dart';

// Méthode principale de l'application Flutter
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  // US 2.4 : le mode d'affichage choisi lors de la dernière session est relu
  // avant l'affichage, afin d'être appliqué dès le lancement de l'application.
  await ThemeController.charger();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Méthode de construction de l'application
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (BuildContext context, ThemeMode mode, Widget? child) {
        // La palette statique suit le mode retenu (US 2.4).
        AppColors.definirMode(mode == ThemeMode.dark);

        return MaterialApp(
          // US 1.1 : identité de l'organisation affichée dans le nom de l'application.
          title: 'SoundBox Studio',
          debugShowMaterialGrid: false,
          debugShowCheckedModeBanner: false,
          // Thème construit à partir de la palette de la page de connexion
          // afin de garantir la cohérence visuelle sur l'ensemble de l'application.
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          // Interface française : le sélecteur de date des rendez-vous
          // s'affiche lui aussi en français.
          locale: const Locale('fr'),
          supportedLocales: const <Locale>[Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const LoginUtilisateur(),
        );
      },
    );
  }
}