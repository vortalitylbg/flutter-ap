import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:resachev/models/reservation.dart';
import 'package:resachev/services/api/config.dart';
import 'package:resachev/services/gestion_token/token.dart';

//Classe permettant de gérer les appels à l'API pour la gestion des réservations

class ReservationApi
{
  // Permet de récupérer la liste des réservations
  static Future<List<Reservation>> listerReservations() async {
    // Récupération du token de l'utilisateur pour l'authentification
    final token = await GestionToken.getToken();
        if (token == null || token.isEmpty) {
      return [];
    }
  // Construction de l'URL de l'API pour récupérer les réservations
    final url = Uri.parse('${AppConfig.apiBaseUrl}/mobile/rdv');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }
      // Décodage de la réponse JSON de l'API
      final decoded = json.decode(response.body);

      List<dynamic> listeBrute = [];
      // Vérification si la réponse est une liste
      if (decoded is List) {      
        listeBrute = decoded;
      } 
      // Convertion des données en objets Reservation
      return listeBrute
          .whereType<Map<String, dynamic>>()
          .map(Reservation.fromJson)
          .toList();
    } catch (_) {
      return [];
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
    final url = Uri.parse('${AppConfig.apiBaseUrl}/mobile/reservation/$idreservation/client');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      if (data["client"] != null && data["client"] is Map<String, dynamic>) {
        final client = data["client"];
        client["mail"] ??= client["email"];
      }

      return Reservation.fromJson(data);  
    }
     catch (e) {
      return null; // Erreur réponse serveur
    }
  }

} 