import 'package:flutter/material.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/services/api/gestionReservation/reservation_api.dart';

// Ecran d'affichage des rendez-vous

class Affichagerdv extends StatefulWidget {
  final void Function(Widget)? onNavigate;
  const Affichagerdv({super.key, this.onNavigate});

  @override
  State<Affichagerdv> createState() => _AffichagerdvState();
}

class _AffichagerdvState extends State<Affichagerdv> {
  late Future<List<Reservation>> _futureReservations;

  @override
  void initState() {
    super.initState();
    _futureReservations = ReservationApi.listerReservations();
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

  // Méthode pour construire la card contenant les informations d'une réservation
  Widget _buildCarteReservation(Reservation reservation) {
    final nomComplet = [
      reservation.utilisateur?.prenom,
      reservation.utilisateur?.nom,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reservation.prestation?.isNotEmpty == true
                  ? reservation.prestation!
                  : 'Prestation non précisée',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Date: ${_formatDate(reservation.datedebut)}'),
            Text('Heure: ${_formatHeure(reservation.heuredebut)}'),
            Text(
              'Client: ${nomComplet.isNotEmpty ? nomComplet : 'Non renseigné'}',
            ),
            Text(
              'Présence: ${reservation.validationpresence == true ? 'Validée' : 'En attente'}',
            ),
            //Text('ID: ${reservation.idreservation}'), Affichage de l'ID de réservation pour test
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Tous les rendez-vous',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Reservation>>(
              future: _futureReservations,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Erreur lors du chargement des rendez-vous.'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _rafraichir,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final reservations = snapshot.data ?? [];

                if (reservations.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _rafraichir,
                    child: ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Aucun rendez-vous trouvé.')),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _rafraichir,
                  child: ListView.builder(
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      return _buildCarteReservation(reservations[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}