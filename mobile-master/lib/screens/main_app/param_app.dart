import 'package:flutter/material.dart';
import 'package:resachev/models/usr.dart';
import 'package:resachev/services/api/gestionUsr/usr_api.dart';

// Ecran de paramètres de l'application
class ParamApp extends StatefulWidget {
  const ParamApp({super.key});

  @override
  State<ParamApp> createState() => _ParamAppState();
}

class _ParamAppState extends State<ParamApp> {
   User? me;
  @override
  void initState() {
    super.initState();    
    loadUser();
  }
    
  Future<void> loadUser() async {    
    final user = await UsrApi.rechercherInfoUsr();
    setState(() {
      me = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: <Widget>[          
          Expanded(
            child: ListView(
              children: [ 
                 Card(
                  margin: EdgeInsets.all(12),
                  child: 
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                        Text('Gestion des paramètres de l\'application',
                        style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),),
                        SizedBox(height: 8),

                        if (me != null) ...[
                          Text("Utilisateur : ${me!.prenom} ${me!.nom}",
                              style: TextStyle(fontSize: 16)),
                          
                        ] else ...[
                          Text("Chargement des informations...",
                              style: TextStyle(fontSize: 16)),
                        ],
                    ],
                    ),
                  ),
                ),      

                    
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}