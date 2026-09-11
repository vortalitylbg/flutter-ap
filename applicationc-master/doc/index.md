# Documentation ResaChev - Application de gestion (C#)

ResaChev est une plateforme open-source de réservation de créneaux. Ce dépôt est l'**application de gestion** (back-office) destinée aux administrateurs de la structure. Elle est développée en **C# / .NET 10 / Windows Forms** et accède directement à la base MySQL partagée via **Entity Framework Core**.

---

## Table des matières

| Fichier | Contenu |
|---|---|
| [architecture.md](architecture.md) | Vue d'ensemble du projet, stack technique, structure des dossiers, couches |
| [base-de-donnees.md](base-de-donnees.md) | Schéma des tables, entités EF Core, `DbContext`, scaffolding |
| [gestion-utilisateurs.md](gestion-utilisateurs.md) | Lister, créer, modifier l'email d'un utilisateur ; envoi d'emails |
| [gestion-reservations.md](gestion-reservations.md) | Suivi calendaire des réservations, détail, création |
| [sfd-std.md](sfd-std.md) | Document de présentation SFD / STD avec captures d'écran — PDF : `sfd-std.pdf`, génération : `bash doc/tools/build.sh` |

---

## Périmètre de ce dépôt

ResaChev repose sur **trois applications** partageant la même base de données MySQL :

| Application | Technologie | Rôle |
|---|---|---|
| **Interface web** | PHP / Laravel 11 | Espace client : connexion, réservations, QR code |
| **Application de gestion** (ce dépôt) | C# / .NET 10 / WinForms | Administration : gestion des utilisateurs et des réservations |
| **Application mobile** | Flutter | Staff terrain : liste des RDV du jour, scan du QR code |

Les fonctionnalités de l'espace client (connexion 2FA, tableau de bord, QR code) et le scan mobile sont **hors périmètre** de ce dépôt.

---

## Installation rapide

```bash
git clone <url>
cd applicationc

dotnet restore
dotnet build
dotnet run --project AP3_applicationC
```

> L'application ne compile et ne s'exécute que sous **Windows** : la cible est `net10.0-windows` et le projet utilise Windows Forms (`UseWindowsForms`).

> La chaîne de connexion est actuellement **écrite en dur** dans `Entities/Ap3BdReservationContext.cs` (méthode `OnConfiguring`). Elle doit être adaptée au serveur MariaDB mutualisé avant tout usage réel. Voir [base-de-donnees.md](base-de-donnees.md).

---

## Prérequis

| Élément | Version / valeur |
|---|---|
| SDK .NET | 10.0 (cible `net10.0-windows`) |
| Système | Windows 10 / 11 (Windows Forms) |
| IDE | Visual Studio 2022+ ou JetBrains Rider |
| Base de données | MySQL 8 / MariaDB accessible, schéma `ap3_bd_reservation` déjà créé |
| Serveur SMTP | Mail catcher `mail.dombtsig.local:1025` (envoi des emails de création de compte) |

Le schéma de la base n'est **pas créé par cette application** : il est déployé par le script SQL du projet ou par les migrations de l'application web (`php artisan migrate:fresh --seed`).

---

## Paquets NuGet

| Paquet | Version | Rôle |
|---|---|---|
| `Microsoft.EntityFrameworkCore` | 9.0.17 | ORM |
| `Microsoft.EntityFrameworkCore.Tools` | 9.0.17 | Commandes de scaffolding (`dotnet ef`) |
| `Pomelo.EntityFrameworkCore.MySql` | 9.0.0 | Fournisseur MySQL / MariaDB pour EF Core |
