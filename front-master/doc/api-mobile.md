# API Mobile – ResaChev

L'API mobile permet à l'application Flutter (staff terrain) de s'authentifier et d'interagir avec les réservations. Elle utilise **Laravel Sanctum** pour l'authentification par token.

Routes définies dans `routes/api.php`. Contrôleur : `app/Http/Controllers/Api/MobileController.php`.

L'URL de base est `/api` (préfixe automatique de Laravel pour `routes/api.php`).

---

## Authentification — flux en deux étapes

Seuls les utilisateurs avec le rôle **staff** (`idrole = 2`) peuvent accéder à l'API mobile.

```
Étape 1 : POST /api/mobile/login
  → vérification email/motpasse
  → envoi code 2FA par email
  → réponse : { message, email }

Étape 2 : POST /api/mobile/verify-2fa
  → vérification du code 2FA
  → révocation des anciens tokens
  → création d'un nouveau token Sanctum
  → réponse : { token, utilisateur }

Requêtes suivantes : Authorization: Bearer {token}
```

---

## Endpoints

### POST `/api/mobile/login` — Étape 1/2

Vérifie les identifiants du staff et envoie un code 2FA par email.

**Corps de la requête :**
```json
{
  "email":    "staff@exemple.fr",
  "motpasse": "motdepasse"
}
```

**Réponse 200 (2FA activée) :**
```json
{
  "message": "Un code de vérification a été envoyé par email.",
  "email":   "staff@exemple.fr"
}
```

**Réponse 200 (2FA désactivée — `AUTH_2FA_ENABLED=false`) :**
```json
{
  "token": "1|AbCdEf...",
  "utilisateur": {
    "idutilisateur": 5,
    "nom":    "Dupont",
    "prenom": "Marie",
    "email":  "staff@exemple.fr"
  }
}
```

**Réponse 401 (identifiants invalides ou utilisateur non staff) :**
```json
{
  "message": "Identifiants invalides ou accès non autorisé."
}
```

---

### POST `/api/mobile/verify-2fa` — Étape 2/2

Vérifie le code 2FA reçu par email et retourne le token Sanctum.

**Corps de la requête :**
```json
{
  "email": "staff@exemple.fr",
  "code":  "123456"
}
```

**Réponse 200 :**
```json
{
  "token": "1|AbCdEf...",
  "utilisateur": {
    "idutilisateur": 5,
    "nom":    "Dupont",
    "prenom": "Marie",
    "email":  "staff@exemple.fr"
  }
}
```

**Réponse 401 (code invalide ou expiré) :**
```json
{
  "message": "Code invalide ou expiré."
}
```

> Le code est invalidé immédiatement après usage. Les anciens tokens Sanctum sont révoqués avant d'en créer un nouveau (un seul token actif par utilisateur).

---

### GET `/api/mobile/rdv` *(auth:sanctum)*

Retourne toutes les réservations à partir d'aujourd'hui, triées par date et heure croissantes.

**En-tête requis :**
```
Authorization: Bearer {token}
```

**Réponse 200 :**
```json
[
  {
    "idreservation":     42,
    "datedebut":         "07/07/2026",
    "heuredebut":        "09:00",
    "validationpresence": 0,
    "prestation":        "exemple prestation1",
    "client": {
      "nom":    "Martin",
      "prenom": "Jean"
    }
  },
  {
    "idreservation":     43,
    "datedebut":         "07/07/2026",
    "heuredebut":        "09:30",
    "validationpresence": 1,
    "prestation":        "exemple prestation2",
    "client": {
      "nom":    "Leblanc",
      "prenom": "Sophie"
    }
  }
]
```

---

### POST `/api/mobile/valider-presence` *(auth:sanctum)*

Valide la présence d'un client à partir de l'`idreservation` transmis via le QR code scanné.

**En-tête requis :**
```
Authorization: Bearer {token}
```

**Corps de la requête :**
```json
{
  "idreservation": 42
}
```

**Réponse 200 :**
```json
{
  "message":       "Présence validée.",
  "idreservation": 42
}
```

**Réponse 409 (présence déjà validée) :**
```json
{
  "message": "Présence déjà validée."
}
```

**Réponse 422 (idreservation manquant ou inexistant) :**
```json
{
  "message": "The idreservation field is required.",
  "errors":  { "idreservation": ["..."] }
}
```

---

## Codes HTTP utilisés

| Code | Signification |
|---|---|
| 200 | Succès |
| 401 | Non authentifié (mauvais identifiants ou token invalide) |
| 409 | Conflit (présence déjà validée) |
| 422 | Données invalides (validation échouée) |

---

## Flux complet — exemple d'utilisation (Flutter)

```
1. Staff ouvre l'app → POST /api/mobile/login { email, motpasse }
   ← { message, email }

2. Staff saisit le code reçu par email → POST /api/mobile/verify-2fa { email, code }
   ← { token, utilisateur }
   → token stocké localement sur l'appareil

3. Staff consulte les RDV du jour → GET /api/mobile/rdv
   Header: Authorization: Bearer {token}
   ← liste des réservations

4. Staff scanne le QR code d'un client → lit l'idreservation
   → POST /api/mobile/valider-presence { idreservation }
   Header: Authorization: Bearer {token}
   ← { message: "Présence validée." }
   → badge "Présence validée" apparaît dans l'interface web du client
```

---

## Désactiver la 2FA (développement / tests)

```env
AUTH_2FA_ENABLED=false
```

Avec ce réglage, `POST /api/mobile/login` retourne directement le token sans passer par l'étape email. Voir [authentification.md](authentification.md) pour les détails.
