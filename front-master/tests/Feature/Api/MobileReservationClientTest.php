<?php

namespace Tests\Feature\Api;

use App\Models\Prestation;
use App\Models\Reservation;
use App\Models\Utilisateur;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MobileReservationClientTest extends TestCase
{
    use RefreshDatabase;

    private function creerStaffAvecToken(): array
    {
        $staff = Utilisateur::factory()->create(['idrole' => 2]);
        $token = $staff->createToken('mobile')->plainTextToken;
        return [$staff, $token];
    }

    private function creerReservation(Utilisateur $client): Reservation
    {
        $prestation = Prestation::create([
            'libelleprestation' => 'Prestation test',
            'montantprestation' => '20.00',
        ]);

        return Reservation::create([
            'idutilisateur'      => $client->idutilisateur,
            'idprestation'       => $prestation->idprestation,
            'datedebut'          => now()->addDay()->toDateString(),
            'heuredebut'         => '10:00:00',
            'validationpresence' => 0,
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/mobile/reservation/{idreservation}/client
    // -------------------------------------------------------------------------

    public function test_client_sans_token_retourne_401(): void
    {
        $client = Utilisateur::factory()->create(['idrole' => 1]);
        $reservation = $this->creerReservation($client);

        $this->getJson("/api/mobile/reservation/{$reservation->idreservation}/client")
             ->assertStatus(401);
    }

    public function test_client_retourne_les_informations_de_la_personne(): void
    {
        [, $token] = $this->creerStaffAvecToken();
        $client = Utilisateur::factory()->create([
            'idrole' => 1,
            'nom'    => 'Martin',
            'prenom' => 'Sophie',
            'email'  => 'sophie.martin@test.com',
        ]);
        $reservation = $this->creerReservation($client);

        $response = $this->getJson(
            "/api/mobile/reservation/{$reservation->idreservation}/client",
            ['Authorization' => "Bearer $token"]
        );

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'idreservation', 'datedebut', 'heuredebut', 'validationpresence', 'prestation',
                     'client' => ['idutilisateur', 'nom', 'prenom', 'email'],
                 ])
                 ->assertJsonPath('idreservation', $reservation->idreservation)
                 ->assertJsonPath('client.nom', 'Martin')
                 ->assertJsonPath('client.prenom', 'Sophie')
                 ->assertJsonPath('client.email', 'sophie.martin@test.com');
    }

    public function test_client_reservation_inexistante_retourne_404(): void
    {
        [, $token] = $this->creerStaffAvecToken();

        $this->getJson('/api/mobile/reservation/999999/client', ['Authorization' => "Bearer $token"])
             ->assertStatus(404)
             ->assertJsonPath('message', 'Cette réservation n\'existe pas.');
    }
}
