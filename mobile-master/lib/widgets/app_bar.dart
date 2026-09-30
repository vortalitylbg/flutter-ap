import 'package:flutter/material.dart';
import 'package:resachev/data/organisation.dart';
import 'package:resachev/theme/app_theme.dart';
import 'package:resachev/widgets/logo_soundbox.dart';

// Custom AppBar pour l'application SoundBox Studio
class AppBarPrincipal extends StatelessWidget implements PreferredSizeWidget {
  /// Actions ajoutées à droite de la barre d'application.
  final List<Widget> actions;

  const AppBarPrincipal({super.key, this.actions = const []});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Méthode de construction de l'AppBar
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.fond,
      foregroundColor: AppColors.principal,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      // US 1.1 : l'identite de l'organisation est visible sur toutes les pages.
      title: const LogoSoundBox(taille: 30, avecNom: true),
      actions: <Widget>[
        ...actions,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.bordure),
      ),
    );
  }
}

/// Titre textuel de l'application, utilisé hors de la barre principale.
String get titreApplication => Organisation.nom;
