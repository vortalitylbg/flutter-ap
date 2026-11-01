# API et données – ResaChev Application mobile (Flutter)

L'application mobile **n'a aucun accès direct** à la base de données. Toutes ses données proviennent de l'**API mobile** exposée par l'application web Laravel, protégée par **Laravel Sanctum**.

C'est une différence de nature avec l'application de gestion C#, qui ouvre elle-même une connexion MySQL : ici, aucune chaîne de connexion, aucun identifiant de base, aucun SQL. Le téléphone d'un membre du staff peut être perdu ou volé sans que cela expose la base.

```
┌───────────────┐   HTTPS/HTTP + Bearer   ┌────────────────┐   PDO   ┌─────────┐
│  Flutter      │ ───────────────────────▶│ Laravel (API)  │ ───────▶│  MySQL  │
│  (ce dépôt)   │ ◀─────────────────────── │  Sanctum       │ ◀────── │         │
└───────────────┘        JSON              └────────────────┘         └─────────┘
```

---

## URL de base

L'URL est choisie au démarrage par `AppConfig` en fonction de la plateforme (voir [architecture.md](architecture.md)) :

| Plateforme | URL en développement |
|---|---|
| Android (valeur actuelle de `env.dev.json`) | `http://192.168.1.17:8000/api` |
| Web / desktop | `http://127.0.0.1:8000/api` |

La valeur Android est l'**adresse du poste de développement sur le réseau local** : le développement se fait sur téléphone physique, ce qui impose de lancer le serveur Laravel avec `php artisan serve --host=0.0.0.0` et d'adapter l'adresse à chaque poste. Sur **émulateur**, la valeur à remettre est `http://10.0.2.2:8000/api` : `10.0.2.2` est l'adresse par laquelle l'émulateur Android atteint le `127.0.0.1` de la machine hôte, `localhost` y désignant l'émulateur lui-même.

> **Point de vigilance.** La permission `INTERNET` a été rétablie dans le manifeste Android, mais `android:usesCleartextTraffic="true"` y manque toujours (voir [architecture.md](architecture.md)) : depuis Android 9, ces URL en `http://` restent refusées par le système, en *debug* comme en *release*.

---

## Endpoints consommés

| Méthode | Route | Authentifié | Utilisé par |
|---|---|---|---|
| `POST` | `/mobile/login` | non | `UsrApi.loginUser()` — [authentification.md](authentification.md) |
| `POST` | `/mobile/verify-2fa` | non | `UsrApi.verifyUser()` — [authentification.md](authentification.md) |
| `GET` | `/mobile/rdv` | **oui** | `ReservationApi.listerReservations()` — [rendez-vous-et-scan.md](rendez-vous-et-scan.md) |
| `GET` | `/mobile/reservation/{id}/client` | **oui** | `ReservationApi.infoReservationParId()` — appelée après la lecture d'un QR code |
| `GET` | `/mobile/me` | **oui** | `UsrApi.rechercherInfoUsr()` — écran Paramètres |

Les deux dernières routes sont **branchées depuis la dernière version** : le scanner résout l'identifiant lu auprès de l'API au lieu d'analyser un texte, et l'écran Paramètres affiche l'identité du staff connecté.

### Routes ajoutées par le Lot 3

| Méthode | Route | Utilisé par |
|---|---|---|
| `GET` | `/mobile/liste-attente?idreservation={id}` | `ReservationApi.listerListeAttente()` — écran Liste d'attente |
| `POST` | `/mobile/liste-attente` | `ReservationApi.inscrireListeAttente()` — inscription d'un client à l'accueil |
| `POST` | `/mobile/liste-attente/proposer` | `ReservationApi.proposerPlace()` — proposition au premier inscrit |

`POST /mobile/annuler-reservation` accepte désormais un champ facultatif `portee` (`"serie"`) pour annuler toutes les occurrences à venir d'une réservation récurrente ; sans ce champ, seule l'occurrence est annulée. Les champs `capacite`, `placesrestantes`, `nbattente`, `idrecurrence`, `recurrence`, `finrecurrence`, `numerooccurrence` et `nboccurrences` sont lus s'ils sont présents sur `/mobile/rdv`. Règles, impacts et contrat détaillé : [lot3-attente-et-recurrence.md](lot3-attente-et-recurrence.md).

### Endpoint disponible mais **non utilisé**

| Méthode | Route | Ce qu'elle permettrait |
|---|---|---|
| `POST` | `/mobile/valider-presence` | **Valider la présence d'un client** à partir de l'`idreservation` lu dans le QR code |

> **Point de vigilance — fonctionnalité à terminer.** `POST /mobile/valider-presence` est le **cœur métier** de l'application mobile : c'est lui qui bascule `reservation.validationpresence` à `1` et fait apparaître le badge « Présence validée » dans l'espace client. Le scanner lit aujourd'hui le QR code mais **n'appelle jamais cette route** : la boucle fonctionnelle n'est pas fermée. Voir [rendez-vous-et-scan.md](rendez-vous-et-scan.md).

---

## Authentification par jeton

Après validation du code 2FA, l'API retourne un **jeton Sanctum**, conservé sur l'appareil dans le **stockage sécurisé** (`flutter_secure_storage`, qui s'appuie sur le Keystore d'Android et le Keychain d'iOS) :

```dart
class GestionToken {
  static final _storage = FlutterSecureStorage();

  static Future<void>    saveToken(String token) async => _storage.write(key: 'auth_token', value: token);
  static Future<bool>    isLogged()              async => await _storage.read(key: 'auth_token') != null;
  static Future<String?> getToken()              async => _storage.read(key: 'auth_token');
  static Future<void>    logout()                async => _storage.delete(key: 'auth_token');
}
```

Ce stockage remplace `shared_preferences`, employé jusqu'à la version précédente : le jeton n'est plus écrit en clair dans un fichier de préférences lisible sur un appareil *rooté*, mais chiffré par le système. L'interface de la classe n'a pas changé — c'est tout l'intérêt d'avoir isolé la gestion du jeton dans un service : le remplacement du mécanisme de stockage n'a modifié **aucun** appelant.

Le jeton est ensuite ajouté à chaque requête protégée :

```dart
headers: {
  'Content-Type': 'application/json; charset=UTF-8',
  'accept': 'application/json',
  'Authorization': 'Bearer $token',
}
```

L'en-tête `Accept: application/json` est important : sans lui, Laravel répond en HTML (page d'erreur) au lieu du JSON attendu, et le décodage échoue.

| Clé de stockage | Contenu | Durée de vie |
|---|---|---|
| `auth_token` | Jeton Sanctum, chiffré par le système (Keystore / Keychain) | Jusqu'à `logout()`, ou jusqu'à la prochaine connexion (l'API révoque les anciens jetons) |

> **Points de vigilance.**
> 1. `isLogged()` vérifie seulement la **présence** du jeton, pas sa validité : un jeton révoqué côté serveur laisse l'utilisateur entrer dans l'application, qui affichera ensuite une liste vide sans expliquer pourquoi.
> 2. `logout()` existe mais **n'est appelé nulle part** : il n'y a toujours pas de bouton de déconnexion, alors que l'écran Paramètres n'est plus vide et s'y prêterait naturellement.
> 3. Un **401** n'est pas distingué des autres erreurs par `ReservationApi` : quand le jeton expire, l'application affiche « Aucun rendez-vous trouvé » pour la liste et « Réservation ou utilisateur introuvable » après un scan, au lieu de renvoyer vers l'écran de connexion.
> 4. `FlutterSecureStorage()` est instancié sans options : il est prudent de prévoir le cas d'une lecture qui échoue (sauvegarde restaurée sur un autre appareil, clé du Keystore invalidée) — une exception y remonterait jusqu'à l'interface, aucun `try/catch` n'entourant les appels à `GestionToken`.

---

## Modèles de données

Les modèles sont de simples classes de données (*DataClass*) : des champs `final` et un constructeur nommé `fromJson`. Ils remplacent les entités générées par scaffolding de l'application C# — ici, rien n'est généré, tout est écrit à la main à partir du contrat d'API.

### `User` — `lib/models/usr.dart`

| Champ Dart | Type | Clé JSON | Origine SQL |
|---|---|---|---|
| `idutilisateur` | `int` | `idutilisateur` | `utilisateur.idutilisateur` |
| `nom` | `String?` | `nom` | `utilisateur.nom` |
| `prenom` | `String?` | `prenom` | `utilisateur.prenom` |
| `email` | `String?` | `email` | `utilisateur.email` |

```dart
factory User.fromJson(Map<String, dynamic> json) {
  int parseId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;                       // valeur absente ou d'un autre type
  }
  return User(
    idutilisateur: parseId(json['idutilisateur']),
    nom:    json['nom']?.toString(),
    prenom: json['prenom']?.toString(),
    email:  json['email']?.toString(),
  );
}
```

`parseId` illustre une règle de survie face à une API : **ne jamais faire confiance au type reçu**. Un identifiant peut arriver en nombre (`42`) ou en chaîne (`"42"`) selon la sérialisation ; un `as int` direct planterait dans le second cas.

Le champ s'appelait `mail` jusqu'à la version précédente ; il a été renommé **`email`**, du nom de la clé réellement envoyée par l'API. C'est le bon sens de correction : aligner le modèle sur le contrat, plutôt que traduire la clé à chaque lecture.

> **Points de vigilance.**
> 1. Le bloc `client` de `/mobile/rdv` ne contient que `nom` et `prenom` : `idutilisateur` y vaut donc toujours `0` et `email` reste `null`. Le modèle est prêt pour un contrat plus riche, que seule `/mobile/reservation/{id}/client` fournit aujourd'hui.
> 2. `ReservationApi.infoReservationParId()` conserve une ligne de compatibilité devenue **sans effet** : `client["mail"] ??= client["email"]` recopie `email` vers `mail`, alors que `User.fromJson` ne lit plus que `email`. À supprimer.

### `Reservation` — `lib/models/reservation.dart`

| Champ Dart | Type | Clé JSON | Format reçu |
|---|---|---|---|
| `idreservation` | `String` | `idreservation` | Nombre, converti en chaîne |
| `datedebut` | `DateTime?` | `datedebut` | `"07/07/2026"` (format français) |
| `heuredebut` | `DateTime?` | `heuredebut` | `"09:00"` |
| `validationpresence` | `bool?` | `validationpresence` | `true` / `false` |
| `prestation` | `String?` | `prestation` | Libellé de la prestation |
| `utilisateur` | `User?` | `utilisateur` **ou** `client` | Objet imbriqué |

Deux fonctions locales assurent la conversion, parce que l'API envoie des **chaînes déjà formatées** et non des dates ISO :

```dart
DateTime? parseDateFr(dynamic value) {
  final parts = value.toString().trim().split('/');   // "07/07/2026" → [07, 07, 2026]
  if (parts.length != 3) return DateTime.tryParse(raw);  // repli : format ISO
  return DateTime(annee, mois, jour);
}

DateTime? parseHeure(dynamic value) {
  final parts = value.toString().trim().split(':');   // "09:00" → [09, 00]
  return DateTime(2000, 1, 1, heure, minute);         // date fictive : seule l'heure importe
}
```

`parseDateFr` ne peut pas se contenter de `DateTime.parse()` : celui-ci attend le format ISO `2026-07-07` et rejetterait `07/07/2026`. Le repli sur `DateTime.tryParse()` rend le code tolérant si l'API changeait un jour de format.

L'heure est portée par un `DateTime` calé sur une date fictive (`1er janvier 2000`), faute de type « heure seule » en Dart — là où C# dispose de `TimeOnly`. Seuls `heure.hour` et `heure.minute` sont ensuite lus.

Enfin, la clé du client est acceptée sous deux noms, l'API ayant évolué :

```dart
final utilisateurOuClient = json['utilisateur'] ?? json['client'];
```

> **Points de vigilance.**
> 1. `validationpresence` est typé `bool?` et affecté **sans conversion** (`json['validationpresence']`). Cela ne fonctionne que parce que le modèle Eloquent côté web déclare `'validationpresence' => 'boolean'` dans ses *casts*. Si ce cast disparaissait, l'API renverrait `0` / `1`, l'affectation lèverait une `TypeError`… **avalée par le `catch` de `ReservationApi`**, et la liste s'afficherait vide sans le moindre message. Une conversion défensive (`value == true || value == 1 || value == '1'`) éviterait ce couplage invisible.
> 2. `idreservation` est stocké en `String` alors que `POST /mobile/valider-presence` attend un **entier**. Il faudra le reconvertir au moment d'implémenter la validation de présence.
> 3. Aucun modèle ne possède de méthode `toJson()` : l'application ne fait aujourd'hui que **lire**. Elle en aura besoin dès la première écriture.

---

## Forme des réponses de l'API

### `GET /api/mobile/rdv`

Retourne un **tableau JSON** de toutes les réservations à partir d'aujourd'hui, triées par date puis par heure :

```json
[
  {
    "idreservation": 42,
    "datedebut": "07/07/2026",
    "heuredebut": "09:00",
    "validationpresence": false,
    "prestation": "Balade à cheval",
    "client": { "nom": "Martin", "prenom": "Jean" }
  }
]
```

Côté Flutter, la conversion tient en trois appels chaînés :

```dart
final decoded = json.decode(response.body);
if (decoded is List) { listeBrute = decoded; }

return listeBrute
    .whereType<Map<String, dynamic>>()   // ignore les éléments d'un autre type
    .map(Reservation.fromJson)           // JSON → objet métier
    .toList();
```

`whereType<Map<String, dynamic>>()` est une sécurité : si un élément du tableau n'était pas un objet, il serait ignoré plutôt que de faire échouer toute la liste.

> **Point de vigilance.** Si l'API changeait pour envelopper la liste dans un objet (`{ "data": [ … ] }`), `decoded is List` serait faux, `listeBrute` resterait vide, et l'application afficherait « Aucun rendez-vous trouvé » **sans erreur visible**. Le contrat d'API doit donc être versionné et son évolution concertée avec l'équipe web.

### `GET /api/mobile/reservation/{id}/client`

Appelée par le scanner avec l'identifiant lu dans le QR code, elle retourne **un objet** décrivant la réservation et son client :

```json
{
  "idreservation": 42,
  "datedebut": "07/07/2026",
  "heuredebut": "09:00",
  "validationpresence": false,
  "prestation": "Balade à cheval",
  "client": { "idutilisateur": 7, "nom": "Martin", "prenom": "Jean", "email": "jean.martin@exemple.fr" }
}
```

Le service la consomme en réutilisant le même modèle que la liste — un seul `Reservation.fromJson` sert les deux routes, la clé `client` étant déjà acceptée comme équivalente à `utilisateur` :

```dart
final url = Uri.parse('${AppConfig.apiBaseUrl}/mobile/reservation/$idreservation/client');
final response = await http.get(url, headers: { /* … Authorization: Bearer … */ });

if (response.statusCode != 200) {
  return null;                       // jeton invalide, réservation inconnue, erreur serveur
}
return Reservation.fromJson(jsonDecode(response.body));
```

> **Point de vigilance.** Toutes les issues défavorables sont ramenées à un même `null` : jeton absent, `404`, `401` et exception réseau sont indiscernables. L'écran affiche par conséquent le même message — « Réservation ou utilisateur introuvable » — qu'il s'agisse d'un QR code inconnu ou d'un serveur éteint.

### `GET /api/mobile/me`

Retourne l'utilisateur connecté, converti directement en `User` par `UsrApi.rechercherInfoUsr()` :

```json
{ "idutilisateur": 3, "nom": "Durand", "prenom": "Claire", "email": "claire.durand@exemple.fr" }
```

> **Point de vigilance.** Cette méthode est la seule de `UsrApi` à ne poser **ni `timeout` ni `try/catch`** : une coupure réseau y lève une exception non interceptée, là où `loginUser()` et `verifyUser()` retournent un résultat exploitable. Elle est en outre `static`, alors que les deux autres sont des méthodes d'instance.

---

## Codes HTTP et messages

Chaque méthode de `UsrApi` traduit le code HTTP en un message affichable :

| Code | Signification | Traitement dans l'application |
|---|---|---|
| 200 | Succès | Poursuite du parcours (2FA, puis application) |
| 401 | Identifiants ou code invalides, ou rôle non staff | Message du serveur affiché tel quel |
| 422 | Données manquantes ou invalides | Message du serveur, ou message par défaut |
| autre | Erreur serveur | `Erreur serveur (<code>)` |
| — | Exception réseau / *timeout* (45 s) | `Erreur inattendue pendant la connexion API.` |

Le message renvoyé par le serveur est privilégié (`data?['message'] ?? …`) : l'application affiche ce que l'API explique, et ne conserve un texte en dur que comme dernier recours.

> **Point de vigilance.** Le `catch (e)` de `UsrApi` **ignore l'exception** : coupure réseau, serveur éteint, certificat refusé et JSON malformé produisent le même message. Journaliser `e` en mode *debug* (`debugPrint`) accélérerait beaucoup le diagnostic.
