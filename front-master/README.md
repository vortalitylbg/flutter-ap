# ResaChev – Interface Web

ResaChev est une plateforme open-source de réservation de créneaux. Ce dépôt contient l'**interface web**, développée en PHP avec Laravel.

---

## Présentation

ResaChev propose une interface de gestion des réservations légère et accessible aux utilisateurs finaux. Elle couvre l'authentification, la visualisation des créneaux et la gestion du profil.

### Fonctionnalités

- **Authentification** — Connexion par email / mot de passe avec double authentification par email (2FA)
- **Tableau de bord** — Affichage du prochain créneau réservé + grille interactive de créneaux sur 7 jours (Vue.js)
- **Grille de créneaux** — Vue semaine générée côté client via une API JSON interne (`GET /espace/creneaux`), navigation semaine précédente / suivante
- **Profil utilisateur** — Modification du nom (le reste est à compléter)
- **QR Code** — Affichage du QR code à faire scanner sur place pour valider la présence, avec billet imprimable

---

## Prérequis

- PHP 8.2+
- Composer
- MySQL ou SQLite
- Un serveur SMTP pour l'envoi d'emails (requis pour la 2FA)

---

## Installation

```bash
git clone <url>
cd resachev-web

composer install
cp .env.example .env
php artisan key:generate
```

Configurer la base de données et le serveur mail dans `.env`, puis créer les tables et les données de référence :

```bash
php artisan migrate:fresh --seed
```

> `migrate:fresh --seed` fait tout : il crée le schéma puis charge les données de référence et les données de démonstration. Les migrations seules ne créent que les tables ; sans le seed, `role`, `parametrage` et `prestation` restent vides et l'application ne démarre pas.
>
> Attention, `migrate:fresh` **supprime toutes les tables** de la base ciblée avant de les recréer. À réserver à une base de développement.

---

## Démarrage

### Accès local uniquement

```bash
php artisan serve
```

L'application est accessible sur [http://localhost:8000](http://localhost:8000).

### Accès réseau (depuis d'autres machines ou une VM)

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

L'application est alors accessible depuis n'importe quelle machine du réseau local via l'IP de la machine hôte : `http://<IP_DE_LA_MACHINE>:8000`.

> Pour connaître l'IP de la machine hôte : `ip a` (Linux/Mac) ou `ipconfig` (Windows).

### Recréer la base depuis zéro

```bash
php artisan migrate:fresh --seed
```

Sans `--seed`, la base est recréée vide : les données de référence sont dans les seeders, plus dans les migrations, et l'application ne démarre pas sans elles.

---

## Test local avec SQLite

Pour lancer l'application en local sans serveur MySQL ni serveur SMTP, le dépôt fournit un fichier de configuration `.env.sqlite` prêt à l'emploi :

```bash
touch database/database.sqlite
php artisan --env=sqlite migrate:fresh --seed
php artisan --env=sqlite serve
```

L'option `--env=sqlite` demande à Laravel de lire `.env.sqlite` au lieu de `.env`. Votre configuration MySQL habituelle reste donc intacte, il n'y a rien à restaurer ensuite.

> **À ne pas modifier :** `.env.sqlite` contient `APP_ENV=sqlite`, valeur qui doit correspondre au suffixe du nom du fichier. La commande `serve` lance un sous-processus `php -S` qui relit toute la configuration, sans recevoir l'option `--env` : il ne se repère que sur `APP_ENV`. Si cette variable vaut autre chose, le sous-processus charge `.env` et donc MySQL, et le serveur démarre sans jamais répondre, chaque requête restant bloquée à attendre un serveur MySQL injoignable.

Ce que ce fichier change par rapport à `.env.example` :

| Réglage | Valeur | Effet |
|---|---|---|
| `DB_CONNECTION` | `sqlite` | Base dans le fichier `database/database.sqlite`, aucun serveur à installer |
| `MAIL_MAILER` | `log` | Les emails sont écrits dans `storage/logs/laravel.log` au lieu d'être envoyés |
| `AUTH_2FA_ENABLED` | `false` | Connexion directe, sans code à saisir |
| `SESSION_DRIVER` / `CACHE_STORE` | `file` | Évite les verrous d'écriture propres à SQLite |
| `QUEUE_CONNECTION` | `sync` | Traitement immédiat, pas de worker à lancer |

L'application est ensuite accessible sur [http://localhost:8000](http://localhost:8000). Le seed crée deux comptes clients et six réservations de démonstration :

| Compte | Mot de passe | Réservations |
|---|---|---|
| `test@example.com` (Jean Dupont) | `password` | Veille 09:00 (présence validée), lendemain 10:30 et 14:00 |
| `marie@example.com` (Marie Martin) | `password` | Veille 11:00 (présence validée), lendemain 09:30 et 15:30 |

Les dates sont calculées au moment du seed, les réservations sont donc toujours visibles dans la grille du tableau de bord.

Se connecter avec l'un puis l'autre permet de voir les quatre statuts de la grille : ses propres créneaux en `valide` et `ma_reservation`, ceux de l'autre client en `occupe`, et les créneaux disponibles en `libre`.

> `migrate:fresh` supprime toutes les tables de la base ciblée. Vérifiez que vous avez bien passé `--env=sqlite` avant de lancer la commande.

Cet environnement est réservé au développement. En production la base est MySQL, et elle est partagée avec les autres applications du projet.

---

## Structure des dossiers

```
resachev-web/
├── app/
│   ├── Http/Controllers/       ← logique métier (ConnexionController, EspaceController…)
│   ├── Models/                 ← modèles Eloquent (Utilisateur, Reservation, Prestation…)
│   └── Utils/                  ← utilitaires (EmailHelpers)
├── config/
│   └── auth.php                ← guard web, modèle Utilisateur, AUTH_2FA_ENABLED
├── database/
│   ├── factories/              ← UtilisateurFactory (mots de passe en clair)
│   ├── migrations/             ← création des tables, schéma uniquement
│   └── seeders/                ← ReferenceSeeder (données requises) + démo
├── doc/                        ← documentation technique du projet
├── public/
│   ├── css/                    ← main.css (global), print.css (billet QR)
│   └── js/                     ← vue.global.prod.js, qrcode.min.js
├── resources/
│   └── views/                  ← templates Blade
│       ├── layouts/app.blade.php
│       ├── connexion/          ← login, 2FA, mot de passe oublié
│       ├── emails/             ← corps des emails envoyés
│       └── espace/             ← dashboard, profil, qrcode (espace connecté)
└── routes/
    ├── web.php                 ← routes navigateur (session)
    └── api.php                 ← routes API mobile (Sanctum)
```

---

## Double authentification (2FA)

La connexion se déroule en deux étapes. Un code à 6 chiffres est envoyé par email après vérification du mot de passe.

```
Utilisateur                  Serveur                        Email
    │                            │                              │
    │── POST /connexion ────────>│                              │
    │   { email, motpasse }      │                              │
    │                            │── génère code (10 min) ─────>│
    │                            │   stocke en base             │ code envoyé
    │<── redirect /verification ─│                              │
    │                            │                              │
    │── POST  ──>│               │
    │   /connexion/verification  │
    │   { code }                 │                              │
    │                            │── vérifie code + expiration  │
    │                            │── invalide le code en base   │
    │<── redirect /espace/tableau-de-bord ──────────────────────│
```

Le code expire après **10 minutes**. En cas de code invalide ou expiré, l'utilisateur reste sur le formulaire de vérification.

### Désactiver la 2FA (développement)

```env
AUTH_2FA_ENABLED=false
```

Avec cette valeur, la connexion est directe après vérification du mot de passe, sans envoi d'email. S'applique aussi à l'API mobile.

> En production, conserver `AUTH_2FA_ENABLED=true`. Un serveur SMTP est requis (`MAIL_*` dans `.env`).

Pour le détail complet de l'implémentation : [doc/authentification.md](doc/authentification.md)

---

## Stack technique

- PHP 8.x / Laravel 11.x
- MySQL / SQLite
- SMTP (configurable)
- Vue.js 3 (Options API) — intégré localement dans `public/js/vue.global.prod.js`, sans CDN
- Bootstrap 5.3 via CDN (styles uniquement)

---

## Licence

ResaChev est un logiciel open-source distribué sous [licence MIT](LICENSE).
