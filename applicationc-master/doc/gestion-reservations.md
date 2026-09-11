# Gestion des réservations – ResaChev Application de gestion (C#)

Deux écrans composent ce module, accessibles depuis le sous-menu **📅 Réservations** de `FormMenu`, plus une boîte de dialogue de détail.

| Écran | Formulaire | Ouverture |
|---|---|---|
| Suivi des réservations | `FormSuivreResa` | Menu → Réservations → Suivre (dans `panelContent`) |
| Détail d'une réservation | `FormReservationDetail` | Double-clic sur une ligne (fenêtre **modale**) |
| Création d'une réservation | `FormCreerResa` | Menu → Réservations → Créer (dans `panelContent`) |

---

## Suivre les réservations — `FormSuivreResa`

![Suivi des réservations](images/10-suivre-reservations.png)

L'écran associe un calendrier mensuel (`mcCalendar`, un `MonthCalendar`) et une grille (`dgvReservations`) listant les réservations du jour sélectionné.

### Chargement initial

```csharp
private void LoadCalendar()
{
    List<Reservation> all = ModeleReservation.listeReservations();

    // Mettre en gras, dans le calendrier, les jours qui portent au moins une réservation
    var dates = all.Select(r => r.Datedebut.ToDateTime(new TimeOnly(0, 0)))
                   .Distinct()
                   .ToArray();
    mcCalendar.RemoveAllBoldedDates();
    foreach (var dt in dates) mcCalendar.AddBoldedDate(dt);
    mcCalendar.UpdateBoldedDates();      // indispensable : applique les dates ajoutées

    // Charger la journée sélectionnée (aujourd'hui au démarrage)
    LoadReservationsForDate(DateOnly.FromDateTime(mcCalendar.SelectionStart));
}
```

Le `MonthCalendar` offre ainsi une **vue d'ensemble immédiate** : les jours en gras sont ceux qui ont de l'activité. `Distinct()` évite d'ajouter plusieurs fois la même date lorsqu'un jour porte plusieurs réservations.

### Affichage d'une journée

L'événement `DateSelected` du calendrier déclenche le rechargement de la grille :

```csharp
private void LoadReservationsForDate(DateOnly date)
{
    List<Reservation> list = ModeleReservation.listeReservationsPourDate(date);
    dgvReservations.Rows.Clear();

    foreach (var r in list.OrderBy(r => r.Heuredebut))
    {
        var time     = r.Heuredebut.ToString("HH:mm");
        var user     = r.IdutilisateurNavigation != null
                       ? $"{r.IdutilisateurNavigation.Nom} {r.IdutilisateurNavigation.Prenom}"
                       : r.Idutilisateur.ToString();
        var prest    = r.IdprestationNavigation?.Libelleprestation ?? r.Idprestation.ToString();
        var presence = r.Validationpresence == 1 ? "Oui" : "Non";

        var idx = dgvReservations.Rows.Add(time, user, prest, presence);
        dgvReservations.Rows[idx].Tag = r;   // l'objet métier est attaché à la ligne
    }

    lblSelectedDate.Text = $"Réservations pour le {date:d} : {list.Count}";
}
```

| Colonne | Contenu | Source |
|---|---|---|
| Heure | `08:30` | `reservation.heuredebut`, formaté `HH:mm` |
| Utilisateur | `Dupont Jean` | Jointure `utilisateur` (nom + prénom) |
| Prestation | `Balade à cheval` | Jointure `prestation` |
| Présence | `Oui` / `Non` | `reservation.validationpresence` (1 / 0) |

Contrairement à `FormListerUtil`, la grille est ici remplie **ligne à ligne** (`Rows.Add`) et non par liaison de données. Cela permet d'appliquer un format d'affichage à chaque valeur, et surtout de conserver l'objet `Reservation` complet dans la propriété `Tag` de la ligne : c'est lui qui sera transmis à la fenêtre de détail, sans nouvelle requête.

Les lignes sont triées par heure (`OrderBy(r => r.Heuredebut)`), la journée se lit donc chronologiquement.

### Détail d'une réservation

Le double-clic sur une ligne ouvre `FormReservationDetail` en fenêtre **modale** :

```csharp
private void dgvReservations_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
{
    if (e.RowIndex < 0) return;                  // clic sur l'en-tête : on ignore
    var row = dgvReservations.Rows[e.RowIndex];

    if (row?.Tag is Reservation r)               // récupération de l'objet attaché à la ligne
    {
        using var dlg = new FormReservationDetail(r);
        dlg.ShowDialog(this);                    // modale : bloque tant qu'elle est ouverte
    }
}
```

![Détail d'une réservation](images/11-reservation-detail.png)

La fenêtre est en **lecture seule** et affiche l'identifiant, le client, la prestation, la date, l'heure et l'état de validation de présence. Le `using` garantit la libération des ressources du formulaire à sa fermeture.

| Règle | Description |
|---|---|
| RG-RESA-1 | Les jours portant au moins une réservation apparaissent en gras dans le calendrier. |
| RG-RESA-2 | La grille affiche les réservations du seul jour sélectionné, triées par heure croissante. |
| RG-RESA-3 | Le détail d'une réservation est consultable en lecture seule, par double-clic. |
| RG-RESA-4 | La validation de présence n'est **pas** modifiable ici : elle est mise à jour par l'application mobile lors du scan du QR code. |

> **Point de vigilance.** `listeReservationsPourDate()` charge **toutes** les réservations puis filtre en mémoire (voir [base-de-donnees.md](base-de-donnees.md)). À chaque clic sur une date, la table entière transite par le réseau. Le filtre doit être exprimé dans la requête LINQ avant `ToList()`.

---

## Créer une réservation — `FormCreerResa`

![Création d'une réservation](images/12-creer-reservation.png)

Le formulaire réunit quatre saisies : le client (`cbUtilisateur`), la date (`dtpDate`, un `DateTimePicker`), l'heure (`cbHeure`) et une case « Validation présence » (`chkValidation`).

### Construction de la liste des créneaux

Les heures proposées sont générées par pas de 30 minutes entre l'ouverture et la fermeture :

```csharp
private void PopulateHeureCombo()
{
    int heureOuverture = (Application.OpenForms["FormMenu"] as FormMenu).heureOuverture;  // 9
    int heureFermeture = (Application.OpenForms["FormMenu"] as FormMenu).heureFermeture;  // 17

    cbHeure.Items.Clear();
    for (int h = heureOuverture; h < heureFermeture; h++)
    {
        cbHeure.Items.Add($"{h:00}:00");
        cbHeure.Items.Add($"{h:00}:30");
    }

    // Présélection du demi-créneau le plus proche de l'heure courante
    DateTime now = DateTime.Now;
    int index = now.Hour * 2 + (now.Minute >= 30 ? 1 : 0);
    …
    cbHeure.SelectedIndex = index;
}
```

C'est la transposition, côté gestion, du calcul de créneaux de l'application web : **aucun créneau n'est stocké en base**, ils sont recalculés à l'affichage.

> **Points de vigilance.**
> 1. Les bornes proviennent des champs publics `heureOuverture` / `heureFermeture` de `FormMenu`, codés en dur à 9 h et 17 h, et non de la table `parametrage` que lit le site web. Le pas de 30 minutes est lui aussi écrit en dur, alors que `parametrage.dureeCreneau` existe. Les deux applications peuvent donc proposer des créneaux différents.
> 2. La présélection `now.Hour * 2 + …` calcule un index comme si la liste commençait à 00:00. Comme elle commence à `heureOuverture`, le créneau présélectionné est décalé (à 10 h, l'index 20 désigne 19:00 dans une liste qui démarre à 09:00, donc en pratique le dernier élément après écrêtage). L'index correct est `(now.Hour - heureOuverture) * 2 + (now.Minute >= 30 ? 1 : 0)`.
> 3. L'accès par `Application.OpenForms["FormMenu"]` lève une `NullReferenceException` si la fenêtre principale n'est pas ouverte. Les valeurs devraient être passées au constructeur.

### Lecture de l'heure choisie

La valeur sélectionnée est une chaîne (`"09:30"`) qu'il faut reconvertir en durée :

```csharp
public TimeSpan GetSelectedHeure()
{
    if (cbHeure?.SelectedItem == null) return TimeSpan.Zero;

    if (TimeSpan.TryParseExact(cbHeure.SelectedItem.ToString(), "hh\\:mm",
                               CultureInfo.InvariantCulture, out TimeSpan ts))
        return ts;
    …
}
```

`CultureInfo.InvariantCulture` évite qu'un poste configuré dans une autre langue n'interprète différemment le séparateur.

### Enregistrement

```csharp
Reservation resa = new Reservation
{
    Idutilisateur      = Convert.ToUInt32(cbUtilisateur.SelectedValue),
    Idprestation       = 99,                                    // valeur par défaut
    Datedebut          = DateOnly.FromDateTime(dtpDate.Value.Date),
    Heuredebut         = TimeOnly.FromTimeSpan(GetSelectedHeure()),
    Validationpresence = chkValidation.Checked ? (sbyte)1 : (sbyte)0
};

bool ok = ModeleReservation.ajouterReservation(resa);
```

Côté modèle, l'ajout est classique et retourne un simple booléen :

```csharp
public static bool ajouterReservation(Reservation r)
{
    try
    {
        ConnexionBD.MonModel.Reservations.Add(r);
        ConnexionBD.MonModel.SaveChanges();
        return true;
    }
    catch
    {
        ConnexionBD.MonModel.ChangeTracker.Clear();
        return false;
    }
}
```

> **Points de vigilance — fonctionnalité à terminer.**
> 1. **`Idprestation = 99` est écrit en dur.** Le formulaire ne propose pas de choisir la prestation. Si aucune prestation ne porte l'identifiant 99, la contrainte de clé étrangère `reservation_idprestation_foreign` est violée et l'insertion échoue systématiquement. Il manque une liste déroulante alimentée par `Prestations`, sur le modèle de `cbRoles` dans `FormCreerUtil`.
> 2. **Le message d'échec est trompeur.** En cas d'erreur, l'application affiche « l'utilisateur est déjà occupé sur ce créneau » alors qu'**aucun contrôle de collision n'est effectué** : le `catch` intercepte n'importe quelle exception (clé étrangère, base injoignable…). Le contrôle d'unicité du couple (utilisateur, date, heure) reste à écrire, et le message à rendre fidèle à la cause réelle.
> 3. Le `catch` du modèle ne conserve pas l'exception : la cause de l'échec est perdue, ce qui rend le diagnostic difficile.
> 4. `cbUtilisateur.DisplayMember = "Nom"` n'affiche que le nom de famille : deux homonymes sont indiscernables. Afficher « Nom Prénom (email) » lèverait l'ambiguïté.

| Règle | Description |
|---|---|
| RG-CREA-1 | Le client est obligatoire ; sans sélection, l'enregistrement est refusé. |
| RG-CREA-2 | Les créneaux proposés vont de 09:00 à 16:30 par pas de 30 minutes (bornes actuellement codées en dur). |
| RG-CREA-3 | La présence peut être validée dès la création, via la case à cocher (usage : saisie a posteriori). |
| RG-CREA-4 | La prestation n'est pas encore sélectionnable : évolution à réaliser. |
