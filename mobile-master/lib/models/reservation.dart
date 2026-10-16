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
      if (parts.length == 3) {
        final jour = int.tryParse(parts[0]);
        final mois = int.tryParse(parts[1]);
        final annee = int.tryParse(parts[2]);
        if (jour != null && mois != null && annee != null) {
          return DateTime(annee, mois, jour);
        }
      }

      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
      return null;
    }

    DateTime? parseHeure(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;

      final parts = raw.split(':');
      if (parts.length >= 2) {
        final heure = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (heure != null && minute != null) {
          return DateTime(2000, 1, 1, heure, minute);
        }
      }

      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateTime(2000, 1, 1, parsed.hour, parsed.minute);
      }
      return null;
    }

    bool? parsePresence(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final texte = value.trim().toLowerCase();
        if (texte == 'true' || texte == '1' || texte == 'yes' || texte == 'y') return true;
        if (texte == 'false' || texte == '0' || texte == 'no' || texte == 'n') return false;
      }
      return null;
    }

    final utilisateurOuClient = json['utilisateur'] ?? json['client'];

    return Reservation(
      idreservation: (json['idreservation'] ?? '').toString(),
      datedebut: parseDateFr(json['datedebut']),
      heuredebut: parseHeure(json['heuredebut']),
      validationpresence: parsePresence(json['validationpresence']),
      prestation: json['prestation']?.toString(),
      utilisateur: utilisateurOuClient is Map<String, dynamic>
          ? User.fromJson(utilisateurOuClient)
          : null,
    );
  }

  /// Nom et prénom du client, dans l'ordre « Prénom NOM ».
  /// Retourne une chaîne vide lorsque l'identité n'est pas renseignée.
  String get nomClient {
    return [utilisateur?.prenom, utilisateur?.nom]
        .where((String? valeur) => valeur != null && valeur.trim().isNotEmpty)
        .join(' ')
        .trim();
  }

  DateTime? get dateEtHeureDebut {
    if (datedebut == null) return null;
    final heure = heuredebut ?? DateTime(2000, 1, 1, 0, 0);
    return DateTime(
      datedebut!.year,
      datedebut!.month,
      datedebut!.day,
      heure.hour,
      heure.minute,
    );
  }

  bool get estAvenir {
    final dateDebut = dateEtHeureDebut;
    return dateDebut != null && !dateDebut.isBefore(DateTime.now());
  }

  int comparerParDateEtHeure(Reservation autre) {
    final dateActuelle = dateEtHeureDebut ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateAutre = autre.dateEtHeureDebut ?? DateTime.fromMillisecondsSinceEpoch(0);
    return dateActuelle.compareTo(dateAutre);
  }

  static String _normaliserRecherche(String? valeur) {
    final texte = (valeur ?? '').toLowerCase();
    final normalise = texte
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('œ', 'oe')
        .replaceAll('æ', 'ae')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalise;
  }

  /// Recherche une réservation à partir d'un nom de client et/ou d'une prestation.
  /// La recherche ignore la casse et les accents pour faciliter les saisies.
  bool correspondRecherche(String? query) {
    final recherche = _normaliserRecherche(query);
    if (recherche.isEmpty) return true;

    final valeurRecherche = _normaliserRecherche([
      nomClient,
      prestation ?? '',
    ].join(' '));

    return valeurRecherche.contains(recherche);
  }

  /// US 1.3 : indique si le client est enregistré pour cette prestation.
  ///
  /// L'API ne renvoie pas d'indicateur d'inscription dédié : on considère donc
  /// qu'un client est enregistré lorsque son identité (nom et prénom) est
  /// renseignée sur le rendez-vous. Une séance sans identité correspond à une
  /// personne non enregistrée, accueillie sans compte au studio.
  bool get clientEnregistre {
    final String? nom = utilisateur?.nom?.trim();
    final String? prenom = utilisateur?.prenom?.trim();
    return nom != null &&
        nom.isNotEmpty &&
        prenom != null &&
        prenom.isNotEmpty;
  }
}

