import 'package:flutter/material.dart';
import 'package:resachev/screens/screen_login/twofa_user.dart';
import 'package:resachev/services/api/gestionUsr/usr_api.dart';

class LoginUtilisateur extends StatefulWidget {
  const LoginUtilisateur({super.key});

  @override
  State<LoginUtilisateur> createState() => _LoginUtilisateurState();
}

class _LoginUtilisateurState extends State<LoginUtilisateur> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false; // Indicateur de chargement pour plus de modernité

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await UsrApi().loginUser(email, password);
      if (!mounted) return;

      final message = result?['message']?.toString() ?? '';
      final isSuccess = result != null &&
          (result['ok'] == true ||
              message.toLowerCase().contains('un code de vérification a été envoyé par email'));

      if (isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TwoFaUser(email: email)),
        );
      } else {
        _showSnackBar(result?['message'] ?? 'Échec de connexion');
      }
    } catch (e) {
      _showSnackBar('Une erreur est survenue');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating, // SnackBar moderne
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Fond blanc moderne/minimaliste
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: SingleChildScrollView( // Évite les bugs d'affichage avec le clavier
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header ultra minimaliste
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

                  // Champ Email
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Adresse email',
                      hintStyle: const TextStyle(color: Colors.black38),
                      prefixIcon: const Icon(Icons.mail_outline, color: Colors.black45, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F5), // Fond gris très clair discret
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none, // Pas de bordure brute
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ Mot de passe
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Mot de passe',
                      hintStyle: const TextStyle(color: Colors.black38),
                      prefixIcon: const Icon(Icons.lock_open_rounded, color: Colors.black45, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.black45,
                          size: 20,
                        ),
                        onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton de connexion moderne
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A), // Bouton noir / sombre
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0, // Pas d'ombre lourde pseudo-3D
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
