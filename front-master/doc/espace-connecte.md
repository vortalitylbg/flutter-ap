# Espace connecté – ResaChev Web

Toutes les routes `/espace/*` sont protégées par le middleware `auth`. Le contrôleur est `app/Http/Controllers/EspaceController.php`.

---

## Tableau de bord — `GET /espace/tableau-de-bord`

Vue : `resources/views/espace/dashboard.blade.php`

La page est composée de deux parties :

1. **Carte "Prochaine réservation"** — rendue côté serveur par Blade
2. **Grille de créneaux** — rendue côté client par Vue.js

### Carte prochaine réservation

Le contrôleur charge la prochaine réservation via la méthode `prochaineReservation()` du modèle `Utilisateur` :

```php
$prochaineReservation = $utilisateur->prochaineReservation()->with('prestation')->first();
```

La méthode `prochaineReservation()` est une relation `HasOne` filtrée sur `datedebut >= aujourd'hui`. Elle retourne `null` s'il n'y a aucune réservation à venir.

La vue affiche :
- Le nom de la prestation et la date/heure
- Un badge **"Afficher mon QR Code"** (lien vers `/espace/qrcode`) si la présence n'est pas encore validée
- Un badge **"Présence validée"** si `validationpresence = 1`

---

## Grille de créneaux (Vue.js + API JSON)

### Architecture

La grille n'est pas rendue par Blade. Elle est entièrement gérée par Vue.js, qui charge les données via un appel `fetch()` vers l'API interne.

```
Navigateur (Vue.js)  →  GET /espace/creneaux?debut=Y-m-d  →  EspaceController@creneaux
                                                                       ↓
                                                               Réponse JSON
                                                                       ↓
                               Vue.js met à jour la grille automatiquement
```

### API interne — `GET /espace/creneaux`

Contrôleur : `EspaceController@creneaux`  
Route nommée : `espace.creneaux`  
Protégée par : middleware `auth` (session web, pas de token)

**Paramètre GET :**

| Paramètre | Type | Défaut | Description |
|---|---|---|---|
| `debut` | `Y-m-d` | hier | Date de départ de la plage à afficher |

**Réponse JSON :**

```json
{
  "debut":   "2026-07-01",
  "semaine": "01 juillet – 07 juillet 2026",
  "jours": [
    {
      "date":  "2026-07-01",
      "label": "Mer. 01/07",
      "slots": [
        {
          "heure":      "08:00",
          "statut":     "libre",
          "prestation": null
        },
        {
          "heure":      "08:30",
          "statut":     "ma_reservation",
          "prestation": "exemple prestation1"
        }
      ]
    }
  ]
}
```

**Valeurs du champ `statut` :**

| Statut | Couleur CSS | Signification |
|---|---|---|
| `libre` | vert clair | Aucune réservation sur ce créneau |
| `occupe` | gris | Réservé par un autre client |
| `ma_reservation` | bleu | Réservé par l'utilisateur connecté, présence non validée |
| `valide` | vert foncé | Réservé par l'utilisateur connecté, présence validée par le staff |

**Fonctionnement interne du contrôleur (étape par étape) :**

**Étape 1 — Plage de dates**
```php
$debut = new \DateTime($request->filled('debut') ? $request->debut : 'yesterday');
$fin   = (clone $debut)->modify('+6 days'); // 7 jours au total
```
Pas de Carbon. `clone` crée une copie indépendante pour ne pas modifier `$debut`.

**Étape 2 — Paramètres lus en base**
```php
$paramCreneau   = Parametrage::where('libelleparam', 'dureeCreneau')->first();
$dureeCreneau   = (int) ($paramCreneau->valeurparam ?? 30);    // ex. 30
$uniteCreneau   = $paramCreneau->uniteparam ?? 'minutes';       // ex. "minutes"
$heureOuverture = Parametrage::getValeur('heureOuverture') ?? '08:00';
$heureFermeture = Parametrage::getValeur('heureFermeture') ?? '18:00';
```

**Étape 3 — Génération des créneaux de la journée**
```php
$heureCourante = \DateTime::createFromFormat('H:i', $heureOuverture);
$heureFin      = \DateTime::createFromFormat('H:i', $heureFermeture);

$heures = [];
while ($heureCourante < $heureFin) {
    $heures[] = $heureCourante->format('H:i');          // ex. "08:00"
    $heureCourante->modify("+{$dureeCreneau} {$uniteCreneau}"); // avance de 30 min
}
// Résultat : ["08:00", "08:30", "09:00", …, "17:30"]
```

**Étape 4 — Réservations de l'utilisateur sur la plage**
```php
$mesReservations = $utilisateur->reservations()
    ->with('prestation')
    ->whereBetween('datedebut', [$dateDebut, $dateFin])
    ->get();

// Tableau associatif clé → réservation pour accès O(1)
$mesReservationsParCle = [];
foreach ($mesReservations as $reservation) {
    $cle = $reservation->datedebut->format('Y-m-d') . '_' . $reservation->heuredebut->format('H:i');
    $mesReservationsParCle[$cle] = $reservation;
}
// Exemple : ["2026-07-01_08:30" => $reservation, …]
```

**Étape 5 — Créneaux occupés (tous clients)**
```php
$toutesLesReservations = Reservation::whereBetween('datedebut', [$dateDebut, $dateFin])
    ->get(['datedebut', 'heuredebut']); // colonnes minimales, pas de données personnelles

$creneauxOccupes = [];
foreach ($toutesLesReservations as $reservation) {
    $cle = $reservation->datedebut->format('Y-m-d') . '_' . $reservation->heuredebut->format('H:i');
    $creneauxOccupes[$cle] = true;
}
```

**Étape 6 — Construction de la réponse**

Pour chaque jour (7 itérations) et chaque heure, on détermine le statut par priorité :
1. L'utilisateur a une réservation sur ce créneau → `ma_reservation` ou `valide`
2. Un autre utilisateur a une réservation → `occupe`
3. Sinon → `libre`

### Vue.js — application `#app-creneaux`

L'application Vue.js est dans `resources/views/espace/dashboard.blade.php`, dans le bloc `@push('scripts')`. Elle utilise l'**Options API** (pas la Composition API) pour rester accessible aux débutants.

**Données réactives (`data()`) :**

| Propriété | Type | Rôle |
|---|---|---|
| `jours` | `Array` | Tableau de jours retourné par l'API |
| `semaineLabel` | `String` | Libellé de la plage (ex. "01 juillet – 07 juillet 2026") |
| `debutActuel` | `String` | Date de début au format `Y-m-d` (pour la navigation) |
| `chargement` | `Boolean` | Affiche "Chargement…" pendant le `fetch()` |

**Méthodes (`methods`) :**

| Méthode | Rôle |
|---|---|
| `hier()` | Retourne la date d'hier au format `Y-m-d` |
| `charger(debut)` | `async` — appelle l'API et met à jour `jours`, `semaineLabel`, `debutActuel` |
| `precedente()` | Recule de 7 jours et appelle `charger()` |
| `suivante()` | Avance de 7 jours et appelle `charger()` |
| `labelStatut(slot)` | Retourne le texte à afficher dans une cellule (`Libre`, `Occupé`, ou le nom de la prestation) |
| `clicCreneau(slot)` | Redirige vers le QR code si `ma_reservation`/`valide`, sinon `console.log()` |

**Directives Vue utilisées dans le template :**

| Directive | Rôle |
|---|---|
| `v-if` / `v-else` | Affiche le spinner ou la grille selon `chargement` |
| `v-for="jour in jours"` | Répète un élément pour chaque jour |
| `v-for="(slot, index) in jours[0].slots"` | Itère sur les créneaux en récupérant l'index |
| `:class` | Binding dynamique de la classe CSS selon le statut |
| `:style` | Définit `grid-template-columns` selon le nombre de jours |
| `@click` | Gère le clic sur un créneau |
| `@{{ }}` | Affiche une variable Vue (le `@` échappe Blade) |

> `<template>` est une balise Vue invisible — elle regroupe plusieurs éléments sans ajouter de `<div>` dans le HTML final.

**CSS de la grille :**

Les styles sont dans `public/css/main.css`. Classes principales :

| Classe | Rôle |
|---|---|
| `.grille` | Container CSS Grid |
| `.grille-entete` | En-tête de colonne (jour) |
| `.grille-heure` | Cellule d'heure (colonne gauche) |
| `.creneau` | Cellule de créneau |
| `.creneau-libre` | Fond vert clair |
| `.creneau-occupe` | Fond gris |
| `.creneau-ma_reservation` | Fond bleu |
| `.creneau-valide` | Fond vert foncé |

**Évolutions possibles (TODO étudiants) :**
- Ouvrir une modale au clic sur un créneau libre pour proposer une réservation
- Filtrer les créneaux par prestation
- Afficher le nombre de places restantes

---

## Profil — `GET /espace/profil`

Vue : `resources/views/espace/profil.blade.php`

Formulaire `PUT /espace/profil` permettant de modifier uniquement le **nom**.

```php
$request->validate(['nom' => 'required|string|max:100']);
Auth::user()->update(['nom' => $request->nom]);
return redirect()->route('espace.profil')->with('statut', 'Profil mis à jour.');
```

**TODO pour les étudiants :** ajouter email, mot de passe, téléphone, etc.

---

## QR Code — `GET /espace/qrcode`

Vue : `resources/views/espace/qrcode.blade.php`

Affiche la prochaine réservation de l'utilisateur sous forme de **billet** avec un QR code scannable par le staff.

### Génération du QR code

La librairie `qrcodejs` (`public/js/qrcode.min.js`) génère le QR code côté navigateur :

```javascript
new QRCode(document.getElementById('qrcode'), {
    text: '{{ $prochaineReservation->idreservation }}', // valeur encodée
    width: 200,
    height: 200,
    colorDark: '#000000',
    colorLight: '#ffffff',
    correctLevel: QRCode.CorrectLevel.H,
});
```

Le QR code encode uniquement l'`idreservation`. Quand le staff scanne le code avec l'application Flutter, il envoie cet identifiant à `POST /api/mobile/valider-presence`.

### Impression

Le bouton "Imprimer le billet" déclenche `window.print()`. La mise en page imprimable est définie dans `public/css/print.css`, chargée uniquement sur cette page via `@push('styles')`.

La classe `.no-print` masque les éléments de navigation à l'impression.
