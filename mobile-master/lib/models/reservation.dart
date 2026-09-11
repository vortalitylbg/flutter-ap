import 'package:resachev/models/usr.dart';
// DataClass représentant une réservation

class Reservation {
  final String idreservation;
  final DateTime? datedebut;
  final DateTime? heuredebut;
  final bool? validationpresence;
  final String? prestation;
  final User? utilisateur;

  Reservation({
    required this.idreservation,
    required this.datedebut,
    required this.heuredebut,
    required this.validationpresence,
    required this.prestation,
    required this.utilisateur,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateFr(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;

      final parts = raw.split('/');
      if (parts.length != 3) return DateTime.tryParse(raw);

      final jour = int.tryParse(parts[0]);
      final mois = int.tryParse(parts[1]);
      final annee = int.tryParse(parts[2]);
      if (jour == null || mois == null || annee == null) return null;
      return DateTime(annee, mois, jour);
    }

    DateTime? parseHeure(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;

      final parts = raw.split(':');
      if (parts.length < 2) return DateTime.tryParse(raw);

      final heure = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (heure == null || minute == null) return null;
      return DateTime(2000, 1, 1, heure, minute);
    }

    final utilisateurOuClient = json['utilisateur'] ?? json['client'];

    return Reservation(
      idreservation: (json['idreservation'] ?? '').toString(),
      datedebut: parseDateFr(json['datedebut']),
      heuredebut: parseHeure(json['heuredebut']),
      validationpresence: json['validationpresence'],
      prestation: json['prestation']?.toString(),
      utilisateur: utilisateurOuClient is Map<String, dynamic>
          ? User.fromJson(utilisateurOuClient)
          : null,
    );
  }

}

