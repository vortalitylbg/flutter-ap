# Base de données – ResaChev

La base de données est **partagée** entre les trois applications (web Laravel, back-office C#, mobile Flutter). Ne pas modifier le schéma sans concertation.

Les noms de tables et de colonnes sont **en français, au singulier, en minuscules**.

---

## Schéma des tables

### `parametrage`

| Colonne | Type | Description |
|---|---|---|
| `idparam` | INT (PK, auto) | Identifiant |
| `libelleparam` | VARCHAR(128) | Nom du paramètre (ex. `dureeCreneau`) |
| `valeurparam` | VARCHAR(128) | Valeur (ex. `30`) |
| `uniteparam` | VARCHAR(50) | Unité (ex. `minutes`), nullable |

Données initiales (créées par `ParametrageSeeder`) :

| `libelleparam` | `valeurparam` | `uniteparam` |
|---|---|---|
| `nomPlateforme` | `Réservation en ligne` | null |
| `dureeCreneau` | `30` | `minutes` |

> Ces deux lignes sont **indispensables au démarrage** : `HomeController` lit `nomPlateforme` sans valeur de repli, et `EspaceController` lit `dureeCreneau` pour construire la grille de créneaux.

> Les paramètres `heureOuverture` et `heureFermeture` peuvent être ajoutés en base. S'ils sont absents, l'application utilise les valeurs par défaut `08:00` et `18:00`.

Accès depuis le code :

```php
// Lecture d'un paramètre simple (retourne la valeurparam en string)
Parametrage::getValeur('dureeCreneau'); // → '30'

// Lecture d'un paramètre avec son unité
$param = Parametrage::where('libelleparam', 'dureeCreneau')->first();
$duree = (int) $param->valeurparam; // → 30
$unite = $param->uniteparam;         // → 'minutes'
```

---

### `prestation`

| Colonne | Type | Description |
|---|---|---|
| `idprestation` | INT (PK, auto) | Identifiant |
| `libelleprestation` | VARCHAR(128) | Nom de la prestation |
| `montantprestation` | DECIMAL(5,2) | Tarif, nullable |

Données initiales (créées par `PrestationSeeder`) : deux prestations d'exemple, à 15,00 et 50,00. En production, le catalogue est saisi depuis le back-office C#.

---

### `role`

| Colonne | Type | Description |
|---|---|---|
| `idrole` | INT (PK, auto) | Identifiant |
| `libellerole` | VARCHAR(128) | `client` (1) ou `staff` (2) |

Données initiales (créées par `RoleSeeder`) : `1 = client`, `2 = staff`. Indispensables, `utilisateur.idrole` étant une clé étrangère vers cette table.

---

### `utilisateur`

| Colonne | Type | Description |
|---|---|---|
| `idutilisateur` | INT (PK, auto) | Identifiant |
| `idrole` | INT (FK, nullable) | Référence `role.idrole` |
| `nom` | VARCHAR(128) | Nom de famille |
| `prenom` | VARCHAR(128) | Prénom |
| `email` | VARCHAR(128) | Adresse email, nullable |
| `motpasse` | VARCHAR(128) | Hash bcrypt, nullable |
| `two_factor_code` | VARCHAR(10) | Code 2FA temporaire (6 chiffres), nullable |
| `two_factor_expires_at` | DATETIME | Expiration du code 2FA, nullable |
| `created_at` | TIMESTAMP | Géré par Laravel |
| `updated_at` | TIMESTAMP | Géré par Laravel |

> C'est la **seule table** avec des timestamps Laravel (`public $timestamps = true`).

---

### `reservation`

| Colonne | Type | Description |
|---|---|---|
| `idreservation` | INT (PK, auto) | Identifiant |
| `idutilisateur` | INT (FK) | Client ayant réservé |
| `idprestation` | INT (FK) | Prestation réservée |
| `datedebut` | DATE | Date du créneau |
| `heuredebut` | TIME | Heure de début du créneau |
| `validationpresence` | TINYINT | `0` = en attente · `1` = présence validée par le staff |

> Il n'y a **pas de table `creneau`**. Les créneaux disponibles sont calculés dynamiquement à partir de `parametrage.dureeCreneau`. Voir [espace-connecte.md](espace-connecte.md) pour le détail.

---

## Diagramme de relations

```
role ──────────────< utilisateur >──────────── reservation
                                                    │
                                               prestation
```

- Un `utilisateur` a un `role` (client ou staff)
- Un `utilisateur` peut avoir plusieurs `reservation`
- Chaque `reservation` porte sur une `prestation`

---

## Migrations et seeders

La migration `2026_07_02_000000_create_resachev_tables` ne crée **que le schéma**. Les données de référence vivent dans des seeders, sous `database/seeders/` :

| Seeder | Table alimentée |
|---|---|
| `RoleSeeder` | `role` |
| `ParametrageSeeder` | `parametrage` |
| `PrestationSeeder` | `prestation` |
| `ReferenceSeeder` | appelle les trois précédents, dans l'ordre imposé par les clés étrangères |
| `DatabaseSeeder` | `ReferenceSeeder`, puis les comptes et réservations de démonstration |

### Conséquence importante

`php artisan migrate` seul produit une base **inutilisable** : l'application ne démarre pas sans `parametrage`, et aucun utilisateur ne peut être créé sans `role`. La commande de référence pour installer ou réinitialiser la base est donc :

```bash
php artisan migrate:fresh --seed
```

Elle recrée le schéma, charge les données de référence puis les données de démonstration. Attention, elle **supprime toutes les tables** au passage : à réserver à une base de développement.

Sur un environnement où les tables existent déjà et ne doivent pas être détruites, charger uniquement les données de référence :

```bash
php artisan db:seed --class=ReferenceSeeder
```

### Réexécution

Chaque seeder utilise `updateOrInsert` sur la clé primaire : le relancer sur une base déjà remplie ne provoque pas d'erreur de doublon, il réinitialise les valeurs. Attention, cela signifie que rejouer `PrestationSeeder` écrase les prestations 1 et 2, à éviter sur une base de production alimentée depuis le back-office.

### Tests

`tests/TestCase.php` déclare `$seed = true` et `$seeder = ReferenceSeeder::class`. Le trait `RefreshDatabase` joue les migrations mais aucun seeder : sans cela, les tests échouent sur la clé étrangère `utilisateur.idrole` et sur la lecture de `parametrage.nomPlateforme`. C'est bien `ReferenceSeeder` qui est utilisé, et non `DatabaseSeeder`, pour que les comptes de démonstration ne faussent pas les assertions.

---

## Modèles Eloquent

Tous les modèles sont dans `app/Models/`. Conventions appliquées :

```php
// Exemple — conventions systématiques sur tous les modèles
class Reservation extends Model
{
    protected $table      = 'reservation';   // nom explicite (singulier français)
    protected $primaryKey = 'idreservation'; // clé primaire non standard
    public    $timestamps = false;           // pas de created_at/updated_at

    protected $fillable = ['idutilisateur', 'idprestation', 'datedebut', 'heuredebut', 'validationpresence'];

    // Les casts permettent de manipuler datedebut et heuredebut comme des objets \DateTime
    protected $casts = [
        'datedebut'  => 'date',
        'heuredebut' => 'datetime',
    ];

    // Relation : une réservation appartient à un utilisateur
    public function utilisateur()
    {
        return $this->belongsTo(Utilisateur::class, 'idutilisateur', 'idutilisateur');
    }
}
```

### Particularités du modèle `Utilisateur`

- Étend `Authenticatable` (et non `Model`) pour s'intégrer au système d'authentification Laravel
- `getAuthPassword()` retourne `$this->motpasse` (colonne non standard)
- `motpasse` est stocké **en clair**, sans cast `hashed` : la connexion compare les chaînes directement. TODO étudiant : implémenter le hachage bcrypt (voir [authentification.md](authentification.md))
- `getRememberTokenName()` retourne `null` (pas de colonne `remember_token`)
- Méthode `verifierCode2FA(string $code): bool` : compare le code soumis, vérifie l'expiration
- Méthode `prochaineReservation()` : relation `HasOne` filtrée sur `datedebut >= aujourd'hui`

```php
// Vérification du code 2FA (dans Utilisateur.php)
public function verifierCode2FA(string $code): bool
{
    return $this->two_factor_code === $code
        && $this->two_factor_expires_at !== null
        && now()->lessThanOrEqualTo($this->two_factor_expires_at);
}
```

> `app/Models/User.php` est un fichier résiduel de Laravel. Il n'est pas utilisé. Ne pas s'y référer.
