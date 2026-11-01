# Lot 3 – Liste d'attente et réservations récurrentes

Ce document présente les **deux user stories retenues** pour le Lot 3, les règles
de fonctionnement assumées par le groupe, leur implémentation dans
l'application mobile et leurs répercussions sur les trois solutions techniques
(web Laravel, mobile Flutter, gestion C#).

---

## 1. User stories retenues

Le Lot 3 propose six user stories et en demande **deux**. Le choix s'est porté
sur :

| US | Intitulé | Pourquoi |
|---|---|---|
| **3.1** | Liste d'attente sur créneau complet | Prolonge directement l'annulation (US 2.6) : une place libérée doit pouvoir être proposée. C'est le seul mécanisme du lot dont le personnel d'accueil est acteur de bout en bout. |
| **3.2** | Gestion de réservations récurrentes | Prolonge la liste par jour (US 2.1) et l'annulation (US 2.6) : il faut distinguer une occurrence d'une série, à l'affichage comme à l'annulation. |

Les autres user stories ont été écartées pour ce lot :

- **3.3 (fidélité)** et **3.6 (évaluation)** concernent d'abord l'espace client
  web et le parcours de paiement, absents de cette application ;
- **3.4 (ressources)** et **3.5 (capacités temps réel)** sont des sujets de
  back-office et de contrat d'API lourds, dont la partie visible sur le mobile
  se limite à de l'affichage.

L'application mobile est l'outil du **staff terrain** : elle ne crée pas de
réservation, elle consulte, accueille, valide les présences et annule. Les deux
US retenues sont donc implémentées côté employé, l'inscription initiale du
client restant possible sur le web (et à l'accueil via le mobile).

---

## 2. US 3.1 – Liste d'attente sur créneau complet

### 2.1 Définitions

- **Créneau complet** : le nombre de places occupées a atteint la capacité du
  créneau (`places restantes = 0`). L'API doit exposer `capacite` et, de
  préférence, `placesrestantes`.
- **Place libérée** : une réservation du créneau est annulée (par le client sur
  le web, par l'employé sur le mobile, ou par un administrateur en C#).
- **Entrée de liste d'attente** : un client inscrit sur un créneau complet, avec
  une date d'inscription et un statut.

### 2.2 Règles retenues

| # | Règle | Justification |
|---|---|---|
| R1 | L'inscription n'est possible que sur un créneau **complet**. Sinon, le client réserve directement. | Éviter de créer une file d'attente sur des places disponibles. |
| R2 | L'ordre de passage est **premier inscrit, premier servi** (FIFO), sans priorité de fidélité. | Règle simple, prévisible et défendable devant un client ; un système de priorité (US 3.3) pourra s'y greffer plus tard. |
| R3 | Un client ne peut être inscrit **qu'une fois** par créneau. | Éviter les doublons et les propositions multiples. |
| R4 | Dès qu'une place se libère, le serveur **propose immédiatement** la place à la première entrée, pour **30 minutes**. | La proposition ne dépend pas de l'application ouverte : elle est déclenchée par l'annulation, quel que soit le client qui l'a demandée. |
| R5 | Sans réponse dans les 30 minutes, la proposition **expire** et la place est proposée à l'entrée suivante. Après la dernière entrée, la place reste libre. | Éviter qu'une place reste bloquée par un client injoignable. |
| R6 | Le client est prévenu par **email** (infrastructure SMTP déjà utilisée pour le code 2FA). Le statut est aussi visible dans son espace web, dans la liste d'attente mobile et dans le back-office C#. | Aucun mécanisme de notification push n'existe dans le projet (pas de jeton d'appareil) ; l'email est le canal déjà disponible. |
| R7 | Une place libérée ne peut être proposée que **jusqu'au début du créneau**. Après le début, la liste d'attente est close. | Une place proposée après le début de la prestation n'a plus d'utilité. |
| R8 | La validation de présence **ne libère pas** de place. Seule une annulation le fait. | Un client présent occupe sa place. |
| R9 | Une place libérée par une annulation de série (US 3.2) suit le même mécanisme, **occurrence par occurrence**. | Chaque occurrence est un créneau distinct. |

### 2.3 Qui est prévenu, comment et dans quel ordre

1. Une annulation libère une place (mobile, web ou C#).
2. Le serveur passe la première entrée `en_attente` au statut `proposee` et fixe
   `propositionexpirele = maintenant + 30 min`.
3. Un email est envoyé à cette personne, avec le créneau et le délai.
4. Si la personne accepte, une réservation est créée pour elle et l'entrée passe
   à `convertie`. La place n'est plus libre.
5. Si le délai expire, l'entrée passe à `expiree` et l'étape 2 est rejouée pour
   l'entrée suivante.
6. Si plus personne n'attend, la place reste disponible à la réservation
   classique.

### 2.4 Implémentation mobile

| Élément | Comportement |
|---|---|
| Carte de rendez-vous | Étiquette **« Complet »** dès que les places sont épuisées, et accès **« Attente (n) »** si la liste existe. |
| Fiche du rendez-vous | Ligne **« Places »** (`2 / 8 places disponibles`) et bouton d'accès à la liste d'attente. |
| Écran « Liste d'attente » | Inscrits dans l'ordre de passage, statut et délai de proposition, bouton **« Proposer la place au suivant »**, bouton **« Inscrire un client »** (nom, prénom, email). |
| Après une annulation | La confirmation propose d'ouvrir directement la liste d'attente pour attribuer la place libérée (`placeLiberee`). |

Fichiers : [liste_attente.dart](../lib/screens/main_app/liste_attente.dart),
[entree_attente.dart](../lib/models/entree_attente.dart),
[reservation_api.dart](../lib/services/api/gestionReservation/reservation_api.dart).

### 2.5 Tests d'acceptation affinés

| Scénario | Étant donné | Lorsque | Alors |
|---|---|---|---|
| Inscription à l'accueil | un créneau est complet (`0 / 8`) | l'employé ouvre la liste d'attente et inscrit un client (nom, prénom, email) | le client apparaît en dernière position, avec le statut « En attente d'une place » |
| Inscription refusée | le créneau n'est pas complet | l'employé tente d'inscrire un client | l'inscription est refusée : le client doit réserver directement |
| Doublon | le client est déjà inscrit sur ce créneau | l'employé l'inscrit à nouveau | le serveur répond `409` et l'application affiche le message |
| Libération d'une place | Alice est première, Bob deuxième, le créneau est complet | une réservation est annulée | Alice reçoit une proposition valable 30 minutes ; Bob reste en attente |
| Proposition non honorée | Alice a une proposition en cours | 30 minutes passent sans réponse | la proposition d'Alice expire et la place est proposée à Bob |
| Plus personne n'attend | la liste est vide | une place se libère | aucune proposition n'est envoyée, la place redevient réservable |
| Créneau commencé | le créneau a débuté | une place se libère | aucune proposition n'est envoyée, la liste est close |
| Proposition manuelle | une place est libre et une personne attend | l'employé appuie sur « Proposer la place au suivant » | le serveur propose la place à la première entrée et l'écran se met à jour |

---

## 3. US 3.2 – Gestion de réservations récurrentes

### 3.1 Définitions et limites

Une **récurrence** est une série de réservations identiques (même prestation,
même heure, même jour de la semaine) qui se répète :

- **fréquence** : hebdomadaire (une occurrence par semaine) ;
- **date de début** : première occurrence ;
- **date de fin** : dernière date possible de la série ;
- **nombre maximal** : 12 occurrences par série ;
- **pas de récurrence infinie** : toute série a une date de fin ;
- **création** : depuis l'espace client web uniquement (le mobile ne crée pas de
  réservation).

### 3.2 Modélisation retenue

La série est matérialisée : **chaque occurrence est une réservation réelle**,
avec son propre `idreservation`, et porte en plus `idrecurrence`,
`numerooccurrence` et `nboccurrences`.

Ce choix est assumé :

- le QR code, la validation de présence, l'annulation et le paiement continuent
  de fonctionner **sans modification** : ils ne connaissent que des
  réservations ;
- chaque occurrence a son propre QR code, donc un client ne peut pas valider
  deux séances avec le même code ;
- l'historique du client et la liste par jour restent inchangés ;
- le prix est dû **par occurrence**, comme pour une réservation simple.

Le coût est un plus grand nombre de lignes en base, sans incidence à cette
échelle.

### 3.3 Règles retenues

| # | Règle | Justification |
|---|---|---|
| R1 | La création est **atomique** : si une seule occurrence est indisponible (créneau complet, ressource occupée, fermeture), **aucune** occurrence n'est créée et la liste des dates en conflit est renvoyée au client. | Éviter une série silencieusement incomplète, que le client découvrirait séance après séance. |
| R2 | La série se crée sur le web ; le mobile et le C# la **consultent** et peuvent l'annuler. | Le mobile est un outil de terrain, pas de réservation. |
| R3 | Une occurrence peut être **modifiée** (date, heure) seule ou avec **toutes les occurrences à venir**. Les occurrences passées ou honorées sont immuables. | Le passé ne doit pas être réécrit. |
| R4 | Une occurrence peut être annulée seule ; une annulation de série annule **toutes les occurrences à venir** et **conserve** le passé et les séances déjà honorées. | Le client qui arrête un abonnement ne doit pas voir ses séances passées disparaître. |
| R5 | Aucun remboursement n'est géré par les applications : la place est libérée, la politique de remboursement reste celle du Lot 2 (aucun remboursement automatique). | Cohérence avec les conditions d'annulation déjà retenues. |
| R6 | Le QR code et la validation de présence sont **propres à chaque occurrence**. | Un QR code ne doit valider qu'une seule séance. |
| R7 | Une place libérée sur une occurrence récurrente alimente la **liste d'attente de cette occurrence** (US 3.1). | Les deux mécanismes se composent sans règle spéciale. |

### 3.4 Implémentation mobile

| Élément | Comportement |
|---|---|
| Carte de rendez-vous | Étiquette **« Série »**. |
| Fiche du rendez-vous | Bloc « Chaque mardi · jusqu'au 15/12/2026 » et « Occurrence 3 sur 8 ». |
| Annulation | Si la réservation est récurrente, le dialogue propose **« Cette séance »** ou **« Toute la série »**, avec la conséquence expliquée. |
| Après annulation d'une série | Les occurrences à venir de la série sont retirées de la liste locale ; un message le confirme. |

Le serveur reçoit `portee: "serie"` uniquement lorsque la série entière est
annulée ; sans ce champ, il annule l'occurrence reçue, ce qui préserve le
comportement du Lot 2.

### 3.5 Tests d'acceptation affinés

| Scénario | Étant donné | Lorsque | Alors |
|---|---|---|---|
| Création d'une série | un client choisit « chaque mardi, du 3 novembre au 15 décembre » (7 occurrences) | il valide | 7 réservations sont créées, numérotées de 1 à 7, partageant le même `idrecurrence` |
| Occurrence indisponible | la 4ᵉ date est complète | le client valide la série | aucune occurrence n'est créée ; les dates en conflit sont affichées |
| Limite de série | le client choisit une date de fin trop lointaine | il valide | la création est refusée au-delà de 12 occurrences |
| Annulation d'une séance | une série de 7 occurrences | l'employé choisit « Cette séance » | seule l'occurrence est annulée ; les 6 autres sont conservées |
| Annulation de la série | une série de 7 occurrences dont 2 passées | l'employé choisit « Toute la série » | les 5 occurrences à venir sont annulées ; les 2 passées restent visibles dans l'historique |
| Séance honorée | une occurrence a sa présence validée | l'employé tente de l'annuler | l'action est refusée avec un message (règle du Lot 2) |
| QR code par occurrence | deux occurrences de la même série | l'employé scanne le QR de la première puis celui de la seconde | chaque scan valide la bonne occurrence ; un même QR ne valide pas deux séances |
| Place libérée | une occurrence complète a une liste d'attente | une place est annulée | la proposition part à la première personne en attente **de cette occurrence** |

---

## 4. Impacts sur les trois solutions techniques

### 4.1 Application web (Laravel 11 – API et espace client)

**Base de données**

- nouvelle table `liste_attente` : `idattente`, `idreservation`,
  `idutilisateur` (ou nom/prénom/email pour un client sans compte), `statut`
  (`en_attente`, `proposee`, `expiree`, `convertie`, `annulee`), `inscritle`,
  `propositionexpirele` ; contrainte d'unicité `(idreservation, idutilisateur)` ;
- nouvelles colonnes sur `reservation` : `idrecurrence`, `numerooccurrence`,
  `nboccurrences` ; table `recurrence` (`idrecurrence`, `frequence`,
  `datefin`, `idutilisateur`, `idprestation`) ;
- `capacite` sur le créneau/prestation pour calculer les places restantes.

**API mobile** (à implémenter par l'équipe web, voir § 5) : exposition de
`capacite`, `placesrestantes`, `nbattente`, des champs de récurrence, et des
routes `liste-attente`.

**Espace client** : bouton « M'inscrire sur la liste d'attente » sur un créneau
complet, affichage du rang et du délai de proposition, création et gestion des
séries, choix du périmètre lors d'une modification ou d'une annulation.

**Traitements serveur**

- notification email à la proposition, via le SMTP déjà configuré ;
- tâche planifiée (Laravel Scheduler, toutes les minutes) pour expirer les
  propositions et passer à l'entrée suivante ;
- **concurrence** : la proposition doit être faite dans une transaction avec
  verrou (`lockForUpdate`) et une mise à jour conditionnelle
  (`WHERE statut = 'en_attente'`), afin que deux annulations simultanées ne
  proposent pas la même place deux fois ;
- création de série dans une transaction : toutes les occurrences ou aucune.

### 4.2 Application mobile (Flutter – ce dépôt)

- **Implémenté** : affichage « Complet » / « Série », écran de liste d'attente,
  inscription d'un client à l'accueil, proposition manuelle au suivant,
  annulation par occurrence ou par série, rafraîchissement après action.
- **Dépend de l'API** : sans `capacite` / `placesrestantes`, aucun créneau n'est
  déclaré complet et la liste d'attente n'est pas proposée ; l'écran affiche
  alors « Non renseignées » plutôt que d'inventer une valeur.
- **Aucune donnée locale** : la file d'attente et les séries sont toujours
  relues depuis l'API, ce qui évite les incohérences entre appareils.
- **Limites connues** : pas de notification push (email uniquement), pas de
  création ni de modification de série depuis le mobile, pas de remboursement.

### 4.3 Application de gestion (C# / WinForms)

- ajout de la capacité et des places restantes dans la vue calendaire ;
- écran d'administration de la liste d'attente : consulter, retirer une
  inscription, relancer une proposition expirée ;
- annulation d'une occurrence ou d'une série, avec la même règle de périmètre ;
- affichage du rattachement à une série et du numéro d'occurrence ;
- **point d'attention** : l'application C# accède directement à MySQL ; elle doit
  appliquer les mêmes règles (statuts, unicité, dates) que l'API, sous peine de
  créer des incohérences que le mobile ne pourrait pas détecter. Une vue ou des
  procédures stockées partagées sont recommandées.

### 4.4 Points transverses

- **Cohérence des statuts** : les cinq statuts de la liste d'attente et les
  trois champs de récurrence doivent être identiques dans les trois
  applications.
- **Fuseau horaire** : toutes les dates sont stockées et comparées en heure
  locale du studio ; les délais (30 minutes, début de créneau) sont calculés
  côté serveur.
- **Concurrence** : la décision d'attribution d'une place est serveur, jamais
  locale ; le mobile ne fait qu'afficher le résultat.
- **Droits** : seul un employé connecté (rôle staff) peut lire et animer la
  liste d'attente ; les routes restent protégées par Sanctum.

---

## 5. Contrat d'API proposé

### Champs ajoutés à `GET /api/mobile/rdv` et `GET /api/mobile/reservation/{id}/client`

```json
{
  "idreservation": 42,
  "datedebut": "15/12/2026",
  "heuredebut": "09:00",
  "prestation": "Enregistrement",
  "participants": 8,
  "capacite": 8,
  "placesrestantes": 0,
  "nbattente": 2,
  "idrecurrence": 12,
  "recurrence": "Chaque mardi",
  "finrecurrence": "15/12/2026",
  "numerooccurrence": 3,
  "nboccurrences": 8
}
```

Tous ces champs sont **facultatifs** côté mobile : le modèle les accepte sous
plusieurs orthographes et retombe sur un affichage neutre s'ils manquent.

### Routes de la liste d'attente

| Méthode | Route | Corps / paramètre | Réponse |
|---|---|---|---|
| `GET` | `/api/mobile/liste-attente?idreservation=42` | — | `{ "entrees": [ … ] }` triées par ordre de passage |
| `POST` | `/api/mobile/liste-attente` | `{ "idreservation": 42, "nom": "Martin", "prenom": "Jean", "email": "jean@exemple.fr" }` | `201` + entrée créée ; `409` si doublon ou créneau non complet |
| `POST` | `/api/mobile/liste-attente/proposer` | `{ "idreservation": 42 }` | `200` + `dateexpiration` ; `409` si aucune place libre ou personne en attente |

Forme d'une entrée :

```json
{
  "idattente": 7,
  "idreservation": 42,
  "client": { "nom": "Martin", "prenom": "Jean", "email": "jean@exemple.fr" },
  "statut": "proposee",
  "inscritle": "2026-12-01T09:15:00",
  "propositionexpirele": "2026-12-01T09:45:00",
  "position": 1
}
```

### Annulation avec périmètre

| Méthode | Route | Corps | Effet |
|---|---|---|---|
| `POST` | `/api/mobile/annuler-reservation` | `{ "idreservation": 42 }` | annule l'occurrence (comportement Lot 2) |
| `POST` | `/api/mobile/annuler-reservation` | `{ "idreservation": 42, "portee": "serie" }` | annule l'occurrence et toutes les occurrences **à venir** de la série |

Codes attendus : `200` / `204` succès, `401` session expirée, `409` action
refusée (passée, honorée, aucune place libre).

---

## 6. Reste à faire

1. Implémenter les routes et les tables côté web (§ 5) : sans elles, le mobile
   fonctionne mais n'affiche ni capacité ni liste d'attente.
2. Ajouter la tâche planifiée d'expiration des propositions et l'email de
   notification.
3. Créer et modifier les séries depuis l'espace client web ; ajouter les écrans
   correspondants en C#.
4. Ajouter des tests d'intégration mobile avec une API simulée (liste d'attente,
   proposition, annulation de série).
5. Étudier une notification push (jeton d'appareil) en complément de l'email.

## 7. Vérifications effectuées sur le mobile

- `flutter analyze` : aucune erreur, 5 avertissements antérieurs au Lot 3
  (bannière inutilisée, avertissements de l'écran de connexion).
- `flutter test` : 48 tests réussis, dont les 16 du Lot 3
  ([lot3_test.dart](../test/lot3_test.dart)) ; 3 échecs antérieurs au Lot 3
  (bannière d'accueil supprimée au Lot 2, date fixe devenue passée).
