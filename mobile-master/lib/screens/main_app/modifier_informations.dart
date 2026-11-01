import 'package:flutter/material.dart';
import 'package:resachev/models/usr.dart';
import 'package:resachev/services/api/gestionUsr/usr_api.dart';
import 'package:resachev/theme/app_theme.dart';

// US 1.4 : page de modification des informations personnelles.
//
// Règles métier couvertes :
//  - RG 1.4.1 : elle est accessible depuis un bouton de la page des paramètres ;
//  - RG 1.4.2 : elle comporte un bouton « Annuler » et un bouton « Valider » ;
//  - RG 1.4.3 : les champs sont validés (pas de champ vide, format d'adresse
//    email, pas de chiffre dans le nom ni dans le prénom) ;
//  - RG 1.4.4 : un message confirme la modification après enregistrement ;
//  - scénario 2 : « Annuler » ramène à la page précédente sans rien appliquer ;
//  - scénario 3 : quitter la page alors que des champs ont été modifiés
//    déclenche une demande de confirmation.

/// Page de modification des informations personnelles de l'employé.
class ModifierInformations extends StatefulWidget {
  /// Informations actuelles, utilisées pour pré-remplir le formulaire.
  final User? utilisateur;

  /// Rappelé après une modification réussie afin que la page des paramètres
  /// affiche les nouvelles valeurs.
  final ValueChanged<User>? onEnregistre;

  const ModifierInformations({super.key, this.utilisateur, this.onEnregistre});

  @override
  State<ModifierInformations> createState() => _ModifierInformationsState();
}

class _ModifierInformationsState extends State<ModifierInformations> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _emailController;

  /// Vrai dès qu'un champ diffère de sa valeur initiale : permet de proposer
  /// une confirmation avant de quitter la page (scénario 3).
  bool _modifie = false;
  bool _envoiEnCours = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.utilisateur?.nom ?? '');
    _prenomController =
        TextEditingController(text: widget.utilisateur?.prenom ?? '');
    _emailController =
        TextEditingController(text: widget.utilisateur?.email ?? '');

    _nomController.addListener(_detecterModification);
    _prenomController.addListener(_detecterModification);
    _emailController.addListener(_detecterModification);
  }

  @override
  void dispose() {
    _nomController
      ..removeListener(_detecterModification)
      ..dispose();
    _prenomController
      ..removeListener(_detecterModification)
      ..dispose();
    _emailController
      ..removeListener(_detecterModification)
      ..dispose();
    super.dispose();
  }

  /// Signale toute modification des champs par rapport aux valeurs initiales.
  void _detecterModification() {
    final bool modifie = _nomController.text != (widget.utilisateur?.nom ?? '') ||
        _prenomController.text != (widget.utilisateur?.prenom ?? '') ||
        _emailController.text != (widget.utilisateur?.email ?? '');
    if (modifie != _modifie) setState(() => _modifie = modifie);
  }

  // ---------------------------------------------------------------------------
  // RG 1.4.3 : validation des champs
  // ---------------------------------------------------------------------------

  /// Champ obligatoire, sans chiffre, de 100 caractères maximum.
  static String? _validerNom(String? valeur, String libelle) {
    final String v = valeur?.trim() ?? '';
    if (v.isEmpty) return 'Le champ « $libelle » est obligatoire.';
    if (AppColors.chiffres.hasMatch(v)) {
      return 'Le champ « $libelle » ne doit pas contenir de chiffre.';
    }
    if (v.length > 100) {
      return 'Le champ « $libelle » ne peut pas dépasser 100 caractères.';
    }
    return null;
  }

  /// Champ obligatoire au format adresse email.
  static String? _validerEmail(String? valeur) {
    final String v = valeur?.trim() ?? '';
    if (v.isEmpty) return 'Le champ « Adresse email » est obligatoire.';
    if (!AppColors.formatEmail.hasMatch(v)) {
      return 'Le format de l\'adresse email est invalide.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // RG 1.4.4 : enregistrement des modifications
  // ---------------------------------------------------------------------------

  Future<void> _valider() async {
    // Affiche les erreurs de tous les champs d'un coup.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _envoiEnCours = true);

    final Map<String, dynamic>? resultat = await UsrApi.modifierInfoUsr(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      email: _emailController.text.trim(),
    );

    // Le widget a pu être retiré de l'arbre pendant l'appel réseau.
    if (!mounted) return;
    setState(() => _envoiEnCours = false);

    final String message =
        resultat?['message']?.toString() ?? 'Erreur lors de la modification.';

    if (resultat?['ok'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(Icons.error_outline,
                  size: 18, color: AppColors.blanc),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
      return;
    }

    final User? misAJour = resultat?['user'] as User?;
    widget.onEnregistre?.call(misAJour ?? widget.utilisateur!);

    // Message de confirmation, puis retour à la page des paramètres.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(Icons.check_circle,
              size: 44, color: AppColors.enregistreTexte),
          title: Text(
            'Modification enregistrée',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.principal,
            ),
          ),
          content: Text(
            'Vos informations personnelles ont bien été mises à jour.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.texte,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Retour'),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // RG 1.4.2 / scénario 2 : annulation
  // ---------------------------------------------------------------------------

  /// Bouton « Annuler » : revient à la page précédente sans appliquer les
  /// modifications saisies.
  void _annuler() {
    Navigator.of(context).pop();
  }

  /// Scénario 3 : demande de confirmation si des champs ont été modifiés.
  Future<void> _confirmerAbandon() async {
    if (!_modifie) {
      _annuler();
      return;
    }

    final bool quitter = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: Icon(Icons.warning_amber_rounded,
                  size: 40, color: AppColors.nonEnregistreTexte),
              title: Text(
                'Modifications non enregistrées',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.principal,
                ),
              ),
              content: Text(
                'Les champs modifiés n\'ont pas été enregistrés. '
                'Voulez-vous quitter cette page sans les appliquer ?',
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
                  child: const Text('Rester sur la page'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.nonEnregistreTexte,
                  ),
                  child: const Text('Quitter sans enregistrer'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (quitter) _annuler();
  }

  /// Ligne de formulaire : libellé, champ et message d'aide.
  Widget _buildChamp({
    required String libelle,
    required String? Function(String?) validateur,
    required TextEditingController controller,
    required IconData icone,
    required TextInputType clavier,
    required String aide,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validateur,
        keyboardType: clavier,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        enableSuggestions: clavier != TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: libelle,
          prefixIcon: Icon(icone),
          helperText: aide,
          helperStyle: TextStyle(fontSize: 12, color: AppColors.secondaire),
          errorMaxLines: 3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // US 2.4 : la palette suit le mode clair / sombre courant.
    AppColors.suivreTheme(context);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        title: const Text('Mes informations'),
        // L'icône de retour passe par la même confirmation que « Annuler ».
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmerAbandon,
          tooltip: 'Retour',
        ),
      ),
      // Empêche la fermeture directe de la route : toute sortie passe par
      // _confirmerAbandon (scénario 3).
      body: PopScope<Object?>(
        canPop: !_modifie,
        onPopInvokedWithResult: (bool didPop, Object? resultat) {
          if (didPop) return;
          _confirmerAbandon();
        },
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.principalVoile,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.info_outline,
                          size: 18, color: AppColors.principal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ces informations identifient votre profil auprès '
                          'du studio. Renseignez-les avant de prendre votre '
                          'poste.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.texte,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildChamp(
                  libelle: 'Nom',
                  validateur: (String? v) => _validerNom(v, 'Nom'),
                  controller: _nomController,
                  icone: Icons.badge_outlined,
                  clavier: TextInputType.name,
                  aide: 'Lettres uniquement, sans chiffre.',
                ),
                _buildChamp(
                  libelle: 'Prénom',
                  validateur: (String? v) => _validerNom(v, 'Prénom'),
                  controller: _prenomController,
                  icone: Icons.person_outline,
                  clavier: TextInputType.name,
                  aide: 'Lettres uniquement, sans chiffre.',
                ),
                _buildChamp(
                  libelle: 'Adresse email',
                  validateur: _validerEmail,
                  controller: _emailController,
                  icone: Icons.email_outlined,
                  clavier: TextInputType.emailAddress,
                  aide: 'Format attendu : prenom.nom@studio.fr',
                ),
                const SizedBox(height: 4),
                // RG 1.4.2 : boutons « Annuler » et « Valider ».
                ElevatedButton(
                  onPressed: _envoiEnCours ? null : _valider,
                  child: _envoiEnCours
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.surAccent,
                          ),
                        )
                      : const Text('Valider les modifications'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _envoiEnCours ? null : _annuler,
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
