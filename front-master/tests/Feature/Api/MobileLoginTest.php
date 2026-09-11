<?php

namespace Tests\Feature\Api;

use App\Models\Utilisateur;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class MobileLoginTest extends TestCase
{
    use RefreshDatabase;

    // Crée un utilisateur staff réutilisable dans les tests de la classe
    private function creerStaff(array $attributs = []): Utilisateur
    {
        return Utilisateur::factory()->create(array_merge([
            'idrole'   => 2,
            'email'    => 'staff@test.com',
            'motpasse' => 'password123',
        ], $attributs));
    }

    // -------------------------------------------------------------------------
    // POST /api/mobile/login
    // -------------------------------------------------------------------------

    public function test_login_identifiants_valides_envoie_code_2fa(): void
    {
        Mail::fake();
        $this->creerStaff();

        $response = $this->postJson('/api/mobile/login', [
            'email'    => 'staff@test.com',
            'motpasse' => 'password123',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure(['message', 'email'])
                 ->assertJsonPath('email', 'staff@test.com');

        // Le code 2FA doit être stocké en base
        $this->assertNotNull(
            Utilisateur::where('email', 'staff@test.com')->value('two_factor_code')
        );
    }

    public function test_login_mauvais_mot_de_passe_retourne_401(): void
    {
        $this->creerStaff();

        $response = $this->postJson('/api/mobile/login', [
            'email'    => 'staff@test.com',
            'motpasse' => 'mauvais',
        ]);

        $response->assertStatus(401)
                 ->assertJsonPath('message', 'Identifiants invalides ou accès non autorisé.');
    }

    public function test_login_utilisateur_client_retourne_401(): void
    {
        Utilisateur::factory()->create([
            'idrole' => 1,
            'email'  => 'client@test.com',
            'motpasse' => 'password123',
        ]);

        $response = $this->postJson('/api/mobile/login', [
            'email'    => 'client@test.com',
            'motpasse' => 'password123',
        ]);

        $response->assertStatus(401);
    }

    public function test_login_email_inconnu_retourne_401(): void
    {
        $response = $this->postJson('/api/mobile/login', [
            'email'    => 'inconnu@test.com',
            'motpasse' => 'password123',
        ]);

        $response->assertStatus(401);
    }

    public function test_login_champs_manquants_retourne_422(): void
    {
        $response = $this->postJson('/api/mobile/login', []);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['email', 'motpasse']);
    }

    public function test_login_email_invalide_retourne_422(): void
    {
        $response = $this->postJson('/api/mobile/login', [
            'email'    => 'pas-un-email',
            'motpasse' => 'password123',
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['email']);
    }

    // -------------------------------------------------------------------------
    // POST /api/mobile/verify-2fa
    // -------------------------------------------------------------------------

    public function test_verify_2fa_code_valide_retourne_token(): void
    {
        $staff = $this->creerStaff();
        $staff->update([
            'two_factor_code'       => '123456',
            'two_factor_expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/mobile/verify-2fa', [
            'email' => 'staff@test.com',
            'code'  => '123456',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure(['token', 'utilisateur' => ['idutilisateur', 'nom', 'prenom', 'email']]);

        // Le code doit être invalidé après usage
        $staff->refresh();
        $this->assertNull($staff->two_factor_code);
        $this->assertNull($staff->two_factor_expires_at);
    }

    public function test_verify_2fa_code_expire_retourne_401(): void
    {
        $staff = $this->creerStaff();
        $staff->update([
            'two_factor_code'       => '123456',
            'two_factor_expires_at' => now()->subMinute(), // expiré
        ]);

        $response = $this->postJson('/api/mobile/verify-2fa', [
            'email' => 'staff@test.com',
            'code'  => '123456',
        ]);

        $response->assertStatus(401)
                 ->assertJsonPath('message', 'Code invalide ou expiré.');
    }

    public function test_verify_2fa_code_incorrect_retourne_401(): void
    {
        $staff = $this->creerStaff();
        $staff->update([
            'two_factor_code'       => '123456',
            'two_factor_expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/mobile/verify-2fa', [
            'email' => 'staff@test.com',
            'code'  => '000000',
        ]);

        $response->assertStatus(401);
    }

    public function test_verify_2fa_code_reutilise_retourne_401(): void
    {
        $staff = $this->creerStaff();
        $staff->update([
            'two_factor_code'       => '123456',
            'two_factor_expires_at' => now()->addMinutes(10),
        ]);

        // Première utilisation — succès
        $this->postJson('/api/mobile/verify-2fa', [
            'email' => 'staff@test.com',
            'code'  => '123456',
        ])->assertStatus(200);

        // Deuxième utilisation — refusée
        $this->postJson('/api/mobile/verify-2fa', [
            'email' => 'staff@test.com',
            'code'  => '123456',
        ])->assertStatus(401);
    }

    public function test_verify_2fa_champs_manquants_retourne_422(): void
    {
        $response = $this->postJson('/api/mobile/verify-2fa', []);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['email', 'code']);
    }

    public function test_verify_2fa_code_trop_court_retourne_422(): void
    {
        $response = $this->postJson('/api/mobile/verify-2fa', [
            'email' => 'staff@test.com',
            'code'  => '123', // moins de 6 caractères
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['code']);
    }
}
