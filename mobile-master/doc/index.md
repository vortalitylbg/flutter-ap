# Documentation ResaChev - Application mobile (Flutter)

ResaChev est une plateforme open-source de réservation de créneaux. Ce dépôt est l'**application mobile** destinée au **staff terrain** de la structure. Elle est développée en **Flutter / Dart** et n'accède **jamais directement** à la base MySQL : elle passe par l'**API mobile** de l'application web (Laravel + Sanctum).

---

## Table des matières

| Fichier | Contenu |
|---|---|
| [architecture.md](architecture.md) | Vue d'ensemble du projet, stack technique, structure des dossiers, couches, navigation |
| [api-et-donnees.md](api-et-donnees.md) | API mobile consommée, jetons Sanctum, modèles de données, mapping JSON |
| [authentification.md](authentification.md) | Connexion en deux étapes (identifiants puis code 2FA), stockage du jeton |
| [rendez-vous-et-scan.md](rendez-vous-et-scan.md) | Liste des rendez-vous, lecture du QR code, validation de présence |
| [lot3-attente-et-recurrence.md](lot3-attente-et-recurrence.md) | Lot 3 : liste d'attente (US 3.1) et réservations récurrentes (US 3.2) — règles, impacts sur les trois applications, tests d'acceptation |
| [sfd-std.md](sfd-std.md) | Document de présentation SFD / STD avec captures d'écran — PDF : `sfd-std.pdf`, génération : `bash doc/tools/build.sh` |

---

## Périmètre de ce dépôt

ResaChev repose sur **trois applications** partageant la même base de données MySQL :

| Application | Technologie | Rôle |
|---|---|---|
| **Interface web** | PHP / Laravel 11 | Espace client : connexion, réservations, QR code — et **API mobile** |
| **Application de gestion** | C# / .NET 10 / WinForms | Administration : gestion des utilisateurs et des réservations |
| **Application mobile** (ce dépôt) | Flutter / Dart | Staff terrain : liste des rendez-vous, scan du QR code |

Les fonctionnalités de l'espace client (tableau de bord, génération du QR code) et l'administration (création de comptes, suivi calendaire) sont **hors périmètre** de ce dépôt. En revanche, le **contrat d'API** est partagé : toute évolution des routes `/api/mobile/*` se décide avec l'équipe web (voir `doc/api-mobile.md` du dépôt web).

---

## Installation rapide

```bash
git clone <url> mobile
cd mobile

flutter pub get
flutter run
```

> L'API doit être joignable : par défaut, l'application lit `assets/env.dev.json`, dont la clé `API_URL_ANDROID` vaut aujourd'hui `http://192.168.1.17:8000/api` — l'adresse d'un poste de développement sur le réseau local, le développement se faisant désormais sur **téléphone physique**. Sur émulateur, remettre `http://10.0.2.2:8000/api` (`10.0.2.2` est l'alias du `127.0.0.1` de la machine hôte vu depuis l'émulateur). Dans les deux cas, lancer Laravel avec `php artisan serve --host=0.0.0.0`.

> Le basculement développement / production se fait **en modifiant le code** de `lib/services/api/config.dart` (ligne commentée). Voir [architecture.md](architecture.md).

---

## Prérequis

| Élément | Version / valeur |
|---|---|
| SDK Flutter | Canal stable, Dart SDK `^3.13.2` |
| Système | Android (cible principale) ; iOS, web et desktop compilent mais sans scanner |
| IDE | Android Studio, VS Code ou JetBrains, avec les extensions Flutter et Dart |
| Chaîne Android | NDK `27.0.12077973` (imposé dans `android/build.gradle.kts`), Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0, JDK 17 |
| iOS | Cible de déploiement `15.0` (relevée depuis `13.0`) |
| Appareil | **Téléphone Android** en mode développeur (le scan de QR code exige une **caméra réelle** ; le scanner est désormais restreint à Android, voir [rendez-vous-et-scan.md](rendez-vous-et-scan.md)) |
| API web | Application Laravel ResaChev lancée (`php artisan serve`), routes `/api/mobile/*` accessibles |
| Base de données | MySQL / MariaDB, atteinte **par l'API** uniquement |
| Serveur SMTP | Mail catcher `mail.dombtsig.local:1025` (réception du code 2FA) |

Un compte de **rôle staff** (`idrole = 2`) est indispensable : l'API refuse la connexion de tout autre rôle.

---

## Paquets pub.dev

| Paquet | Version | Rôle |
|---|---|---|
| `http` | ^1.6.0 | Appels HTTP vers l'API mobile |
| `flutter_secure_storage` | ^10.3.1 | Stockage **chiffré** du jeton d'authentification (Keystore Android / Keychain iOS) |
| `mobile_scanner` | ^6.0.11 | Lecture du QR code par la caméra |
| `cupertino_icons` | ^1.0.8 | Jeu d'icônes iOS |
| `flutter_lints` | ^6.0.0 | Règles d'analyse statique (dépendance de développement) |
