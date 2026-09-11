# AGENTS.md - ResaChev Web

Instructions pour les agents IA intervenant sur ce projet.

---

## Contexte du projet

**ResaChev** est une plateforme open-source de réservation de créneaux.  
Ce dépôt est l'**interface web** (PHP / Laravel). Deux autres applications partagent la même base de données : une application bureau C# (back-office admin) et une application mobile Flutter (staff terrain).

### Fonctionnalités couvertes par ce front web
- Authentification email / mot de passe avec **double authentification par email (2FA)**
- Tableau de bord : prochain créneau réservé + grille de créneaux sur 7 jours (J-1 → J+5) gérée par Vue.js
- API JSON interne `GET /espace/creneaux?debut=Y-m-d` consommée par Vue.js via `fetch()`
- Édition du profil (nom uniquement — le reste est à compléter par les étudiants)
- Affichage du QR code à faire scanner par le staff + billet imprimable (print.css)

### Fonctionnalités hors périmètre
- Partie vitrine / présentation publique
- Back-office (gestion créneaux, utilisateurs) → application C#
- Scan QR code et liste des RDV du jour → application Flutter

---

## Stack technique

- PHP 8.x / Laravel 11.x
- Base de données : MySQL (pas de SQLite en production)
- Authentification : **faite manuellement**, sans Laravel Breeze ni Fortify — mots de passe stockés et comparés en clair (TODO étudiant : hachage bcrypt)
- Emails : SMTP (requis pour la 2FA)
- CSS : Bootstrap 5.3 via CDN (pas de Vite/npm pour les styles) + `public/css/main.css` (global) + `public/css/print.css` (billet QR)
- JS : Vue.js 3 (`public/js/vue.global.prod.js`) et qrcodejs (`public/js/qrcode.min.js`) — **toujours locaux, pas de CDN**

---

## Base de données

La BDD est partagée entre les trois applications. **Ne pas modifier le schéma sans concertation.**  
Les noms de tables et de colonnes sont en français, au singulier, en minuscules.

### Tables et clés primaires

| Table | Clé primaire | Timestamps |
|---|---|---|
| `parametrage` | `idparam` | non |
| `prestation` | `idprestation` | non |
| `role` | `idrole` | non |
| `utilisateur` | `idutilisateur` | oui (`created_at`, `updated_at`) |
| `reservation` | `idreservation` | non |

Tables Laravel internes (hors BDD métier) : `sessions`, `cache`, `jobs`, `personal_access_tokens`.

### Points importants
- La table `utilisateur` utilise `motpasse` (pas `password`) et `idrole` (FK nullable).
- La 2FA est stockée dans `two_factor_code` (varchar 10) et `two_factor_expires_at` (datetime).
- `reservation.validationpresence` est un tinyint (0/1) qui indique si le client a été scanné par le staff.
- Il n'y a **pas de table `creneau`** : les créneaux disponibles sont calculés dynamiquement à partir de `parametrage.dureeCreneau` (valeur : 30 minutes).

### Seeders (`database/seeders/`)

**Les migrations ne créent plus que le schéma.** Les données de référence ont été sorties de `2026_07_02_000000_create_resachev_tables` vers des seeders. Conséquence directe : `php artisan migrate` seul produit une base inutilisable, l'application ne démarrant pas sans `parametrage`, et aucun utilisateur ne pouvant être créé sans `role`.

| Seeder | Contenu |
|---|---|
| `RoleSeeder` | 1 = client, 2 = staff |
| `ParametrageSeeder` | `nomPlateforme`, `dureeCreneau` = 30 minutes |
| `PrestationSeeder` | deux prestations d'exemple |
| `ReferenceSeeder` | appelle les trois ci-dessus, dans cet ordre (clés étrangères) |
| `DatabaseSeeder` | `ReferenceSeeder` puis les données de démonstration |

Deux commandes selon le besoin :

```bash
# Commande de référence : schéma + données de référence + démonstration
php artisan migrate:fresh --seed

# Base existante à ne pas détruire : données de référence seules
php artisan db:seed --class=ReferenceSeeder
```

`migrate:fresh --seed` supprime toutes les tables avant de les recréer, à réserver au développement.

Tous les seeders utilisent `updateOrInsert` sur la clé primaire : ils sont réexécutables sans erreur de doublon. En contrepartie, relancer `PrestationSeeder` écrase les prestations 1 et 2, à éviter sur une base de production alimentée depuis le back-office.

`tests/TestCase.php` déclare `$seed = true` et `$seeder = ReferenceSeeder::class`. C'est indispensable : `RefreshDatabase` joue les migrations mais aucun seeder, et les données de référence n'étant plus dans la migration, les tests échoueraient sur la clé étrangère `utilisateur.idrole` et sur `parametrage.nomPlateforme`. `ReferenceSeeder` et non `DatabaseSeeder`, pour que les comptes de démonstration ne faussent pas les assertions.

#### Données de démonstration (`DatabaseSeeder`)

Lancé par `php artisan migrate:fresh --seed`. En plus des données de référence, il crée :

- Deux comptes clients, `test@example.com` (Jean Dupont) et `marie@example.com` (Marie Martin), mot de passe `password` pour les deux. Les mots de passe sont stockés **en clair**, comme le fait `UtilisateurFactory`, pour rester cohérent avec la connexion qui compare les chaînes directement. Un mot de passe haché rendrait les comptes inutilisables.
- Six réservations de démonstration, trois par client, aux dates **calculées au lancement** et non écrites en dur, pour qu'elles restent dans la fenêtre J-1 à J+5 du tableau de bord. Chaque client a une réservation la veille avec `validationpresence = true` et deux le lendemain avec `validationpresence = false`.

Deux clients plutôt qu'un, c'est délibéré : la grille n'exerce ses quatre statuts que s'il existe des réservations appartenant à quelqu'un d'autre. Connecté en Jean, ses propres créneaux s'affichent en `valide` et `ma_reservation`, ceux de Marie en `occupe` sans que sa prestation soit divulguée, et la vue est symétrique en se connectant en Marie. Garder au moins deux clients si le seeder évolue.

Les heures ne doivent pas se chevaucher entre les deux clients, et doivent rester alignées sur la grille des créneaux (08:00 à 18:00, pas de 30 minutes), sinon les réservations n'apparaissent dans aucune case du calendrier.

### Données initiales

Elles ne sont **plus** créées par la migration mais par `ReferenceSeeder` (voir la section Seeders) :

- `role` : 1 = client, 2 = staff
- `parametrage` : `nomPlateforme` = "Réservation en ligne", `dureeCreneau` = 30 minutes
- `prestation` : deux prestations d'exemple

---

## Modèles Eloquent

Chaque table a son modèle dans `app/Models/`. Conventions appliquées :

- `$table` et `$primaryKey` toujours explicités (noms non standards)
- `public $timestamps = false` sur toutes les tables sauf `utilisateur`
- `$fillable` complet sur chaque modèle
- Les relations utilisent toujours les clés explicites (3 arguments)

### Particularités du modèle `Utilisateur`
- Étend `Authenticatable` (pas `Model`)
- Traits : `HasApiTokens`, `HasFactory`, `Notifiable`
- `getAuthPassword()` retourne `$this->motpasse`
- `getRememberTokenName()` retourne `null` (pas de colonne remember_token)
- `motpasse` est stocké **en clair** (pas de cast `hashed`) — TODO étudiant : ajouter le hachage via `password_hash()` à la création/modification et `password_verify()` à la connexion
- Méthode `verifierCode2FA(string $code): bool` disponible
- Méthode `prochaineReservation()` : HasOne filtré sur `datedebut >= aujourd'hui`

### Accès aux paramètres
```php
Parametrage::getValeur('dureeCreneau'); // retourne '30'
```

### Fichier résiduel
`app/Models/User.php` est un fichier résiduel de Laravel, il n'est **pas utilisé**. Ne pas y faire référence.

---

## Authentification

- **Pas de Breeze, pas de Fortify** : l'authentification est implémentée manuellement.
- Flow 2FA web : `POST /connexion` → génère code + envoie email + stocke `2fa_email` en session → `POST /connexion/verification` → `Auth::login()` + `session()->regenerate()` → dashboard.
- Le guard utilisé est `web` (session), configuré dans `config/auth.php` sur le modèle `Utilisateur`.
- La redirection des non-connectés est configurée dans `bootstrap/app.php` via `redirectGuestsTo()` → route `connexion`.
- L'email `2fa_email` est stocké en session entre les deux étapes ; `showVerification()` redirige vers `/connexion` si la session est absente.
- Le code 2FA est invalidé immédiatement après usage (`two_factor_code = null`).
- Flow mot de passe oublié : `POST /mot-de-passe-oublie` → génère `reset_token` (64 chars) valable 30 min + envoie lien par email → `GET /reset-mot-de-passe/{token}` → `POST` → nouveau mot de passe stocké en clair + token invalidé → redirect connexion.
- Le message de succès de `/mot-de-passe-oublie` est identique que l'email existe ou non (pas de divulgation d'existence de compte).
- Mot de passe minimum 8 caractères, confirmation requise (`confirmed`).
- L'API mobile utilise Sanctum (`auth:sanctum`).

---

## Contrôleurs

| Fichier | Namespace | Rôle |
|---|---|---|
| `HomeController` | `App\Http\Controllers` | Page d'accueil publique |
| `ConnexionController` | `App\Http\Controllers` | Login, 2FA, logout |
| `EspaceController` | `App\Http\Controllers` | Espace connecté (dashboard, API créneaux JSON, profil, QR code) |
| `Api\MobileController` | `App\Http\Controllers\Api` | API Sanctum pour l'app Flutter |

### `EspaceController::creneaux()`
La méthode est découpée en 6 étapes numérotées en commentaires (plage de dates, lecture des paramètres, génération des heures, réservations de l'utilisateur, créneaux occupés, construction de la réponse). Elle est **abondamment commentée à destination des étudiants** : conserver ce niveau de détail lors des modifications.

Deux points à ne pas casser :
- Les réservations sont indexées dans des tableaux associatifs à clé `"Y-m-d_H:i"` (étapes 4 et 5) pour éviter une requête par créneau.
- `clone` est obligatoire avant chaque `->modify()` sur un `DateTime`, sinon l'objet source est décalé à chaque tour de boucle.

---

## Routes

### Web (`routes/web.php`)

| Méthode | URI | Nom | Contrôleur |
|---|---|---|---|
| GET | `/` | `home` | `HomeController@index` |
| GET | `/api-doc` | `api-doc` | `HomeController@apiDoc` |
| GET | `/connexion` | `connexion` | `ConnexionController@index` |
| POST | `/connexion` | `connexion.login` | `ConnexionController@login` |
| GET | `/connexion/verification` | `connexion.verification` | `ConnexionController@showVerification` |
| POST | `/connexion/verification` | `connexion.verify2fa` | `ConnexionController@verify2FA` |
| POST | `/deconnexion` | `deconnexion` | `ConnexionController@logout` |
| GET | `/mot-de-passe-oublie` | `connexion.motdepasseoublie` | `ConnexionController@showMotDePasseOublie` |
| POST | `/mot-de-passe-oublie` | `connexion.motdepasseoublie.envoyer` | `ConnexionController@envoyerMotDePasseOublie` |
| GET | `/reset-mot-de-passe/{token}` | `connexion.reset` | `ConnexionController@showResetMotDePasse` |
| POST | `/reset-mot-de-passe/{token}` | `connexion.reset.enregistrer` | `ConnexionController@resetMotDePasse` |
| GET | `/espace/tableau-de-bord` | `espace.dashboard` | `EspaceController@dashboard` |
| GET | `/espace/calendrier` | `espace.calendrier` | `EspaceController@calendrier` |
| GET | `/espace/profil` | `espace.profil` | `EspaceController@profil` |
| PUT | `/espace/profil` | `espace.profil.update` | `EspaceController@updateProfil` |
| GET | `/espace/qrcode` | `espace.qrcode` | `EspaceController@qrcode` |
| GET | `/espace/creneaux` | `espace.creneaux` | `EspaceController@creneaux` |

Les routes `/espace/*` sont protégées par le middleware `auth`.

> **`/espace/creneaux` est une API JSON interne** (pas une vue Blade). Elle est appelée par Vue.js via `fetch()` depuis le dashboard. Elle retourne `{ debut, semaine, jours: [{ date, label, slots: [{ heure, statut, prestation }] }] }`. Les statuts possibles : `libre`, `occupe`, `ma_reservation`, `valide`.

### API (`routes/api.php`)

| Méthode | URI | Nom | Middleware |
|---|---|---|---|
| POST | `/api/mobile/login` | `api.mobile.login` | — |
| POST | `/api/mobile/verify-2fa` | `api.mobile.verify2fa` | — |
| GET | `/api/mobile/me` | `api.mobile.me` | `auth:sanctum` |
| PUT | `/api/mobile/me` | `api.mobile.me.update` | `auth:sanctum` |
| GET | `/api/mobile/rdv` | `api.mobile.rdv` | `auth:sanctum` |
| POST | `/api/mobile/valider-presence` | `api.mobile.valider` | `auth:sanctum` |
| GET | `/api/mobile/reservation/{idreservation}/client` | `api.mobile.reservation.client` | `auth:sanctum` |

#### Détail des endpoints

**POST `/api/mobile/login`** — Étape 1/2
- Body : `{ email, motpasse }`
- Accès réservé au rôle staff (`idrole = 2`)
- Génère un code 2FA à 6 chiffres (valable 10 min) et l'envoie par email via `EmailHelpers`
- Réponse : `{ message, email }` — pas encore de token

**POST `/api/mobile/verify-2fa`** — Étape 2/2
- Body : `{ email, code }`
- Vérifie le code via `Utilisateur::verifierCode2FA()`, invalide le code après usage
- Révoque les anciens tokens Sanctum avant d'en créer un nouveau
- Réponse : `{ token, utilisateur: { idutilisateur, nom, prenom, email } }`

**GET `/api/mobile/me`** *(auth:sanctum)*
- Retourne le profil du staff connecte, identifie par son token Sanctum via `$request->user()`
- Reponse : `{ idutilisateur, idrole, nom, prenom, email }`. Les champs sont listes un par un, jamais le modele complet : `motpasse` et les colonnes `two_factor_*` ne doivent pas fuiter

**PUT `/api/mobile/me`** *(auth:sanctum)*
- Body : `{ nom }`. Seul le nom est modifiable pour l'instant, tout autre champ envoye est ignore car `update()` ne recoit que la cle `nom`
- Validation : `required|string|max:100`, sinon 422
- Reponse : `{ message, utilisateur: { idutilisateur, idrole, nom, prenom, email } }`
- TODO etudiant : ouvrir la modification aux autres champs (prenom, email avec regle d'unicite). `idrole` ne doit jamais etre modifiable depuis le mobile

**GET `/api/mobile/rdv`** *(auth:sanctum)*
- Retourne toutes les réservations à partir d'aujourd'hui, triées par date/heure
- Réponse : tableau de `{ idreservation, datedebut, heuredebut, validationpresence, prestation, client: { nom, prenom } }`

**POST `/api/mobile/valider-presence`** *(auth:sanctum)*
- Body : `{ idreservation }`
- Retourne 409 si la présence est déjà validée
- Réponse : `{ message, idreservation }`

**GET `/api/mobile/reservation/{idreservation}/client`** *(auth:sanctum)*
- Retourne les informations de la personne rattachee a une reservation, a partir de l'identifiant lu dans le QR code
- Retourne 404 si aucune reservation ne porte cet identifiant
- Reponse : `{ idreservation, datedebut, heuredebut, validationpresence, prestation, client: { idutilisateur, nom, prenom, email } }`
- Le parametre d'URL est contraint par `whereNumber('idreservation')`

**Syntaxe routes** : toujours utiliser `[Controller::class, 'méthode']`, ne pas utiliser `Route::controller()`.

---

## Vues

Moteur de template : Blade. Structure :

```
resources/views/
├── layouts/
│   └── app.blade.php       ← layout principal Bootstrap 5
├── home.blade.php
├── api-doc.blade.php
└── connexion/
    ├── index.blade.php
    ├── verification.blade.php
    ├── mot-de-passe-oublie.blade.php
    └── reset-mot-de-passe.blade.php
```

### Structure des vues

```
resources/views/
├── layouts/
│   └── app.blade.php           ← layout principal Bootstrap 5
├── home.blade.php
├── api-doc.blade.php
├── connexion/
│   ├── index.blade.php
│   ├── verification.blade.php
│   ├── mot-de-passe-oublie.blade.php
│   └── reset-mot-de-passe.blade.php
└── espace/
    ├── dashboard.blade.php     ← tableau de bord + grille Vue.js
    ├── profil.blade.php        ← édition du profil (nom uniquement)
    └── qrcode.blade.php        ← billet QR code imprimable
```

### Layout `layouts/app.blade.php`
- `@yield('titre')` → balise `<title>` (défaut : `ResaChev`)
- `@yield('contenu')` → corps de la page
- `@stack('styles')` dans `<head>` pour les CSS additionnelles par vue
- `@stack('scripts')` avant `</body>` pour les scripts additionnels par vue
- Navbar avec liens *Accueil*, *Tableau de bord*, *Mon profil* (selon auth), classe `active` via `request()->routeIs()`
- `<link href="/css/main.css" rel="stylesheet">` chargé globalement

### Conventions Blade
- Chaque vue commence par `@extends('layouts.app')`
- `@section('titre', '...')` pour le titre de l'onglet
- `@section('contenu') ... @endsection` pour le contenu
- Affichage des erreurs de validation : `@error('champ')` par champ + alerte globale `$errors->any()`
- `{{ old('champ') }}` sur tous les champs texte pour conserver les valeurs en cas d'erreur
- Variables passées aux vues **toujours sous forme de tableau explicite** — `return view('...', ['cle' => $valeur])` — **jamais `compact()`**

---

## Utilitaires

### `App\Utils\EmailHelpers`

Classe utilitaire pour l'envoi d'emails. **Toujours utiliser cette classe** plutôt que d'appeler `Mail::` directement.

```php
EmailHelpers::sendEmail($to, $subject, $template, $data);
```

| Paramètre | Type | Description |
|---|---|---|
| `$to` | `string` | Adresse email du destinataire |
| `$subject` | `string` | Objet de l'email |
| `$template` | `string` | Chemin de la vue Blade à utiliser comme corps (ex: `'emails.code2fa'`) |
| `$data` | `array` | Variables passées à la vue (optionnel) |

Exemple d'utilisation pour la 2FA :
```php
EmailHelpers::sendEmail(
    $utilisateur->email,
    'Votre code de connexion',
    'emails.code2fa',
    ['code' => $utilisateur->two_factor_code]
);
```

Les vues emails sont à placer dans `resources/views/emails/`.

---

## Feuilles de style et scripts

### CSS

| Fichier | Rôle | Chargement |
|---|---|---|
| `public/css/main.css` | Styles globaux (grille créneaux, navbar…) | `layouts/app.blade.php` via `<link href="/css/main.css">` |
| `public/css/print.css` | Styles du billet QR (écran + impression) | `espace/qrcode.blade.php` via `@push('styles')` |

Ne pas utiliser `{{ asset() }}` — utiliser directement les chemins `/css/...` et `/js/...`.

### JavaScript

| Fichier | Rôle |
|---|---|
| `public/js/vue.global.prod.js` | Vue.js 3 production build (164 Ko) |
| `public/js/qrcode.min.js` | qrcodejs — génération de QR codes (19 Ko) |

Ces librairies sont locales. **Ne pas les remplacer par des CDN.**

### Vue.js (dashboard)

L'application Vue.js du dashboard est dans `resources/views/espace/dashboard.blade.php`, dans le bloc `@push('scripts')`. Elle utilise l'Options API (pas la Composition API), ce qui est plus lisible pour des étudiants débutants. Toutes les méthodes et directives sont commentées en français.

Le template Vue est dans le même fichier Blade. Les directives Vue (`v-if`, `v-for`, `@click`, `:class`) s'écrivent directement dans le HTML. Les expressions Vue utilisent `@{{ }}` (préfixe `@` pour échapper Blade).

---

## Conventions de code

- **Langue** : commentaires et PHPDoc en français, noms de variables et méthodes en français ou camelCase français (`prochaineReservation`, `verifierCode2FA`).
- **PHPDoc** sur toutes les méthodes publiques non triviales, avec `@param` et `@return`.
- **Commentaires inline** en français pour expliquer les choix non évidents.
- **Jamais `compact()`** pour passer des variables aux vues — utiliser un tableau explicite.
- **Jamais `{{ asset() }}`** pour les chemins CSS/JS locaux — utiliser `/css/...` et `/js/...` directement.
- **Jamais Carbon** pour manipuler les dates dans les contrôleurs — utiliser `\DateTime`, `clone`, `->modify()`.
- Style de référence : voir `../../2024-2025/front-equipe/app/Models/`.

---

## Commandes utiles

```bash
# Recréer la base depuis zéro (migration + seed)
php artisan migrate:fresh --seed

# Lancer le serveur de développement
php artisan serve

# Lancer la suite de tests (80 tests, tous au vert)
php artisan test

# Travailler en local sur SQLite, sans MySQL ni SMTP (voir .env.sqlite)
touch database/database.sqlite
php artisan --env=sqlite migrate:fresh --seed
php artisan --env=sqlite serve
```

### Environnement local SQLite

Le fichier `.env.sqlite` permet de lancer l'application sans serveur MySQL ni serveur SMTP. L'option `--env=sqlite` le charge à la place de `.env`, donc la configuration MySQL habituelle n'est pas écrasée.

Différences avec `.env.example` : `DB_CONNECTION=sqlite` sur `database/database.sqlite`, `SESSION_DRIVER` et `CACHE_STORE` en `file` (SQLite verrouille toute la base à chaque écriture), `QUEUE_CONNECTION=sync`, `MAIL_MAILER=log` (les emails partent dans `storage/logs/laravel.log`) et `AUTH_2FA_ENABLED=false` pour se connecter sans saisir de code.

**Piège à connaître : `.env.sqlite` doit contenir `APP_ENV=sqlite`.** L'option `--env` n'est lue que dans l'`argv` du processus courant (`LoadEnvironmentVariables::checkForSpecificEnvironmentFile`), elle n'est jamais exportée dans l'environnement. Or `artisan serve` lance un sous-processus `php -S` qui rebootstrape l'application et ne reçoit pas cette option : il ne dispose que de la variable `APP_ENV`, transmise via la liste `ServeCommand::$passthroughVariables`. Si `.env.sqlite` déclare `APP_ENV=local`, le sous-processus charge `.env`, bascule sur MySQL et le serveur démarre sans jamais répondre (chaque requête attend la fin du timeout TCP vers un hôte MySQL injoignable). La règle vaut pour tout futur fichier `.env.<suffixe>` : `APP_ENV` doit toujours valoir le suffixe.

C'est un environnement de développement uniquement : la BDD réelle est MySQL et elle est partagée avec les applications C# et Flutter.

---

## Tests

La suite tourne sur SQLite en mémoire. Points à connaître :

- Tout test qui touche la base doit utiliser le trait `RefreshDatabase`, sinon les migrations ne sont pas jouées et les requêtes échouent avec `no such table`. C'est le cas même pour `GET /`, qui lit `parametrage.nomPlateforme`.
- Les mots de passe étant stockés **en clair**, les assertions comparent la chaîne directement (`assertSame`) et non `Hash::check()`. À reprendre le jour où le hachage bcrypt sera implémenté.
- Il n'existe pas de route `espace.calendrier` : la grille de créneaux vit dans `espace.dashboard` et se remplit via l'API `espace.creneaux`.

---

## Documentation de présentation (SFD / STD)

- `doc/sfd-std.md` : document de présentation du projet (introduction, fonctionnalités, captures, architecture). PDF : `doc/sfd-std.pdf`.
- Génération automatisée : `bash doc/tools/build.sh` (base SQLite temporaire via variables d'environnement, seed `doc/tools/seed-demo.php`, captures Chrome headless `doc/tools/screenshots.mjs` dans `doc/images/`, PDF via `doc/tools/md2pdf.php`). `bash doc/tools/build.sh pdf` régénère seulement le PDF.
- Après toute évolution visible de l'interface, relancer la génération complète pour rafraîchir les captures et vérifier que le texte de `sfd-std.md` reste exact.
