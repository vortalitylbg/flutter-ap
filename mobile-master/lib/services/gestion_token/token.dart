import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//classe pour la gestion du token de l'utilisateur stocké dans les préférences partagées de l'appareil android
class GestionToken {
  static final _storage = FlutterSecureStorage();

  //Permet de récupérer le token de l'utilisateur et de le sauver dans les préférences partagées
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  //permet de savoir si l'utilisateur est connecté en vérifiant si le token existe 
  static Future<bool> isLogged() async {
    return await _storage.read(key: 'auth_token') != null;
  }

  //Permet de ce déloger de l'utilisateur en supprimant le token
  static Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  //permet de récupérer le token de l'utilisateur
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}