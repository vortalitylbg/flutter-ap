import 'package:flutter/material.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/theme/app_theme.dart';

// US 2.1, scénario 3 : lorsqu'un employé sélectionne un client, l'ensemble de
// ses rendez-vous est affiché. La liste provient des rendez-vous chargés depuis
// l'API ; elle est triée du plus récent au plus ancien.

/// Historique des rendez-vous d'un client.
class HistoriqueClient extends StatelessWidget {
  final String nomClient;
  final List<Reservation> reservations;

  const HistoriqueClient({
    super.key,
    required this.nomClient,
    required this.reservations,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    final j = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$j/$m/${date.year}';
  }

  String _formatHeure(DateTime? heure) {
    if (heure == null) return '--:--';
    final h = heure.hour.toString().padLeft(2, '0');
    final m = heure.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildCarte(Reservation reservation) {
    final bool validee = reservation.estValidee;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _formatHeure(reservation.heuredebut),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.principal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(reservation.datedebut),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaire,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  reservation.prestation?.trim().isNotEmpty == true
                      ? reservation.prestation!.trim()
                      : 'Prestation non précisée',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.texte,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  validee ? 'Présence validée' : 'Présence en attente',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: validee
                        ? AppColors.enregistreTexte
                        : AppColors.secondaire,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.suivreTheme(context);

    final List<Reservation> triees = List<Reservation>.of(reservations)
      ..sort((a, b) => b.comparerParDateEtHeure(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Historique du client')),
      body: SafeArea(
        child: triees.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucun rendez-vous enregistré pour '
                    '${nomClient.isEmpty ? 'ce client' : nomClient}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.secondaire),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: <Widget>[
                  Text(
                    nomClient.isEmpty ? 'Client non identifié' : nomClient,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.principal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${triees.length} rendez-vous',
                    style: TextStyle(fontSize: 13, color: AppColors.secondaire),
                  ),
                  const SizedBox(height: 14),
                  for (final Reservation reservation in triees)
                    _buildCarte(reservation),
                ],
              ),
      ),
    );
  }
}
