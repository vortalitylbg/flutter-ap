<?php

namespace Tests\Feature\Api;

use App\Models\Prestation;
use App\Models\Reservation;
use App\Models\Utilisateur;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MobileRdvTest extends TestCase
{
    use RefreshDatabase;

    private function creerStaffAvecToken(): array
    {
        $staff = Utilisateur::factory()->create(['idrole' => 2]);
        $token = $staff->createToken('mobile')->plainTextToken;
        return [$staff, $token];
    }

    private function creerReservationFuture(Utilisateur $client, int $joursOffset = 1): Reservation
    {
        $prestation = Prestation::create([
            'libelleprestation' => 'Prestation test',
            'montantprestation' => '20.00',
        ]);

        return Reservation::create([
            'idutilisateur'      => $client->idutilisateur,
            'idprestation'       => $prestation->idprestation,
            'datedebut'          => now()->addDays($joursOffset)->toDateString(),
            'heuredebut'         => '10:00:00',
            'validationpresence' => 0,
        ]);
    }

    // -------------------------------------------------------------------------
    // GET /api/mobile/rdv
    // -------------------------------------------------------------------------

    public function test_rdv_sans_token_retourne_401(): void
    {
        $this->getJson('/api/mobile/rdv')
             ->assertStatus(401);
    }

    public function test_rdv_retourne_liste_vide_si_aucune_reservation(): void
    {
        [, $token] = $this->creerStaffAvecToken();

        $this->getJson('/api/mobile/rdv', ['Authorization' => "Bearer $token"])
             ->assertStatus(200)
             ->assertExactJson([]);
    }

    public function test_rdv_retourne_reservations_futures(): void
    {
        [, $token] = $this->creerStaffAvecToken();
        $client = Utilisateur::factory()->create(['idrole' => 1]);
        $this->creerReservationFuture($client);

        $response = $this->getJson('/api/mobile/rdv', ['Authorization' => "Bearer $token"]);

        $response->assertStatus(200)
                 ->assertJsonCount(1)
                 ->assertJsonStructure([['idreservation', 'datedebut', 'heuredebut', 'validationpresence', 'prestation', 'client' => ['nom', 'prenom']]]);
    }

    public function test_rdv_n_inclut_pas_les_reservations_passees(): void
    {
        [, $token] = $this->creerStaffAvecToken();
        $client = Utilisateur::factory()->create(['idrole' => 1]);

        // Réservation passée
        $prestation = Prestation::create(['libelleprestation' => 'P', 'montantprestation' => '10.00']);
        Reservation::create([
            'idutilisateur'      => $client->idutilisateur,
            'idprestation'       => $prestation->idprestation,
            'datedebut'          => now()->subDay()->toDateString(),
            'heuredebut'         => '10:00:00',
            'validationpresence' => 0,
        ]);

        $this->getJson('/api/mobile/rdv', ['Authorization' => "Bearer $token"])
             ->assertStatus(200)
             ->assertExactJson([]);
    }

    public function test_rdv_trie_par_date_et_heure(): void
    {
        [, $token] = $this->creerStaffAvecToken();
        $client = Utilisateur::factory()->create(['idrole' => 1]);
        $prestation = Prestation::create(['libelleprestation' => 'P', 'montantprestation' => '10.00']);

        Reservation::create(['idutilisateur' => $client->idutilisateur, 'idprestation' => $prestation->idprestation, 'datedebut' => now()->addDays(2)->toDateString(), 'heuredebut' => '14:00:00', 'validationpresence' => 0]);
        Reservation::create(['idutilisateur' => $client->idutilisateur, 'idprestation' => $prestation->idprestation, 'datedebut' => now()->addDay()->toDateString(), 'heuredebut' => '09:00:00', 'validationpresence' => 0]);

        $response = $this->getJson('/api/mobile/rdv', ['Authorization' => "Bearer $token"]);

        $response->assertStatus(200)->assertJsonCount(2);
        $reservations = $response->json();
        $this->assertLessThan($reservations[1]['datedebut'], $reservations[0]['datedebut']);;
    }

    // -------------------------------------------------------------------------
    // POST /api/mobile/valider-presence
    // -------------------------------------------------------------------------

    public function test_valider_presence_sans_token_retourne_401(): void
    {
        $this->postJson('/api/mobile/valider-presence', ['idreservation' => 1])
             ->assertStatus(401);
    }

    public function test_valider_presence_retourne_200(): void
    {
        [, $token] = $this->creerStaffAvecToken();
        $client = Utilisateur::factory()->create(['idrole' => 1]);
        $reservation = $this->creerReservationFuture($client);

        $this->postJson(
            '/api/mobile/valider-presence',
            ['idreservation' => $reservation->idreservation],
            ['Authorization' => "Bearer $token"]
        )->assertStatus(200)
         ->assertJsonPath('message', 'Présence validée.')
         ->assertJsonPath('idreservation', $reservation->idreservation);

        $this->assertTrue($reservation->fresh()->validationpresence);
    }

    public function test_valider_presence_doublon_retourne_409(): void
    {
        [, $token] = $this->creerStaffAvecToken();
        $client = Utilisateur::factory()->create(['idrole' => 1]);
        $reservation = $this->creerReservationFuture($client);

        $headers = ['Authorization' => "Bearer $token"];

        $this->postJson('/api/mobile/valider-presence', ['idreservation' => $reservation->idreservation], $headers)
             ->assertStatus(200);

        $this->postJson('/api/mobile/valider-presence', ['idreservation' => $reservation->idreservation], $headers)
             ->assertStatus(409)
             ->assertJsonPath('message', 'Présence déjà validée.');
    }

    public function test_valider_presence_id_inexistant_retourne_422(): void
    {
        [, $token] = $this->creerStaffAvecToken();

        $this->postJson(
            '/api/mobile/valider-presence',
            ['idreservation' => 9999],
            ['Authorization' => "Bearer $token"]
        )->assertStatus(422)
         ->assertJsonValidationErrors(['idreservation']);
    }

    public function test_valider_presence_champ_manquant_retourne_422(): void
    {
        [, $token] = $this->creerStaffAvecToken();

        $this->postJson('/api/mobile/valider-presence', [], ['Authorization' => "Bearer $token"])
             ->assertStatus(422)
             ->assertJsonValidationErrors(['idreservation']);
    }
}
