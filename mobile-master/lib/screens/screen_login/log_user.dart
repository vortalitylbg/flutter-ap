import 'package:flutter/material.dart';
import 'package:resachev/screens/screen_login/twofa_user.dart';
import 'package:resachev/services/api/gestionUsr/usr_api.dart';



// Ecran de connexion pour les utilisateurs
class LoginUtilisateur extends StatefulWidget {
  const LoginUtilisateur({super.key});
  @override

   State<LoginUtilisateur> createState() => _LoginUtilisateurState();
}

class _LoginUtilisateurState extends State<LoginUtilisateur> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

  // Méthode pour gérer la connexion de l'utilisateur
  void _login() async{
    String email = emailController.text;
    String password = passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      final result = await UsrApi().loginUser(email, password);
      // Vérifie que le widget est toujours actif avant d'utiliser context (Bonne pratique pour éviter les erreurs de contexte)
      if (!mounted) return; 

      final message = result?['message']?.toString() ?? '';
      final isSuccess =
          result != null &&
          (result['ok'] == true ||
              message.toLowerCase().contains('un code de vérification a été envoyé par email'));

      if (isSuccess) {                       
        Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => TwoFaUser(email: email)),); // Ouvre la page permettant de saisir le code de la double authentification après la connexion
      } 

      else {
        final message = result?['message'] ?? 'Échec de connexion';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );    
      } 
    }   
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(title: Text('Connexion'), centerTitle: true,),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous pour continuer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),

            // Champ de saisie pour l'email
            TextField( 
              style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 15),
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFf3f4f6),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            // Champ de saisie pour le mot de passe + icone pour afficher/masquer le mot de passe
            TextField(
              style: TextStyle(color: Color(0xFF344d59),),
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
                filled: true,
                fillColor: Color(0xFFf3f4f6),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}