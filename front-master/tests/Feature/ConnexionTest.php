<?php

namespace Tests\Feature;

use App\Models\Utilisateur;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class ConnexionTest extends TestCase
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
    // GET /connexion
    // -------------------------------------------------------------------------

    public function test_page_connexion_accessible(): void
    {
        $this->get(route('connexion'))->assertStatus(200);
    }

    public function test_utilisateur_connecte_redirige_vers_dashboard(): void
    {
        $user = $this->creerUtilisateur();

        $this->actingAs($user)
             ->get(route('connexion'))
             ->assertRedirect(route('espace.dashboard'));
    }

    // -------------------------------------------------------------------------
    // POST /connexion
    // -------------------------------------------------------------------------

    public function test_login_identifiants_valides_redirige_vers_verification(): void
    {
        Mail::fake();
        $this->creerUtilisateur();

        $this->post(route('connexion.login'), [
            'email'    => 'user@test.com',
            'motpasse' => 'password123',
        ])->assertRedirect(route('connexion.verification'));
    }

    public function test_login_stocke_email_en_session(): void
    {
        Mail::fake();
        $this->creerUtilisateur();

        $this->post(route('connexion.login'), [
            'email'    => 'user@test.com',
            'motpasse' => 'password123',
        ])->assertSessionHas('2fa_email', 'user@test.com');
    }

    public function test_login_genere_code_2fa_en_base(): void
    {
        Mail::fake();
        $this->creerUtilisateur();

        $this->post(route('connexion.login'), [
            'email'    => 'user@test.com',
            'motpasse' => 'password123',
        ]);

        $utilisateur = Utilisateur::where('email', 'user@test.com')->first();
        $this->assertNotNull($utilisateur->two_factor_code);
        $this->assertNotNull($utilisateur->two_factor_expires_at);
    }

    public function test_login_mauvais_mot_de_passe_retourne_erreur(): void
    {
        $this->creerUtilisateur();

        $this->post(route('connexion.login'), [
            'email'    => 'user@test.com',
            'motpasse' => 'mauvais',
        ])->assertSessionHasErrors('email');
    }

    public function test_login_email_inconnu_retourne_erreur(): void
    {
        $this->post(route('connexion.login'), [
            'email'    => 'inconnu@test.com',
            'motpasse' => 'password123',
        ])->assertSessionHasErrors('email');
    }

    public function test_login_champs_manquants_retourne_erreurs_validation(): void
    {
        $this->post(route('connexion.login'), [])
             ->assertSessionHasErrors(['email', 'motpasse']);
    }

    public function test_login_conserve_email_en_cas_erreur(): void
    {
        $this->creerUtilisateur();

        $response = $this->post(route('connexion.login'), [
            'email'    => 'user@test.com',
            'motpasse' => 'mauvais',
        ]);

        $response->assertSessionHasErrors('email');
        $this->assertEquals('user@test.com', session()->getOldInput('email'));
    }

    // -------------------------------------------------------------------------
    // GET /connexion/verification
    // -------------------------------------------------------------------------

    public function test_page_verification_accessible_avec_session_2fa(): void
    {
        $this->withSession(['2fa_email' => 'user@test.com'])
             ->get(route('connexion.verification'))
             ->assertStatus(200);
    }

    public function test_page_verification_redirige_sans_session_2fa(): void
    {
        $this->get(route('connexion.verification'))
             ->assertRedirect(route('connexion'));
    }

    // -------------------------------------------------------------------------
    // POST /connexion/verification
    // -------------------------------------------------------------------------

    public function test_verify_2fa_code_valide_connecte_et_redirige(): void
    {
        $user = $this->creerUtilisateur();
        $user->update([
            'two_factor_code'       => '123456',
            'two_factor_expires_at' => now()->addMinutes(10),
        ]);

        $this->withSession(['2fa_email' => 'user@test.com'])
             ->post(route('connexion.verify2fa'), ['code' => '123456'])
             ->assertRedirect(route('espace.dashboard'));

        $this->assertAuthenticatedAs($user);
    }

    public function test_verify_2fa_invalide_le_code_apres_usage(): void
    {
        $user = $this->creerUtilisateur();
        $user->update([
            'two_factor_code'       => '123456',
            'two_factor_expires_at' => now()->addMinutes(10),
        ]);

        $this->withSession(['2fa_email' => 'user@test.com'])
             ->post(route('connexion.verify2fa'), ['code' => '123456']);

        $user->refresh();
        $this->assertNull($user->two_factor_code);
        $this->assertNull($user->two_factor_expires_at);
    }

    public function test_verify_2fa_nettoie_session_2fa_apres_connexion(): void
    {
        $user = $this->creerUtilisateur();
        $user->update([
            'two_factor_code'       => '123456',
            'two_factor_expires_at' => now()->addMinutes(10),
        ]);

        $this->withSession(['2fa_email' => 'user@test.com'])
             ->post(route('connexion.verify2fa'), ['code' => '123456'])
             ->assertSessionMissing('2fa_email');
    }

    public function test_verify_2fa_code_incorrect_retourne_erreur(): void
    {
        $user = $this->creerUtilisateur();
        $user->update([
            'two_factor_code'       => '123456',
            'two_factor_expires_at' => now()->addMinutes(10),
        ]);

        $this->withSession(['2fa_email' => 'user@test.com'])
             ->post(route('connexion.verify2fa'), ['code' => '000000'])
             ->assertSessionHasErrors('code');

        $this->assertGuest();
    }

    public function test_verify_2fa_code_expire_retourne_erreur(): void
    {
        $user = $this->creerUtilisateur();
        $user->update([
            'two_factor_code'       => '123456',
            'two_factor_expires_at' => now()->subMinute(),
        ]);

        $this->withSession(['2fa_email' => 'user@test.com'])
             ->post(route('connexion.verify2fa'), ['code' => '123456'])
             ->assertSessionHasErrors('code');
    }

    public function test_verify_2fa_sans_session_redirige_vers_connexion(): void
    {
        $this->post(route('connexion.verify2fa'), ['code' => '123456'])
             ->assertRedirect(route('connexion'));
    }

    public function test_verify_2fa_champ_manquant_retourne_erreur_validation(): void
    {
        $this->withSession(['2fa_email' => 'user@test.com'])
             ->post(route('connexion.verify2fa'), [])
             ->assertSessionHasErrors('code');
    }

    // -------------------------------------------------------------------------
    // POST /deconnexion
    // -------------------------------------------------------------------------

    public function test_logout_deconnecte_et_redirige_vers_home(): void
    {
        $user = $this->creerUtilisateur();

        $this->actingAs($user)
             ->post(route('deconnexion'))
             ->assertRedirect(route('home'));

        $this->assertGuest();
    }

    public function test_routes_espace_inaccessibles_sans_connexion(): void
    {
        // Il n'y a pas de route `espace.calendrier` : la grille de créneaux est
        // affichée dans le tableau de bord et alimentée par l'API `espace.creneaux`.
        $this->get(route('espace.dashboard'))->assertRedirect(route('connexion'));
        $this->get(route('espace.creneaux'))->assertRedirect(route('connexion'));
        $this->get(route('espace.profil'))->assertRedirect(route('connexion'));
        $this->get(route('espace.qrcode'))->assertRedirect(route('connexion'));
    }
}
