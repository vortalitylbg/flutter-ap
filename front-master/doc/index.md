# Documentation ResaChev - Interface Web

ResaChev est une plateforme open-source de réservation de créneaux développée en PHP/Laravel. Ce dépôt est l'**interface web** destinée aux clients.

---

## Table des matières

| Fichier | Contenu |
|---|---|
| [architecture.md](architecture.md) | Vue d'ensemble du projet, stack technique, structure des dossiers |
| [base-de-donnees.md](base-de-donnees.md) | Schéma des tables, relations, migrations et seeders |
| [authentification.md](authentification.md) | Flux de connexion web : 2FA, mot de passe oublié |
| [espace-connecte.md](espace-connecte.md) | Tableau de bord, grille de créneaux (Vue.js), profil, QR code |
| [api-mobile.md](api-mobile.md) | API Sanctum consommée par l'application Flutter (staff terrain) |
| [sfd-std.md](sfd-std.md) | Document de présentation SFD / STD avec captures d'écran — PDF : `sfd-std.pdf`, génération : `bash doc/tools/build.sh` |

---

## Périmètre de ce dépôt

ResaChev repose sur **trois applications** partageant la même base de données MySQL :

| Application | Technologie | Rôle |
|---|---|---|
| **Interface web** (ce dépôt) | PHP / Laravel 11 | Espace client : connexion, réservations, QR code |
| **Back-office** | C# | Administration : gestion des créneaux, utilisateurs |
| **Application mobile** | Flutter | Staff terrain : liste des RDV du jour, scan du QR code |

Les fonctionnalités back-office et les fonctionnalités de scan QR code sont **hors périmètre** de ce dépôt.

---

## Installation rapide

```bash
git clone <url>
cd resachev-web

composer install
cp .env.example .env
php artisan key:generate

# Configurer DB_* et MAIL_* dans .env, puis :
php artisan migrate:fresh --seed
php artisan serve
```

> `migrate:fresh --seed` crée le schéma puis charge les données de référence et de démonstration. Les migrations seules ne créent que les tables : sans le seed, `role`, `parametrage` et `prestation` restent vides et l'application ne démarre pas. Voir [base-de-donnees.md](base-de-donnees.md).
>
> `migrate:fresh` supprime toutes les tables avant de les recréer : à réserver à une base de développement.

Pour travailler sans serveur MySQL ni SMTP, le dépôt fournit un `.env.sqlite` :

```bash
touch database/database.sqlite
php artisan --env=sqlite migrate:fresh --seed
php artisan --env=sqlite serve
```

---

## Variables d'environnement importantes

| Variable | Défaut | Rôle |
|---|---|---|
| `DB_CONNECTION` | `mysql` | Pilote de base de données |
| `AUTH_2FA_ENABLED` | `true` | Active/désactive la double authentification par email |
| `MAIL_*` | — | Paramètres SMTP (requis si `AUTH_2FA_ENABLED=true`) |

> En développement, positionner `AUTH_2FA_ENABLED=false` évite de configurer un serveur SMTP.
