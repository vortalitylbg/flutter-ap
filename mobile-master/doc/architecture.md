# Architecture – ResaChev Application mobile (Flutter)

## Stack technique

| Couche | Technologie |
|---|---|
| Langage | Dart (SDK `^3.13.2`, *null safety* activée) |
| Framework | Flutter, widgets **Material 3** (`ColorScheme.fromSeed`) |
| Interface graphique | Widgets standards : `Scaffold`, `AppBar`, `NavigationBar`, `Card`, `ListView`, `FutureBuilder`, `TextField` |
| Accès aux données | `http` — appels REST vers l'**API mobile** de l'application web (Laravel) |
| Authentification | Jeton **Laravel Sanctum**, transmis en en-tête `Authorization: Bearer …` |
| Stockage local | `flutter_secure_storage` (jeton d'authentification, chiffré par le Keystore Android / le Keychain iOS) |
| Caméra / QR | `mobile_scanner` (^6.0.11) |
| Configuration | Fichier JSON embarqué dans les *assets* (`assets/env.dev.json`, `assets/env.prod.json`) |

Aucune bibliothèque de gestion d'état tierce (Provider, Riverpod, Bloc…) : l'état est porté par les `StatefulWidget` et `setState()`, ce qui suffit à la taille de l'application et reste lisible pour un lecteur qui découvre Flutter.

**Différence majeure avec l'application de gestion C#** : l'application mobile **ne parle jamais à MySQL**. Elle n'embarque ni pilote de base, ni requête SQL, ni ORM. Toute donnée transite par l'API web, qui reste seule responsable des règles métier et des accès à la base.

---

## Structure des dossiers

```
mobile/
├── pubspec.yaml                         ← dépendances, version, déclaration des assets
├── analysis_options.yaml                ← règles de lint (package flutter_lints ; dossiers natifs exclus)
├── assets/
│   ├── env.dev.json                     ← URL de l'API en développement
│   └── env.prod.json                    ← URL de l'API en production
├── android/ ios/ web/ linux/ windows/   ← projets natifs générés par Flutter
├── test/
│   └── widget_test.dart                 ← test généré par « flutter create » (non adapté)
└── lib/
    ├── main.dart                        ← point d'entrée : chargement de la config + MaterialApp
    │
    ├── models/                          ← objets métier (DataClass) et désérialisation JSON
    │   ├── usr.dart                     ← User
    │   └── reservation.dart             ← Reservation
    │
    ├── services/                        ← couche d'accès aux données (équivalent du Modele/ en C#)
    │   ├── api/
    │   │   ├── config.dart              ← AppConfig : lecture de l'URL de l'API selon la plateforme
    │   │   ├── gestionUsr/usr_api.dart  ← UsrApi : login, vérification du code 2FA, profil du staff
    │   │   └── gestionReservation/reservation_api.dart  ← ReservationApi : liste des rendez-vous, réservation par identifiant
    │   └── gestion_token/token.dart     ← GestionToken : jeton dans le stockage sécurisé (lecture / écriture / suppression)
    │
    ├── screens/                         ← écrans (une classe = une page)
    │   ├── screen_login/log_user.dart   ← saisie email + mot de passe
    │   ├── screen_login/twofa_user.dart ← saisie du code à 6 chiffres
    │   ├── affichage_plog.dart          ← coquille de l'application connectée (navigation)
    │   ├── main_app/accueil_app.dart    ← accueil + bouton d'accès au scanner
    │   ├── main_app/affichage_rdv.dart  ← liste des rendez-vous
    │   ├── main_app/param_app.dart      ← paramètres : identité du staff connecté (GET /mobile/me)
    │   └── scanner/scanner_screen.dart  ← lecture du QR code + appel de l'API
    │
    ├── widgets/                         ← composants réutilisables
    │   ├── app_bar.dart                 ← AppBarPrincipal
    │   └── bottom_bar.dart              ← BottomNavbar
    │
    └── doc/                             ← (ce dossier est à la racine du dépôt : doc/)
```

Les dossiers natifs sont **exclus de l'analyse statique** : `analysis_options.yaml` liste `build/`, `android/`, `ios/`, `web/`, `windows/` et — depuis la génération de la cible Linux — `linux/`, afin que `flutter analyze` ne rapporte que le code écrit dans `lib/`. Les fichiers `linux/flutter/generated_plugin_registrant.cc` et `generated_plugins.cmake` sont **générés par Flutter** : ils enregistrent `flutter_secure_storage_linux` et la bibliothèque FFI `jni` pour la cible desktop Linux, et ne se modifient jamais à la main.

Contrairement à Windows Forms, **un écran = un seul fichier** : il n'y a ni fichier généré par un concepteur visuel, ni fichier de ressources. L'interface est décrite **en code**, dans la méthode `build()`, sous forme d'un arbre de widgets.

---

## Découpage en couches

L'application applique le même découpage que l'application de gestion, transposé à Flutter :

```
   screens/ + widgets/ (présentation)        services/ (accès données)          API web (Laravel)
 ┌────────────────────────────────┐      ┌──────────────────────────┐      ┌──────────────────┐
 │ LoginUtilisateur, TwoFaUser,   │ ───▶ │ UsrApi                   │ ───▶ │ /api/mobile/…    │──▶ MySQL
 │ PageLogP, Accueil,             │      │ ReservationApi           │      │ (Sanctum)        │
 │ Affichagerdv, QrScannerScreen  │ ◀─── │ GestionToken · AppConfig │ ◀─── │                  │
 └────────────────────────────────┘      └──────────────────────────┘      └──────────────────┘
              │                                       │
              └──▶ models/ (User, Reservation) ◀──────┘
```

| Couche | Rôle | Règle |
|---|---|---|
| **Écrans** (`screens/`) | Affichent les données et réagissent aux gestes de l'utilisateur. Ne construisent **aucune URL** et ne manipulent **aucun JSON** : ils appellent les services. | Un écran n'importe jamais `dart:convert` ni `package:http` |
| **Widgets** (`widgets/`) | Composants d'interface réutilisés par plusieurs écrans (barre du haut, barre de navigation). | Sans logique métier |
| **Services** (`services/`) | Contiennent les appels HTTP, la lecture de la configuration et la gestion du jeton. Capturent les exceptions et retournent une valeur neutre (`[]`, `null`) ou une `Map` de résultat. | Point d'entrée unique vers l'extérieur |
| **Modèles** (`models/`) | Classes de données immuables (`final`) et leur constructeur `fromJson`. | Aucune dépendance à Flutter |

C'est l'équivalent mobile du trio `Form*.cs` → `Modele/` → `Entities/` de l'application C#. La différence de fond : la couche basse n'est pas un ORM sur une base locale, mais un **client HTTP** sur une API distante.

---

## Cycle de vie de l'application

`main()` est le point d'entrée. Il attend la fin du chargement de la configuration **avant** de construire l'interface :

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  // obligatoire avant tout accès aux assets
  await AppConfig.load();                     // lit assets/env.dev.json → AppConfig.apiBaseUrl
  runApp(const MyApp());
}
```

`WidgetsFlutterBinding.ensureInitialized()` initialise le lien entre le code Dart et le moteur Flutter : sans lui, `rootBundle.loadString()` échoue parce que le canal de communication avec la plateforme n'est pas encore ouvert.

```
main()
  │
  ├─ AppConfig.load()              ← assets/env.dev.json → apiBaseUrl, appVersion
  └─ runApp(MyApp)
        └─ MaterialApp(home: LoginUtilisateur)
              │
              ├─ POST /api/mobile/login ──────▶ TwoFaUser (pushReplacement)
              │                                     │
              │                                     ├─ POST /api/mobile/verify-2fa
              │                                     │     └─ jeton enregistré (FlutterSecureStorage)
              │                                     ▼
              └───────────────────────────────▶ PageLogP  ← coquille de l'application connectée
                                                    ├─ Accueil        (index 0) ─▶ QrScannerScreen
                                                    │                                 └─▶ GET /api/mobile/reservation/{id}/client
                                                    ├─ Affichagerdv   (index 1) ─▶ GET /api/mobile/rdv
                                                    └─ ParamApp       (index 2) ─▶ GET /api/mobile/me
```

L'application démarre **toujours** sur l'écran de connexion : le jeton éventuellement présent dans le stockage sécurisé n'est pas relu au lancement.

> **Point de vigilance.** Une reconnexion automatique serait simple à ajouter : appeler `GestionToken.isLogged()` dans `main()` et choisir `home:` en conséquence. En l'état, le staff ressaisit ses identifiants **et** un nouveau code 2FA à chaque ouverture de l'application, alors que le jeton stocké reste valide.

---

## Navigation

Deux mécanismes de navigation coexistent :

**1. La navigation par routes** (`Navigator`), pour les changements d'écran complets :

```dart
// Après la saisie des identifiants : on remplace l'écran, sans possibilité de revenir en arrière
Navigator.pushReplacement(context,
    MaterialPageRoute(builder: (context) => TwoFaUser(email: email)));

// Ouverture du scanner : push simple, la flèche « retour » ramène à l'accueil
Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QrScannerScreen()));
```

`pushReplacement` est employé pour le parcours de connexion : revenir en arrière sur l'écran de saisie du mot de passe après validation du code 2FA n'aurait pas de sens.

**2. L'échange du corps de page** dans `PageLogP`, pour les trois onglets. Le `Scaffold` reste en place ; seul son `body` change :

```dart
Future<void> _onDestinationSelected(int index) async {
  setState(() {
    currentPageIndex = index;
    switch (index) {
      case 0: currentBody = Accueil(onNavigate: afficherNouvellePage); break;
      case 1: currentBody = Affichagerdv(onNavigate: afficherNouvellePage); break;
      case 2: currentBody = const ParamApp(); break;
      default: currentBody = const Center(child: Text('Page introuvable'));
    }
  });
}
```

C'est exactement le rôle du `panelContent` et de `openChildForm()` de `FormMenu` côté C# : une coquille unique, dont on remplace le contenu.

| Onglet | Icône | Écran |
|---|---|---|
| Accueil | 🏠 `Icons.home` | `Accueil` — présentation + bouton flottant « Lire un QR code » |
| Liste des reservations | 📋 `Icons.list_alt` | `Affichagerdv` — rendez-vous à venir |
| Paramètres | ⚙️ `Icons.settings` | `ParamApp` — identité du staff connecté (`GET /mobile/me`) |

> **Points de vigilance.**
> 1. Le contrôle « l'utilisateur est-il connecté ? » est écrit **deux fois** : dans `BottomNavbar._verifValidite()` et dans `PageLogP._onDestinationSelected()`. Le premier bloque déjà l'appel, le second ne s'exécute donc jamais. Un seul des deux suffit — de préférence celui de la coquille, la barre restant un composant d'affichage.
> 2. Ce contrôle ne porte que sur l'onglet 1 : le scanner, atteint depuis l'accueil, reste accessible sans jeton. Il appelle désormais l'API : sans jeton, la lecture d'un QR code affiche « Réservation ou utilisateur introuvable » au lieu de renvoyer vers l'écran de connexion.
> 3. Le paramètre `onNavigate` est transmis à `Accueil` et `Affichagerdv`, mais **aucun des deux ne l'utilise** : c'est un reste d'une navigation abandonnée, à supprimer.
> 4. Le libellé de l'onglet d'accueil est orthographié « Acceuil ».

---

## Configuration : `AppConfig`

Flutter ne sait pas lire un fichier `.env` : la configuration est donc un **fichier JSON déclaré comme asset** et lu au démarrage.

```dart
class AppConfig {
  static late final String apiBaseUrl;
  static late final String appVersion;

  static Future<void> load() async {
    // CHANGER ICI pour passer en production
    // final jsonString = await rootBundle.loadString('assets/env.prod.json');
    final jsonString = await rootBundle.loadString('assets/env.dev.json');
    final Map<String, dynamic> config = jsonDecode(jsonString);

    if (kIsWeb)                 { apiBaseUrl = config['API_URL_WEB']; }
    else if (Platform.isAndroid){ apiBaseUrl = config['API_URL_ANDROID']; }
    else if (Platform.isIOS)    { apiBaseUrl = config['API_URL_IOS']; }
    // …
    appVersion = config['APP_VERSION'] ?? '1.0.0';
  }
}
```

Le test `kIsWeb` doit précéder tout accès à `Platform` : sur le web, `dart:io` n'existe pas et `Platform.isAndroid` lèverait une erreur — d'où l'import `dart:io show Platform` et l'ordre des conditions.

| Clé | `env.dev.json` | `env.prod.json` |
|---|---|---|
| `API_URL_ANDROID` | `http://192.168.1.17:8000/api` | *(chaîne vide)* |
| `API_URL_WEB` | `http://127.0.0.1:8000/api` | *(chaîne vide)* |
| `API_URL_DESKTOP` | `http://127.0.0.1:8000/api` | *(chaîne vide)* |
| `APP_VERSION` | `1.0.0-dev` | `1.0.0` |

`API_URL_ANDROID` pointe désormais sur l'**adresse IP du poste de développement** sur le réseau local, le développement se faisant sur téléphone physique : la valeur est donc à adapter à chaque poste et à chaque réseau, et l'API doit être lancée avec `php artisan serve --host=0.0.0.0`. Sur émulateur, la valeur à remettre est `http://10.0.2.2:8000/api`.

> **Points de vigilance.**
> 1. Le choix dev / prod se fait en **commentant une ligne de code**, ce qui suppose de recompiler et expose au risque de livrer une version pointant sur `localhost`. Flutter propose `--dart-define-from-file`, mentionné dans le `README.md` mais **non branché** dans le code : le fichier est lu depuis les assets, pas depuis les `--dart-define`. À unifier.
> 2. `API_URL_IOS` n'existe dans **aucun** des deux fichiers. Sur iOS, `apiBaseUrl` recevrait `null` alors qu'il est déclaré `late final String` : l'application planterait au démarrage.
> 3. **`env.prod.json` ne contient plus aucune URL** : les trois clés sont des chaînes vides depuis la réinitialisation du projet. Basculer en production en l'état construirait des URL de la forme `/mobile/login`, et **tous les appels échoueraient**. Les valeurs (`http://frontap3.dombtsig.local/api`, suffixe `/api` compris) sont à rétablir avant toute livraison.
> 4. `API_URL_ANDROID` contient une **adresse IP privée codée en dur** (`192.168.1.17`), propre au poste de son auteur : sur un autre poste ou un autre réseau, l'application ne joint plus rien. C'est un fichier de développement, mais la valeur ne devrait pas être versionnée telle quelle.
> 5. Les URL sont en `http://` alors que le manifeste **ne déclare toujours pas `android:usesCleartextTraffic="true"`**, supprimé par la réinitialisation et non rétabli à ce jour : depuis Android 9, le trafic en clair est refusé par défaut, et les appels API échouent sans message explicite. Il faut soit rétablir l'autorisation de trafic en clair (développement), soit passer l'API en HTTPS (production).
> 6. Les permissions `android.permission.INTERNET` et `android.permission.CAMERA`, elles aussi supprimées par la réinitialisation, ont été **rétablies** dans `android/app/src/main/AndroidManifest.xml` (commit « Ajout accès reseau et camera », 3 septembre 2026) : la compilation *release* émet de nouveau des requêtes et peut ouvrir la caméra. Il reste à restaurer la clé `NSCameraUsageDescription` du `Info.plist` iOS — voir [rendez-vous-et-scan.md](rendez-vous-et-scan.md).

---

## Conventions du projet

- **Commentaires** : en français, orientés pédagogie (le public cible est des étudiants BTS SIO).
- **Nommage** : les fichiers en `snake_case` (convention Dart), les classes en `PascalCase`. Le nommage des classes mélange français et anglais (`Accueil`, `Affichagerdv`, `GestionToken`, `UsrApi`) ; les méthodes privées d'un `State` sont préfixées d'un `_` (`_login`, `_submitCode`, `_onDetect`), convention Dart pour la visibilité **fichier**.
- **Immuabilité** : les modèles n'exposent que des champs `final` ; un objet `Reservation` reçu de l'API n'est jamais modifié.
- **`const`** : les widgets qui ne dépendent d'aucune variable sont déclarés `const`, ce qui évite leur reconstruction à chaque rendu (règle de lint `prefer_const_constructors`).
- **Gestion des erreurs** : les services encapsulent l'appel dans un `try/catch` et retournent une valeur neutre ; l'écran appelant affiche un `SnackBar` ou un état « vide ». Aucune exception ne remonte jusqu'à l'interface.
- **`if (!mounted) return;`** après chaque `await` précédant un usage de `context` : entre le lancement de la requête et sa réponse, l'utilisateur a pu quitter l'écran ; utiliser un `context` détaché lèverait une exception. La règle est appliquée dans `QrScannerScreen._onDetect()`, mais **oubliée dans `ParamApp.loadUser()`**, qui appelle `setState()` après un `await` sans vérifier `mounted` : quitter l'onglet Paramètres pendant le chargement du profil déclenche une exception.
