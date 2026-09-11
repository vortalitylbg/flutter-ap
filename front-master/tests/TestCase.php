<?php

namespace Tests;

use Database\Seeders\ReferenceSeeder;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    /**
     * Joue un seeder après les migrations, dans les tests qui utilisent
     * RefreshDatabase.
     *
     * Les données de référence (role, modepaiement, parametrage, prestation)
     * vivaient dans la migration : elles étaient donc présentes d'office. Elles
     * sont maintenant dans des seeders, et RefreshDatabase ne joue aucun seeder
     * par défaut. Sans cela, les tests échouent sur la clé étrangère
     * `utilisateur.idrole` et sur la lecture de `parametrage.nomPlateforme`.
     */
    protected bool $seed = true;

    /**
     * ReferenceSeeder et non DatabaseSeeder : les tests ont besoin des données
     * de référence, mais surtout pas des comptes et réservations de
     * démonstration, qui fausseraient les assertions.
     */
    protected string $seeder = ReferenceSeeder::class;
}
