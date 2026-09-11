<?php

namespace App\Http\Controllers;

use App\Models\Utilisateur;
use App\Utils\EmailHelpers;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class ConnexionController extends Controller
{
    /**
     * Affiche le formulaire de connexion.
     * Redirige vers le tableau de bord si l'utilisateur est déjà connecté.
     */
    public function index()
    {
        // Auth::check() retourne true si un utilisateur est connecté (session active)
        if (Auth::check()) {
            // redirect()->route('nom') redirige vers la route nommée correspondante
            return redirect()->route('espace.dashboard');
        }

        // view('chemin') charge la vue Blade resources/views/connexion/index.blade.php
        return view('connexion.index');
    }

    /**
     * Traite la soumission du formulaire de connexion (email / mot de passe).
     * Si les identifiants sont valides, génère un code 2FA et redirige vers la vérification.
     */
    public function login(Request $request)
    {
        // validate() vérifie les données du formulaire selon les règles définies.
        // En cas d'échec, Laravel redirige automatiquement vers le formulaire avec les erreurs.
        $request->validate([
            'email'    => 'required|email',
            'motpasse' => 'required|string',
        ], [
            'email.required' => 'L\'adresse email est obligatoire.',
            'email.email'    => 'L\'adresse email n\'est pas valide.',
            'motpasse.required' => 'Le mot de passe est obligatoire.',
        ]);

        // ->first() retourne le premier résultat de la requête, ou null si aucun résultat
        $utilisateur = Utilisateur::where('email', $request->email)->first();

        // TODO: Remplacer la comparaison directe par password_verify() pour comparer
        //   le mot de passe saisi avec le hash bcrypt stocké en base :
        //   if (!$utilisateur || !password_verify($request->motpasse, $utilisateur->motpasse))
        if (!$utilisateur || $request->motpasse !== $utilisateur->motpasse) {
            // back() redirige vers la page précédente (le formulaire)
            // withInput() conserve les valeurs saisies pour les réafficher
            // withErrors() transmet les messages d'erreur à la vue
            return back()
                ->withInput($request->only('email'))
                ->withErrors(['email' => 'Identifiants incorrects.']);
        }

        // config() lit une valeur depuis les fichiers de configuration (config/auth.php),
        // qui elle-même est issue du fichier .env via env()
        if (!config('auth.2fa_enabled')) {
            // Auth::login() ouvre la session pour l'utilisateur (le connecte)
            Auth::login($utilisateur);
            // regenerate() génère un nouvel ID de session (protection contre la fixation de session)
            $request->session()->regenerate();
            return redirect()->route('espace.dashboard');
        }

        // Génération d'un code 2FA à 6 chiffres, valable 10 minutes
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // ->update() envoie un UPDATE SQL pour les colonnes spécifiées
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

        // session()->put() stocke une valeur en session, accessible sur les requêtes suivantes
        $request->session()->put('2fa_email', $utilisateur->email);

        return redirect()->route('connexion.verification');
    }

    /**
     * Affiche le formulaire de vérification du code 2FA.
     * Redirige vers la connexion si aucune session 2FA n'est en cours.
     */
    public function showVerification(Request $request)
    {
        // session()->has() vérifie si une clé est présente en session
        if (!$request->session()->has('2fa_email')) {
            return redirect()->route('connexion');
        }

        return view('connexion.verification');
    }

    /**
     * Vérifie le code 2FA saisi et ouvre la session si valide.
     */
    public function verify2FA(Request $request)
    {
        $request->validate([
            'code' => 'required|string|size:6',
        ], [
            'code.required' => 'Le code de vérification est obligatoire.',
            'code.size'     => 'Le code doit contenir exactement 6 caractères.',
        ]);

        // session()->get() lit une valeur stockée en session
        $email = $request->session()->get('2fa_email');

        if (!$email) {
            return redirect()->route('connexion');
        }

        $utilisateur = Utilisateur::where('email', $email)->first();

        if (!$utilisateur || !$utilisateur->verifierCode2FA($request->code)) {
            return back()->withErrors(['code' => 'Code invalide ou expiré.']);
        }

        // Invalidation du code après usage
        $utilisateur->update([
            'two_factor_code'       => null,
            'two_factor_expires_at' => null,
        ]);

        // session()->forget() supprime une clé de la session
        $request->session()->forget('2fa_email');

        Auth::login($utilisateur);

        $request->session()->regenerate();

        return redirect()->route('espace.dashboard');
    }

    /**
     * Déconnecte l'utilisateur et invalide la session.
     */
    public function logout(Request $request)
    {
        // Auth::logout() ferme la session de l'utilisateur connecté
        Auth::logout();

        // invalidate() détruit complètement la session côté serveur
        $request->session()->invalidate();
        // regenerateToken() génère un nouveau token CSRF pour la prochaine requête
        $request->session()->regenerateToken();

        return redirect()->route('home');
    }

    /**
     * Affiche le formulaire de mot de passe oublié.
     */
    public function showMotDePasseOublie()
    {
        return view('connexion.mot-de-passe-oublie');
    }

    /**
     * Traite la demande de réinitialisation : génère un token et envoie le lien par email.
     * Toujours afficher le même message de succès, même si l'email est inconnu (sécurité).
     */
    public function envoyerMotDePasseOublie(Request $request)
    {
        $request->validate(['email' => 'required|email'], [
            'email.required' => 'L\'adresse email est obligatoire.',
            'email.email'    => 'L\'adresse email n\'est pas valide.',
        ]);

        $utilisateur = Utilisateur::where('email', $request->email)->first();

        if ($utilisateur) {
            // Str::random(64) génère une chaîne aléatoire de 64 caractères
            $token = Str::random(64);

            $utilisateur->update([
                'reset_token'            => $token,
                'reset_token_expires_at' => now()->addMinutes(30),
            ]);

            EmailHelpers::sendEmail(
                $utilisateur->email,
                'Réinitialisation de votre mot de passe ResaChev',
                'emails.reset-mot-de-passe',
                [
                    'prenom' => $utilisateur->prenom,
                    // route() génère l'URL complète d'une route nommée, avec paramètre
                    'lien'   => route('connexion.reset', $token),
                ]
            );
        }

        // ->with('cle', 'valeur') transmet un message flash (visible une seule fois, sur la requête suivante)
        return back()->with('statut', 'Si cette adresse est associée à un compte, un email vous a été envoyé.');
    }

    /**
     * Affiche le formulaire de saisie du nouveau mot de passe.
     * Vérifie que le token existe et n'est pas expiré.
     */
    public function showResetMotDePasse(string $token)
    {
        $utilisateur = Utilisateur::where('reset_token', $token)
            ->where('reset_token_expires_at', '>', now())
            ->first();

        if (!$utilisateur) {
            return redirect()->route('connexion.motdepasseoublie')
                ->withErrors(['email' => 'Ce lien est invalide ou a expiré.']);
        }

        return view('connexion.reset-mot-de-passe', [
            'token' => $token,
        ]);
    }

    /**
     * Enregistre le nouveau mot de passe et invalide le token.
     */
    public function resetMotDePasse(Request $request, string $token)
    {
        // La règle 'confirmed' vérifie que le champ motpasse_confirmation est identique à motpasse
        $request->validate([
            'motpasse'              => 'required|string|min:8|confirmed',
            'motpasse_confirmation' => 'required|string',
        ], [
            'motpasse.required'  => 'Le mot de passe est obligatoire.',
            'motpasse.min'       => 'Le mot de passe doit contenir au moins 8 caractères.',
            'motpasse.confirmed' => 'La confirmation du mot de passe ne correspond pas.',
            'motpasse_confirmation.required' => 'La confirmation du mot de passe est obligatoire.',
        ]);

        $utilisateur = Utilisateur::where('reset_token', $token)
            ->where('reset_token_expires_at', '>', now())
            ->first();

        if (!$utilisateur) {
            return redirect()->route('connexion.motdepasseoublie')
                ->withErrors(['email' => 'Ce lien est invalide ou a expiré.']);
        }

        $utilisateur->update([
            'motpasse'               => $request->motpasse,
            'reset_token'            => null,
            'reset_token_expires_at' => null,
        ]);

        return redirect()->route('connexion')
            ->with('statut', 'Mot de passe mis à jour. Vous pouvez vous connecter.');
    }
}
