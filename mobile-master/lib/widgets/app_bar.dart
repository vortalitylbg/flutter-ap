import 'package:flutter/material.dart';

// Custom AppBar pour l'application ResaChev
class AppBarPrincipal extends StatefulWidget implements PreferredSizeWidget {
  /// Custom AppBar 
  final List<Widget> actions;
  const AppBarPrincipal({super.key, this.actions = const []});
  @override

  State<AppBarPrincipal> createState() => _AppBarPrincipalState();
  @override
  // Gestion de la taille préférée de l'AppBar
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarPrincipalState extends State<AppBarPrincipal> {
  // Méthode de construction de l'AppBar
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      title: Text('ResaChev'),
      actions: <Widget>[        
        ...widget.actions,
      ],
    );
  }
}