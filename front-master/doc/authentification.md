# Authentification – ResaChev Web

L'authentification est **implémentée manuellement**, sans Laravel Breeze ni Fortify. Elle utilise le guard `web` (sessions) configuré dans `config/auth.php` sur le modèle `Utilisateur`.

---

## Flux de connexion (2FA)

### Cas normal — 2FA activée (`AUTH_2FA_ENABLED=true`)

```
Navigateur                    ConnexionController              Base de données        Email
    │                                │                               │                  │
    │── POST /connexion ────────────>│                               │                  │
    │   email + motpasse             │── SELECT WHERE email=... ────>│                  │
    │                                │<─ utilisateur ────────────────│                  │
    │                                │── motpasse === BDD ? ─────────│                  │
    │                                │                               │                  │
    │                                │── UPDATE two_factor_code ────>│                  │
    │                                │         two_factor_expires_at  │                  │
    │                                │── EmailHelpers::sendEmail() ──────────────────>  │
    │                                │── session()->put('2fa_email') │    code 6 chiff. │
    │<── redirect /connexion/verification ────────────────────────── │                  │
    │                                │                               │                  │
    │── POST /connexion/verification ─>│                              │                  │
    │   code                         │── SELECT WHERE email=... ────>│                  │
    │                                │<─ utilisateur ────────────────│                  │
    │                                │── verifierCode2FA(code) ──────│ vérifie code     │
    │                                │                               │ + expiration      │
    │                                │── UPDATE two_factor_code=null>│                  │
    │                                │── Auth::login()               │                  │
    │                                │── session()->regenerate()     │                  │
    │<── redirect /espace/tableau-de-bord ───────────────────────────│                  │
```

### Cas dégradé — 2FA désactivée (`AUTH_2FA_ENABLED=false`)

```
Navigateur                    ConnexionController
    │                                │
    │── POST /connexion ────────────>│
    │   email + motpasse             │── motpasse === BDD ?
    │                                │── Auth::login()
    │                                │── session()->regenerate()
    │<── redirect /espace/tableau-de-bord ──────────────────────
```

### Cas d'erreur

```
POST /connexion
   ├─ email ou motpasse incorrect   → back() + withErrors(['email' => '...'])
   └─ 2FA activée, identifiants OK  → génère code + email + redirect vérification

POST /connexion/verification
   ├─ code incorrect ou expiré      → back() + withErrors(['code' => '...'])
   └─ session '2fa_email' absente   → redirect /connexion (accès direct à l'URL)
```

### Comptes de test

`php artisan migrate:fresh --seed` crée deux comptes clients, mot de passe `password` pour les deux :

| Email | Nom |
|---|---|
| `test@example.com` | Jean Dupont |
| `marie@example.com` | Marie Martin |

Les mots de passe sont stockés en clair dans le seeder et la factory, par cohérence avec la comparaison directe décrite ci-dessous. Un mot de passe haché rendrait ces comptes inutilisables tant que le hachage n'est pas implémenté côté connexion.

Pour tester sans configurer de serveur SMTP, positionner `AUTH_2FA_ENABLED=false` : la connexion devient directe, sans code à saisir.

---

### Étape 1 — `POST /connexion` (`ConnexionController@login`)

1. Validation : `email` (requis, format email) + `motpasse` (requis)
2. Recherche de l'utilisateur par email (`Utilisateur::where('email', ...)->first()`)
3. Vérification du mot de passe par **comparaison directe** (`$request->motpasse !== $utilisateur->motpasse`) — les mots de passe sont stockés en clair  
   > TODO étudiant : remplacer par `password_verify($request->motpasse, $utilisateur->motpasse)` et stocker les mots de passe hashés avec `password_hash($motpasse, PASSWORD_BCRYPT)`
4. Si `AUTH_2FA_ENABLED=false` → `Auth::login()` direct
5. Sinon → génère un code à 6 chiffres (`str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT)`)
6. Stocke le code et son expiration (10 min) dans `two_factor_code` / `two_factor_expires_at`
7. Envoie le code par email via `EmailHelpers::sendEmail()`
8. Stocke l'email en session (`session()->put('2fa_email', ...)`)
9. Redirige vers `/connexion/verification`

### Étape 2 — `POST /connexion/verification` (`ConnexionController@verify2FA`)

1. Validation : `code` (requis, exactement 6 caractères)
2. Récupère l'email depuis la session (`session()->get('2fa_email')`)
3. Appelle `$utilisateur->verifierCode2FA($code)` → vérifie code + expiration
4. Si invalide → retour formulaire avec erreur `code`
5. Si valide :
   - Invalide le code (`two_factor_code = null`, `two_factor_expires_at = null`)
   - Supprime `2fa_email` de la session
   - `Auth::login($utilisateur)`
   - `session()->regenerate()` (protection CSRF/fixation)
   - Redirige vers `/espace/tableau-de-bord`

### Protection

- La redirection des non-connectés vers `/connexion` est configurée dans `bootstrap/app.php` via `redirectGuestsTo()`.
- Les routes `/espace/*` sont toutes protégées par le middleware `auth`.
- `showVerification()` redirige vers `/connexion` si la session `2fa_email` est absente.

---

## Déconnexion — `POST /deconnexion`

```php
Auth::logout();
$request->session()->invalidate();       // détruit la session côté serveur
$request->session()->regenerateToken();  // nouveau token CSRF
redirect()->route('home');
```

---

## Mot de passe oublié

Flux en deux étapes :

```
1. GET  /mot-de-passe-oublie     → affiche le formulaire email
2. POST /mot-de-passe-oublie     → génère token + envoie lien par email
3. GET  /reset-mot-de-passe/{token} → formulaire nouveau mot de passe
4. POST /reset-mot-de-passe/{token} → enregistre + invalide token + redirect connexion
```

### Sécurité

- Le message de succès du `POST /mot-de-passe-oublie` est **identique** que l'email existe ou non (évite la divulgation d'existence de compte).
- Le token de reset est un string aléatoire de 64 caractères (`Str::random(64)`), valable **30 minutes**.
- Après usage, `reset_token` et `reset_token_expires_at` sont remis à `null`.
- Mot de passe minimum 8 caractères, confirmation requise (règle `confirmed`).

> Les colonnes `reset_token` et `reset_token_expires_at` existent sur la table `utilisateur` mais ne figurent pas dans la migration initiale — elles sont à ajouter selon l'avancement du projet.

---

## Désactiver la 2FA (développement)

Dans `.env` :

```
AUTH_2FA_ENABLED=false
```

Lue dans `config/auth.php` :

```php
'2fa_enabled' => env('AUTH_2FA_ENABLED', true),
```

Testée dans `ConnexionController@login` :

```php
if (!config('auth.2fa_enabled')) {
    Auth::login($utilisateur);
    $request->session()->regenerate();
    return redirect()->route('espace.dashboard');
}
```

> La désactivation court-circuite l'envoi d'email et la vérification du code. Elle s'applique aussi à l'API mobile (voir [api-mobile.md](api-mobile.md)).

---

## Envoi d'emails — `EmailHelpers`

Toujours utiliser `App\Utils\EmailHelpers` plutôt que d'appeler `Mail::` directement :

```php
EmailHelpers::sendEmail(
    $utilisateur->email,          // destinataire
    'Votre code de connexion',    // objet
    'emails.code2fa',             // vue Blade du corps
    ['prenom' => '...', 'code' => '...'] // variables passées à la vue
);
```

Les vues emails sont dans `resources/views/emails/`.
