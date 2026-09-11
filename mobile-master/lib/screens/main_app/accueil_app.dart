import 'package:flutter/material.dart';
import 'package:resachev/screens/scanner/scanner_screen.dart';

// Ecran d'accueil de l'application une fois l'utilisateur connecté. 
//Il présente des informations sur l'application
class Accueil extends StatefulWidget {
  final void Function(Widget)? onNavigate;
  const Accueil({super.key, this.onNavigate});

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Gestion des rendez-vous',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Card(
              margin: const EdgeInsets.all(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Bienvenue sur l\'application de gestion des rendez-vous resachev. Cette application vous permet de gérer vos rendez-vous de manière efficace et pratique.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.all(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Gérez vos rendez-vous simplement Lorem ipsum dolor sit amet, \nconsectetur adipiscing elit. Nulla facilisi. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. \nVestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante. \nDonec eu libero sit amet quam egestas semper. \nAenean ultricies mi vitae est. Mauris placerat eleifend leo. Quisque sit amet est et sapien ullamcorper pharetra. ',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const QrScannerScreen(),
            ),
          );
        },
        tooltip: 'Lire un QR code',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}