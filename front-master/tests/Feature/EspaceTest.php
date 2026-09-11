<?php

namespace Tests\Feature;

use App\Models\Prestation;
use App\Models\Reservation;
use App\Models\Utilisateur;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EspaceTest extends TestCase
{
    use RefreshDatabase;

    private function creerClient(array $attributs = []): Utilisateur
    {
        return Utilisateur::factory()->create(array_merge(['idrole' => 1], $attributs));
    }

    private function creerPrestation(): Prestation
    {
        return Prestation::create([
            'libelleprestation' => 'Prestation test',
            'montantprestation' => '30.00',
        ]);
    }

    private function creerReservation(Utilisateur $client, array $attributs = []): Reservation
    {
        $prestation = $this->creerPrestation();

        return Reservation::create(array_merge([
            'idutilisateur'      => $client->idutilisateur,
            'idprestation'       => $prestation->idprestation,
            'datedebut'          => now()->addDay()->toDateString(),
            'heuredebut'         => '10:00:00',
            'validationpresence' => 0,
        ], $attributs));
    }

    // -------------------------------------------------------------------------
    // GET /espace/tableau-de-bord
    // -------------------------------------------------------------------------

    public function test_dashboard_inaccessible_sans_connexion(): void
    {
        $this->get(route('espace.dashboard'))->assertRedirect(route('connexion'));
    }

    public function test_dashboard_accessible_pour_utilisateur_connecte(): void
    {
        $client = $this->creerClient();

        $this->actingAs($client)
             ->get(route('espace.dashboard'))
             ->assertStatus(200);
    }

    public function test_dashboard_affiche_prochaine_reservation(): void
    {
        $client = $this->creerClient();
        $this->creerReservation($client);

        $this->actingAs($client)
             ->get(route('espace.dashboard'))
             ->assertStatus(200);
    }

    public function test_dashboard_sans_reservation_a_venir(): void
    {
        $client = $this->creerClient();

        $this->actingAs($client)
             ->get(route('espace.dashboard'))
             ->assertStatus(200);
    }

    // -------------------------------------------------------------------------
    // GET /espace/creneaux
    // -------------------------------------------------------------------------

    public function test_creneaux_inaccessible_sans_connexion(): void
    {
        $this->get(route('espace.creneaux'))->assertRedirect(route('connexion'));
    }

    public function test_creneaux_retourne_json_avec_structure_correcte(): void
    {
        $client = $this->creerClient();

        $this->actingAs($client)
             ->getJson(route('espace.creneaux'))
             ->assertStatus(200)
             ->assertJsonStructure(['debut', 'semaine', 'jours']);
    }

    public function test_creneaux_retourne_7_jours(): void
    {
        $client = $this->creerClient();

        $response = $this->actingAs($client)
                         ->getJson(route('espace.creneaux'))
                         ->assertStatus(200);

        $this->assertCount(7, $response->json('jours'));
    }

    public function test_creneaux_accepte_parametre_debut(): void
    {
        $client = $this->creerClient();
        $debut  = now()->addDays(3)->format('Y-m-d');

        $response = $this->actingAs($client)
                         ->getJson(route('espace.creneaux') . "?debut={$debut}")
                         ->assertStatus(200);

        $this->assertEquals($debut, $response->json('debut'));
    }

    public function test_creneaux_slot_statut_ma_reservation(): void
    {
        $client     = $this->creerClient();
        $datedebut  = now()->addDay()->toDateString();
        $this->creerReservation($client, ['datedebut' => $datedebut, 'heuredebut' => '08:00:00', 'validationpresence' => 0]);

        $response = $this->actingAs($client)
                         ->getJson(route('espace.creneaux') . "?debut={$datedebut}")
                         ->assertStatus(200);

        $slot = collect($response->json('jours.0.slots'))->firstWhere('heure', '08:00');
        $this->assertEquals('ma_reservation', $slot['statut']);
    }

    public function test_creneaux_slot_statut_valide(): void
    {
        $client    = $this->creerClient();
        $datedebut = now()->addDay()->toDateString();
        $this->creerReservation($client, ['datedebut' => $datedebut, 'heuredebut' => '08:00:00', 'validationpresence' => 1]);

        $response = $this->actingAs($client)
                         ->getJson(route('espace.creneaux') . "?debut={$datedebut}")
                         ->assertStatus(200);

        $slot = collect($response->json('jours.0.slots'))->firstWhere('heure', '08:00');
        $this->assertEquals('valide', $slot['statut']);
    }

    public function test_creneaux_slot_statut_occupe_par_autre_client(): void
    {
        $client      = $this->creerClient();
        $autreClient = $this->creerClient();
        $datedebut   = now()->addDay()->toDateString();
        $this->creerReservation($autreClient, ['datedebut' => $datedebut, 'heuredebut' => '08:00:00']);

        $response = $this->actingAs($client)
                         ->getJson(route('espace.creneaux') . "?debut={$datedebut}")
                         ->assertStatus(200);

        $slot = collect($response->json('jours.0.slots'))->firstWhere('heure', '08:00');
        $this->assertEquals('occupe', $slot['statut']);
        $this->assertNull($slot['prestation']);
    }

    public function test_creneaux_slot_statut_libre(): void
    {
        $client    = $this->creerClient();
        $datedebut = now()->addDay()->toDateString();

        $response = $this->actingAs($client)
                         ->getJson(route('espace.creneaux') . "?debut={$datedebut}")
                         ->assertStatus(200);

        $slot = collect($response->json('jours.0.slots'))->firstWhere('heure', '08:00');
        $this->assertEquals('libre', $slot['statut']);
    }

    // -------------------------------------------------------------------------
    // GET /espace/profil
    // -------------------------------------------------------------------------

    public function test_profil_inaccessible_sans_connexion(): void
    {
        $this->get(route('espace.profil'))->assertRedirect(route('connexion'));
    }

    public function test_profil_accessible_pour_utilisateur_connecte(): void
    {
        $client = $this->creerClient();

        $this->actingAs($client)
             ->get(route('espace.profil'))
             ->assertStatus(200);
    }

    // -------------------------------------------------------------------------
    // POST /espace/profil
    // -------------------------------------------------------------------------

    public function test_update_profil_inaccessible_sans_connexion(): void
    {
        $this->post(route('espace.profil.update'), ['nom' => 'Dupont'])
             ->assertRedirect(route('connexion'));
    }

    public function test_update_profil_valide_met_a_jour_le_nom(): void
    {
        $client = $this->creerClient();

        $this->actingAs($client)
             ->post(route('espace.profil.update'), ['nom' => 'Dupont'])
             ->assertRedirect(route('espace.profil'))
             ->assertSessionHas('statut');

        $this->assertEquals('Dupont', $client->fresh()->nom);
    }

    public function test_update_profil_nom_manquant_retourne_erreur(): void
    {
        $client = $this->creerClient();

        $this->actingAs($client)
             ->post(route('espace.profil.update'), [])
             ->assertSessionHasErrors('nom');
    }

    public function test_update_profil_nom_trop_long_retourne_erreur(): void
    {
        $client = $this->creerClient();

        $this->actingAs($client)
             ->post(route('espace.profil.update'), ['nom' => str_repeat('a', 101)])
             ->assertSessionHasErrors('nom');
    }

    // -------------------------------------------------------------------------
    // GET /espace/qrcode
    // -------------------------------------------------------------------------

    public function test_qrcode_inaccessible_sans_connexion(): void
    {
        $this->get(route('espace.qrcode'))->assertRedirect(route('connexion'));
    }

    public function test_qrcode_accessible_pour_utilisateur_connecte(): void
    {
        $client = $this->creerClient();

        $this->actingAs($client)
             ->get(route('espace.qrcode'))
             ->assertStatus(200);
    }

    public function test_qrcode_avec_prochaine_reservation(): void
    {
        $client = $this->creerClient();
        $this->creerReservation($client);

        $this->actingAs($client)
             ->get(route('espace.qrcode'))
             ->assertStatus(200);
    }
}
