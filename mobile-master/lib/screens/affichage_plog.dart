import 'package:flutter/material.dart';
import 'package:resachev/screens/main_app/accueil_app.dart';
import 'package:resachev/screens/main_app/affichage_rdv.dart';
import 'package:resachev/screens/main_app/param_app.dart';
import 'package:resachev/services/gestion_token/token.dart';
import 'package:resachev/widgets/app_bar.dart';
import 'package:resachev/widgets/bottom_bar.dart';

// Route principale de l'application après la connexion de l'utilisateur. 
//Elle gère la navigation entre les différentes pages de l'application.

class PageLogP extends StatefulWidget {
  const PageLogP({super.key});

  @override
  State<PageLogP> createState() => _PageLogPState();
}

class _PageLogPState extends State<PageLogP> {
  // Index pour la navigation
  int currentPageIndex = 0;
  Widget? currentBody;

  @override
  void initState() {
    super.initState();
    currentBody = Accueil(onNavigate: afficherNouvellePage);
  }

  void afficherNouvellePage(Widget nouvellePage) {
    setState(() {
      currentBody = nouvellePage;
    });
  }

  // Méthode pour empecher de visuallier les pages si l'utilisateur n'est pas connecté
  Future<void> _onDestinationSelected(int index) async {
    if (index == 1) {
      final autorise = await GestionToken.isLogged();
      if (!autorise && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Veuillez vous connecter pour accéder à l'application."),
          ),
        );
        return;
      }
    }
    // Mise à jour du corps de la page
    setState(() {
      currentPageIndex = index;
      switch (index) {
        case 0:
          currentBody = Accueil(onNavigate: afficherNouvellePage);
          break;
        case 1:
          currentBody = Affichagerdv(onNavigate: afficherNouvellePage);
          break;
        case 2:
          currentBody = const ParamApp();
          break;
        default:
          currentBody = const Center(child: Text('Page introuvable'));
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Appel de l'AppBar personnalisée
      appBar: AppBarPrincipal(),
              
      // Affichage du corps de la page
      body: SafeArea(
        child: currentBody ?? const Center(child: Text('Page introuvable')),
      ),
      // Appel de la barre de navigation en bas personnalisée
      bottomNavigationBar: BottomNavbar(
        currentIndex: currentPageIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}