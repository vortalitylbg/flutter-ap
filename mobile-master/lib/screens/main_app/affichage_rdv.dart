import 'package:flutter/material.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/screens/main_app/detail_reservation.dart';
import 'package:resachev/screens/main_app/liste_attente.dart';
import 'package:resachev/services/api/gestionReservation/reservation_api.dart';
import 'package:resachev/theme/app_theme.dart';

// US 2.1 : liste des rendez-vous de la journée, recherche par client ou
// prestation, navigation vers un autre jour, retour rapide à l'état initial,
// tri par heure de début, rendez-vous passés masqués par défaut.
// US 2.2 : validation de la présence directement depuis la liste.
// US 2.5 / US 2.6 : la fiche détaillée présente les informations et permet
// l'annulation.
// US 3.1 : un créneau complet expose sa liste d'attente.
// US 3.2 : les occurrences d'une série sont signalées ; l'annulation de la
// série retire toutes ses occurrences de la liste locale.

/// Ecran d'affichage des rendez-vous.
class Affichagerdv extends StatefulWidget {
  final void Function(Widget)? onNavigate;
  const Affichagerdv({super.key, this.onNavigate});

  @override
  State<Affichagerdv> createState() => _AffichagerdvState();
}

class _AffichagerdvState extends State<Affichagerdv> {
  List<Reservation> _reservations = <Reservation>[];
  bool _chargement = true;
  String? _erreur;

  final TextEditingController _rechercheController = TextEditingController();
  String _recherche = '';

  /// Jour affiché (US 2.1, règle 1) — la journée en cours au départ.
  late DateTime _jour;

  /// Règle 6 : les rendez-vous passés sont masqués par défaut.
  bool _afficherPasses = false;

  /// Règle 5 : tri par heure de début, croissant par défaut.
  bool _triDecroissant = false;

  final Set<String> _validationsEnCours = <String>{};

  @override
  void initState() {
    super.initState();
    _jour = _dateSeule(DateTime.now());
    _charger();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Données
  // ---------------------------------------------------------------------------

  static DateTime _dateSeule(DateTime valeur) =>
      DateTime(valeur.year, valeur.month, valeur.day);

  /// [silencieux] conserve la liste affichée pendant le rechargement (retour
  /// de la liste d'attente, par exemple).
  Future<void> _charger({bool silencieux = false}) async {
    setState(() {
      if (!silencieux) _chargement = true;
      _erreur = null;
    });

    try {
      final List<Reservation> liste = await ReservationApi.listerReservations();
      if (!mounted) return;
      setState(() {
        _reservations = liste;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        if (!silencieux) {
          _erreur =
              'Impossible de charger les rendez-vous. Vérifiez votre '
              'connexion et votre session.';
        }
      });
    }
  }

  Future<void> _rafraichir() async {
    await _charger();
  }

  /// Rendez-vous affichés : jour choisi, recherche, passés et tri (US 2.1).
  ///
  /// Par défaut, seuls les rendez-vous du jour choisi sont listés. Dès qu'une
  /// recherche est saisie, elle porte sur toutes les dates : un client peut
  /// demander un renseignement sur un rendez-vous d'un autre jour (scénario 1).
  List<Reservation> get _reservationsVisibles {
    final bool rechercheActive = _recherche.trim().isNotEmpty;
    final List<Reservation> filtrees = _reservations
        .where((Reservation r) => rechercheActive || r.estLeJour(_jour))
        .where((Reservation r) => r.correspondRecherche(_recherche))
        .where((Reservation r) => _afficherPasses || !r.estPassee)
        .toList();

    filtrees.sort(
      (Reservation a, Reservation b) => _triDecroissant
          ? b.comparerParDateEtHeure(a)
          : a.comparerParDateEtHeure(b),
    );
    return filtrees;
  }

  /// Vrai lorsque l'écran n'est plus dans son état initial (règle 4).
  bool get _etatInitial =>
      _recherche.trim().isEmpty &&
      !_afficherPasses &&
      !_triDecroissant &&
      _jour == _dateSeule(DateTime.now());

  void _reinitialiser() {
    _rechercheController.clear();
    setState(() {
      _recherche = '';
      _afficherPasses = false;
      _triDecroissant = false;
      _jour = _dateSeule(DateTime.now());
    });
  }

  void _changerJour(int nombreDeJours) {
    setState(() {
      _jour = _jour.add(Duration(days: nombreDeJours));
    });
  }

  Future<void> _choisirJour() async {
    final DateTime aujourdhui = _dateSeule(DateTime.now());
    final DateTime? choix = await showDatePicker(
      context: context,
      initialDate: _jour,
      firstDate: DateTime(aujourdhui.year - 2),
      lastDate: DateTime(aujourdhui.year + 3),
    );
    if (choix == null || !mounted) return;
    setState(() => _jour = _dateSeule(choix));
  }

  void _remplacerReservation(Reservation miseAJour) {
    final int index = _reservations.indexWhere(
      (Reservation r) => r.idreservation == miseAJour.idreservation,
    );
    if (index == -1) return;
    _reservations[index] = miseAJour;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// US 2.2 : validation rapide de la présence (règle 2).
  Future<void> _validerPresence(Reservation reservation) async {
    if (_validationsEnCours.contains(reservation.idreservation)) return;

    setState(() => _validationsEnCours.add(reservation.idreservation));
    final Map<String, dynamic> resultat = await ReservationApi.validerPresence(
      reservation.idreservation,
    );
    if (!mounted) return;

    setState(() {
      _validationsEnCours.remove(reservation.idreservation);
      if (resultat['ok'] == true) {
        _remplacerReservation(
          reservation.copyWith(
            validationpresence: true,
            presenceValideeLe: DateTime.now(),
          ),
        );
      }
    });

    final String message = resultat['ok'] == true
        ? 'Présence validée à ${_formatHeure(DateTime.now())}.'
        : resultat['message']?.toString() ?? 'Validation impossible.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// US 3.1 : ouvre la liste d'attente du créneau.
  Future<void> _ouvrirListeAttente(
    Reservation reservation, {
    bool placeLiberee = false,
  }) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ListeAttente(reservation: reservation, placeLiberee: placeLiberee),
      ),
    );
    if (!mounted) return;
    // Le nombre d'inscriptions et les places libres ont pu changer.
    await _charger(silencieux: true);
  }

  /// Ouvre la fiche détaillée et applique son résultat à la liste.
  Future<void> _ouvrirDetail(Reservation reservation) async {
    final List<Reservation> historique = _reservations
        .where((Reservation r) => r.memeClient(reservation))
        .toList();
    if (historique.isEmpty) historique.add(reservation);

    final ResultatDetail? resultat = await Navigator.of(context)
        .push<ResultatDetail>(
          MaterialPageRoute<ResultatDetail>(
            builder: (_) => DetailReservation(
              reservation: reservation,
              historiqueClient: historique,
            ),
          ),
        );

    if (!mounted || resultat == null) return;

    setState(() {
      if (resultat.annulee) {
        _reservations.removeWhere(
          (Reservation r) => r.idreservation == reservation.idreservation,
        );
        // US 3.2 : une annulation de série retire ses autres occurrences.
        if (resultat.idrecurrenceAnnulee != null) {
          _reservations.removeWhere(
            (Reservation r) => r.idrecurrence == resultat.idrecurrenceAnnulee,
          );
        }
      } else if (resultat.reservation != null) {
        _remplacerReservation(resultat.reservation!);
      }
    });

    if (resultat.annulee) {
      final bool serie = resultat.idrecurrenceAnnulee != null;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              serie
                  ? 'Série annulée : les séances à venir sont de nouveau '
                        'disponibles.'
                  : 'Réservation annulée : le créneau est de nouveau '
                        'disponible.',
            ),
            // US 3.1 : le créneau libéré peut être proposé aux personnes en
            // attente.
            action: reservation.listeAttenteDisponible
                ? SnackBarAction(
                    label: 'Liste d\'attente',
                    onPressed: () =>
                        _ouvrirListeAttente(reservation, placeLiberee: true),
                  )
                : null,
          ),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Formatage
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non définie';
    final j = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$j/$m/${date.year}';
  }

  String _formatHeure(DateTime? heure) {
    if (heure == null) return 'Non définie';
    final h = heure.hour.toString().padLeft(2, '0');
    final m = heure.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _libelleJour() {
    final int ecart = _jour.difference(_dateSeule(DateTime.now())).inDays;
    final String date = _formatDate(_jour);
    if (ecart == 0) return 'Aujourd\'hui — $date';
    if (ecart == 1) return 'Demain — $date';
    if (ecart == -1) return 'Hier — $date';
    return date;
  }

  /// Palette appliquée à une séance selon l'état d'enregistrement du client
  /// (US 1.3).
  ({Color texte, Color fond, Color bordure, String libelle, IconData icone})
  _palette(Reservation reservation) {
    final bool enregistre = reservation.clientEnregistre;
    return (
      texte: enregistre
          ? AppColors.enregistreTexte
          : AppColors.nonEnregistreTexte,
      fond: enregistre ? AppColors.enregistreFond : AppColors.nonEnregistreFond,
      bordure: enregistre
          ? AppColors.enregistreTexte
          : AppColors.nonEnregistreTexte,
      libelle: enregistre ? 'Client enregistré' : 'Client non enregistré',
      icone: enregistre ? Icons.verified_user : Icons.person_off_outlined,
    );
  }

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------

  /// Étiquettes discrètes d'un créneau : série (US 3.2) et complet (US 3.1).
  Widget _buildEtiquettes(Reservation reservation) {
    if (!reservation.estRecurrente && !reservation.estComplete) {
      return const SizedBox.shrink();
    }

    Widget etiquette(IconData icone, String texte, Color couleur) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: couleur),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icone, size: 12, color: couleur),
            const SizedBox(width: 4),
            Text(
              texte,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: couleur,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: <Widget>[
          if (reservation.estRecurrente)
            etiquette(Icons.repeat, 'Série', AppColors.principal),
          if (reservation.estComplete)
            etiquette(
              Icons.event_seat_outlined,
              'Complet',
              AppColors.nonEnregistreTexte,
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(Reservation reservation) {
    final palette = _palette(reservation);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.texte,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(palette.icone, size: 13, color: AppColors.surAccent),
          const SizedBox(width: 5),
          Text(
            palette.libelle,
            style: TextStyle(
              color: AppColors.surAccent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarreRecherche() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _rechercheController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom ou prestation',
          prefixIcon: Icon(Icons.search, color: AppColors.principal),
          suffixIcon: _recherche.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.secondaire),
                  onPressed: () {
                    _rechercheController.clear();
                    setState(() => _recherche = '');
                  },
                )
              : null,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (String query) {
          setState(() => _recherche = query);
        },
      ),
    );
  }

  /// Barre d'outils : tri par heure, affichage des rendez-vous passés.
  Widget _buildOutils() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ActionChip(
            avatar: Icon(
              _triDecroissant ? Icons.south : Icons.north,
              size: 16,
              color: AppColors.principal,
            ),
            label: Text(
              _triDecroissant ? 'Heure décroissante' : 'Heure croissante',
            ),
            onPressed: () {
              setState(() => _triDecroissant = !_triDecroissant);
            },
          ),
          FilterChip(
            selected: _afficherPasses,
            label: const Text('Afficher les passés'),
            onSelected: (bool valeur) {
              setState(() => _afficherPasses = valeur);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntete() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Rendez-vous',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.principal,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rendez-vous du jour, recherche client ou prestation.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaire,
                      ),
                    ),
                  ],
                ),
              ),
              // Règle 4 : retour rapide à l'état initial.
              IconButton(
                tooltip: 'Revenir à aujourd\'hui',
                onPressed: _etatInitial ? null : _reinitialiser,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Jour précédent',
                onPressed: () => _changerJour(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _choisirJour,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    _libelleJour(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Jour suivant',
                onPressed: () => _changerJour(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarteReservation(Reservation reservation) {
    final palette = _palette(reservation);
    final bool validee = reservation.estValidee;
    final bool enCours = _validationsEnCours.contains(
      reservation.idreservation,
    );
    final DateTime? fin = reservation.finTheorique;
    final String presence = validee
        ? (reservation.presenceValideeHeure == null
              ? 'Présence validée'
              : 'Présence validée à ${reservation.presenceValideeHeure}')
        : 'Présence en attente';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: palette.fond,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _ouvrirDetail(reservation),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Liseré vertical coloré : signal d'état visible d'un coup d'œil.
                Container(width: 6, color: palette.texte),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _formatHeure(reservation.heuredebut),
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.principal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                reservation.prestation?.trim().isNotEmpty ==
                                        true
                                    ? reservation.prestation!.trim()
                                    : 'Prestation non précisée',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.texte,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatDate(reservation.datedebut)}'
                          '${fin == null ? '' : ' · fin prévue ${_formatHeure(fin)}'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaire,
                          ),
                        ),
                        _buildEtiquettes(reservation),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: palette.texte,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                reservation.clientEnregistre
                                    ? reservation.nomClient
                                    : 'Identité non renseignée',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: reservation.clientEnregistre
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontStyle: reservation.clientEnregistre
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                  color: reservation.clientEnregistre
                                      ? AppColors.texte
                                      : AppColors.nonEnregistreTexte,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(child: _buildBadge(reservation)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                presence,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: validee
                                      ? AppColors.enregistreTexte
                                      : AppColors.secondaire,
                                ),
                              ),
                            ),
                            // US 3.1 : accès direct à la liste d'attente.
                            if (reservation.listeAttenteDisponible)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.nonEnregistreTexte,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 36),
                                ),
                                onPressed: () =>
                                    _ouvrirListeAttente(reservation),
                                icon: const Icon(Icons.hourglass_top, size: 18),
                                label: Text(
                                  reservation.nombreListeAttente > 0
                                      ? 'Attente '
                                            '(${reservation.nombreListeAttente})'
                                      : 'Attente',
                                ),
                              ),
                            // US 2.2, règle 2 : action rapide et accessible.
                            if (!validee &&
                                reservation.presenceValidableManuellement)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.enregistreTexte,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 36),
                                ),
                                onPressed: enCours
                                    ? null
                                    : () => _validerPresence(reservation),
                                icon: enCours
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.how_to_reg, size: 18),
                                label: const Text('Valider'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListeVide({required bool passesMasques}) {
    return RefreshIndicator(
      onRefresh: _rafraichir,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          Icon(
            Icons.event_busy_outlined,
            size: 44,
            color: AppColors.secondaire,
          ),
          const SizedBox(height: 12),
          Text(
            _recherche.trim().isEmpty
                ? 'Aucun rendez-vous ce jour.'
                : 'Aucun rendez-vous trouvé.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaire,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _recherche.trim().isEmpty
                ? (passesMasques
                      ? 'Les rendez-vous passés sont masqués.'
                      : 'Changez de jour ou revenez plus tard.')
                : 'Essayez un nom de client ou une prestation différente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.secondaire),
          ),
          if (passesMasques)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => _afficherPasses = true),
                  child: const Text('Afficher les rendez-vous passés'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // US 2.4 : la palette suit le mode clair / sombre courant.
    AppColors.suivreTheme(context);

    final List<Reservation> visibles = _reservationsVisibles;
    final bool passesMasques =
        !_afficherPasses &&
        _reservations.any((Reservation r) => r.estLeJour(_jour) && r.estPassee);

    return Column(
      children: <Widget>[
        _buildEntete(),
        _buildBarreRecherche(),
        _buildOutils(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _recherche.trim().isEmpty
                  ? '${visibles.length} rendez-vous affiché'
                        '${visibles.length > 1 ? 's' : ''}'
                  : '${visibles.length} résultat'
                        '${visibles.length > 1 ? 's' : ''} — toutes dates',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaire,
              ),
            ),
          ),
        ),
        Expanded(
          child: _chargement
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.principal),
                )
              : _erreur != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.cloud_off,
                          size: 40,
                          color: AppColors.secondaire,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _erreur!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.texte),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 180,
                          child: ElevatedButton(
                            onPressed: _rafraichir,
                            child: const Text('Réessayer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : visibles.isEmpty
              ? _buildListeVide(passesMasques: passesMasques)
              : RefreshIndicator(
                  onRefresh: _rafraichir,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 2, bottom: 24),
                    itemCount: visibles.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildCarteReservation(visibles[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
