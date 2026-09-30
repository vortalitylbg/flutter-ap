import 'package:flutter/material.dart';
import 'package:resachev/models/usr.dart';
import 'package:resachev/screens/main_app/modifier_informations.dart';
import 'package:resachev/screens/screen_login/log_user.dart';
import 'package:resachev/services/api/config.dart';
import 'package:resachev/services/api/gestionUsr/usr_api.dart';
import 'package:resachev/services/gestion_token/token.dart';
import 'package:resachev/theme/app_theme.dart';
import 'package:resachev/widgets/logo_soundbox.dart';

// US 1.2 : la page des paramètres affiche les informations du compte, dont
// l'adresse email, dans une zone clairement délimitée.
//
// US 1.4 : elle fournit le bouton d'accès à la page de modification des
// informations (RG 1.4.1) et le bouton de déconnexion (RG 1.4.5), qui
// ramène à la page d'identification (RG 1.4.6).

/// Ecran de paramètres de l'application.
class ParamApp extends StatefulWidget {
  /// Informations connues à l'avance. L'application ne les fournit pas : elles
  /// sont alors chargées depuis l'API. Ce paramètre existe pour permettre
  /// l'aperçu et les tests sans appel réseau.
  final User? utilisateurInitial;

  const ParamApp({super.key, this.utilisateurInitial});

  @override
  State<ParamApp> createState() => _ParamAppState();
}

class _ParamAppState extends State<ParamApp> {
  User? me;
  bool chargementEnCours = true;
  String? messageErreur;

  @override
  void initState() {
    super.initState();
    me = widget.utilisateurInitial;
    chargerUtilisateur();
  }

  /// Charge les informations du compte via l'API (GET /mobile/me).
  Future<void> chargerUtilisateur() async {
    if (!mounted) return;
    setState(() {
      chargementEnCours = true;
      messageErreur = null;
    });

    try {
      final User? utilisateur = await UsrApi.rechercherInfoUsr();
      if (!mounted) return;
      setState(() {
        // Un échec réseau ne doit pas effacer des informations déjà connues.
        if (utilisateur != null) me = utilisateur;
        chargementEnCours = false;
        messageErreur =
            utilisateur == null ? 'Impossible de charger votre profil.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        chargementEnCours = false;
        messageErreur = 'Impossible de charger votre profil.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // RG 1.4.1 : accès à la page de modification des informations
  // ---------------------------------------------------------------------------

  Future<void> ouvrirModification() async {
    final User? misAJour = await Navigator.of(context).push<User>(
      MaterialPageRoute<User>(
        builder: (BuildContext context) => ModifierInformations(
          utilisateur: me,
          onEnregistre: (User utilisateur) {
            // Met à jour l'affichage sans repasser par l'API.
            if (!mounted) return;
            setState(() => me = utilisateur);
          },
        ),
      ),
    );

    if (misAJour == null || !mounted) return;

    setState(() => me = misAJour);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vos informations ont été mises à jour.')),
    );
  }

  // ---------------------------------------------------------------------------
  // RG 1.4.5 et 1.4.6 : déconnexion puis retour à la page d'identification
  // ---------------------------------------------------------------------------

  Future<void> seDeconnecter() async {
    // Supprime le token : l'employé ne doit plus être considéré comme connecté.
    await GestionToken.logout();
    if (!mounted) return;

    // RG 1.4.6 : la page d'identification est affichée après déconnexion.
    // pushReplacement retire la page courante de la pile de navigation, ce qui
    // détruit le shell logged et empêche d'y revenir avec le bouton « retour ».
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginUtilisateur()),
      (Route<dynamic> route) => false,
    );
  }

  /// Demande confirmation avant de déconnecter : le terminal est partagé
  /// entre les employés (scénario 4).
  Future<void> _confirmerDeconnexion() async {
    final bool valider = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.logout,
                  size: 40, color: AppColors.nonEnregistreTexte),
              title: const Text(
                'Se déconnecter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.principal,
                ),
              ),
              content: const Text(
                'Vous pourrez ensuite transmettre le terminal à votre '
                'collègue. La page de connexion sera affichée.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.texte,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Rester connecté'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.nonEnregistreTexte,
                  ),
                  child: const Text('Se déconnecter'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (valider) await seDeconnecter();
  }

  // ---------------------------------------------------------------------------
  // Zone d'informations du compte (US 1.2)
  // ---------------------------------------------------------------------------

  /// Carte « Informations du compte », délimitée visuellement du reste de la
  /// page (règle métier US 1.2.2). L'adresse email y figure toujours.
  Widget _buildZoneInformations() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.principal, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // En-tête de la zone : l'intitulé rend explicite la partie de l'écran
          // qui contient les informations de l'utilisateur.
          Container(
            color: AppColors.principal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: <Widget>[
                Icon(Icons.badge_outlined, size: 18, color: AppColors.blanc),
                SizedBox(width: 10),
                Text(
                  'Informations du compte',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.blanc,
                  ),
                ),
              ],
            ),
          ),
          if (chargementEnCours && me == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.principal,
                  ),
                ),
              ),
            )
          else if (me == null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Text(
                    messageErreur ??
                        (chargementEnCours
                            ? 'Chargement des informations...'
                            : 'Profil indisponible.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: chargementEnCours
                          ? AppColors.secondaire
                          : AppColors.nonEnregistreTexte,
                    ),
                  ),
                  if (!chargementEnCours) ...<Widget>[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 160,
                      child: OutlinedButton(
                        onPressed: chargerUtilisateur,
                        child: const Text('Réessayer'),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Identité : initiales, nom et rôle au sein du studio.
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.principalVoile,
                        child: Text(
                          _initiales(me!),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.principal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _nomComplet(me!),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.texte,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Personnel du studio',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaire,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(),
                  ),
                  _ligneInfo(
                    icone: Icons.person_outline,
                    libelle: 'Prénom',
                    valeur: _valeurOu(me!.prenom),
                  ),
                  const SizedBox(height: 12),
                  _ligneInfo(
                    icone: Icons.badge_outlined,
                    libelle: 'Nom',
                    valeur: _valeurOu(me!.nom),
                  ),
                  const SizedBox(height: 12),
                  // Règle métier US 1.2.1 : l'adresse email apparaît sur la
                  // page des paramètres.
                  _ligneInfo(
                    icone: Icons.email_outlined,
                    libelle: 'Adresse email',
                    valeur: _valeurOu(me!.email),
                    miseEnEvidence: true,
                  ),
                  const SizedBox(height: 12),
                  _ligneInfo(
                    icone: Icons.tag,
                    libelle: 'Identifiant',
                    valeur: me!.idutilisateur.toString(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Ligne « libellé : valeur » de la zone d'informations.
  Widget _ligneInfo({
    required IconData icone,
    required String libelle,
    required String valeur,
    bool miseEnEvidence = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icone, size: 18, color: AppColors.secondaire),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                libelle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: AppColors.secondaire,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valeur,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: miseEnEvidence ? AppColors.principal : AppColors.texte,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Carte « Mon compte » regroupant les actions sur le profil.
  Widget _buildCarteCompte() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Mon compte',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.principal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mettez à jour les informations que le studio utilise pour vous '
            'identifier.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.secondaire,
            ),
          ),
          const SizedBox(height: 14),
          // RG 1.4.1 : ce bouton ouvre la page de modification.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: me == null ? null : ouvrirModification,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Modifier mes informations'),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte « Session » : déconnexion et informations sur l'application.
  Widget _buildCarteSession() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.principal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Le terminal est partagé entre les employés : déconnectez-vous '
            'avant de le transmettre.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.secondaire,
            ),
          ),
          const SizedBox(height: 14),
          // RG 1.4.5 : ce bouton déconnecte l'employé.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmerDeconnexion,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.nonEnregistreTexte,
                side: const BorderSide(color: AppColors.nonEnregistreTexte),
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Se déconnecter'),
            ),
          ),
        ],
      ),
    );
  }

  /// Pied de page : identité de l'organisation et version de l'application.
  Widget _buildPiedDePage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        children: <Widget>[
          const LogoSoundBox(taille: 44, avecNom: true),
          const SizedBox(height: 10),
          Text(
            'SoundBox Booking · Version ${AppConfig.appVersion}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.secondaire),
          ),
        ],
      ),
    );
  }

  /// Initiales affichées dans l'avatar : première lettre du prénom et du nom.
  static String _initiales(User utilisateur) {
    final String p = (utilisateur.prenom ?? '').trim();
    final String n = (utilisateur.nom ?? '').trim();
    final String initiales = <String>[
      if (p.isNotEmpty) p.substring(0, 1),
      if (n.isNotEmpty) n.substring(0, 1),
    ].join();
    return initiales.isEmpty ? '?' : initiales.toUpperCase();
  }

  /// Nom et prénom combinés, dans l'ordre « Prénom NOM ».
  static String _nomComplet(User utilisateur) {
    final String complet = <String>[
      utilisateur.prenom ?? '',
      utilisateur.nom ?? '',
    ].where((String v) => v.trim().isNotEmpty).join(' ').trim();
    return complet.isEmpty ? 'Profil incomplet' : complet;
  }

  /// Remplace une valeur absente par un texte explicite.
  static String _valeurOu(String? valeur) {
    final String v = valeur?.trim() ?? '';
    return v.isEmpty ? 'Non renseigné' : v;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.principal,
      onRefresh: chargerUtilisateur,
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Paramètres',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.principal,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Vos informations et la gestion de la session.',
                  style: TextStyle(fontSize: 13, color: AppColors.secondaire),
                ),
              ],
            ),
          ),
          _buildZoneInformations(),
          _buildCarteCompte(),
          _buildCarteSession(),
          _buildPiedDePage(),
        ],
      ),
    );
  }
}
