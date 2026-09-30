<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reservation;
use App\Models\Utilisateur;
use App\Utils\EmailHelpers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class MobileController extends Controller
{
    /**
     * Étape 1 – Vérifie les identifiants du staff et envoie un code 2FA par email.
     * Seuls les utilisateurs avec le rôle staff (idrole = 2) sont autorisés.
     * Le token Sanctum n'est pas encore émis à cette étape.
     * @return JsonResponse
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email'    => 'required|email',
            'motpasse' => 'required|string',
        ], [
            'email.required'    => 'L\'adresse email est obligatoire.',
            'email.email'       => 'L\'adresse email n\'est pas valide.',
            'motpasse.required' => 'Le mot de passe est obligatoire.',
        ]);

        $utilisateur = Utilisateur::where('email', $request->email)
            ->where('idrole', 2)
            ->first();

        // TODO: Remplacer la comparaison directe par password_verify() pour comparer
        //   le mot de passe saisi avec le hash bcrypt stocké en base :
        //   if (!$utilisateur || !password_verify($request->motpasse, $utilisateur->motpasse))
        if (!$utilisateur || $request->motpasse !== $utilisateur->motpasse) {
            // response()->json($data, $code) retourne une réponse JSON avec le code HTTP indiqué
            return response()->json([
                'message' => 'Identifiants invalides ou accès non autorisé.',
            ], 401);
        }

        // config() lit une valeur depuis les fichiers de configuration (config/auth.php),
        // qui elle-même est issue du fichier .env via env()
        if (!config('auth.2fa_enabled')) {
            // ->tokens()->delete() révoque tous les tokens Sanctum existants de cet utilisateur
            $utilisateur->tokens()->delete();
            // createToken() crée un nouveau token Sanctum ; plainTextToken retourne sa valeur en clair
            $token = $utilisateur->createToken('mobile')->plainTextToken;

            return response()->json([
                'token'       => $token,
                'utilisateur' => [
                    'idutilisateur' => $utilisateur->idutilisateur,
                    'nom'           => $utilisateur->nom,
                    'prenom'        => $utilisateur->prenom,
                    'email'         => $utilisateur->email,
                ],
            ]);
        }

        // Génération d'un code 2FA numérique à 6 chiffres, valable 10 minutes
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // now() retourne la date/heure actuelle ; addMinutes(10) ajoute 10 minutes
        $utilisateur->update([
            'two_factor_code'       => $code,
            'two_factor_expires_at' => now()->addMinutes(10),
        ]);

        EmailHelpers::sendEmail(
            $utilisateur->email,
            'Votre code de connexion ResaChev',
            'emails.code2fa',
            ['prenom' => $utilisateur->prenom, 'code' => $code]
        );

        return response()->json([
            'message' => 'Un code de vérification a été envoyé par email.',
            'email'   => $utilisateur->email,
        ]);
    }

    /**
     * Étape 2 – Vérifie le code 2FA et retourne le token Sanctum si valide.
     * @return JsonResponse
     */
    public function verify2FA(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'code'  => 'required|string|size:6',
        ], [
            'email.required' => 'L\'adresse email est obligatoire.',
            'email.email'    => 'L\'adresse email n\'est pas valide.',
            'code.required'  => 'Le code de vérification est obligatoire.',
            'code.size'      => 'Le code doit contenir exactement 6 caractères.',
        ]);

        $utilisateur = Utilisateur::where('email', $request->email)
            ->where('idrole', 2)
            ->first();

        if (!$utilisateur || !$utilisateur->verifierCode2FA($request->code)) {
            return response()->json([
                'message' => 'Code invalide ou expiré.',
            ], 401);
        }

        // Invalidation du code après utilisation
        $utilisateur->update([
            'two_factor_code'       => null,
            'two_factor_expires_at' => null,
        ]);

        // Révocation des anciens tokens avant d'en créer un nouveau
        $utilisateur->tokens()->delete();

        $token = $utilisateur->createToken('mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'utilisateur' => [
                'idutilisateur' => $utilisateur->idutilisateur,
                'nom'           => $utilisateur->nom,
                'prenom'        => $utilisateur->prenom,
                'email'         => $utilisateur->email,
            ],
        ]);
    }

    /**
     * Retourne la liste des prochains rendez-vous à partir d'aujourd'hui,
     * triés par date et heure croissantes.
     * @return JsonResponse
     */
    public function prochainRdv(): JsonResponse
    {
        // ->with([...]) charge les relations en même temps (évite N requêtes supplémentaires)
        // now()->toDateString() retourne la date du jour au format Y-m-d
        // ->orderBy() trie les résultats par colonne croissante (équivalent SQL ORDER BY)
        // ->get() exécute la requête et retourne une Collection
        // ->map() transforme chaque élément de la Collection en un tableau personnalisé
        $reservations = Reservation::with(['utilisateur', 'prestation'])
            ->where('datedebut', '>=', now()->toDateString())
            ->orderBy('datedebut')
            ->orderBy('heuredebut')
            ->get()
            ->map(fn($r) => [
                'idreservation'      => $r->idreservation,
                'datedebut'          => $r->datedebut->format('d/m/Y'),
                'heuredebut'         => $r->heuredebut->format('H:i'),
                'validationpresence' => $r->validationpresence,
                'prestation'         => $r->prestation->libelleprestation,
                'client'             => [
                    'nom'    => $r->utilisateur->nom,
                    'prenom' => $r->utilisateur->prenom,
                ],
            ]);

        return response()->json($reservations);
    }

    /**
     * Valide la présence d'un client à partir de l'identifiant de réservation
     * transmis via le QR code scanné.
     * @return JsonResponse
     */
    public function validerPresence(Request $request): JsonResponse
    {
        // La règle 'exists:reservation,idreservation' vérifie que la valeur existe bien en base
        $request->validate([
            'idreservation' => 'required|integer|exists:reservation,idreservation',
        ], [
            'idreservation.required' => 'L\'identifiant de réservation est obligatoire.',
            'idreservation.integer'  => 'L\'identifiant de réservation doit être un entier.',
            'idreservation.exists'   => 'Cette réservation n\'existe pas.',
        ]);

        // findOrFail() cherche la réservation par sa clé primaire et retourne une erreur 404 si absente
        $reservation = Reservation::findOrFail($request->idreservation);

        if ($reservation->validationpresence) {
            // 409 Conflict : la ressource existe mais son état empêche l'opération
            return response()->json([
                'message' => 'Présence déjà validée.',
            ], 409);
        }

        $reservation->update(['validationpresence' => true]);

        return response()->json([
            'message'       => 'Présence validée.',
            'idreservation' => $reservation->idreservation,
        ]);
    }

    /**
     * Retourne les informations de la personne (le client) associée à une réservation,
     * à partir de l'identifiant de réservation lu dans le QR code.
     * @param int $idreservation Identifiant de la réservation
     * @return JsonResponse
     */
    public function clientParReservation(int $idreservation): JsonResponse
    {
        // with() charge la relation utilisateur en même temps que la réservation (une seule requête)
        // find() retourne null si aucune réservation ne porte cet identifiant
        $reservation = Reservation::with(['utilisateur', 'prestation'])->find($idreservation);

        if (!$reservation) {
            // 404 Not Found : l'identifiant transmis ne correspond à aucune réservation
            return response()->json([
                'message' => 'Cette réservation n\'existe pas.',
            ], 404);
        }

        return response()->json([
            'idreservation'      => $reservation->idreservation,
            'datedebut'          => $reservation->datedebut->format('d/m/Y'),
            'heuredebut'         => $reservation->heuredebut->format('H:i'),
            'validationpresence' => $reservation->validationpresence,
            'prestation'         => $reservation->prestation->libelleprestation,
            'client'             => [
                'idutilisateur' => $reservation->utilisateur->idutilisateur,
                'nom'           => $reservation->utilisateur->nom,
                'prenom'        => $reservation->utilisateur->prenom,
                'email'         => $reservation->utilisateur->email,
            ],
        ]);
    }

    /**
     * Retourne les informations du staff connecté (identifié par son token Sanctum).
     * Ni motpasse ni les colonnes two_factor_* ne sont exposés.
     * @return JsonResponse
     */
    public function getMe(Request $request): JsonResponse
    {
        // $request->user() retourne l'utilisateur associé au token Sanctum envoyé dans la requête
        $utilisateur = $request->user();

        return response()->json([
            'idutilisateur' => $utilisateur->idutilisateur,
            'idrole'        => $utilisateur->idrole,
            'nom'           => $utilisateur->nom,
            'prenom'        => $utilisateur->prenom,
            'email'         => $utilisateur->email,
        ]);
    }

    /**
     * Met à jour les informations personnelles du staff connecté (US 1.4).
     *
     * Les champs modifiables sont le nom, le prénom et l'adresse email.
     * Ni motpasse ni idrole ne sont exposés : le rôle du staff ne doit jamais
     * être modifiable depuis l'application mobile.
     *
     * Règles de validation :
     *  - nom et prénom : obligatoires, 100 caractères maximum, et sans chiffre
     *    (règle métier US 1.4.3). Aucune autre restriction n'est appliquée, afin
     *    d'accepter les lettres accentuées, les apostrophes et les traits
     *    d'union propres aux noms français.
     *  - email : obligatoire, format valide, et unique sur la table
     *    utilisateur (en excluant la ligne de l'utilisateur connecté).
     *
     * @return JsonResponse
     */
    public function updateMe(Request $request): JsonResponse
    {
        $utilisateur = $request->user();

        // Règle commune au nom et au prénom (règle métier US 1.4.3).
        $regleNom = ['required', 'string', 'max:100', 'not_regex:/[0-9]/'];

        $request->validate([
            'nom'    => $regleNom,
            'prenom' => $regleNom,
            'email'  => [
                'required',
                'string',
                'email',
                'max:128',
                // unique:table,colonne,id à ignorer,colonne de la clé primaire
                'unique:utilisateur,email,' . $utilisateur->idutilisateur . ',idutilisateur',
            ],
        ], [
            'nom.required'     => 'Le nom est obligatoire.',
            'nom.max'          => 'Le nom ne peut pas dépasser 100 caractères.',
            'nom.not_regex'    => 'Le nom ne doit pas contenir de chiffre.',
            'prenom.required'  => 'Le prénom est obligatoire.',
            'prenom.max'       => 'Le prénom ne peut pas dépasser 100 caractères.',
            'prenom.not_regex' => 'Le prénom ne doit pas contenir de chiffre.',
            'email.required'   => 'L\'adresse email est obligatoire.',
            'email.email'      => 'L\'adresse email n\'est pas valide.',
            'email.max'        => 'L\'adresse email ne peut pas dépasser 128 caractères.',
            'email.unique'     => 'Cette adresse email est déjà utilisée par un autre compte.',
        ]);

        $utilisateur->update([
            'nom'    => $request->nom,
            'prenom' => $request->prenom,
            'email'  => $request->email,
        ]);

        return response()->json([
            'message'     => 'Profil mis à jour.',
            'utilisateur' => [
                'idutilisateur' => $utilisateur->idutilisateur,
                'idrole'        => $utilisateur->idrole,
                'nom'           => $utilisateur->nom,
                'prenom'        => $utilisateur->prenom,
                'email'         => $utilisateur->email,
            ],
        ]);
    }
}
