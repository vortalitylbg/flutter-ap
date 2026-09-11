<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    // La page d'accueil lit `parametrage.nomPlateforme` en base (HomeController).
    // Sans RefreshDatabase les migrations ne sont pas jouées sur la base SQLite
    // en mémoire, la table `parametrage` n'existe pas et la requête renvoie 500.
    use RefreshDatabase;

    /**
     * A basic test example.
     */
    public function test_the_application_returns_a_successful_response(): void
    {
        $response = $this->get('/');

        $response->assertStatus(200);
    }
}
