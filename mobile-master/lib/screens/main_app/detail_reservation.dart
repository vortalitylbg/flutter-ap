import 'package:flutter/material.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/screens/main_app/historique_client.dart';
import 'package:resachev/screens/main_app/liste_attente.dart';
import 'package:resachev/services/api/gestionReservation/reservation_api.dart';
import 'package:resachev/theme/app_theme.dart';

// US 2.5 : présentation des informations d'un rendez-vous (montant, durée,
// heure de fin théorique, participants).
// US 2.2 : validation de la présence depuis la fiche.
// US 2.6 : annulation de la réservation, avec message explicatif lorsque
// l'action est refusée.
// US 3.1 : accès à la liste d'attente du créneau.
// US 3.2 : une séance issue d'une série peut être annulée seule ou avec toutes
// les occurrences à venir.

/// Résultat renvoyé à la liste des rendez-vous après une action sur la fiche.
class ResultatDetail {
  /// Rendez-vous mis à jour (présence validée), ou `null` s'il a été annulé.
  final Reservation? reservation;

  /// Vrai lorsque la réservation a été annulée.
  final bool annulee;

  /// Série annulée en entier (US 3.2), pour retirer ses occurrences de la
  /// liste locale.
  final String? idrecurrenceAnnulee;

  const ResultatDetail({
    this.reservation,
    this.annulee = false,
    this.idrecurrenceAnnulee,
  });
}

/// Fiche détaillée d'un rendez-vous.
class DetailReservation extends StatefulWidget {
  final Reservation reservation;

  /// Rendez-vous du même client, transmis pour l'historique (US 2.1, sc. 3).
  final List<Reservation> historiqueClient;

  const DetailReservation({
    super.key,
    required this.reservation,
    this.historiqueClient = const <Reservation>[],
  });

  @override
  State<DetailReservation> createState() => _DetailReservationState();
}

class _DetailReservationState extends State<DetailReservation> {
  late Reservation _reservation;
  bool _validationEnCours = false;
  bool _annulationEnCours = false;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;
  }

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

  // ---------------------------------------------------------------------------
  // US 2.2 : validation de la présence
  // ---------------------------------------------------------------------------

  Future<void> _validerPresence() async {
    if (_validationEnCours) return;
    setState(() => _validationEnCours = true);

    final resultat = await ReservationApi.validerPresence(
      _reservation.idreservation,
    );

    if (!mounted) return;
    setState(() => _validationEnCours = false);

    final bool ok = resultat['ok'] == true;
    if (ok) {
      setState(() {
        _reservation = _reservation.copyWith(
          validationpresence: true,
          presenceValideeLe: DateTime.now(),
        );
      });
    }

    final String message = ok
        ? 'Présence validée à ${_formatHeure(DateTime.now())}.'
        : resultat['message']?.toString() ?? 'Validation impossible.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------
  // US 2.6 : annulation
  // ---------------------------------------------------------------------------

  Future<void> _confirmerAnnulation() async {
    final bool recurrente = _reservation.estRecurrente;

    // US 3.2 : le périmètre doit être explicite pour une série ; pour une
    // réservation simple, le dialogue ne propose que l'occurrence.
    final PorteeAnnulation? portee = await showDialog<PorteeAnnulation>(
      context: context,
      builder: (BuildContext dialogContext) {
        PorteeAnnulation choix = PorteeAnnulation.occurrence;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                recurrente
                    ? 'Annuler une séance de la série'
                    : 'Annuler la réservation',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'La réservation de '
                    '${_reservation.nomClient.isEmpty ? 'ce client' : _reservation.nomClient} '
                    'va être annulée et le créneau libéré.\n\n'
                    '${Reservation.conditionsAnnulation}',
                  ),
                  if (recurrente) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(
                      'Cette séance fait partie d\'une série : choisissez le '
                      'périmètre de l\'annulation.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.secondaire,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<PorteeAnnulation>(
                      segments: const <ButtonSegment<PorteeAnnulation>>[
                        ButtonSegment<PorteeAnnulation>(
                          value: PorteeAnnulation.occurrence,
                          label: Text('Cette séance'),
                        ),
                        ButtonSegment<PorteeAnnulation>(
                          value: PorteeAnnulation.serie,
                          label: Text('Toute la série'),
                        ),
                      ],
                      selected: <PorteeAnnulation>{choix},
                      onSelectionChanged: (Set<PorteeAnnulation> selection) {
                        setDialogState(() => choix = selection.first);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      choix == PorteeAnnulation.serie
                          ? 'Toutes les occurrences à venir seront annulées. '
                                'Les séances passées ou déjà honorées sont '
                                'conservées.'
                          : 'Seule cette séance sera annulée ; les autres '
                                'occurrences de la série sont conservées.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.secondaire,
                      ),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Conserver'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(choix),
                  child: Text(
                    choix == PorteeAnnulation.serie
                        ? 'Annuler la série'
                        : 'Annuler la réservation',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (portee == null || !mounted) return;

    setState(() => _annulationEnCours = true);
    final Map<String, dynamic> resultat =
        await ReservationApi.annulerReservation(
          _reservation.idreservation,
          portee: portee,
        );
    if (!mounted) return;
    setState(() => _annulationEnCours = false);

    if (resultat['ok'] == true) {
      Navigator.of(context).pop(
        ResultatDetail(
          annulee: true,
          idrecurrenceAnnulee: portee == PorteeAnnulation.serie
              ? _reservation.idrecurrence
              : null,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            resultat['message']?.toString() ?? 'Annulation impossible.',
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Affichage
  // ---------------------------------------------------------------------------

  Widget _ligne({
    required IconData icone,
    required String libelle,
    required String valeur,
    Color? couleurValeur,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaire,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valeur,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: couleurValeur ?? AppColors.texte,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteInformations() {
    final bool validee = _reservation.estValidee;
    final DateTime? fin = _reservation.finTheorique;
    final String presence = validee
        ? (_reservation.presenceValideeHeure == null
              ? 'Présence validée'
              : 'Présence validée à ${_reservation.presenceValideeHeure}')
        : 'Présence en attente';

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
            _reservation.prestation?.trim().isNotEmpty == true
                ? _reservation.prestation!.trim()
                : 'Prestation non précisée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.principal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatHeure(_reservation.heuredebut)}'
            '${fin == null ? '' : ' – ${_formatHeure(fin)}'}'
            ' · ${_formatDate(_reservation.datedebut)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaire,
            ),
          ),
          // US 3.2 : rattachement à une série de réservations.
          if (_reservation.estRecurrente) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.principalVoile,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.repeat, size: 18, color: AppColors.principal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _reservation.libelleRecurrenceAffiche,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte,
                          ),
                        ),
                        if (_reservation.occurrenceAffichee != null)
                          Text(
                            _reservation.occurrenceAffichee!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaire,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.bordure),
          ),
          // US 2.5 : informations demandées par les règles métier.
          _ligne(
            icone: Icons.person_outline,
            libelle: 'Client',
            valeur: _reservation.nomClient.isEmpty
                ? 'Identité non renseignée'
                : _reservation.nomClient,
          ),
          _ligne(
            icone: Icons.calendar_today_outlined,
            libelle: 'Date',
            valeur: _formatDate(_reservation.datedebut),
          ),
          _ligne(
            icone: Icons.schedule,
            libelle: 'Heure de début',
            valeur: _formatHeure(_reservation.heuredebut),
          ),
          _ligne(
            icone: Icons.schedule_outlined,
            libelle: 'Heure de fin théorique',
            valeur: _formatHeure(fin),
          ),
          _ligne(
            icone: Icons.timelapse,
            libelle: 'Durée',
            valeur: _reservation.dureeAffichee,
          ),
          _ligne(
            icone: Icons.euro_outlined,
            libelle: 'Montant de la prestation',
            valeur: _reservation.montantAffiche,
          ),
          _ligne(
            icone: Icons.groups_outlined,
            libelle: 'Participants',
            valeur: _reservation.participantsAffiches,
          ),
          // US 3.1 : remplissage du créneau, support de la liste d'attente.
          if (_reservation.capacite != null ||
              _reservation.placesRestantes != null)
            _ligne(
              icone: Icons.event_seat_outlined,
              libelle: 'Places',
              valeur: _reservation.placesAffichees,
              couleurValeur: _reservation.estComplete
                  ? AppColors.nonEnregistreTexte
                  : AppColors.enregistreTexte,
            ),
          _ligne(
            icone: validee ? Icons.check_circle_outline : Icons.hourglass_empty,
            libelle: 'Présence',
            valeur: presence,
            couleurValeur: validee
                ? AppColors.enregistreTexte
                : AppColors.secondaire,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.suivreTheme(context);

    final DateTime maintenant = DateTime.now();
    final String? motifAnnulation = _reservation.motifAnnulationImpossible(
      maintenant,
    );

    // Le retour transmet l'état courant afin que la liste reflète une
    // validation de présence effectuée depuis la fiche.
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).pop(ResultatDetail(reservation: _reservation));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Détail du rendez-vous')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              _buildCarteInformations(),
              const SizedBox(height: 16),

              // US 2.1, scénario 3 : accès à l'historique du client.
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HistoriqueClient(
                        nomClient: _reservation.nomClient,
                        reservations: widget.historiqueClient,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history, size: 20),
                label: const Text('Historique du client'),
              ),

              // US 3.1 : liste d'attente du créneau.
              if (_reservation.listeAttenteDisponible) ...<Widget>[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ListeAttente(reservation: _reservation),
                      ),
                    );
                  },
                  icon: const Icon(Icons.hourglass_top, size: 20),
                  label: Text(
                    _reservation.nombreListeAttente > 0
                        ? 'Liste d\'attente '
                              '(${_reservation.nombreListeAttente})'
                        : 'Liste d\'attente',
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // US 2.2 : validation rapide de la présence, le jour du
              // rendez-vous (la présence n'est pas validée à l'avance).
              if (_reservation.presenceValidableManuellement)
                ElevatedButton.icon(
                  onPressed: _validationEnCours ? null : _validerPresence,
                  icon: _validationEnCours
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surAccent,
                          ),
                        )
                      : const Icon(Icons.how_to_reg, size: 20),
                  label: const Text('Valider la présence'),
                ),

              const SizedBox(height: 20),

              // US 2.6 : annulation, refusée avec un message explicatif hors
              // des conditions définies.
              Text(
                'Annulation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.principal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                motifAnnulation ?? Reservation.conditionsAnnulation,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: motifAnnulation == null
                      ? AppColors.secondaire
                      : AppColors.nonEnregistreTexte,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: (motifAnnulation != null || _annulationEnCours)
                    ? null
                    : _confirmerAnnulation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.nonEnregistreTexte,
                  side: BorderSide(color: AppColors.nonEnregistreTexte),
                ),
                icon: _annulationEnCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_busy, size: 20),
                label: const Text('Annuler la réservation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
