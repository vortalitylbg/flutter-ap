<?php

namespace Tests\Feature;

use App\Models\Utilisateur;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Tests\TestCase;

class MotDePasseOublieTest extends TestCase
{
    use RefreshDatabase;

    private function creerUtilisateur(array $attributs = []): Utilisateur
    {
        return Utilisateur::factory()->create(array_merge([
            'idrole'   => 1,
            'email'    => 'user@test.com',
            'motpasse' => 'password123',
        ], $attributs));
    }

    // -------------------------------------------------------------------------
    // GET /mot-de-passe-oublie
    // -------------------------------------------------------------------------

    public function test_page_mot_de_passe_oublie_accessible(): void
    {
        $this->get(route('connexion.motdepasseoublie'))->assertStatus(200);
    }

    // -------------------------------------------------------------------------
    // POST /mot-de-passe-oublie
    // -------------------------------------------------------------------------

    public function test_envoi_email_reset_pour_email_connu(): void
    {
        Mail::fake();
        $this->creerUtilisateur();

        $this->post(route('connexion.motdepasseoublie.envoyer'), ['email' => 'user@test.com'])
             ->assertSessionHas('statut');

        $utilisateur = Utilisateur::where('email', 'user@test.com')->first();
        $this->assertNotNull($utilisateur->reset_token);
        $this->assertNotNull($utilisateur->reset_token_expires_at);
    }

    public function test_email_inconnu_affiche_meme_message_de_statut(): void
    {
        // Même réponse que pour un email connu (sécurité : pas de divulgation)
        $this->post(route('connexion.motdepasseoublie.envoyer'), ['email' => 'inconnu@test.com'])
             ->assertSessionHas('statut');
    }

    public function test_champ_email_manquant_retourne_erreur_validation(): void
    {
        $this->post(route('connexion.motdepasseoublie.envoyer'), [])
             ->assertSessionHasErrors('email');
    }

    public function test_email_invalide_retourne_erreur_validation(): void
    {
        $this->post(route('connexion.motdepasseoublie.envoyer'), ['email' => 'pas-un-email'])
             ->assertSessionHasErrors('email');
    }

    // -------------------------------------------------------------------------
    // GET /reset-mot-de-passe/{token}
    // -------------------------------------------------------------------------

    public function test_page_reset_accessible_avec_token_valide(): void
    {
        $utilisateur = $this->creerUtilisateur();
        $token = Str::random(64);
        $utilisateur->update([
            'reset_token'            => $token,
            'reset_token_expires_at' => now()->addMinutes(30),
        ]);

        $this->get(route('connexion.reset', $token))->assertStatus(200);
    }

    public function test_page_reset_redirige_avec_token_inconnu(): void
    {
        $this->get(route('connexion.reset', 'token-inexistant'))
             ->assertRedirect(route('connexion.motdepasseoublie'))
             ->assertSessionHasErrors('email');
    }

    public function test_page_reset_redirige_avec_token_expire(): void
    {
        $utilisateur = $this->creerUtilisateur();
        $token = Str::random(64);
        $utilisateur->update([
            'reset_token'            => $token,
            'reset_token_expires_at' => now()->subMinute(),
        ]);

        $this->get(route('connexion.reset', $token))
             ->assertRedirect(route('connexion.motdepasseoublie'))
             ->assertSessionHasErrors('email');
    }

    // -------------------------------------------------------------------------
    // POST /reset-mot-de-passe/{token}
    // -------------------------------------------------------------------------

    public function test_reset_mot_de_passe_valide_met_a_jour_et_redirige(): void
    {
        $utilisateur = $this->creerUtilisateur();
        $token = Str::random(64);
        $utilisateur->update([
            'reset_token'            => $token,
            'reset_token_expires_at' => now()->addMinutes(30),
        ]);

        $this->post(route('connexion.reset.enregistrer', $token), [
            'motpasse'              => 'nouveau_pass_123',
            'motpasse_confirmation' => 'nouveau_pass_123',
        ])->assertRedirect(route('connexion'))
          ->assertSessionHas('statut');

        // Le token doit être invalidé
        $utilisateur->refresh();
        $this->assertNull($utilisateur->reset_token);
        $this->assertNull($utilisateur->reset_token_expires_at);

        // Le nouveau mot de passe est bien enregistré.
        // Il est stocké **en clair** (voir ConnexionController::enregistrerReset),
        // on compare donc directement la chaîne. TODO étudiant : quand le hachage
        // bcrypt sera en place, réimporter la façade Hash et remplacer cette
        // assertion par Hash::check('nouveau_pass_123', $utilisateur->motpasse).
        $this->assertSame('nouveau_pass_123', $utilisateur->motpasse);
    }

    public function test_reset_avec_token_expire_redirige_avec_erreur(): void
    {
        $utilisateur = $this->creerUtilisateur();
        $token = Str::random(64);
        $utilisateur->update([
            'reset_token'            => $token,
            'reset_token_expires_at' => now()->subMinute(),
        ]);

        $this->post(route('connexion.reset.enregistrer', $token), [
            'motpasse'              => 'nouveau_pass_123',
            'motpasse_confirmation' => 'nouveau_pass_123',
        ])->assertRedirect(route('connexion.motdepasseoublie'))
          ->assertSessionHasErrors('email');
    }

    public function test_reset_avec_token_inconnu_redirige_avec_erreur(): void
    {
        $this->post(route('connexion.reset.enregistrer', 'token-inconnu'), [
            'motpasse'              => 'nouveau_pass_123',
            'motpasse_confirmation' => 'nouveau_pass_123',
        ])->assertRedirect(route('connexion.motdepasseoublie'));
    }

    public function test_reset_mots_de_passe_differents_retourne_erreur(): void
    {
        $utilisateur = $this->creerUtilisateur();
        $token = Str::random(64);
        $utilisateur->update([
            'reset_token'            => $token,
            'reset_token_expires_at' => now()->addMinutes(30),
        ]);

        $this->post(route('connexion.reset.enregistrer', $token), [
            'motpasse'              => 'nouveau_pass_123',
            'motpasse_confirmation' => 'different',
        ])->assertSessionHasErrors('motpasse');
    }

    public function test_reset_mot_de_passe_trop_court_retourne_erreur(): void
    {
        $utilisateur = $this->creerUtilisateur();
        $token = Str::random(64);
        $utilisateur->update([
            'reset_token'            => $token,
            'reset_token_expires_at' => now()->addMinutes(30),
        ]);

        $this->post(route('connexion.reset.enregistrer', $token), [
            'motpasse'              => 'court',
            'motpasse_confirmation' => 'court',
        ])->assertSessionHasErrors('motpasse');
    }
}
