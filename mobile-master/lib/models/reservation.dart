import 'package:resachev/models/usr.dart';

// DataClass représentant une réservation.
//
// Lot 2 :
//  - US 2.1 : les méthodes de date permettent de filtrer la journée, de trier
//    par heure de début et d'identifier un même client ;
//  - US 2.3 : [verifierValiditeQr] applique la fenêtre de validité du QR code ;
//  - US 2.5 : [montant], [dureeMinutes], [participants] et [finTheorique]
//    portent les informations complémentaires du rendez-vous ;
//  - US 2.6 : [motifAnnulationImpossible] centralise les conditions
//    d'annulation.
//
// Lot 3 :
//  - US 3.1 : [capacite], [placesRestantes] et [estComplete] décrivent le
//    remplissage d'un créneau, support de la liste d'attente ;
//  - US 3.2 : [estRecurrente] et [libelleRecurrenceAffiche] identifient les
//    rendez-vous issus d'une série, et [PorteeAnnulation] fixe le périmètre
//    d'une annulation (occurrence seule ou série entière).

class Reservation {
  final String idreservation;
  final DateTime? datedebut;
  final DateTime? heuredebut;

  /// Heure de fin fournie par l'API, si elle existe.
  final DateTime? heurefin;

  final bool? validationpresence;

  /// Horodatage de la validation de présence, si l'API le transmet.
  final DateTime? presenceValideeLe;

  final String? prestation;
  final User? utilisateur;

  /// Montant de la prestation, en euros (US 2.5).
  final double? montant;

  /// Durée de la prestation, en minutes (US 2.5).
  final int? dureeMinutes;

  /// Nombre de participants au rendez-vous (US 2.5).
  final int? participants;

  /// Identifiant de la série dont ce rendez-vous est une occurrence (US 3.2).
  final String? idrecurrence;

  /// Libellé de la récurrence (« Chaque mardi ») fourni par l'API (US 3.2).
  final String? libelleRecurrence;

  /// Dernière date de la série (US 3.2).
  final DateTime? finRecurrence;

  /// Numéro de l'occurrence dans la série, à partir de 1 (US 3.2).
  final int? numeroOccurrence;

  /// Nombre total d'occurrences prévues dans la série (US 3.2).
  final int? occurrencesTotal;

  /// Capacité du créneau, en places (US 3.1).
  final int? capacite;

  /// Places restantes transmises par l'API, si elle les expose (US 3.1).
  final int? placesRestantesApi;

  /// Nombre de personnes en liste d'attente (US 3.1).
  final int? nbListeAttente;

  Reservation({
    required this.idreservation,
    required this.datedebut,
    required this.heuredebut,
    required this.validationpresence,
    required this.prestation,
    required this.utilisateur,
    this.heurefin,
    this.presenceValideeLe,
    this.montant,
    this.dureeMinutes,
    this.participants,
    this.idrecurrence,
    this.libelleRecurrence,
    this.finRecurrence,
    this.numeroOccurrence,
    this.occurrencesTotal,
    this.capacite,
    this.placesRestantesApi,
    this.nbListeAttente,
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
        if (texte == 'true' || texte == '1' || texte == 'yes' || texte == 'y') {
          return true;
        }
        if (texte == 'false' || texte == '0' || texte == 'no' || texte == 'n') {
          return false;
        }
      }
      return null;
    }

    /// Montant accepté en nombre ou en chaîne (« 45,00 € »).
    double? parseMontant(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      final raw = value
          .toString()
          .replaceAll('€', '')
          .replaceAll(' ', '')
          .replaceAll(',', '.')
          .trim();
      if (raw.isEmpty) return null;
      return double.tryParse(raw);
    }

    /// Durée exprimée en minutes, en nombre ou en chaîne (« 90 », « 1:30 »,
    /// « 1 h 30 »).
    int? parseDuree(dynamic value) {
      if (value == null) return null;
      if (value is num) {
        final minutes = value.round();
        return minutes > 0 ? minutes : null;
      }
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;

      final direct = int.tryParse(raw);
      if (direct != null) return direct > 0 ? direct : null;

      final colonnes = raw.split(':');
      if (colonnes.length >= 2) {
        final heures = int.tryParse(colonnes[0]);
        final minutes = int.tryParse(colonnes[1]);
        if (heures != null && minutes != null) {
          final total = heures * 60 + minutes;
          return total > 0 ? total : null;
        }
      }

      final match = RegExp(
        r'^(\d+)\s*h\s*(\d{0,2})$',
        caseSensitive: false,
      ).firstMatch(raw);
      if (match != null) {
        final heures = int.tryParse(match.group(1) ?? '');
        final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
        if (heures != null) {
          final total = heures * 60 + minutes;
          return total > 0 ? total : null;
        }
      }
      return null;
    }

    int? parseEntier(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.round();
      return int.tryParse(value.toString().trim());
    }

    /// Une liste d'attente peut arriver sous forme de nombre ou de tableau.
    int? parseListeAttente(dynamic value) {
      if (value is List) return value.length;
      return parseEntier(value);
    }

    /// Texte non vide, en écartant les structures imbriquées.
    String? parseTexte(dynamic value) {
      if (value == null || value is Map || value is List) return null;
      final texte = value.toString().trim();
      return texte.isEmpty ? null : texte;
    }

    /// Horodatage ISO renvoyé par l'API (« 2026-10-31 09:12:00 »).
    DateTime? parseDateHeure(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw)?.toLocal();
    }

    final utilisateurOuClient = json['utilisateur'] ?? json['client'];

    return Reservation(
      idreservation: (json['idreservation'] ?? '').toString(),
      datedebut: parseDateFr(json['datedebut']),
      heuredebut: parseHeure(json['heuredebut']),
      heurefin: parseHeure(
        json['heurefin'] ?? json['heure_fin'] ?? json['heurefinprestation'],
      ),
      validationpresence: parsePresence(json['validationpresence']),
      presenceValideeLe: parseDateHeure(
        json['presencevalideele'] ??
            json['validationpresencele'] ??
            json['datevalidationpresence'] ??
            json['validationpresence_at'] ??
            json['presence_validee_le'],
      ),
      prestation: json['prestation']?.toString(),
      utilisateur: utilisateurOuClient is Map<String, dynamic>
          ? User.fromJson(utilisateurOuClient)
          : null,
      montant: parseMontant(
        json['montant'] ??
            json['prix'] ??
            json['tarif'] ??
            json['montantprestation'],
      ),
      dureeMinutes: parseDuree(
        json['duree'] ??
            json['duree_minutes'] ??
            json['dureeminutes'] ??
            json['dureeprestation'],
      ),
      participants: parseEntier(
        json['participants'] ??
            json['nbparticipants'] ??
            json['nombreparticipants'] ??
            json['nb_participants'],
      ),
      idrecurrence: parseTexte(
        json['idrecurrence'] ?? json['idserie'] ?? json['recurrence_id'],
      ),
      libelleRecurrence: parseTexte(
        json['libellerecurrence'] ??
            json['recurrence'] ??
            json['frequence'] ??
            json['libelle_recurrence'],
      ),
      finRecurrence: parseDateFr(
        json['finrecurrence'] ??
            json['datefinrecurrence'] ??
            json['daterecurrencefin'],
      ),
      numeroOccurrence: parseEntier(
        json['numerooccurrence'] ??
            json['numeroccurrence'] ??
            json['occurrence'],
      ),
      occurrencesTotal: parseEntier(
        json['nboccurrences'] ??
            json['totaloccurrences'] ??
            json['nombretotaloccurrences'],
      ),
      capacite: parseEntier(
        json['capacite'] ?? json['nbplaces'] ?? json['places'],
      ),
      placesRestantesApi: parseEntier(
        json['placesrestantes'] ??
            json['places_restantes'] ??
            json['nbplacesrestantes'],
      ),
      nbListeAttente: parseListeAttente(
        json['nbattente'] ??
            json['listeattente'] ??
            json['nb_liste_attente'] ??
            json['listattente'],
      ),
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

  // ---------------------------------------------------------------------------
  // US 2.5 : informations complémentaires du rendez-vous
  // ---------------------------------------------------------------------------

  /// Heure de fin théorique : celle de l'API si elle existe, sinon l'heure de
  /// début augmentée de la durée de la prestation.
  DateTime? get finTheorique {
    final debut = dateEtHeureDebut;
    if (debut == null) return null;

    if (heurefin != null) {
      return DateTime(
        debut.year,
        debut.month,
        debut.day,
        heurefin!.hour,
        heurefin!.minute,
      );
    }
    if (dureeMinutes != null) {
      return debut.add(Duration(minutes: dureeMinutes!));
    }
    return null;
  }

  /// Montant prêt à l'affichage (« 45,00 € » ou « Non renseigné »).
  String get montantAffiche {
    if (montant == null) return 'Non renseigné';
    return '${montant!.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  /// Durée prête à l'affichage (« 1 h 30 », « 45 min »).
  String get dureeAffichee {
    if (dureeMinutes == null) return 'Non renseignée';
    final heures = dureeMinutes! ~/ 60;
    final minutes = dureeMinutes! % 60;
    if (heures == 0) return '$minutes min';
    if (minutes == 0) return '$heures h';
    return '$heures h ${minutes.toString().padLeft(2, '0')}';
  }

  /// Nombre de participants prêt à l'affichage.
  String get participantsAffiches {
    if (participants == null) return 'Non renseigné';
    return participants == 1 ? '1 participant' : '$participants participants';
  }

  // ---------------------------------------------------------------------------
  // US 3.1 : capacité du créneau et liste d'attente
  // ---------------------------------------------------------------------------

  /// Places encore disponibles : valeur de l'API si elle existe, sinon la
  /// capacité diminuée des participants déjà inscrits.
  int? get placesRestantes {
    if (placesRestantesApi != null) return placesRestantesApi;
    if (capacite == null) return null;
    final int restantes = capacite! - (participants ?? 0);
    return restantes < 0 ? 0 : restantes;
  }

  /// Vrai lorsque le créneau n'a plus aucune place.
  bool get estComplete {
    final int? restantes = placesRestantes;
    return restantes != null && restantes <= 0;
  }

  /// Nombre de personnes en liste d'attente (0 lorsque l'API ne le transmet
  /// pas).
  int get nombreListeAttente => nbListeAttente ?? 0;

  /// La liste d'attente d'un créneau n'est proposée que s'il est complet ou
  /// si des inscriptions existent déjà.
  bool get listeAttenteDisponible => estComplete || nombreListeAttente > 0;

  /// Remplissage prêt à l'affichage (« 2 / 8 places disponibles »).
  String get placesAffichees {
    if (capacite == null) return 'Non renseignées';
    return '${placesRestantes ?? 0} / $capacite places disponibles';
  }

  // ---------------------------------------------------------------------------
  // US 3.2 : réservations récurrentes
  // ---------------------------------------------------------------------------

  /// Vrai lorsque ce rendez-vous appartient à une série.
  bool get estRecurrente =>
      (idrecurrence != null && idrecurrence!.isNotEmpty) ||
      libelleRecurrence != null ||
      occurrencesTotal != null;

  /// Description de la série prête à l'affichage.
  String get libelleRecurrenceAffiche {
    final List<String> parties = <String>[];
    parties.add(libelleRecurrence ?? 'Réservation récurrente');
    if (finRecurrence != null) {
      final String j = finRecurrence!.day.toString().padLeft(2, '0');
      final String m = finRecurrence!.month.toString().padLeft(2, '0');
      parties.add('jusqu\'au $j/$m/${finRecurrence!.year}');
    }
    return parties.join(' · ');
  }

  /// Position de l'occurrence dans la série (« Occurrence 3 sur 8 »).
  String? get occurrenceAffichee {
    if (numeroOccurrence == null) return null;
    if (occurrencesTotal == null) return 'Occurrence $numeroOccurrence';
    return 'Occurrence $numeroOccurrence sur $occurrencesTotal';
  }

  // ---------------------------------------------------------------------------
  // US 2.1 : journée, tri et recherche
  // ---------------------------------------------------------------------------

  bool estLeJour(DateTime jour) {
    final debut = dateEtHeureDebut;
    if (debut == null) return false;
    return debut.year == jour.year &&
        debut.month == jour.month &&
        debut.day == jour.day;
  }

  bool get estAujourdhui => estLeJour(DateTime.now());

  bool get estAvenir {
    final dateDebut = dateEtHeureDebut;
    return dateDebut != null && !dateDebut.isBefore(DateTime.now());
  }

  /// Vrai lorsque l'heure de début est déjà passée (US 2.1, règle 6).
  bool get estPassee {
    final dateDebut = dateEtHeureDebut;
    return dateDebut != null && dateDebut.isBefore(DateTime.now());
  }

  int comparerParDateEtHeure(Reservation autre) {
    final dateActuelle =
        dateEtHeureDebut ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateAutre =
        autre.dateEtHeureDebut ?? DateTime.fromMillisecondsSinceEpoch(0);
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

  /// Recherche une réservation à partir d'un nom de client et/ou d'une
  /// prestation (US 2.1, règle 2). La recherche ignore la casse et les
  /// accents pour faciliter les saisies.
  bool correspondRecherche(String? query) {
    final recherche = _normaliserRecherche(query);
    if (recherche.isEmpty) return true;

    final valeurRecherche = _normaliserRecherche(
      [nomClient, prestation ?? ''].join(' '),
    );

    return valeurRecherche.contains(recherche);
  }

  /// Vrai lorsque les deux rendez-vous concernent le même client (US 2.1,
  /// scénario 3). L'identifiant est privilégié ; à défaut, l'identité complète.
  bool memeClient(Reservation autre) {
    final int id = utilisateur?.idutilisateur ?? 0;
    final int idAutre = autre.utilisateur?.idutilisateur ?? 0;
    if (id > 0 && idAutre > 0) return id == idAutre;
    return nomClient.isNotEmpty &&
        _normaliserRecherche(nomClient) ==
            _normaliserRecherche(autre.nomClient);
  }

  // ---------------------------------------------------------------------------
  // US 2.2 / US 2.3 : validation de présence
  // ---------------------------------------------------------------------------

  /// Le QR code s'ouvre une demi-heure avant le début du rendez-vous.
  static const Duration qrOuvertureAvant = Duration(minutes: 30);

  /// Il expire trois quarts d'heure après le début du rendez-vous.
  static const Duration qrValiditeApres = Duration(minutes: 45);

  bool get estValidee => validationpresence == true;

  /// Validation manuelle possible le jour même, tant que la présence n'est pas
  /// déjà enregistrée.
  bool get presenceValidableManuellement => !estValidee && estAujourdhui;

  /// Contrôle la validité du QR code à l'instant [maintenant] (US 2.3).
  /// Retourne `null` si la présence peut être validée, sinon le motif du refus
  /// affiché à l'employé.
  String? verifierValiditeQr(DateTime maintenant) {
    final debut = dateEtHeureDebut;
    if (debut == null) {
      return 'La date du rendez-vous est inconnue : la présence ne peut pas '
          'être validée.';
    }
    if (estValidee) {
      return 'La présence de ce client a déjà été validée.';
    }

    final ouverture = debut.subtract(qrOuvertureAvant);
    final fermeture = debut.add(qrValiditeApres);

    if (maintenant.isBefore(ouverture)) {
      return 'QR code non valide : il est activé 30 minutes avant le début du '
          'rendez-vous (prévu le ${_dateCourte(debut)} à ${_heureCourte(debut)}).';
    }
    if (maintenant.isAfter(fermeture)) {
      return 'QR code expiré : il n\'est plus valide au-delà de 45 minutes '
          'après le début du rendez-vous (${_heureCourte(debut)}).';
    }
    return null;
  }

  /// Horodatage de la validation, pour l'affichage (US 2.2, règle 3).
  String? get presenceValideeHeure =>
      presenceValideeLe == null ? null : _heureCourte(presenceValideeLe!);

  // ---------------------------------------------------------------------------
  // US 2.6 : annulation
  // ---------------------------------------------------------------------------

  /// Conditions d'annulation retenues par le groupe : un rendez-vous peut être
  /// annulé jusqu'à son heure de début, à condition qu'il n'ait pas déjà été
  /// honoré. Aucun remboursement n'est traité par l'application mobile : le
  /// créneau est simplement remis à disposition.
  static const String conditionsAnnulation =
      'Annulation possible jusqu\'au début du rendez-vous. Le créneau redevient '
      'immédiatement disponible ; aucun remboursement n\'est géré par '
      'l\'application.';

  /// Retourne `null` si l'annulation est autorisée, sinon le message
  /// explicatif affiché à l'employé (US 2.6, scénario 2).
  String? motifAnnulationImpossible(DateTime maintenant) {
    final debut = dateEtHeureDebut;
    if (debut == null) {
      return 'La date du rendez-vous est inconnue : l\'annulation n\'est pas '
          'possible.';
    }
    if (estValidee) {
      return 'La présence du client est déjà validée : le rendez-vous a été '
          'honoré et ne peut plus être annulé.';
    }
    if (!debut.isAfter(maintenant)) {
      return 'Ce rendez-vous a déjà commencé ou est passé : il ne peut plus '
          'être annulé.';
    }
    return null;
  }

  bool peutEtreAnnulee(DateTime maintenant) =>
      motifAnnulationImpossible(maintenant) == null;

  // ---------------------------------------------------------------------------
  // Mise à jour locale après une action (validation de présence)
  // ---------------------------------------------------------------------------

  Reservation copyWith({
    bool? validationpresence,
    DateTime? presenceValideeLe,
    int? nbListeAttente,
    int? placesRestantesApi,
  }) {
    return Reservation(
      idreservation: idreservation,
      datedebut: datedebut,
      heuredebut: heuredebut,
      heurefin: heurefin,
      validationpresence: validationpresence ?? this.validationpresence,
      presenceValideeLe: presenceValideeLe ?? this.presenceValideeLe,
      prestation: prestation,
      utilisateur: utilisateur,
      montant: montant,
      dureeMinutes: dureeMinutes,
      participants: participants,
      idrecurrence: idrecurrence,
      libelleRecurrence: libelleRecurrence,
      finRecurrence: finRecurrence,
      numeroOccurrence: numeroOccurrence,
      occurrencesTotal: occurrencesTotal,
      capacite: capacite,
      placesRestantesApi: placesRestantesApi ?? this.placesRestantesApi,
      nbListeAttente: nbListeAttente ?? this.nbListeAttente,
    );
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
    return nom != null && nom.isNotEmpty && prenom != null && prenom.isNotEmpty;
  }

  static String _heureCourte(DateTime valeur) {
    final h = valeur.hour.toString().padLeft(2, '0');
    final m = valeur.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _dateCourte(DateTime valeur) {
    final j = valeur.day.toString().padLeft(2, '0');
    final m = valeur.month.toString().padLeft(2, '0');
    return '$j/$m/${valeur.year}';
  }
}

/// US 3.2 : périmètre d'une annulation demandée sur une réservation
/// récurrente.
///
/// - [occurrence] n'annule que la séance affichée ;
/// - [serie] annule la séance et toutes les occurrences à venir de la série.
///
/// Les occurrences passées ou déjà honorées ne sont jamais annulées par une
/// action sur la série.
enum PorteeAnnulation {
  occurrence,
  serie;

  String get libelle => this == PorteeAnnulation.serie
      ? 'Toute la série'
      : 'Cette séance uniquement';

  /// Valeur transmise à l'API (`portee`).
  String get valeurApi => name;
}
