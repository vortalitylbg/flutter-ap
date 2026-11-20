<?php

namespace App\Http\Controllers;

use App\Models\Parametrage;
use App\Models\Reservation;
use App\Models\Evaluation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EspaceController extends Controller
{
    /**
     * Affiche le tableau de bord avec la prochaine réservation.
     * La grille de créneaux est chargée côté client via /espace/creneaux.
     */
    public function dashboard()
    {
        // Auth::user() retourne l'objet Utilisateur actuellement connecté
        $utilisateur = Auth::user();

        // ->with('prestation') charge la relation en même temps (un seul aller-retour en base)
        // ->first() retourne le premier résultat, ou null si aucune réservation à venir
        $prochaineReservation = $utilisateur->prochaineReservation()->with('prestation')->first();
        $reservationsAEvaluer = $utilisateur->reservationsEvalables()->get();

        return view('espace.dashboard', [
            'utilisateur'          => $utilisateur,
            'prochaineReservation' => $prochaineReservation,
            'pointsFidelite'       => $utilisateur->pointsFidelite(),
            'niveauFidelite'       => $utilisateur->niveauFidelite(),
            'reservationsAEvaluer' => $reservationsAEvaluer,
        ]);
    }

    /**
     * API interne — Retourne les créneaux sur 7 jours au format JSON.
     *
     * Appelée par le tableau de bord Vue.js via fetch().
     * Protégée par le middleware `auth` (session web) — aucun token requis.
     *
     * Paramètre GET optionnel :
     *   ?debut=Y-m-d  Date de départ de la plage (J-1 par défaut = hier).
     *                 Affiche 7 jours consécutifs à partir de cette date.
     *
     * Réponse JSON :
     * {
     *   "debut":   "2026-07-01",
     *   "semaine": "01 juillet – 07 juillet 2026",
     *   "jours": [
     *     {
     *       "date":  "2026-07-01",
     *       "label": "Mer. 01/07",
     *       "slots": [
     *         {
     *           "heure":      "08:00",
     *           "statut":     "libre" | "occupe" | "ma_reservation" | "valide",
     *           "prestation": null | "Nom de la prestation"
     *         },
     *         ...
     *       ]
     *     },
     *     ...  (7 jours)
     *   ]
     * }
     *
     * Valeurs du champ `statut` :
     *   - libre          : aucune réservation sur ce créneau
     *   - occupe         : réservé par un autre client (nom non divulgué)
     *   - ma_reservation : réservé par l'utilisateur connecté, présence non encore validée
     *   - valide         : réservé par l'utilisateur connecté, présence validée par le staff
     */
    public function creneaux(Request $request): JsonResponse
    {
        $utilisateur = Auth::user();

        // --- 1. Détermination de la plage à afficher ---
        // Par défaut on part d'hier (J-1) pour afficher J-1 → J+6.
        // Le paramètre ?debut=Y-m-d permet à Vue.js de naviguer d'une plage à l'autre.
        // $request->filled('debut') retourne true si le paramètre est présent ET non vide
        $debut = new \DateTime($request->filled('debut') ? $request->debut : 'yesterday');
        $fin   = (clone $debut)->modify('+6 days'); // J-1 + 6 = J+5 (7 jours au total)

        // --- 2. Paramètres des créneaux lus en base de données ---
        // Ces valeurs sont stockées dans la table `parametrage` (colonnes libelleparam / valeurparam / uniteparam).
        // Elles sont récupérées via le modèle Parametrage (SELECT WHERE libelleparam = '…').
        // Les valeurs par défaut sont utilisées si la ligne n'existe pas en base.
        //   dureeCreneau   : durée d'un créneau, avec son unité (ex. valeur=30, unité=minutes)
        //   heureOuverture : première heure de la journée           (défaut : "08:00")
        //   heureFermeture : fin des créneaux — borne exclusive      (défaut : "18:00")
        $paramCreneau   = Parametrage::where('libelleparam', 'dureeCreneau')->first();
        $dureeCreneau   = (int) ($paramCreneau->valeurparam ?? 30);
        $uniteCreneau   = $paramCreneau->uniteparam ?? 'minutes'; // ex. "minutes", "hours"

        $heureOuverture = Parametrage::getValeur('heureOuverture') ?? '08:00';
        $heureFermeture = Parametrage::getValeur('heureFermeture') ?? '18:00';

        // --- 3. Génération de la liste des heures de la journée ---
        // On part de l'heure d'ouverture et on avance de dureeCreneau minutes à chaque tour
        // jusqu'à atteindre l'heure de fermeture.
        // Exemple : ouverture 08:00, fermeture 18:00, durée 30 min
        //   → ["08:00", "08:30", "09:00", …, "17:30"]
        $heureCourante = \DateTime::createFromFormat('H:i', $heureOuverture);
        $heureFin      = \DateTime::createFromFormat('H:i', $heureFermeture);

        $heures = [];
        while ($heureCourante < $heureFin) {
            // On enregistre l'heure courante au format "H:i" (ex. "09:30")
            $heures[] = $heureCourante->format('H:i');

            // On avance au prochain créneau (valeur et unité lues depuis parametrage)
            $heureCourante->modify("+{$dureeCreneau} {$uniteCreneau}");
        }

        $dateDebut = $debut->format('Y-m-d');
        $dateFin   = $fin->format('Y-m-d');

        // --- 4. Réservations de l'utilisateur connecté sur la plage ---
        // On récupère toutes ses réservations entre le lundi et le dimanche,
        // en chargeant la prestation associée (jointure automatique via la relation).
        // ->whereBetween('col', [$min, $max]) filtre les lignes où col est entre $min et $max (SQL BETWEEN)
        // ->get() exécute la requête et retourne toutes les lignes sous forme de Collection
        $mesReservations = $utilisateur->reservations()
            ->with('prestation')
            ->whereBetween('datedebut', [$dateDebut, $dateFin])
            ->get();

        // On construit un tableau associatif [ "2026-07-07_09:00" => $reservation ]
        // pour pouvoir retrouver rapidement une réservation à partir d'une date et d'une heure.
        $mesReservationsParCle = [];
        foreach ($mesReservations as $reservation) {
            $cle = $reservation->datedebut->format('Y-m-d') . '_' . $reservation->heuredebut->format('H:i');
            $mesReservationsParCle[$cle] = $reservation;
        }

        // --- 5. Créneaux occupés par n'importe quel client sur la plage ---
        // On récupère uniquement les colonnes de date/heure, sans données personnelles des autres clients.
        // ->get(['col1', 'col2']) limite les colonnes retournées (équivalent de SELECT col1, col2)
        $toutesLesReservations = Reservation::whereBetween('datedebut', [$dateDebut, $dateFin])
            ->get(['datedebut', 'heuredebut']);

        // On construit un tableau des clés occupées [ "2026-07-07_09:00" => true, … ]
        $creneauxOccupes = [];
        foreach ($toutesLesReservations as $reservation) {
            $cle = $reservation->datedebut->format('Y-m-d') . '_' . $reservation->heuredebut->format('H:i');
            $creneauxOccupes[$cle] = true;
        }

        // --- 6. Construction de la réponse jour par jour, créneau par créneau ---
        // Pour chaque créneau, on détermine le statut par priorité :
        //   a) L'utilisateur connecté a une réservation sur ce créneau → ma_reservation ou valide
        //   b) Un autre utilisateur a une réservation                  → occupe
        //   c) Aucune réservation                                      → libre
        $joursFr = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
        $moisFr  = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin',
                    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

        // On parcourt les 7 jours de la plage. Pour chaque jour, on parcourt toutes
        // les heures calculées à l'étape 3, et on produit un "slot" par heure.
        // Le tableau final $jours est directement consommé par Vue.js.
        $jours = [];
        for ($i = 0; $i < 7; $i++) {
            // clone est indispensable : ->modify() modifie l'objet DateTime sur place.
            // Sans clone, $debut serait décalé à chaque tour de boucle.
            $jour = (clone $debut)->modify("+{$i} days");

            // Format machine ("2026-07-01"), utilisé comme clé et renvoyé dans le JSON.
            $dateStr = $jour->format('Y-m-d');

            // Format lisible ("Mer. 01/07") affiché en en-tête de colonne.
            // format('N') retourne le jour de la semaine en chiffre ISO : 1 = lundi … 7 = dimanche.
            // On soustrait 1 car $joursFr est indexé à partir de 0.
            $labelJour = $joursFr[(int) $jour->format('N') - 1] . ' ' . $jour->format('d/m');

            $slots = [];
            foreach ($heures as $heure) {
                // Clé de recherche identique à celle construite aux étapes 4 et 5,
                // par exemple "2026-07-01_09:00".
                $cle = $dateStr . '_' . $heure;

                // ?? null : si la clé n'existe pas dans le tableau, on obtient null
                // au lieu d'une erreur "undefined array key".
                $maReservation = $mesReservationsParCle[$cle] ?? null;

                // Les trois cas sont testés dans l'ordre de priorité décrit plus haut.
                if ($maReservation) {
                    // Cas a) réservation de l'utilisateur connecté.
                    // validationpresence est casté en booléen par le modèle Reservation :
                    // true si le staff a déjà scanné le QR code, false sinon.
                    $statut = $maReservation->validationpresence ? 'valide' : 'ma_reservation';

                    // La prestation a été préchargée par ->with('prestation') à l'étape 4,
                    // cet accès ne déclenche donc pas de requête supplémentaire.
                    $prestation = $maReservation->prestation->libelleprestation;
                } elseif (isset($creneauxOccupes[$cle])) {
                    // Cas b) créneau pris par un autre client.
                    // On ne divulgue ni son nom ni sa prestation : le front affiche
                    // simplement la case comme indisponible.
                    $statut     = 'occupe';
                    $prestation = null;
                } else {
                    // Cas c) aucune réservation : le créneau est réservable.
                    $statut     = 'libre';
                    $prestation = null;
                }

                $slots[] = [
                    'heure'      => $heure,
                    'statut'     => $statut,
                    'prestation' => $prestation,
                ];
            }

            // Une entrée par jour, contenant la liste complète de ses créneaux.
            $jours[] = [
                'date'  => $dateStr,
                'label' => $labelJour,
                'slots' => $slots,
            ];
        }

        // "01 juillet 07 juillet 2026" (les deux dates sont séparées par un tiret). L'année n'apparaît qu'une fois, à la fin.
        // "01 juillet – 07 juillet 2026". L'année n'apparaît qu'une fois, à la fin.
        // format('n') retourne le mois en chiffre sans zéro initial (1 à 12),
        // d'où le -1 pour l'utiliser comme index dans $moisFr.
        $semaineLbl = $debut->format('d') . ' ' . $moisFr[(int) $debut->format('n') - 1]
            . ' – '
            . $fin->format('d') . ' ' . $moisFr[(int) $fin->format('n') - 1] . ' ' . $fin->format('Y');

        // response()->json() retourne une réponse HTTP avec le contenu encodé en JSON
        return response()->json([
            'debut'   => $debut->format('Y-m-d'),
            'semaine' => $semaineLbl,
            'jours'   => $jours,
        ]);
    }

    /**
     * Affiche le formulaire d'édition du profil.
     */
    public function profil()
    {
        $utilisateur = Auth::user();

        return view('espace.profil', [
            'utilisateur'    => $utilisateur,
            'pointsFidelite' => $utilisateur->pointsFidelite(),
            'niveauFidelite' => $utilisateur->niveauFidelite(),
        ]);
    }

    /**
     * Enregistre les modifications du profil.
     * TODO : email, mot de passe, téléphone…
     */
    public function updateProfil(Request $request)
    {
        $request->validate([
            'nom' => 'required|string|max:100',
        ], [
            'nom.required' => 'Le nom est obligatoire.',
            'nom.max'      => 'Le nom ne peut pas dépasser 100 caractères.',
        ]);

        Auth::user()->update([
            'nom' => $request->nom,
        ]);

        return redirect()->route('espace.profil')
            ->with('statut', 'Profil mis à jour.');
    }

    /**
     * Affiche le QR code de la prochaine réservation à faire scanner par le staff.
     */
    public function qrcode()
    {
        $utilisateur = Auth::user();

        $prochaineReservation = $utilisateur->prochaineReservation()->with('prestation')->first();

        return view('espace.qrcode', [
            'utilisateur'          => $utilisateur,
            'prochaineReservation' => $prochaineReservation,
        ]);
    }

    /**
     * Enregistre une évaluation pour une réservation.
     */
    public function evaluerReservation(Request $request)
    {
        $request->validate([
            'idreservation' => 'required|integer',
            'note' => 'required|integer|between:1,5',
            'commentaire' => 'nullable|string|max:1000',
        ], [
            'note.required' => 'Choisissez une note entre 1 et 5 étoiles.',
            'note.between' => 'La note doit être comprise entre 1 et 5 étoiles.',
        ]);

        $utilisateur = Auth::user();
        $reservation = $utilisateur->reservations()
            ->whereKey($request->idreservation)
            ->where('validationpresence', 1)
            ->whereDoesntHave('evaluation')
            ->first();

        if (!$reservation) {
            return back()->withErrors([
                'evaluation' => 'Cette réservation ne peut pas être évaluée.',
            ]);
        }

        Evaluation::create([
            'idreservation' => $reservation->idreservation,
            'note' => $request->note,
            'commentaire' => $request->commentaire,
            'dateevaluation' => now(),
        ]);

        $reservation->update(['evaluation_invitee_at' => now()]);

        return back()->with('statut', 'Merci pour votre évaluation !');
    }
}
