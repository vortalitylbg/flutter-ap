import 'package:flutter/material.dart';
import 'package:resachev/models/entree_attente.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/services/api/gestionReservation/reservation_api.dart';
import 'package:resachev/theme/app_theme.dart';

// US 3.1 : liste d'attente d'un créneau complet.
//
// L'employé consulte les inscriptions dans l'ordre de passage (premier arrivé,
// premier servi), peut inscrire un client accueilli à l'accueil et proposer la
// place libérée à la première personne de la file. Lorsqu'une réservation est
// annulée, l'écran est ouvert avec [placeLiberee] à vrai : la place est alors
// disponible et peut être proposée immédiatement.

/// Liste d'attente d'un créneau.
class ListeAttente extends StatefulWidget {
  /// Créneau concerné.
  final Reservation reservation;

  /// Vrai lorsque la place vient d'être libérée par une annulation.
  final bool placeLiberee;

  /// Chargement des inscriptions, injectable pour les tests.
  final Future<Map<String, dynamic>> Function(String idreservation)? chargeur;

  const ListeAttente({
    super.key,
    required this.reservation,
    this.placeLiberee = false,
    this.chargeur,
  });

  @override
  State<ListeAttente> createState() => _ListeAttenteState();
}

class _ListeAttenteState extends State<ListeAttente> {
  List<EntreeAttente> _entrees = <EntreeAttente>[];
  bool _chargement = true;
  bool _actionEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    final Future<Map<String, dynamic>> Function(String) chargeur =
        widget.chargeur ?? ReservationApi.listerListeAttente;
    final Map<String, dynamic> resultat = await chargeur(
      widget.reservation.idreservation,
    );

    if (!mounted) return;

    final dynamic brut = resultat['entrees'];
    final List<EntreeAttente> entrees = brut is List
        ? brut.whereType<EntreeAttente>().toList()
        : <EntreeAttente>[];
    entrees.sort((EntreeAttente a, EntreeAttente b) => a.comparerParOrdre(b));

    setState(() {
      _chargement = false;
      _entrees = entrees;
      _erreur = resultat['ok'] == true
          ? null
          : resultat['message']?.toString() ??
                'Impossible de charger la liste d\'attente.';
    });
  }

  /// Une place peut être proposée si le créneau en a une de libre, si aucune
  /// proposition n'est en cours et si quelqu'un attend encore.
  bool get _peutProposer {
    final DateTime maintenant = DateTime.now();
    final bool placeDisponible =
        widget.placeLiberee || (widget.reservation.placesRestantes ?? 0) > 0;
    final bool propositionActive = _entrees.any(
      (EntreeAttente entree) => entree.estProposee(maintenant),
    );
    final bool quelquUnAttend = _entrees.any(
      (EntreeAttente entree) => entree.estEnAttente,
    );
    return placeDisponible && !propositionActive && quelquUnAttend;
  }

  Future<void> _proposerPlace() async {
    if (_actionEnCours) return;

    final bool valider =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Proposer la place'),
              content: const Text(
                'La place va être proposée à la première personne de la '
                'liste d\'attente. Elle disposera de 30 minutes pour '
                'l\'accepter ; passé ce délai, la place passera à la '
                'personne suivante.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Proposer'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!valider || !mounted) return;

    setState(() => _actionEnCours = true);
    final Map<String, dynamic> resultat = await ReservationApi.proposerPlace(
      widget.reservation.idreservation,
    );
    if (!mounted) return;
    setState(() => _actionEnCours = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            resultat['message']?.toString() ??
                (resultat['ok'] == true
                    ? 'Place proposée.'
                    : 'Proposition impossible.'),
          ),
        ),
      );

    if (resultat['ok'] == true) await _charger();
  }

  Future<void> _ouvrirInscription() async {
    if (_actionEnCours) return;

    final TextEditingController nom = TextEditingController();
    final TextEditingController prenom = TextEditingController();
    final TextEditingController email = TextEditingController();
    final GlobalKey<FormState> formulaire = GlobalKey<FormState>();

    final bool valider =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Inscrire un client'),
              content: Form(
                key: formulaire,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: prenom,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Prénom'),
                        validator: (String? valeur) =>
                            (valeur ?? '').trim().isEmpty
                            ? 'Prénom requis'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: nom,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: (String? valeur) =>
                            (valeur ?? '').trim().isEmpty ? 'Nom requis' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          helperText: 'Sert à prévenir le client.',
                        ),
                        validator: (String? valeur) {
                          final String texte = (valeur ?? '').trim();
                          if (texte.isEmpty) return 'Email requis';
                          final bool valide = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(texte);
                          return valide ? null : 'Email invalide';
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    if (formulaire.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: const Text('Inscrire'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (valider != true || !mounted) {
      nom.dispose();
      prenom.dispose();
      email.dispose();
      return;
    }

    setState(() => _actionEnCours = true);
    final Map<String, dynamic> resultat =
        await ReservationApi.inscrireListeAttente(
          idreservation: widget.reservation.idreservation,
          nom: nom.text,
          prenom: prenom.text,
          email: email.text,
        );
    nom.dispose();
    prenom.dispose();
    email.dispose();

    if (!mounted) return;
    setState(() => _actionEnCours = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            resultat['message']?.toString() ??
                (resultat['ok'] == true
                    ? 'Client inscrit.'
                    : 'Inscription impossible.'),
          ),
        ),
      );

    if (resultat['ok'] == true) await _charger();
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    final String j = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    return '$j/$m/${date.year}';
  }

  String _formatHeure(DateTime? heure) {
    if (heure == null) return '--:--';
    final String h = heure.hour.toString().padLeft(2, '0');
    final String m = heure.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateHeure(DateTime? date) {
    if (date == null) return 'Date inconnue';
    return '${_formatDate(date)} à ${_formatHeure(date)}';
  }

  Widget _buildEntete() {
    final Reservation reservation = widget.reservation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            reservation.prestation?.trim().isNotEmpty == true
                ? reservation.prestation!.trim()
                : 'Prestation non précisée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.principal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(reservation.datedebut)} · '
            '${_formatHeure(reservation.heuredebut)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaire,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.placeLiberee
                ? '1 place libérée par une annulation'
                : reservation.placesAffichees,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.placeLiberee || reservation.estComplete
                  ? AppColors.nonEnregistreTexte
                  : AppColors.enregistreTexte,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ordre de passage : premier inscrit, premier servi. Une place '
            'libérée est proposée 30 minutes à la première personne, puis à '
            'la suivante si elle ne répond pas.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.secondaire,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _peutProposer && !_actionEnCours
                  ? _proposerPlace
                  : null,
              icon: _actionEnCours
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.front_hand_outlined, size: 20),
              label: const Text('Proposer la place au suivant'),
            ),
          ),
          if (widget.reservation.estComplete &&
              !widget.placeLiberee) ...<Widget>[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _actionEnCours ? null : _ouvrirInscription,
                icon: const Icon(Icons.person_add_alt, size: 20),
                label: const Text('Inscrire un client'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarte(EntreeAttente entree, int rang) {
    final DateTime maintenant = DateTime.now();
    final bool positive =
        entree.estProposee(maintenant) ||
        entree.statut == StatutAttente.convertie;
    final Color couleur = positive
        ? AppColors.enregistreTexte
        : entree.estPropositionExpiree(maintenant) ||
              entree.statut == StatutAttente.expiree
        ? AppColors.nonEnregistreTexte
        : AppColors.secondaire;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.principalVoile,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rang',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.principal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entree.nomClient,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.texte,
                  ),
                ),
                if (entree.email != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    entree.email!,
                    style: TextStyle(fontSize: 12, color: AppColors.secondaire),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  entree.inscritLe == null
                      ? 'Inscription enregistrée'
                      : 'Inscrit le ${_formatDateHeure(entree.inscritLe)}',
                  style: TextStyle(fontSize: 12, color: AppColors.secondaire),
                ),
                const SizedBox(height: 6),
                Text(
                  entree.libelleStatut(maintenant),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: couleur,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu() {
    if (_chargement) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.principal),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          _buildEntete(),
          _buildActions(),
          if (_erreur != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _erreur!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.nonEnregistreTexte,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Réservations en attente (${_entrees.length})',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.principal,
            ),
          ),
          const SizedBox(height: 10),
          if (_entrees.isEmpty)
            Text(
              'Aucune inscription pour ce créneau. Utilisez « Inscrire un '
              'client » lorsqu\'un client souhaite une place déjà prise.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.secondaire,
              ),
            )
          else
            for (int i = 0; i < _entrees.length; i++)
              _buildCarte(_entrees[i], i + 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.suivreTheme(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Liste d\'attente')),
      body: SafeArea(child: _buildContenu()),
    );
  }
}
