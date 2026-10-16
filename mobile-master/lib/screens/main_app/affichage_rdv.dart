import 'package:flutter/material.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/services/api/gestionReservation/reservation_api.dart';
import 'package:resachev/theme/app_theme.dart';

// US 1.3 : la page des rendez-vous indique pour chaque séance si le client est
// enregistré ou non. Les deux états sont distingués à la fois par un code
// couleur (fond, liseré, badge) et par la graisse / le style de la police.

/// Ecran d'affichage des rendez-vous.
class Affichagerdv extends StatefulWidget {
  final void Function(Widget)? onNavigate;
  const Affichagerdv({super.key, this.onNavigate});

  @override
  State<Affichagerdv> createState() => _AffichagerdvState();
}

class _AffichagerdvState extends State<Affichagerdv> {
  late Future<List<Reservation>> _futureReservations;
  final TextEditingController _rechercheController = TextEditingController();
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _futureReservations = ReservationApi.listerReservations();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  // Méthode pour appeler l'API et rafraîchir la liste des rendez-vous
  Future<void> _rafraichir() async {
    setState(() {
      _futureReservations = ReservationApi.listerReservations();
    });
    await _futureReservations;
  }

  // Méthode pour formater la date au format "dd/MM/yyyy"
  String _formatDate(DateTime? date) {
    if (date == null) return 'Non définie';
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final annee = date.year.toString();
    return '$jour/$mois/$annee';
  }

  // Méthode pour formater l'heure au format "HH:mm"
  String _formatHeure(DateTime? heure) {
    if (heure == null) return 'Non définie';
    final h = heure.hour.toString().padLeft(2, '0');
    final m = heure.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Palette appliquée à une séance selon l'état d'enregistrement du client.
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

  /// Badge color announcing si le client est enregistré ou non.
  Widget _buildBadge(Reservation reservation) {
    final palette = _palette(reservation);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.texte,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(palette.icone, size: 14, color: AppColors.blanc),
          const SizedBox(width: 6),
          Text(
            palette.libelle,
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Police du nom du client : grass pour un client enregistré (US 1.3.2),
  /// italique pour un client non enregistré (US 1.3.3).
  static TextStyle _styleNomClient(bool enregistre) {
    return TextStyle(
      fontSize: 14,
      height: 1.35,
      color: enregistre ? AppColors.texte : AppColors.nonEnregistreTexte,
      fontWeight: enregistre ? FontWeight.w800 : FontWeight.w600,
      fontStyle: enregistre ? FontStyle.normal : FontStyle.italic,
    );
  }

  /// Ligne dédiée au client : applique le code couleur et la police
  /// correspondantes à l'état d'enregistrement (règles métier US 1.3.2 / 1.3.3).
  Widget _buildLigneClient(Reservation reservation) {
    final bool enregistre = reservation.clientEnregistre;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            width: 82,
            child: Text(
              'Client',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaire,
              ),
            ),
          ),
          Expanded(
            child: Text(
              enregistre
                  ? reservation.nomClient
                  : 'Identité non renseignée',
              style: _styleNomClient(enregistre),
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne d'information « libellé : valeur ».
  Widget _buildLigne(String libelle, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 82,
            child: Text(
              libelle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaire,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valeur,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.texte,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire la barre de recherche des rendez-vous par nom du
  // client et/ou prestation afin de confirmer la réservation concernée.
  Widget _buildBarreRecherche() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _rechercheController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom ou prestation',
          prefixIcon: const Icon(Icons.search, color: AppColors.principal),
          suffixIcon: _recherche.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.secondaire),
                  onPressed: () {
                    _rechercheController.clear();
                    setState(() => _recherche = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.bordure),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.principal, width: 1.6),
          ),
          filled: true,
          fillColor: AppColors.blanc,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (String query) {
          setState(() {
            _recherche = query;
          });
        },
      ),
    );
  }


  /// Méthode pour construire la carte d'une séance.
  ///
  /// Règle métier US 1.3.2 et 1.3.3 : la carte change de couleur selon que le
  /// client est enregistré ou non, et le nom du client est mis en valeur par
  /// une police adaptée (gras pour un client enregistré, italique pour un
  /// client non enregistré).
  Widget _buildCarteReservation(Reservation reservation) {
    final palette = _palette(reservation);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.fond,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.bordure.withValues(alpha: 0.35)),
      ),
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
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            reservation.prestation?.trim().isNotEmpty == true
                                ? reservation.prestation!.trim()
                                : 'Séance non précisée',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.texte,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.schedule,
                            size: 15, color: palette.texte),
                        const SizedBox(width: 4),
                        Text(
                          _formatHeure(reservation.heuredebut),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: palette.texte,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildBadge(reservation),
                    const SizedBox(height: 12),
                    _buildLigne('Date', _formatDate(reservation.datedebut)),
                    _buildLigneClient(reservation),
                    _buildLigne(
                      'Présence',
                      reservation.validationpresence == true
                          ? 'Validée'
                          : 'En attente',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bandeau récapitulatif du nombre de séances et d'artistes enregistrés.
  Widget _buildRecapitulatif(List<Reservation> reservations) {
    final int enregistres =
        reservations.where((Reservation r) => r.clientEnregistre).length;
    final int nonEnregistres = reservations.length - enregistres;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${reservations.length} séance${reservations.length > 1 ? 's' : ''} '
            'à venir',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.principal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.verified_user,
                  size: 16, color: AppColors.enregistreTexte),
              const SizedBox(width: 6),
              Text(
                '$enregistres enregistré${enregistres > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.enregistreTexte,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.person_off_outlined,
                  size: 16, color: AppColors.nonEnregistreTexte),
              const SizedBox(width: 6),
              Text(
                '$nonEnregistres non enregistré${nonEnregistres > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: AppColors.nonEnregistreTexte,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Message d'état vide.
  Widget _buildListeVide({String title = 'Aucune séance à venir.', String subtitle = 'Les réservations du studio apparaîtront ici.'}) {
    return RefreshIndicator(
      onRefresh: _rafraichir,
      child: ListView(
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          const Icon(Icons.event_busy_outlined,
              size: 44, color: AppColors.secondaire),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaire,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.secondaire),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Planning du studio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.principal,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Vérifiez la présence des artistes à chaque séance.',
                  style: TextStyle(fontSize: 13, color: AppColors.secondaire),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildBarreRecherche(),
        Expanded(
          child: FutureBuilder<List<Reservation>>(
            future: _futureReservations,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<Reservation>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.principal,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.cloud_off,
                          size: 40, color: AppColors.secondaire),
                      const SizedBox(height: 12),
                      const Text(
                        'Erreur lors du chargement des séances.',
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
                );
              }

              final List<Reservation> reservations = snapshot.data ?? <Reservation>[];
              final List<Reservation> reservationsFiltrees = reservations
                  .where((Reservation reservation) =>
                      reservation.correspondRecherche(_recherche))
                  .toList();

              if (reservationsFiltrees.isEmpty) {
                return _buildListeVide(
                  title: _recherche.trim().isEmpty
                      ? 'Aucune séance à venir.'
                      : 'Aucun rendez-vous trouvé.',
                  subtitle: _recherche.trim().isEmpty
                      ? 'Les réservations du studio apparaîtront ici.'
                      : 'Essayez un nom de client ou une prestation différente.',
                );
              }

              return RefreshIndicator(
                onRefresh: _rafraichir,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: reservationsFiltrees.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    // La première ligne de la liste est le bandeau récapitulatif.
                    if (index == 0) {
                      return _buildRecapitulatif(reservationsFiltrees);
                    }
                    return _buildCarteReservation(reservationsFiltrees[index - 1]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
