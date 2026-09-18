import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:resachev/models/usr.dart';
import 'package:resachev/services/api/config.dart';
import 'package:resachev/services/gestion_token/token.dart';

//classe permettant de gérer les appels à l'API pour la gestion des utilisateurs 

class UsrApi 
{
// Permet de se connecter à l'API et de récupérer les informations de l'utilisateur
Future<Map<String, dynamic>?> loginUser(String mail,String paswd) async {
  // Construction de l'URL de l'API pour la connexion
  final url = Uri.parse('${AppConfig.apiBaseUrl}/mobile/login');
    try {
    // Envoi de la requête POST à l'API avec les informations de connexion
    final response = await http
        .post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(<String, String>{
            'email': mail,
            'motpasse': paswd,           
          }),
        )
        .timeout(const Duration(seconds: 45));    

    Map<String, dynamic>? data;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        data = null;
      }
    }

    // Vérification du statut de la réponse 
    // Si la réponse est 200, la connexion a réussi
    if (response.statusCode == 200) {
      if (data != null) {
        return {
          'ok': true,
          'message': data['message'] ?? 'Connexion réussie',
          'user': data['data'],
        };
      }

      return {
        'ok': false,
        'message': data?['message'] ?? 'Réponse API invalide.',
        'user': null,
      };
    }

    if (response.statusCode == 401) {
      final backendMessage =
          data?['message'] ?? data?['error'] ?? data?['detail'] ?? 'Identifiants invalides ou accès non autorisé.';
      return {
        'ok': false,
        'message': backendMessage,
        'user': null,
      };
    }

    if (response.statusCode == 422) {
      return {
        'ok': false,
        'message': data?['message'] ?? 'Identifiants incorrects',
        'user': null,
      };
    }

    return {
      'ok': false,
      'message': data?['message'] ?? 'Erreur serveur (${response.statusCode})',
      'user': null,
    };
  } 
  catch (e) {
    return {
      'ok': false,
      'message': 'Erreur inattendue pendant la connexion API.',
      'user': null,
    };
  }
  }

  //Gestion de la double authentification 
  Future<Map<String, dynamic>?> verifyUser(String mail,String code) async {
  final url = Uri.parse('${AppConfig.apiBaseUrl}/mobile/verify-2fa');
  try {
    final response = await http
        .post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(<String, String>{
            'email': mail,
            'code': code,
          }),
        )
        .timeout(const Duration(seconds: 45));

    Map<String, dynamic>? data;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        data = null;
      }
    }

    // Vérification du statut de la réponse
    if (response.statusCode == 200) {
      final hasToken = data?['token'] != null;
      final hasUser = data?['utilisateur'] is Map<String, dynamic>;
      
      if (hasToken && hasUser) {
        // Enregistrement du token   
        await GestionToken.saveToken(data?['token']); 
        return {
          'ok': true,
          'message': data?['message'] ?? 'Connexion réussie',
          'token': data?['token'],
          'user': data?['utilisateur'],
        };
      }
      
      return {
        'ok': false,
        'message': data?['message'] ?? 'Réponse API invalide.',
        'user': null,
      };
    }

    if (response.statusCode == 401) {
      final backendMessage =
          data?['message'] ?? data?['error'] ?? data?['detail'] ?? 'Code invalide ou expiré.';
      return {
        'ok': false,
        'message': backendMessage,
        'user': null,
      };
    }

    if (response.statusCode == 422) {
      return {
        'ok': false,
        'message': data?['message'] ?? 'Données manquantes ou invalides.',
        'user': null,
      };
    }

    return {
      'ok': false,
      'message': data?['message'] ?? 'Erreur serveur (${response.statusCode})',
      'user': null,
    };
  } 
  catch (e) {
    return {
      'ok': false,
      'message': 'Erreur inattendue pendant la connexion API.',
      'user': null,
    };
  }
  }

static Future<User?> rechercherInfoUsr() async {
// Récupération du token de l'utilisateur pour l'authentification
    final token = await GestionToken.getToken();
        if (token == null || token.isEmpty) {
      return null;
    }

  final response = await http.get(
    Uri.parse('${AppConfig.apiBaseUrl}/mobile/me'),
    headers: {
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final raw = jsonDecode(response.body);
          return User.fromJson(raw);
    }
    
    return null;
  }
}
