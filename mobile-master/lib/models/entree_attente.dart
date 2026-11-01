// US 3.1 : inscription d'un client sur la liste d'attente d'un créneau complet.
//
// Une entrée est rattachée à un rendez-vous (le créneau) et à un client. Son
// rang est déterminé par l'ordre d'inscription (premier arrivé, premier servi).
// Lorsqu'une place se libère, la première entrée reçoit une proposition valable
// un temps limité ; passé ce délai, elle expire et la place est proposée à
// l'entrée suivante.

/// Statut d'une entrée de la liste d'attente.
enum StatutAttente {
  /// Le client attend qu'une place se libère.
  enAttente,

  /// Une place vient d'être libérée et lui est proposée pour une durée limitée.
  proposee,

  /// La proposition n'a pas été acceptée dans le délai imparti.
  expiree,

  /// Le client a obtenu la place : la réservation correspondante a été créée.
  convertie,

  /// Le client s'est retiré de la liste d'attente.
  annulee,
}

/// Une entrée de liste d'attente, telle que renvoyée par l'API mobile.
class EntreeAttente {
  /// Identifiant de l'inscription (clé de l'action « proposer »).
  final String idattente;

  /// Créneau concerné.
  final String idreservation;

  /// Identité du client.
  final String nomClient;

  /// Adresse utilisée pour prévenir le client (API web).
  final String? email;

  /// Date et heure d'inscription, pour l'ordre de passage.
  final DateTime? inscritLe;

  /// Fin de la proposition lorsqu'une place a été libérée.
  final DateTime? propositionExpireLe;

  final StatutAttente statut;

  /// Rang fourni par l'API, sinon calculé à l'affichage.
  final int? position;

  const EntreeAttente({
    required this.idattente,
    required this.idreservation,
    required this.nomClient,
    this.email,
    this.inscritLe,
    this.propositionExpireLe,
    this.statut = StatutAttente.enAttente,
    this.position,
  });

  factory EntreeAttente.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateHeure(dynamic value) {
      if (value == null) return null;
      final String raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw)?.toLocal();
    }

    int? parseEntier(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.round();
      return int.tryParse(value.toString().trim());
    }

    String? parseTexte(dynamic value) {
      if (value == null || value is Map || value is List) return null;
      final String texte = value.toString().trim();
      return texte.isEmpty ? null : texte;
    }

    final dynamic client = json['client'] ?? json['utilisateur'];
    String? nom = parseTexte(json['nomclient'] ?? json['nomcomplet']);
    String? prenom = parseTexte(json['prenom']);
    String? email = parseTexte(json['email'] ?? json['mail']);
    if (client is Map<String, dynamic>) {
      nom ??= parseTexte(client['nom']);
      nom ??= parseTexte(client['nomclient']);
      prenom ??= parseTexte(client['prenom']);
      email ??= parseTexte(client['email'] ?? client['mail']);
      if (nom != null && prenom != null) {
        // « Prénom NOM », comme le reste de l'application.
        nom = '${prenom.trim()} ${nom.trim()}'.trim();
        prenom = null;
      }
    }
    if (nom == null && prenom != null) nom = prenom;
    final String statutBrut = (parseTexte(json['statut']) ?? '').toLowerCase();
    final DateTime? propositionExpireLe = parseDateHeure(
      json['propositionexpirele'] ??
          json['dateexpirationproposition'] ??
          json['expirele'],
    );

    StatutAttente statut;
    switch (statutBrut) {
      case 'proposee':
      case 'propose':
      case 'offre':
      case 'offert':
        statut = StatutAttente.proposee;
        break;
      case 'expiree':
      case 'expire':
        statut = StatutAttente.expiree;
        break;
      case 'convertie':
      case 'converti':
      case 'confirmee':
      case 'acceptee':
        statut = StatutAttente.convertie;
        break;
      case 'annulee':
      case 'annule':
      case 'retiree':
        statut = StatutAttente.annulee;
        break;
      default:
        statut = StatutAttente.enAttente;
    }

    // Une proposition en cours est identifiable par sa date d'expiration même
    // si l'API n'envoie pas encore de statut explicite.
    if (statutBrut.isEmpty && propositionExpireLe != null) {
      statut = StatutAttente.proposee;
    }

    return EntreeAttente(
      idattente: (json['idattente'] ?? json['id'] ?? '').toString(),
      idreservation: (json['idreservation'] ?? '').toString(),
      nomClient: nom ?? 'Client non identifié',
      email: email,
      inscritLe: parseDateHeure(
        json['inscritle'] ?? json['dateinscription'] ?? json['created_at'],
      ),
      propositionExpireLe: propositionExpireLe,
      statut: statut,
      position: parseEntier(json['position'] ?? json['rang']),
    );
  }

  /// Vrai lorsque la place est actuellement proposée à ce client.
  bool estProposee(DateTime maintenant) {
    if (statut != StatutAttente.proposee) return false;
    if (propositionExpireLe == null) return true;
    return propositionExpireLe!.isAfter(maintenant);
  }

  /// Vrai lorsque la proposition a dépassé son délai et que la place doit être
  /// proposée à l'entrée suivante.
  bool estPropositionExpiree(DateTime maintenant) =>
      statut == StatutAttente.proposee &&
      propositionExpireLe != null &&
      !propositionExpireLe!.isAfter(maintenant);

  /// Vrai lorsque le client attend toujours son tour.
  bool get estEnAttente =>
      statut == StatutAttente.enAttente || statut == StatutAttente.expiree;

  /// Libellé du statut, adapté à l'employé.
  String libelleStatut(DateTime maintenant) {
    switch (statut) {
      case StatutAttente.proposee:
        if (propositionExpireLe == null) {
          return 'Place proposée au client';
        }
        if (estPropositionExpiree(maintenant)) {
          return 'Proposition expirée';
        }
        return 'Place proposée jusqu’à ${_heure(propositionExpireLe!)}';
      case StatutAttente.expiree:
        return 'Proposition expirée';
      case StatutAttente.convertie:
        return 'Place obtenue';
      case StatutAttente.annulee:
        return 'Inscription annulée';
      case StatutAttente.enAttente:
        return 'En attente d’une place';
    }
  }

  /// Couleur du statut, dans la palette de l'application.
  bool get statutPositif =>
      statut == StatutAttente.proposee || statut == StatutAttente.convertie;

  /// Ordre de passage : rang fourni par l'API, sinon date d'inscription.
  int comparerParOrdre(EntreeAttente autre) {
    if (position != null && autre.position != null) {
      return position!.compareTo(autre.position!);
    }
    if (position != null) return -1;
    if (autre.position != null) return 1;
    final DateTime ici = inscritLe ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime la =
        autre.inscritLe ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ici.compareTo(la);
  }

  static String _heure(DateTime valeur) {
    final String h = valeur.hour.toString().padLeft(2, '0');
    final String m = valeur.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
