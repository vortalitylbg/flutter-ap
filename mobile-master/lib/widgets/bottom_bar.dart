import 'package:flutter/material.dart';
import 'package:resachev/services/gestion_token/token.dart';

//Barre de navigation en bas de l'application. Est appelé une fois la connexion  validée.

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });
  // Empeche l'utilisateur d'aller dans l'application s'il n'est pas connecté
  Future<void> _verifValidite(BuildContext context, int index) async {
    if (index == 1) {
      final autorise = await GestionToken.isLogged();
      if (!autorise && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter.')),
        );
        return;
      }
    }
    onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    // Construction de la barre de navigation 
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _verifValidite(context, index),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: const [
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Acceuil',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.list_outlined),
          icon: Icon(Icons.list_alt_outlined),
          label: 'Liste des reservations',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.settings),
          icon: Icon(Icons.settings_outlined),
          label: 'Paramètres',
        ),
      ],
    );
  }
}