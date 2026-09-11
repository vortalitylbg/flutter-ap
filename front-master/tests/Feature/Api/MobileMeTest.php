<?php

namespace Tests\Feature\Api;

use App\Models\Utilisateur;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MobileMeTest extends TestCase
{
    use RefreshDatabase;

    private function creerStaffAvecToken(array $attributs = []): array
    {
        $staff = Utilisateur::factory()->create(array_merge(['idrole' => 2], $attributs));
        $token = $staff->createToken('mobile')->plainTextToken;
        return [$staff, $token];
    }

    // -------------------------------------------------------------------------
    // GET /api/mobile/me
    // -------------------------------------------------------------------------

    public function test_me_sans_token_retourne_401(): void
    {
        $this->getJson('/api/mobile/me')
             ->assertStatus(401);
    }

    public function test_me_retourne_le_profil_du_staff_connecte(): void
    {
        [$staff, $token] = $this->creerStaffAvecToken([
            'nom'    => 'Dupont',
            'prenom' => 'Jean',
            'email'  => 'jean.dupont@test.com',
        ]);

        $this->getJson('/api/mobile/me', ['Authorization' => "Bearer $token"])
             ->assertStatus(200)
             ->assertExactJson([
                 'idutilisateur' => $staff->idutilisateur,
                 'idrole'        => 2,
                 'nom'           => 'Dupont',
                 'prenom'        => 'Jean',
                 'email'         => 'jean.dupont@test.com',
             ]);
    }

    public function test_me_n_expose_ni_le_mot_de_passe_ni_le_code_2fa(): void
    {
        [, $token] = $this->creerStaffAvecToken();

        $this->getJson('/api/mobile/me', ['Authorization' => "Bearer $token"])
             ->assertStatus(200)
             ->assertJsonMissingPath('motpasse')
             ->assertJsonMissingPath('two_factor_code');
    }

    // -------------------------------------------------------------------------
    // PUT /api/mobile/me
    // -------------------------------------------------------------------------

    public function test_update_me_sans_token_retourne_401(): void
    {
        $this->putJson('/api/mobile/me', ['nom' => 'Nouveau'])
             ->assertStatus(401);
    }

    public function test_update_me_modifie_le_nom(): void
    {
        [$staff, $token] = $this->creerStaffAvecToken(['nom' => 'Ancien']);

        $this->putJson('/api/mobile/me', ['nom' => 'Nouveau'], ['Authorization' => "Bearer $token"])
             ->assertStatus(200)
             ->assertJsonPath('message', 'Profil mis à jour.')
             ->assertJsonPath('utilisateur.nom', 'Nouveau');

        $this->assertSame('Nouveau', $staff->fresh()->nom);
    }

    public function test_update_me_ignore_les_autres_champs(): void
    {
        [$staff, $token] = $this->creerStaffAvecToken([
            'nom'    => 'Ancien',
            'prenom' => 'Jean',
            'email'  => 'jean@test.com',
        ]);

        $this->putJson('/api/mobile/me', [
            'nom'    => 'Nouveau',
            'prenom' => 'Pirate',
            'email'  => 'pirate@test.com',
            'idrole' => 1,
        ], ['Authorization' => "Bearer $token"])
             ->assertStatus(200);

        $staff = $staff->fresh();
        $this->assertSame('Nouveau', $staff->nom);
        $this->assertSame('Jean', $staff->prenom);
        $this->assertSame('jean@test.com', $staff->email);
        $this->assertSame(2, $staff->idrole);
    }

    public function test_update_me_sans_nom_retourne_422(): void
    {
        [, $token] = $this->creerStaffAvecToken();

        $this->putJson('/api/mobile/me', [], ['Authorization' => "Bearer $token"])
             ->assertStatus(422)
             ->assertJsonValidationErrors('nom');
    }
}
