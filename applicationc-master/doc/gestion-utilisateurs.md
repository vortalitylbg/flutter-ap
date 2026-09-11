# Gestion des utilisateurs – ResaChev Application de gestion (C#)

Trois écrans composent ce module, accessibles depuis le sous-menu **👤 Utilisateurs** de `FormMenu` : la liste, la création, et la modification de l'email.

| Écran | Formulaire | Ouverture |
|---|---|---|
| Liste des utilisateurs | `FormListerUtil` | Menu → Utilisateurs → Lister (dans `panelContent`) |
| Création d'un utilisateur | `FormCreerUtil` | Menu → Utilisateurs → Créer (dans `panelContent`) |
| Modification de l'email | `FormModifEmail` | Clic droit sur une ligne de la liste (fenêtre séparée) |

> L'entrée de menu **Modifier/Supprimer** n'est pas implémentée : elle affiche seulement un libellé dans la zone de contenu.

---

## Lister les utilisateurs — `FormListerUtil`

L'écran affiche l'ensemble des comptes dans un `DataGridView` (`dgvListeUtil`) alimenté par un `BindingSource` (`bsListeUtil`).

```csharp
public void FormListerUtil_Load(object sender, EventArgs e)
{
    bsListeUtil.DataSource = ModeleUtilisateur.listeUtilisateurs().Select(static x => new
    {
        x.Idutilisateur, x.Nom, x.Prenom, x.Email, x.Idrole,
        x.IdroleNavigation.Libellerole     // colonne issue de la table role, via la jointure
    });
    dgvListeUtil.DataSource = bsListeUtil;

    dgvListeUtil.Columns[0].HeaderText = "Identifiant";
    dgvListeUtil.Columns[1].HeaderText = "Nom";
    // …
}
```

Trois notions à retenir :

- **Le type anonyme** (`new { … }`) sélectionne uniquement les colonnes à afficher. Le `motpasse` et les jetons 2FA ne sont donc jamais chargés dans la grille.
- **Le `BindingSource`** sert d'intermédiaire entre les données et la grille : il connaît la ligne courante (`bsListeUtil.Current`), ce qui permet au menu contextuel de savoir sur quel utilisateur on a cliqué.
- **`Libellerole`** est disponible grâce au `Include(x => x.IdroleNavigation)` du modèle : sans cette jointure, la propriété de navigation serait `null` et la projection lèverait une `NullReferenceException`.

| Colonne affichée | Source |
|---|---|
| Identifiant | `utilisateur.idutilisateur` |
| Nom · Prénom · Email | `utilisateur.nom` · `prenom` · `email` |
| Id Role | `utilisateur.idrole` |
| Libellé Role | `role.libellerole` (jointure) |

### Menu contextuel

Un clic droit sur une ligne ouvre l'entrée **Modifier Email**, qui récupère l'identifiant de la ligne courante puis ouvre `FormModifEmail` :

```csharp
System.Type type = bsListeUtil.Current.GetType();
uint idU = (uint)type.GetProperty("Idutilisateur").GetValue(bsListeUtil.Current, null);

FormModifEmail formModifEmail = new FormModifEmail(idU);
formModifEmail.Show();
```

> La lecture par **réflexion** (`GetProperty(...).GetValue(...)`) est nécessaire ici parce que le `BindingSource` contient des objets de type anonyme, dont le type n'a pas de nom utilisable dans un `as`. Se lier à la liste de `Utilisateur` et masquer les colonnes inutiles éviterait ce détour.

---

## Créer un utilisateur — `FormCreerUtil`

![Création d'un utilisateur](images/07-creer-utilisateur.png)

Le formulaire comporte quatre champs : `tbNom`, `tbPrenom`, `tbEmail` et la liste déroulante `cbRoles`, remplie au chargement :

```csharp
List<Role> roles = ModeleUtilisateur.listeRoles();
cbRoles.DisplayMember = "libellerole";   // texte affiché
cbRoles.ValueMember   = "idrole";        // valeur retournée par SelectedValue
cbRoles.DataSource    = roles;
```

### Enchaînement à l'enregistrement

```
btnSave_Click
   │
   ├─ champs vides ou rôle non choisi ?  ──▶ MessageBox « Veuillez saisir tous les champs. »
   │
   ├─ Controleur.ValidMail(tbEmail.Text) == false ?  ──▶ MessageBox d'erreur de format
   │
   └─ ModeleUtilisateur.AjoutUtilisateur(nom, prenom, email, idRole)
         │
         ├─ true  ──▶ MessageBox de confirmation
         │            Controleur.CreationEmail(email, nom, prenom)   ← envoi SMTP
         │            this.Close()
         │
         └─ false ──▶ MessageBox « Erreur dans l'ajout d'un utilisateur »
```

Côté modèle, l'insertion crée l'entité puis la confie au contexte :

```csharp
public static bool AjoutUtilisateur(string nom, string prenom, string email, int idRole)
{
    bool vretour = true;
    try
    {
        Utilisateur unU = new Utilisateur
        {
            Nom = nom, Prenom = prenom, Email = email, Idrole = (uint)idRole
        };
        ConnexionBD.MonModel.Utilisateurs.Add(unU);
        ConnexionBD.MonModel.SaveChanges();
    }
    catch (Exception ex)
    {
        ConnexionBD.MonModel.ChangeTracker.Clear();
        vretour = false;
        MessageBox.Show(ex.Message.ToString());
    }
    return vretour;
}
```

Le champ `motpasse` n'est pas renseigné : le compte est créé sans mot de passe, et l'email de bienvenue invite l'utilisateur à le définir lui-même par la procédure « mot de passe oublié » du site web.

| Règle | Description |
|---|---|
| RG-UTIL-1 | Les quatre champs (nom, prénom, email, rôle) sont obligatoires. |
| RG-UTIL-2 | L'email doit respecter le format contrôlé par `Controleur.ValidMail()`. |
| RG-UTIL-3 | Un utilisateur est créé **sans mot de passe** ; il le définit lui-même via le site web. |
| RG-UTIL-4 | L'email de bienvenue n'est envoyé **qu'après** un enregistrement réussi en base. |

---

## Modifier l'email — `FormModifEmail`

![Modification de l'email](images/06-modifier-email.png)

Le formulaire reçoit l'identifiant de l'utilisateur par son constructeur, puis charge ses informations au `Load` :

```csharp
public FormModifEmail(uint idU)
{
    InitializeComponent();
    this.idUtilisateur = idU;
}

private void FormModifEmail_Load(object sender, EventArgs e)
{
    Utilisateur U = ModeleUtilisateur.RecupererUtilisateur(idUtilisateur);
    tbNom.Text = U.Nom;         // lecture seule à l'écran
    tbPrenom.Text = U.Prenom;
    tbEmail.Text = U.Email;
    tbEmail.Focus();
}
```

Nom et prénom sont affichés pour identifier le compte, seul l'email est modifiable. À l'enregistrement, le même contrôle de format s'applique, puis le modèle met à jour l'entité **déjà suivie** par le contexte :

```csharp
public static bool ModifierEmailUtilisateur(uint idUtilisateur, string email)
{
    bool vretour = true;
    try
    {
        Utilisateur unU = RecupererUtilisateur(idUtilisateur);
        unU.Email = email;
        ConnexionBD.MonModel.SaveChanges();     // EF Core génère l'UPDATE
    }
    catch (Exception ex) { /* … ChangeTracker.Clear(), vretour = false … */ }
    return vretour;
}
```

C'est ici qu'apparaît clairement l'intérêt d'un ORM : aucune requête `UPDATE` n'est écrite. EF Core compare l'état de l'entité suivie avec sa valeur d'origine et n'écrit que la colonne modifiée.

### Rafraîchissement de la liste

Après la mise à jour, le formulaire demande à la liste de se recharger :

```csharp
(System.Windows.Forms.Application.OpenForms["FormListerUtil"] as FormListerUtil)
    .FormListerUtil_Load(sender, e);
this.Close();
```

> **Point de vigilance.** Si `FormListerUtil` a été fermé entre-temps, `OpenForms["FormListerUtil"]` retourne `null` et le `as` produit `null` : l'appel lève une `NullReferenceException`. C'est aussi ce qui oblige `FormListerUtil_Load` à être `public`. Un mécanisme d'événement (le formulaire de modification publie un événement `EmailModifie`, la liste s'y abonne) supprimerait ce couplage.

---

## Utilitaires — `Controleur`

`Controleur` est une classe **statique** qui regroupe deux fonctions transversales, indépendantes de la base de données.

### Validation du format d'un email

```csharp
public static bool ValidMail(string mail)
{
    string pattern = @"^([a-zA-Z0-9_\.]+)@([a-zA-Z0-9_\-]+)\.([\w]{2,4})$";
    Regex r1 = new Regex(pattern);
    return r1.IsMatch(mail);
}
```

L'expression régulière impose : des caractères alphanumériques, `_` ou `.` avant l'arobase ; un nom de domaine alphanumérique avec `_` ou `-` ; une extension de 2 à 4 caractères.

> Cette expression rejette des adresses pourtant valides : sous-domaines (`nom@mail.univ.fr`), signe `+` (`nom+resa@example.com`), extensions longues (`.travel`, `.museum`). `new MailAddress(mail)` dans un `try/catch`, ou l'attribut `[EmailAddress]`, seraient plus tolérants. La validation reste de toute façon **indicative** : seule la réception effective de l'email prouve que l'adresse existe.

### Envoi de l'email de création de compte

```csharp
public static void CreationEmail(string dest, string nom, string prenom)
{
    string from = "admin.chevrollier.contact@resachev.com";
    MailMessage message = new MailMessage(from, dest);
    message.Subject = "RESA CHEV : AJOUT D'UN UTILISATEUR";
    message.Body = "Bonjour " + nom + " " + prenom + ", …";

    SmtpClient client = new SmtpClient();
    client.Host = "mail.dombtsig.local";
    client.Port = 1025;
    client.UseDefaultCredentials = true;

    try { client.Send(message); }
    catch (Exception ex) { Console.WriteLine("Exception caught in CreateEmail(): {0}", ex); }
}
```

| Paramètre | Valeur |
|---|---|
| Serveur SMTP | `mail.dombtsig.local` |
| Port | `1025` |
| Expéditeur | `admin.chevrollier.contact@resachev.com` |
| Sujet | `RESA CHEV : AJOUT D'UN UTILISATEUR` |
| Authentification | Aucune (`UseDefaultCredentials`) |

Le serveur est le **mail catcher** de l'environnement de projet : il intercepte tous les messages au lieu de les délivrer, ce qui permet de tester l'envoi sans qu'aucun email n'atteigne un destinataire réel.

Le corps du message annonce la création du compte et indique la marche à suivre pour définir un mot de passe :

> Bonjour {nom} {prénom},
>
> Nous validons la création de votre compte en tant que nouvel utilisateur.
>
> Pour vous connecter au service de réservation web, utiliser le mot de passe oublié la première fois pour le définir.
>
> Bien Cordialement,
>
> L'équipe de RésaChev'

> **Points de vigilance.**
> 1. L'échec d'envoi est écrit sur la console (`Console.WriteLine`), invisible dans une application Windows Forms : l'administrateur croit l'email parti alors qu'il ne l'est pas. Un `MessageBox` ou un journal de log s'impose.
> 2. `SmtpClient` est marqué obsolète par Microsoft pour les nouveaux développements ; `MailKit` est la bibliothèque recommandée en production.
> 3. L'envoi est **synchrone** : l'interface se fige le temps de la connexion SMTP, jusqu'au délai d'expiration si le serveur est injoignable.
