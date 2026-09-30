import 'package:flutter/material.dart';
import 'package:resachev/data/organisation.dart';
import 'package:resachev/models/actualite.dart';
import 'package:resachev/screens/scanner/scanner_screen.dart';
import 'package:resachev/theme/app_theme.dart';
import 'package:resachev/widgets/logo_soundbox.dart';

// US 1.1 : page d'accueil de l'application.
//
// Elle présente l'identité de SoundBox Studio (nom, logo, visuel), une
// description des prestations proposées et les dernières actualités du
// studio. Tous les textes relèvent du domaine d'activité « studio de
// musique » : aucun contenu générique ne subsiste (règles métier 1 et 2).

/// Ecran d'accueil de l'application une fois l'utilisateur connecté.
class Accueil extends StatefulWidget {
  final void Function(Widget)? onNavigate;
  const Accueil({super.key, this.onNavigate});

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  /// Titre d'un bloc de section.
  Widget _titreSection(String titre, {IconData? icone}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: <Widget>[
          if (icone != null) ...<Widget>[
            Icon(icone, size: 20, color: AppColors.principal),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              titre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.principal,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bannière : logo, nom du studio, slogan et visuel du studio.
  Widget _buildBanniere() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.degradePrincipal,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const LogoSoundBox(taille: 56),
                const SizedBox(height: 16),
                Text(
                  Organisation.nom,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blanc,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Organisation.slogan,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.principalVoile,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          // Visuel du studio : la photo d'atelier sert d'illustration de marque.
          AspectRatio(
            aspectRatio: 1254 / 620,
            child: Image.asset(
              Organisation.image,
              fit: BoxFit.cover,
              // Un visuel absent ne doit pas casser la page d'accueil.
              errorBuilder: (BuildContext context, Object erreur, StackTrace? pile) {
                return Container(
                  color: AppColors.principal,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.graphic_eq,
                    size: 56,
                    color: AppColors.principalVoile,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Row(
              children: <Widget>[
                const Icon(Icons.place_outlined,
                    size: 16, color: AppColors.principalVoile),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    Organisation.adresse,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.principalVoile,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte de présentation du studio et de l'application.
  Widget _buildPresentation() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Le studio',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.principal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Organisation.description,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.texte,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.smartphone_outlined,
                  size: 18, color: AppColors.principal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  Organisation.descriptionApplication,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.secondaire,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Carte d'un horario d'ouverture / contact.
  Widget _buildCarteInfos(Widget Function() contenu, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.principalVoile,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icone, size: 20, color: AppColors.principal),
            const SizedBox(height: 8),
            contenu(),
          ],
        ),
      ),
    );
  }

  /// Grille des prestations proposées par le studio.
  Widget _buildPrestations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _titreSection('Nos prestations', icone: Icons.library_music_outlined),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: Organisation.services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (BuildContext context, int index) {
              final ServiceStudio service = Organisation.services[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.blanc,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.bordure),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.principalVoile,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        service.icone,
                        size: 22,
                        color: AppColors.principal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      service.titre,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.principal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        service.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.secondaire,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Carte d'une actualité du studio.
  Widget _buildCarteActualite(Actualite actualite, {bool miseEnAvant = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: miseEnAvant ? AppColors.principalVoile : AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: miseEnAvant ? AppColors.principal : AppColors.bordure,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.blanc,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(actualite.icone, size: 22, color: AppColors.principal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.principal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        actualite.categorie.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.blanc,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        actualite.date,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaire,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  actualite.titre,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.texte,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  actualite.resume,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.secondaire,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bloc « Dernières actualités du studio ».
  Widget _buildActualites() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _titreSection('Dernières actualités du studio',
            icone: Icons.campaign_outlined),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < Organisation.actualites.length; i++)
                _buildCarteActualite(
                  Organisation.actualites[i],
                  // La dernière annonce est mise en avant.
                  miseEnAvant: i == 0,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Pied de page : coordonnées de l'organisation.
  Widget _buildPiedDePage() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.principalVoile,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LogoSoundBox(taille: 40, avecNom: true),
          const SizedBox(height: 14),
          _ligneContact(Icons.place_outlined, Organisation.adresse),
          const SizedBox(height: 6),
          _ligneContact(Icons.phone_outlined, Organisation.telephone),
          const SizedBox(height: 6),
          _ligneContact(Icons.schedule_outlined, Organisation.horaires),
        ],
      ),
    );
  }

  Widget _ligneContact(IconData icone, String texte) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icone, size: 16, color: AppColors.secondaire),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texte,
            style: const TextStyle(fontSize: 13, color: AppColors.texte),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          _buildBanniere(),
          _buildPresentation(),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                _buildCarteInfos(
                  () => const Text(
                    Organisation.horaires,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte,
                    ),
                  ),
                  Icons.schedule_outlined,
                ),
                const SizedBox(width: 12),
                _buildCarteInfos(
                  () => const Text(
                    Organisation.telephone,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte,
                    ),
                  ),
                  Icons.phone_in_talk_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildPrestations(),
          const SizedBox(height: 18),
          _buildActualites(),
          _buildPiedDePage(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const QrScannerScreen(),
            ),
          );
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          'Scanner',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        tooltip: 'Scanner le QR code d\'un artiste',
      ),
    );
  }
}
