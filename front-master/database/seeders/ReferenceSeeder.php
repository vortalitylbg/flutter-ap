<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Données de référence, sans lesquelles l'application ne fonctionne pas.
 *
 * Ces lignes vivaient auparavant dans la migration
 * `2026_07_02_000000_create_resachev_tables`. Les avoir sorties dans des
 * seeders veut dire qu'elles ne sont plus créées par `php artisan migrate` :
 * tout nouvel environnement doit être initialisé avec
 *
 *   php artisan migrate:fresh --seed
 *
 * qui recrée le schéma puis charge ces données et celles de démonstration.
 * Sur une base existante à ne pas détruire, ce seeder se joue seul :
 *
 *   php artisan db:seed --class=ReferenceSeeder
 *
 * Il ne contient aucune donnée de démonstration : c'est ce qui permet aux
 * tests de s'en servir (voir `tests/TestCase.php`) sans hériter des comptes
 * et réservations fictifs de `DatabaseSeeder`.
 *
 * Chaque seeder appelé est réexécutable sans erreur (updateOrInsert).
 */
class ReferenceSeeder extends Seeder
{
    public function run(): void
    {
        // L'ordre compte : `utilisateur.idrole` et `reservation.idprestation`
        // sont des clés étrangères, les tables pointées doivent exister avant
        // que quoi que ce soit ne les référence.
        $this->call([
            RoleSeeder::class,
            ParametrageSeeder::class,
            PrestationSeeder::class,
        ]);
    }
}
