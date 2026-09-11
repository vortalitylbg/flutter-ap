# resachev

ResaChev propose une interface de gestion des réservations légère et accessible aux utilisateurs finaux. Elle couvre l'authentification, la visualisation des créneaux et la gestion du profil.

## Fonctionnalité
- Authentification : Connexion via login/mot de passe + authentification par code envoyé via mail 2FA.
- Liste des rendez-vous à venir.
- Lecture de QR code.

## Pré requis
- Android Studio avec :
    - NDK 27.0.12077973
    - Android SDK Command-line tools    

- SDK Flutter
- JAVA Version 17 
- API web fonctionnelle
- Mysql
- serveur d'envoit de mail (Mailhog)

## Contenu du projet 
- Le code source de l'application mobile

## Quelques conseils 
Une fois le projet cloné via le lien. 
Lancer votre éditeur de code avec flutter et dart à jour puis lancez la commande : 

```bash flutter pub get ``` 

Pour lancer l'application en mode dev vous pouvez utiliser la commande suivante : 

```bash flutter run --dart-define-from-file=env.dev.json ```

En cas d'erreur, vérifier le bon fonctionnement de Flutter sur votre poste vous pouvez executer la commande suivante dans une console :

```bash flutter doctor ``` 

## Documentation
La documentation du projet se trouve dans le dossier [`doc/`](doc/index.md) :

- [`doc/architecture.md`](doc/architecture.md) — structure du projet, couches, navigation, configuration
- [`doc/api-et-donnees.md`](doc/api-et-donnees.md) — API mobile consommée, jeton Sanctum, modèles de données
- [`doc/authentification.md`](doc/authentification.md) — connexion en deux étapes (identifiants puis code 2FA)
- [`doc/rendez-vous-et-scan.md`](doc/rendez-vous-et-scan.md) — liste des rendez-vous, lecture du QR code
- [`doc/sfd-std.md`](doc/sfd-std.md) — dossier de spécifications SFD / STD (PDF : `doc/sfd-std.pdf`, génération : `bash doc/tools/build.sh`)

## Technologies 
- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)
  
## Packages utilisés 
- [http](https://pub.dev/packages/http) Requête Http pour l'accès API
- [shared_preferences](https://pub.dev/packages/shared_preferences) Stockage local des préférences
- [mobile_scanner] (https://pub.dev/packages/mobile_scanner) Scan QR Code

## Note
Ce projet est réalisé à des fins pédagogiques
