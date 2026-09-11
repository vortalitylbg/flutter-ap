import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resachev/screens/affichage_plog.dart';
import 'package:resachev/services/api/gestionUsr/usr_api.dart';


class TwoFaUser extends StatefulWidget {
  final String email;

  const TwoFaUser({super.key, required this.email});

  @override
  State<TwoFaUser> createState() => _TwoFaUserState();
}

class _TwoFaUserState extends State<TwoFaUser> {
  //Fonction permettant de passer automatiquement au champ suivant 
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  // Génération des 6 champs de saisie pour le code
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  String get _code => _controllers.map((c) => c.text).join();
  // Vérifie si les champs de saisie sont remplis
  bool get _isCodeComplete =>
      _controllers.every((controller) => controller.text.isNotEmpty);

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Méthode pour gérer la saisie des chiffres du code
  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }   
    
    setState(() {});
  }
  
  // Méthode pour soumettre le code saisi par l'utilisateur
  Future<void> _submitCode() async {
    if (!_isCodeComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir les 6 chiffres du code.')),
      );
      return;
    }
    // Appel à l'API pour vérifier le code saisi + Envoi email de l'utilisateur pour identifier le compte
    final result = await UsrApi().verifyUser(widget.email, _code);
    // Vérifie que le widget est toujours actif avant d'utiliser context (Bonne pratique pour éviter les erreurs de contexte)
    if (!mounted) {
      return;
    }

    final isSuccess = result != null && result['ok'] == true;
    if (!isSuccess) {
      final message = result?['message']?.toString() ?? 'Code invalide ou expiré.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    // Redirige vers la page d'accueil de l'application
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PageLogP()),
    );
  }

  Widget _buildDigitField(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) => _onDigitEntered(index, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Code d'authentification")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildDigitField(i),
              )),
            ),
            SizedBox(height: 24),
            SizedBox(              
              child: ElevatedButton(
                onPressed: _submitCode,
                child: Text('Valider'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

