# Architecture – ResaChev Application de gestion (C#)

## Stack technique

| Couche | Technologie |
|---|---|
| Langage | C# 13 (`Nullable` et `ImplicitUsings` activés) |
| Plateforme | .NET 10 — cible `net10.0-windows` |
| Interface graphique | Windows Forms (`UseWindowsForms`), formulaires MDI-like dans un `Panel` |
| Accès aux données | Entity Framework Core 9 (ORM), fournisseur `Pomelo.EntityFrameworkCore.MySql` |
| Base de données | MySQL / MariaDB (partagée entre les 3 applications) |
| Emails | `System.Net.Mail.SmtpClient` vers le mail catcher `mail.dombtsig.local:1025` |

Aucune dépendance graphique tierce : l'interface repose uniquement sur les contrôles standards de Windows Forms (`Panel`, `Button`, `DataGridView`, `MonthCalendar`, `ComboBox`, `DateTimePicker`, `Timer`).

---

## Structure des dossiers

```
applicationc/
├── AP3_applicationC.slnx                  ← solution (format slnx)
└── AP3_applicationC/
    ├── AP3_applicationC.csproj            ← cible, paquets NuGet
    ├── Program.cs                         ← point d'entrée : init BDD + FormMenu
    ├── Controleur.cs                      ← utilitaires : validation email, envoi SMTP
    │
    ├── Entities/                           ← entités générées par scaffolding EF Core
    │   ├── Ap3BdReservationContext.cs      ← DbContext : DbSet + mapping + connexion
    │   ├── Utilisateur.cs
    │   ├── Reservation.cs
    │   ├── Prestation.cs
    │   ├── Role.cs
    │   ├── Parametrage.cs
    │   ├── Paiement.cs  ·  Modepaiement.cs
    │   └── Cache.cs · CacheLock.cs · Job.cs · JobBatch.cs · FailedJob.cs
    │       Migration.cs · PersonalAccessToken.cs · Session.cs
    │                                        ← tables techniques de Laravel, non utilisées ici
    │
    ├── Modele/                             ← couche d'accès aux données (écrite à la main)
    │   ├── ConnexionBD.cs                  ← contexte statique + lecture de parametrage
    │   ├── ModeleUtilisateur.cs            ← listes, ajout, lecture, modification d'email
    │   └── ModeleReservation.cs            ← listes, filtrage par date, ajout
    │
    ├── FormMenu.cs                         ← fenêtre principale : menu latéral animé
    ├── FormListerUtil.cs                   ← liste des utilisateurs (DataGridView)
    ├── FormCreerUtil.cs                    ← formulaire de création d'utilisateur
    ├── FormModifEmail.cs                   ← modification de l'email d'un utilisateur
    ├── FormSuivreResa.cs                   ← calendrier + réservations du jour choisi
    ├── FormReservationDetail.cs            ← détail d'une réservation (boîte modale)
    ├── FormCreerResa.cs                    ← formulaire de création de réservation
    └── doc/                                ← ce dossier
```

Chaque formulaire est composé de **trois fichiers**, convention Windows Forms :

| Fichier | Contenu |
|---|---|
| `FormXxx.cs` | Code que l'on écrit : gestionnaires d'événements, appels au modèle |
| `FormXxx.Designer.cs` | Code **généré** par le concepteur visuel : création et positionnement des contrôles |
| `FormXxx.resx` | Ressources du formulaire (images, chaînes localisées) |

> Ne jamais modifier `FormXxx.Designer.cs` à la main : le concepteur visuel de Visual Studio le réécrit. Toute logique se place dans `FormXxx.cs`.

---

## Découpage en couches

L'application suit un découpage **présentation / modèle / entités**, transposition en C# du MVC vu en cours :

```
   Formulaires (Vue + Contrôleur)          Modele/ (accès données)        Entities/ (ORM)
 ┌──────────────────────────────┐      ┌────────────────────────┐    ┌───────────────────┐
 │ FormMenu, FormListerUtil,    │ ───▶ │ ModeleUtilisateur      │───▶│ DbSet<Utilisateur>│──▶ MySQL
 │ FormCreerUtil, FormModif...  │      │ ModeleReservation      │    │ DbSet<Reservation>│
 │ FormSuivreResa, FormCreerResa│ ◀─── │ ConnexionBD            │◀───│ Ap3BdReservation  │
 └──────────────────────────────┘      └────────────────────────┘    │      Context      │
              │                                                       └───────────────────┘
              └──▶ Controleur (validation email, envoi SMTP)
```

| Couche | Rôle | Règle |
|---|---|---|
| **Formulaires** (`Form*.cs`) | Affichent les données et réagissent aux clics. Ne contiennent **aucune requête** : ils appellent les méthodes de `Modele/`. | Un formulaire ne référence jamais `ConnexionBD.MonModel` directement |
| **Modele** (`Modele/`) | Contient toutes les requêtes LINQ / EF Core (lecture, ajout, modification) et retourne des objets métier. Capture les exceptions et retourne un `bool` de succès. | Point d'entrée unique vers la base |
| **Entities** (`Entities/`) | Classes générées par scaffolding EF Core : une classe par table, plus le `DbContext`. | Régénérées, jamais modifiées à la main |
| **Controleur** (`Controleur.cs`) | Fonctions transversales sans lien avec la base : validation du format d'un email, envoi d'un message SMTP. | Classe `static` |

---

## Cycle de vie de l'application

`Program.cs` est le point d'entrée. Il initialise la configuration Windows Forms, ouvre **la connexion à la base** puis lance la fenêtre principale :

```csharp
[STAThread]
static void Main()
{
    ApplicationConfiguration.Initialize();
    Modele.ConnexionBD.init();     // crée l'instance unique de Ap3BdReservationContext
    Application.Run(new FormMenu()); // fenêtre principale ; sa fermeture termine le programme
}
```

`ConnexionBD` expose un `DbContext` **statique**, partagé par toute l'application :

```csharp
public class ConnexionBD
{
    private static Ap3BdReservationContext monModel;
    public static Ap3BdReservationContext MonModel { get => monModel; set => monModel = value; }

    public static void init() => monModel = new Ap3BdReservationContext();

    // Lecture de la table parametrage (nom de la plateforme, durées…)
    public static List<Parametrage> listeParametres()
        => ConnexionBD.MonModel.Parametrages.ToList();
}
```

> **Point de vigilance.** Un `DbContext` maintenu ouvert pendant toute la durée de vie du programme accumule les entités suivies et sert des données qui peuvent être **périmées** si une autre application (web ou mobile) modifie la base entre-temps. La bonne pratique EF Core est un contexte de courte durée (un par unité de travail, dans un `using`). C'est une évolution à prévoir ; en attendant, chaque méthode du modèle appelle `ChangeTracker.Clear()` en cas d'erreur pour ne pas laisser d'entité invalide dans le suivi.

---

## Navigation : la fenêtre principale

`FormMenu` est la seule fenêtre de premier niveau. Elle contient :

- un `panelMenu` latéral, réductible (200 px déployé / 60 px réduit) et animé par un `Timer` ;
- deux sous-menus dépliants (`panelProfileSubMenuUtil` pour les utilisateurs, `panelReservationSubMenu` pour les réservations), animés par leurs propres `Timer` ;
- un `panelContent` qui accueille les formulaires enfants.

Les autres formulaires sont ouverts **à l'intérieur** de ce panneau, par `openChildForm()` :

```csharp
public void openChildForm(Form formEnfant)
{
    if (activeForm != null) activeForm.Close();   // un seul formulaire enfant à la fois

    activeForm = formEnfant;
    formEnfant.TopLevel = false;                  // le formulaire devient un contrôle
    formEnfant.FormBorderStyle = FormBorderStyle.None;
    formEnfant.Dock = DockStyle.Fill;
    panelContent.Controls.Add(formEnfant);
    formEnfant.BringToFront();
    formEnfant.Show();
}
```

Structure du menu :

| Entrée | Sous-entrée | Action |
|---|---|---|
| 🏠 Accueil | — | Message de bienvenue reprenant le nom de la plateforme |
| 👤 Utilisateurs | Lister | `openChildForm(new FormListerUtil())` |
| | Créer | `openChildForm(new FormCreerUtil())` |
| | Modifier/Supprimer | Non implémenté (affiche un simple libellé) |
| 📅 Réservations | Suivre | `openChildForm(new FormSuivreResa())` |
| | Créer | `openChildForm(new FormCreerResa())` |
| 🔒 Quitter | — | `Application.Exit()` |

Deux formulaires font exception et s'ouvrent en fenêtre séparée : `FormModifEmail` (`Show()`) et `FormReservationDetail` (`ShowDialog()`, modale).

---

## Paramétrage de la plateforme

Au chargement, `FormMenu` lit la table `parametrage` pour renommer sa barre de titre :

```csharp
List<Parametrage> listParam = ConnexionBD.listeParametres();
nomPlateforme = listParam[0].Valeurparam.ToString();
this.Text = $"Administration de {nomPlateforme}";
```

Les heures d'ouverture et de fermeture, utilisées pour construire la liste des créneaux dans `FormCreerResa`, sont portées par deux champs publics de `FormMenu` :

```csharp
public int heureOuverture = 9;
public int heureFermeture = 17;
```

> **Points de vigilance.**
> 1. `listParam[0]` suppose que le paramètre `nomPlateforme` est la **première ligne** de la table. Il faudrait le rechercher par son libellé : `listParam.First(p => p.Libelleparam == "nomPlateforme").Valeurparam`.
> 2. `heureOuverture` / `heureFermeture` sont **codées en dur** alors que l'application web lit ces mêmes valeurs dans `parametrage`. Les deux applications peuvent donc diverger.
> 3. `FormCreerResa` va chercher ces valeurs par `Application.OpenForms["FormMenu"] as FormMenu`, ce qui couple fortement les deux formulaires et provoque une `NullReferenceException` si `FormMenu` n'est pas ouvert. Passer les valeurs en paramètre du constructeur serait plus sûr.

---

## Conventions du projet

- **Commentaires** : en français, orientés pédagogie (le public cible est des étudiants BTS SIO).
- **Nommage** : les classes et les entités suivent la casse Pascal générée par le scaffolding (`Idutilisateur`, `IdroleNavigation`) ; les méthodes du modèle écrites à la main utilisent parfois la casse camel (`listeUtilisateurs`, `ajouterReservation`), héritée des TP.
- **Préfixes des contrôles** : `btn` (bouton), `tb` (zone de texte), `cb` (liste déroulante), `dgv` (`DataGridView`), `lbl` (libellé), `bs` (`BindingSource`), `mc` (`MonthCalendar`), `dtp` (`DateTimePicker`), `chk` (case à cocher), `panel`, `timer`.
- **Gestion des erreurs** : les méthodes du modèle encapsulent l'appel dans un `try/catch`, affichent un `MessageBox` et retournent `false` ; le formulaire appelant se contente d'afficher le résultat.
- **Aucune requête SQL écrite à la main** : tout passe par LINQ et EF Core, donc par des requêtes paramétrées.
