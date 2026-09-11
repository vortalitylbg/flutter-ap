<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Prestations proposées à la réservation.
 *
 * Ce sont des exemples destinés au développement et à la démonstration, pas
 * un catalogue réel : en production, les prestations sont saisies depuis le
 * back-office C#. Ne pas jouer ce seeder sur une base de production déjà
 * alimentée, il écraserait les prestations 1 et 2.
 */
class PrestationSeeder extends Seeder
{
    public function run(): void
    {
        $prestations = [
            ['idprestation' => 1, 'libelleprestation' => 'exemple prestation1', 'montantprestation' => '15.00'],
            ['idprestation' => 2, 'libelleprestation' => 'exemple prestation2', 'montantprestation' => '50.00'],
            ['idprestation' => 99, 'libelleprestation' => 'Prestation par défaut', 'montantprestation' => null]
        ];

        foreach ($prestations as $prestation) {
            DB::table('prestation')->updateOrInsert(
                ['idprestation' => $prestation['idprestation']],
                $prestation
            );
        }
    }
}
