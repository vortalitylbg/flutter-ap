import 'package:flutter/material.dart';
import 'package:resachev/screens/screen_login/log_user.dart';
import 'package:resachev/services/api/config.dart';

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
      title: 'ResaChev',
      debugShowMaterialGrid: false,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginUtilisateur(),
    );
  }
}