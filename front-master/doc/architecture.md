# Architecture – ResaChev Web

## Stack technique

| Couche | Technologie |
|---|---|
| Langage serveur | PHP 8.2+ |
| Framework | Laravel 11.x |
| Base de données | MySQL (partagée entre les 3 applications) |
| CSS | Bootstrap 5.3 via CDN + `public/css/main.css` (global) + `public/css/print.css` (billet QR) |
| JavaScript | Vue.js 3 (`public/js/vue.global.prod.js`) · qrcodejs (`public/js/qrcode.min.js`) |
| Authentification web | Session Laravel (guard `web`), implémentée manuellement |
| Authentification API | Laravel Sanctum (tokens pour l'app Flutter) |
| Emails | SMTP via `App\Utils\EmailHelpers` |

Les librairies JS sont **locales** (dans `public/js/`), sans CDN.

---

## Structure des dossiers

```
resachev-web/
├── app/
│   ├── Http/
│   │   └── Controllers/
│   │       ├── HomeController.php          ← page d'accueil, doc API
│   │       ├── ConnexionController.php     ← login, 2FA, logout, reset mot de passe
│   │       ├── EspaceController.php        ← espace client connecté
│   │       └── Api/
│   │           └── MobileController.php    ← API Sanctum pour Flutter
│   ├── Models/
│   │   ├── Utilisateur.php
│   │   ├── Reservation.php
│   │   ├── Prestation.php
│   │   ├── Parametrage.php
│   │   └── Role.php
│   └── Utils/
│       └── EmailHelpers.php                ← envoi d'emails centralisé
├── config/
│   └── auth.php                            ← guard web, modèle Utilisateur, 2fa_enabled
├── database/
│   ├── factories/
│   │   └── UtilisateurFactory.php          ← mots de passe stockés en clair
│   ├── migrations/
│   │   └── 2026_07_02_000000_create_resachev_tables.php  ← schéma uniquement
│   └── seeders/
│       ├── ReferenceSeeder.php             ← appelle les 3 seeders ci-dessous
│       ├── RoleSeeder.php
│       ├── ParametrageSeeder.php
│       ├── PrestationSeeder.php
│       └── DatabaseSeeder.php              ← référence + données de démo
├── doc/                                    ← ce dossier
├── public/
│   ├── css/
│   │   ├── main.css                        ← styles globaux
│   │   └── print.css                       ← billet QR imprimable
│   └── js/
│       ├── vue.global.prod.js              ← Vue.js 3 production (164 Ko)
│       └── qrcode.min.js                  ← qrcodejs (19 Ko)
├── resources/
│   └── views/
│       ├── layouts/
│       │   └── app.blade.php               ← layout principal
│       ├── home.blade.php
│       ├── api-doc.blade.php
│       ├── connexion/
│       │   ├── index.blade.php
│       │   ├── verification.blade.php
│       │   ├── mot-de-passe-oublie.blade.php
│       │   └── reset-mot-de-passe.blade.php
│       ├── emails/
│       │   ├── code2fa.blade.php
│       │   └── reset-mot-de-passe.blade.php
│       └── espace/
│           ├── dashboard.blade.php         ← tableau de bord + grille Vue.js
│           ├── profil.blade.php
│           └── qrcode.blade.php
└── routes/
    ├── web.php                             ← routes Blade (session)
    └── api.php                             ← routes JSON (Sanctum)
```

---

## Modèle MVC Laravel

Laravel suit le patron **MVC** (Modèle – Vue – Contrôleur) :

- **Modèles** (`app/Models/`) : représentent les tables. Gèrent les requêtes Eloquent et les relations.
- **Vues** (`resources/views/`) — templates Blade. Affichent le HTML.
- **Contrôleurs** (`app/Http/Controllers/`) — reçoivent les requêtes HTTP, appellent les modèles, retournent une vue ou une réponse JSON.

```
Navigateur  →  routes/web.php  →  Contrôleur  →  Modèle (BDD)
                                       ↓
                                     Vue Blade  →  HTML  →  Navigateur
```

Pour l'API mobile, la vue est remplacée par une réponse JSON :

```
App Flutter  →  routes/api.php  →  MobileController  →  Modèle (BDD)
                                          ↓
                                       JSON  →  App Flutter
```

---

## Conventions générales

- **Variables en vue** : toujours passées sous forme de tableau explicite — `return view('nom', ['cle' => $valeur])`. Jamais `compact()`.
- **Chemins CSS/JS** : chemins directs (`/css/main.css`, `/js/vue.global.prod.js`). Jamais `{{ asset() }}`.
- **Dates** : `\DateTime`, `clone`, `->modify()`. Jamais Carbon dans les contrôleurs.
- **Commentaires** : en français, orientés pédagogie (le public cible est des étudiants BTS SIO).
- **Noms de variables** : camelCase français (`prochaineReservation`, `utilisateur`, `heureOuverture`).
