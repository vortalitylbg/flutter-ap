# Base de données – ResaChev Application de gestion (C#)

La base de données est **partagée** entre les trois applications (web Laravel, gestion C#, mobile Flutter). Ne pas modifier le schéma sans concertation.

Les noms de tables et de colonnes sont **en français, au singulier, en minuscules**. Le schéma n'est **pas créé par cette application** : il est déployé par le script SQL du projet (`AP3_BD_reservation.sql`) ou par les migrations de l'application web.

---

## Connexion

La chaîne de connexion est déclarée dans `Entities/Ap3BdReservationContext.cs` :

```csharp
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    => optionsBuilder.UseMySql(
        "server=127.0.0.1;port=3306;user=root;database=ap3_bd_reservation",
        ServerVersion.Parse("8.0.31-mysql"));
```

| Paramètre | Valeur actuelle |
|---|---|
| `server` | `127.0.0.1` |
| `port` | `3306` |
| `user` | `root` (sans mot de passe) |
| `database` | `ap3_bd_reservation` |
| Version serveur | `8.0.31-mysql` |

> **Point de vigilance (repris par le compilateur lui-même sous forme de `#warning`).** La chaîne de connexion est écrite en dur dans le code source, avec le compte `root`. Elle est donc versionnée dans Git et identique pour tous les postes. Deux évolutions sont attendues :
> 1. externaliser la chaîne dans un fichier de configuration (`appsettings.json`) lu au démarrage, comme le fait le `.env` côté web ;
> 2. utiliser un compte MariaDB dédié, avec un mot de passe et les seuls droits nécessaires (`SELECT`, `INSERT`, `UPDATE` sur les tables métier), et non `root`.

---

## Schéma des tables

### `role`

| Colonne | Type SQL | Propriété C# | Description |
|---|---|---|---|
| `idrole` | INT UNSIGNED (PK, auto) | `Idrole` (`uint`) | Identifiant |
| `libellerole` | VARCHAR(128) | `Libellerole` (`string`) | `client` (1) ou `staff` (2) |

Alimente la liste déroulante des rôles de `FormCreerUtil`.

---

### `utilisateur`

| Colonne | Type SQL | Propriété C# | Description |
|---|---|---|---|
| `idutilisateur` | INT UNSIGNED (PK, auto) | `Idutilisateur` (`uint`) | Identifiant |
| `idrole` | INT UNSIGNED (FK, nullable) | `Idrole` (`uint?`) | Référence `role.idrole` |
| `nom` | VARCHAR(128) | `Nom` (`string`) | Nom de famille |
| `prenom` | VARCHAR(128) | `Prenom` (`string`) | Prénom |
| `email` | VARCHAR(128), nullable | `Email` (`string?`) | Adresse email (identifiant de connexion côté web) |
| `motpasse` | VARCHAR(128), nullable | `Motpasse` (`string?`) | Mot de passe — **non renseigné par cette application** |
| `two_factor_code` | VARCHAR(10), nullable | `TwoFactorCode` | Code 2FA temporaire, géré par l'application web |
| `two_factor_expires_at` | DATETIME, nullable | `TwoFactorExpiresAt` | Expiration du code 2FA |
| `reset_token` | VARCHAR(64), nullable | `ResetToken` | Jeton de réinitialisation du mot de passe |
| `reset_token_expires_at` | DATETIME, nullable | `ResetTokenExpiresAt` | Expiration du jeton |
| `created_at` | TIMESTAMP, nullable | `CreatedAt` | Géré par Laravel |
| `updated_at` | TIMESTAMP, nullable | `UpdatedAt` | Géré par Laravel |

> Un utilisateur créé depuis cette application a un `motpasse` **`NULL`**. C'est volontaire : l'email de bienvenue l'invite à utiliser la procédure « mot de passe oublié » du site web pour le définir lui-même. L'application de gestion ne manipule donc jamais de mot de passe.

Relations exposées par l'entité : `IdroleNavigation` (le `Role`) et `Reservations` (la collection de ses réservations).

---

### `prestation`

| Colonne | Type SQL | Propriété C# | Description |
|---|---|---|---|
| `idprestation` | INT UNSIGNED (PK, auto) | `Idprestation` (`uint`) | Identifiant |
| `libelleprestation` | VARCHAR(128) | `Libelleprestation` (`string`) | Nom de la prestation |
| `montantprestation` | DECIMAL(5,2), nullable | `Montantprestation` (`decimal?`) | Tarif |

> Le catalogue des prestations n'est pas encore administrable depuis cette application : il n'existe ni écran de saisie, ni liste déroulante de sélection dans `FormCreerResa`. C'est une évolution attendue (voir [gestion-reservations.md](gestion-reservations.md)).

---

### `reservation`

| Colonne | Type SQL | Propriété C# | Description |
|---|---|---|---|
| `idreservation` | INT UNSIGNED (PK, auto) | `Idreservation` (`uint`) | Identifiant |
| `idutilisateur` | INT UNSIGNED (FK) | `Idutilisateur` (`uint`) | Client ayant réservé |
| `idprestation` | INT UNSIGNED (FK) | `Idprestation` (`uint`) | Prestation réservée |
| `datedebut` | DATE | `Datedebut` (`DateOnly`) | Date du créneau |
| `heuredebut` | TIME | `Heuredebut` (`TimeOnly`) | Heure de début du créneau |
| `validationpresence` | TINYINT | `Validationpresence` (`sbyte`) | `0` = en attente · `1` = présence validée par le staff |

Les types `DateOnly` et `TimeOnly` (.NET 6+) correspondent exactement aux types SQL `DATE` et `TIME` : pas de composante horaire parasite, contrairement à `DateTime`. La conversion depuis les contrôles Windows Forms est explicite :

```csharp
Datedebut = DateOnly.FromDateTime(dtpDate.Value.Date);
Heuredebut = TimeOnly.FromTimeSpan(GetSelectedHeure());
```

> Il n'y a **pas de table `creneau`**. Les créneaux réservables sont calculés à la volée, ici de `heureOuverture` à `heureFermeture` par pas de 30 minutes.

---

### `parametrage`

| Colonne | Type SQL | Propriété C# | Description |
|---|---|---|---|
| `idparam` | INT UNSIGNED (PK, auto) | `Idparam` (`uint`) | Identifiant |
| `libelleparam` | VARCHAR(128) | `Libelleparam` (`string`) | Nom du paramètre (ex. `dureeCreneau`) |
| `valeurparam` | VARCHAR(128) | `Valeurparam` (`string`) | Valeur (ex. `30`) |
| `uniteparam` | VARCHAR(50), nullable | `Uniteparam` (`string?`) | Unité (ex. `minutes`) |

Cette table est **indispensable au démarrage** : `FormMenu` y lit le nom de la plateforme pour composer sa barre de titre. Si la table est vide, `listParam[0]` lève une `ArgumentOutOfRangeException` et l'application ne s'ouvre pas.

---

### `paiement` et `modepaiement`

| Table | Colonnes | Description |
|---|---|---|
| `modepaiement` | `idmode` (PK), `libellemode` | Chèque, chèques vacances, carte bleue, bon cadeau |
| `paiement` | `idpaiement` (PK), `idmode` (FK), `idreservation` (FK **UNIQUE**), `datepaiement` | Une réservation a au plus un paiement |

Les entités `Paiement` et `Modepaiement` sont **générées** (elles font partie du schéma partagé) mais **aucun écran ne les utilise** : la gestion des paiements n'est pas encore implémentée dans cette application.

---

### Tables techniques de Laravel

Le scaffolding a également généré des entités pour les tables internes du framework web : `cache`, `cache_locks`, `jobs`, `job_batches`, `failed_jobs`, `migrations`, `personal_access_tokens`, `sessions`.

Elles sont présentes dans `Entities/` et déclarées dans le `DbContext`, mais **ne doivent jamais être manipulées** depuis l'application de gestion : elles appartiennent au fonctionnement interne de Laravel (cache, files d'attente, sessions web, jetons Sanctum de l'application mobile). Les toucher casserait le site.

---

## Diagramme de relations

![Schéma de la base de données (schema)](images/schema-bdd.svg)

```
role ──────────────< utilisateur >──────────── reservation >──── paiement
                                                    │                │
                                               prestation      modepaiement
```

- Un `utilisateur` a un `role` (client ou staff)
- Un `utilisateur` peut avoir plusieurs `reservation`
- Chaque `reservation` porte sur une `prestation`
- Chaque `reservation` peut avoir au plus un `paiement` (contrainte UNIQUE)

---

## Le `DbContext`

`Ap3BdReservationContext` est la classe centrale d'EF Core. Elle déclare un `DbSet<T>` par table — la collection sur laquelle on écrit les requêtes LINQ — et décrit dans `OnModelCreating()` la correspondance entre les propriétés C# et les colonnes SQL, le schéma ne suivant pas les conventions de nommage d'EF Core :

```csharp
modelBuilder.Entity<Reservation>(entity =>
{
    entity.HasKey(e => e.Idreservation).HasName("PRIMARY");
    entity.ToTable("reservation").UseCollation("utf8mb4_unicode_ci");

    entity.Property(e => e.Idreservation).HasColumnName("idreservation");
    entity.Property(e => e.Heuredebut).HasColumnType("time").HasColumnName("heuredebut");
    // …

    // Clés étrangères et propriétés de navigation
    entity.HasOne(d => d.IdutilisateurNavigation).WithMany(p => p.Reservations)
          .HasForeignKey(d => d.Idutilisateur)
          .HasConstraintName("reservation_idutilisateur_foreign");
});
```

On y retrouve exactement les mêmes informations que dans les modèles Eloquent côté web (`$table`, `$primaryKey`, `belongsTo`, `hasMany`), exprimées avec l'API *fluent* d'EF Core.

---

## Scaffolding : régénérer les entités

Les fichiers de `Entities/` sont **générés à partir de la base existante** (approche *Database First*), avec l'outil `dotnet ef` fourni par le paquet `Microsoft.EntityFrameworkCore.Tools` :

```bash
dotnet tool install --global dotnet-ef

dotnet ef dbcontext scaffold \
  "server=127.0.0.1;port=3306;user=root;database=ap3_bd_reservation" \
  Pomelo.EntityFrameworkCore.MySql \
  --output-dir Entities \
  --context Ap3BdReservationContext \
  --force
```

Sous Visual Studio, la même opération se fait depuis la **Console du Gestionnaire de package** avec `Scaffold-DbContext`.

> `--force` **écrase** tout le contenu de `Entities/`. Aucune modification manuelle ne doit donc y être apportée : les classes sont déclarées `partial`, ce qui permet d'ajouter des méthodes métier dans un **autre fichier** portant le même nom de classe, hors du dossier régénéré.

Après un changement de schéma décidé entre les trois équipes, la marche à suivre est : mettre à jour la base, relancer le scaffolding, recompiler, corriger les éventuelles ruptures dans `Modele/`.

---

## Requêtes LINQ utilisées

| Méthode | Requête | Équivalent SQL |
|---|---|---|
| `ModeleUtilisateur.listeUtilisateurs()` | `Utilisateurs.Include(x => x.IdroleNavigation).ToList()` | `SELECT … FROM utilisateur LEFT JOIN role …` |
| `ModeleUtilisateur.listeRoles()` | `Roles.ToList()` | `SELECT * FROM role` |
| `ModeleUtilisateur.RecupererUtilisateur(id)` | `Utilisateurs.First(x => x.Idutilisateur == idU)` | `SELECT … WHERE idutilisateur = ? LIMIT 1` |
| `ModeleReservation.listeReservations()` | `Reservations.Include(r => r.IdutilisateurNavigation).Include(r => r.IdprestationNavigation).ToList()` | `SELECT … FROM reservation JOIN utilisateur JOIN prestation` |
| `ConnexionBD.listeParametres()` | `Parametrages.ToList()` | `SELECT * FROM parametrage` |

`Include()` est l'équivalent du chargement des relations (`with()` en Eloquent) : sans lui, les propriétés de navigation seraient `null`, EF Core n'activant pas le *lazy loading* par défaut.

> **Point de vigilance.** `listeReservationsPourDate()` appelle `listeReservations()` puis filtre **en mémoire** avec `.Where(r => r.Datedebut == date)`. Toutes les réservations de la base sont donc chargées à chaque changement de jour dans le calendrier. Le filtre devrait être appliqué avant `ToList()`, pour qu'il soit traduit en clause `WHERE` par EF Core.

---

## Écritures

Toute écriture suit le même schéma : modifier l'objet suivi par le contexte, puis appeler `SaveChanges()`.

```csharp
// Ajout
Utilisateur unU = new Utilisateur { Nom = nom, Prenom = prenom, Email = email, Idrole = (uint)idRole };
ConnexionBD.MonModel.Utilisateurs.Add(unU);
ConnexionBD.MonModel.SaveChanges();      // INSERT

// Modification : l'entité est déjà suivie par le contexte, il suffit de la modifier
Utilisateur unU = RecupererUtilisateur(idUtilisateur);
unU.Email = email;
ConnexionBD.MonModel.SaveChanges();      // UPDATE
```

En cas d'exception (contrainte violée, base injoignable), le modèle appelle `ChangeTracker.Clear()` : les modifications en attente sont abandonnées, sans quoi le contexte tenterait de les rejouer au prochain `SaveChanges()`.
