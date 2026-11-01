import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:resachev/models/entree_attente.dart';
import 'package:resachev/models/reservation.dart';
import 'package:resachev/services/api/config.dart';
import 'package:resachev/services/gestion_token/token.dart';

// Classe permettant de gérer les appels à l'API pour la gestion des réservations
//
// Lot 2 :
//  - US 2.1 : la liste n'est plus filtrée sur les rendez-vous à venir ; le
//    filtrage par jour et par heure est fait par l'écran des rendez-vous ;
//  - US 2.2 / 2.3 : [validerPresence] transmet la présence au serveur ;
//  - US 2.6 : [annulerReservation] libère le créneau côté serveur.
//
// Lot 3 :
//  - US 3.1 : [listerListeAttente], [inscrireListeAttente] et [proposerPlace]
//    consultent et animent la liste d'attente d'un créneau complet ;
//  - US 3.2 : [annulerReservation] accepte une [PorteeAnnulation] pour
//    n'annuler qu'une occurrence ou toute la série.

class ReservationApi {
  /// Routes d'action du contrat d'API mobile.
  static const String cheminValiderPresence = '/mobile/valider-presence';
  static const String cheminAnnulerReservation = '/mobile/annuler-reservation';
  static const String cheminListeAttente = '/mobile/liste-attente';
  static const String cheminProposerPlace = '/mobile/liste-attente/proposer';

  static const Duration _delai = Duration(seconds: 20);

  // En-têtes communs aux requêtes authentifiées.
  static Map<String, String> _entetes(String token) {
    return <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Décode un corps JSON objet sans jamais lever d'exception.
  static Map<String, dynamic>? _decoder(String corps) {
    if (corps.isEmpty) return null;
    try {
      final decoded = json.decode(corps);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return null;
    }
    return null;
  }

  // Permet de récupérer la liste des réservations
  static Future<List<Reservation>> listerReservations() async {
    // Récupération du token de l'utilisateur pour l'authentification
    final token = await GestionToken.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token d’authentification absent.');
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/mobile/rdv');

    try {
      final response = await http
          .get(url, headers: _entetes(token))
          .timeout(_delai);

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode} lors de la récupération des rendez-vous.',
        );
      }

      final decoded = json.decode(response.body);

      List<dynamic> listeBrute = [];
      if (decoded is List) {
        listeBrute = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final nested =
            decoded['data'] ?? decoded['reservations'] ?? decoded['result'];
        if (nested is List) {
          listeBrute = nested;
        }
      }

      final reservations = listeBrute
          .whereType<Map<String, dynamic>>()
          .map(Reservation.fromJson)
          .toList();

      reservations.sort((a, b) => a.comparerParDateEtHeure(b));
      return reservations;
    } catch (e) {
      rethrow;
    }
  }

  // Permet de récupérer les informations d'une réservation
  static Future<Reservation?> infoReservationParId(String idreservation) async {
    // Récupération du token de l'utilisateur pour l'authentification
    final token = await GestionToken.getToken();
    if (token == null || token.isEmpty) {
      return null; // Non autorisé, utilisateur non connecté ou token manquant (période de session expirée)
    }
    // Construction de l'URL de l'API pour récupérer les réservations
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/mobile/reservation/$idreservation/client',
    );

    try {
      final response = await http
          .get(url, headers: _entetes(token))
          .timeout(_delai);

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        return null;
      }

      return Reservation.fromJson(data);
    } catch (e) {
      return null; // Erreur réponse serveur
    }
  }

  // ---------------------------------------------------------------------------
  // US 2.2 / US 2.3 : validation de la présence du client
  // ---------------------------------------------------------------------------

  /// Valide la présence du client à la réservation [idreservation].
  ///
  /// Retourne une carte normalisée :
  /// `{'ok': bool, 'message': String, 'nonAutorise': bool, 'dejaValidee': bool,
  ///   'dateValidation': String?}`.
  static Future<Map<String, dynamic>> validerPresence(
    String idreservation,
  ) async {
    final int? id = int.tryParse(idreservation.trim());
    if (id == null) {
      return <String, dynamic>{
        'ok': false,
        'message': 'Identifiant de réservation invalide.',
      };
    }

    final token = await GestionToken.getToken();
    if (token == null || token.isEmpty) {
      return <String, dynamic>{
        'ok': false,
        'nonAutorise': true,
        'message': 'Session expirée, veuillez vous reconnecter.',
      };
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}$cheminValiderPresence');

    try {
      final response = await http
          .post(
            url,
            headers: _entetes(token),
            body: jsonEncode(<String, dynamic>{'idreservation': id}),
          )
          .timeout(_delai);

      final data = _decoder(response.body);
      final message = data?['message']?.toString();

      if (response.statusCode == 200) {
        return <String, dynamic>{
          'ok': true,
          'message': message ?? 'Présence validée.',
          'dateValidation':
              (data?['datevalidation'] ??
                      data?['presencevalideele'] ??
                      data?['validationpresencele'] ??
                      data?['date'])
                  ?.toString(),
        };
      }

      if (response.statusCode == 409) {
        return <String, dynamic>{
          'ok': false,
          'dejaValidee': true,
          'message': message ?? 'La présence de ce client a déjà été validée.',
        };
      }

      if (response.statusCode == 401) {
        return <String, dynamic>{
          'ok': false,
          'nonAutorise': true,
          'message': message ?? 'Session expirée, veuillez vous reconnecter.',
        };
      }

      return <String, dynamic>{
        'ok': false,
        'message':
            message ??
            'Erreur serveur (${response.statusCode}) lors de la '
                'validation de la présence.',
      };
    } on TimeoutException {
      return <String, dynamic>{
        'ok': false,
        'message': 'Le serveur ne répond pas. Vérifiez la connexion.',
      };
    } catch (_) {
      return <String, dynamic>{
        'ok': false,
        'message': 'Erreur inattendue lors de la validation de la présence.',
      };
    }
  }

  // ---------------------------------------------------------------------------
  // US 2.6 : annulation d'une réservation
  // ---------------------------------------------------------------------------

  /// Annule la réservation [idreservation] afin de libérer le créneau.
  ///
  /// Pour une réservation récurrente, [portee] détermine si seule la séance
  /// affichée est annulée ou si toute la série à venir l'est (US 3.2).
  ///
  /// Retourne une carte normalisée :
  /// `{'ok': bool, 'message': String, 'nonAutorise': bool}`.
  static Future<Map<String, dynamic>> annulerReservation(
    String idreservation, {
    PorteeAnnulation portee = PorteeAnnulation.occurrence,
  }) async {
    final int? id = int.tryParse(idreservation.trim());
    if (id == null) {
      return <String, dynamic>{
        'ok': false,
        'message': 'Identifiant de réservation invalide.',
      };
    }

    final token = await GestionToken.getToken();
    if (token == null || token.isEmpty) {
      return <String, dynamic>{
        'ok': false,
        'nonAutorise': true,
        'message': 'Session expirée, veuillez vous reconnecter.',
      };
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}$cheminAnnulerReservation');

    try {
      final response = await http
          .post(
            url,
            headers: _entetes(token),
            body: jsonEncode(corpsAnnulation(id, portee)),
          )
          .timeout(_delai);

      final data = _decoder(response.body);
      final message = data?['message']?.toString();

      if (response.statusCode == 200 || response.statusCode == 204) {
        return <String, dynamic>{
          'ok': true,
          'portee': portee.valeurApi,
          'message':
              message ??
              (portee == PorteeAnnulation.serie
                  ? 'Série annulée : les créneaux à venir sont de nouveau '
                        'disponibles.'
                  : 'Réservation annulée : le créneau est de nouveau '
                        'disponible.'),
        };
      }

      if (response.statusCode == 409) {
        return <String, dynamic>{
          'ok': false,
          'message':
              message ??
              'Cette réservation ne peut plus être annulée : elle est passée '
                  'ou sa présence est déjà validée.',
        };
      }

      if (response.statusCode == 401) {
        return <String, dynamic>{
          'ok': false,
          'nonAutorise': true,
          'message': message ?? 'Session expirée, veuillez vous reconnecter.',
        };
      }

      return <String, dynamic>{
        'ok': false,
        'message':
            message ??
            'Erreur serveur (${response.statusCode}) lors de l\'annulation.',
      };
    } on TimeoutException {
      return <String, dynamic>{
        'ok': false,
        'message': 'Le serveur ne répond pas. Vérifiez la connexion.',
      };
    } catch (_) {
      return <String, dynamic>{
        'ok': false,
        'message': 'Erreur inattendue lors de l\'annulation.',
      };
    }
  }

  /// Corps JSON d'une annulation. La portée n'est envoyée que pour une série :
  /// sans elle, le serveur annule uniquement l'occurrence reçue, ce qui
  /// conserve le comportement du Lot 2.
  static Map<String, dynamic> corpsAnnulation(
    int idreservation,
    PorteeAnnulation portee,
  ) {
    final Map<String, dynamic> corps = <String, dynamic>{
      'idreservation': idreservation,
    };
    if (portee == PorteeAnnulation.serie) {
      corps['portee'] = portee.valeurApi;
    }
    return corps;
  }

  // ---------------------------------------------------------------------------
  // US 3.1 : liste d'attente
  // ---------------------------------------------------------------------------

  /// Retourne les inscriptions de la liste d'attente du créneau
  /// [idreservation], dans l'ordre de passage.
  ///
  /// Carte normalisée : `ok`, `message`, `entrees` (liste d'`EntreeAttente`)
  /// et `nonAutorise`.
  static Future<Map<String, dynamic>> listerListeAttente(
    String idreservation,
  ) async {
    final int? id = int.tryParse(idreservation.trim());
    if (id == null) {
      return <String, dynamic>{
        'ok': false,
        'message': 'Identifiant de réservation invalide.',
        'entrees': <EntreeAttente>[],
      };
    }

    final String? token = await GestionToken.getToken();
    if (token == null || token.isEmpty) {
      return <String, dynamic>{
        'ok': false,
        'nonAutorise': true,
        'message': 'Session expirée, veuillez vous reconnecter.',
        'entrees': <EntreeAttente>[],
      };
    }

    final Uri url = Uri.parse(
      '${AppConfig.apiBaseUrl}$cheminListeAttente?idreservation=$id',
    );

    try {
      final http.Response response = await http
          .get(url, headers: _entetes(token))
          .timeout(_delai);
      final Map<String, dynamic>? data = _decoder(response.body);
      final String? message = data?['message']?.toString();

      if (response.statusCode == 401) {
        return <String, dynamic>{
          'ok': false,
          'nonAutorise': true,
          'message': message ?? 'Session expirée, veuillez vous reconnecter.',
          'entrees': <EntreeAttente>[],
        };
      }

      if (response.statusCode != 200) {
        return <String, dynamic>{
          'ok': false,
          'message':
              message ??
              'Erreur serveur (${response.statusCode}) lors du chargement de '
                  'la liste d\'attente.',
          'entrees': <EntreeAttente>[],
        };
      }

      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (_) {
        decoded = null;
      }

      dynamic listeBrute = decoded;
      if (decoded is Map<String, dynamic>) {
        listeBrute =
            decoded['entrees'] ??
            decoded['listeattente'] ??
            decoded['data'] ??
            decoded['attente'];
      }

      final List<EntreeAttente> entrees = listeBrute is List
          ? listeBrute
                .whereType<Map<String, dynamic>>()
                .map(EntreeAttente.fromJson)
                .toList()
          : <EntreeAttente>[];
      entrees.sort((EntreeAttente a, EntreeAttente b) => a.comparerParOrdre(b));

      return <String, dynamic>{
        'ok': true,
        'message': message ?? 'Liste d\'attente chargée.',
        'entrees': entrees,
      };
    } on TimeoutException {
      return <String, dynamic>{
        'ok': false,
        'message': 'Le serveur ne répond pas. Vérifiez la connexion.',
        'entrees': <EntreeAttente>[],
      };
    } catch (_) {
      return <String, dynamic>{
        'ok': false,
        'message':
            'Erreur inattendue lors du chargement de la liste '
            'd\'attente.',
        'entrees': <EntreeAttente>[],
      };
    }
  }

  /// Inscrit un client sur la liste d'attente d'un créneau complet (US 3.1,
  /// scénario 1). L'employé saisit l'identité du client ; l'email sert à la
  /// notification envoyée par l'API web lorsqu'une place se libère.
  static Future<Map<String, dynamic>> inscrireListeAttente({
    required String idreservation,
    required String nom,
    required String prenom,
    required String email,
  }) async {
    final int? id = int.tryParse(idreservation.trim());
    if (id == null) {
      return <String, dynamic>{
        'ok': false,
        'message': 'Identifiant de réservation invalide.',
      };
    }

    final String? token = await GestionToken.getToken();
    if (token == null || token.isEmpty) {
      return <String, dynamic>{
        'ok': false,
        'nonAutorise': true,
        'message': 'Session expirée, veuillez vous reconnecter.',
      };
    }

    final Uri url = Uri.parse('${AppConfig.apiBaseUrl}$cheminListeAttente');

    try {
      final http.Response response = await http
          .post(
            url,
            headers: _entetes(token),
            body: jsonEncode(<String, dynamic>{
              'idreservation': id,
              'nom': nom.trim(),
              'prenom': prenom.trim(),
              'email': email.trim(),
            }),
          )
          .timeout(_delai);

      final Map<String, dynamic>? data = _decoder(response.body);
      final String? message = data?['message']?.toString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return <String, dynamic>{
          'ok': true,
          'message': message ?? 'Client inscrit sur la liste d\'attente.',
        };
      }

      if (response.statusCode == 401) {
        return <String, dynamic>{
          'ok': false,
          'nonAutorise': true,
          'message': message ?? 'Session expirée, veuillez vous reconnecter.',
        };
      }

      if (response.statusCode == 409) {
        return <String, dynamic>{
          'ok': false,
          'message':
              message ??
              'Ce client est déjà inscrit, ou le créneau n\'est plus complet.',
        };
      }

      return <String, dynamic>{
        'ok': false,
        'message':
            message ??
            'Erreur serveur (${response.statusCode}) lors de '
                'l\'inscription en liste d\'attente.',
      };
    } on TimeoutException {
      return <String, dynamic>{
        'ok': false,
        'message': 'Le serveur ne répond pas. Vérifiez la connexion.',
      };
    } catch (_) {
      return <String, dynamic>{
        'ok': false,
        'message':
            'Erreur inattendue lors de l\'inscription en liste '
            'd\'attente.',
      };
    }
  }

  /// Propose la place libérée à la première personne de la liste d'attente
  /// (US 3.1, scénario 2). C'est le serveur qui choisit l'entrée : l'ordre de
  /// passage reste premier arrivé, premier servi.
  ///
  /// Carte normalisée : `{'ok': bool, 'message': String,
  /// 'dateExpiration': String?, 'nonAutorise': bool}`.
  static Future<Map<String, dynamic>> proposerPlace(
    String idreservation,
  ) async {
    final int? id = int.tryParse(idreservation.trim());
    if (id == null) {
      return <String, dynamic>{
        'ok': false,
        'message': 'Identifiant de réservation invalide.',
      };
    }

    final String? token = await GestionToken.getToken();
    if (token == null || token.isEmpty) {
      return <String, dynamic>{
        'ok': false,
        'nonAutorise': true,
        'message': 'Session expirée, veuillez vous reconnecter.',
      };
    }

    final Uri url = Uri.parse('${AppConfig.apiBaseUrl}$cheminProposerPlace');

    try {
      final http.Response response = await http
          .post(
            url,
            headers: _entetes(token),
            body: jsonEncode(<String, dynamic>{'idreservation': id}),
          )
          .timeout(_delai);

      final Map<String, dynamic>? data = _decoder(response.body);
      final String? message = data?['message']?.toString();

      if (response.statusCode == 200) {
        return <String, dynamic>{
          'ok': true,
          'message': message ?? 'Place proposée au premier client en attente.',
          'dateExpiration':
              (data?['dateexpiration'] ??
                      data?['expirele'] ??
                      data?['propositionexpirele'])
                  ?.toString(),
        };
      }

      if (response.statusCode == 401) {
        return <String, dynamic>{
          'ok': false,
          'nonAutorise': true,
          'message': message ?? 'Session expirée, veuillez vous reconnecter.',
        };
      }

      if (response.statusCode == 409) {
        return <String, dynamic>{
          'ok': false,
          'message':
              message ??
              'Aucune place libre ou aucune personne en attente à prévenir.',
        };
      }

      return <String, dynamic>{
        'ok': false,
        'message':
            message ??
            'Erreur serveur (${response.statusCode}) lors de la proposition '
                'de la place.',
      };
    } on TimeoutException {
      return <String, dynamic>{
        'ok': false,
        'message': 'Le serveur ne répond pas. Vérifiez la connexion.',
      };
    } catch (_) {
      return <String, dynamic>{
        'ok': false,
        'message': 'Erreur inattendue lors de la proposition de la place.',
      };
    }
  }
}
