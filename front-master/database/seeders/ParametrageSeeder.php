<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Paramètres de fonctionnement de la plateforme.
 *
 * ATTENTION : sans ces lignes l'application ne fonctionne pas.
 * `HomeController::index()` lit `nomPlateforme` sans valeur de repli, et
 * `EspaceController::creneaux()` lit `dureeCreneau` pour construire la grille.
 * Ce seeder doit donc être joué sur tout nouvel environnement, production
 * comprise.
 *
 * `heureOuverture` et `heureFermeture` ne sont volontairement pas créés :
 * EspaceController retombe sur ses valeurs par défaut (08:00 et 18:00) quand
 * ils sont absents. Les ajouter ici les rendrait configurables en base.
 */
class ParametrageSeeder extends Seeder
{
    public function run(): void
    {
        $parametres = [
            [
                'idparam'      => 1,
                'libelleparam' => 'nomPlateforme',
                'valeurparam'  => 'RésaChev',
                'uniteparam'   => null,
            ],
            [
                'idparam'      => 2,
                'libelleparam' => 'dureeCreneau',
                'valeurparam'  => '30',
                'uniteparam'   => 'minutes',
            ],
        ];

        // updateOrInsert : relancer le seeder réinitialise les valeurs aux
        // réglages par défaut au lieu d'échouer sur une clé primaire dupliquée.
        foreach ($parametres as $parametre) {
            DB::table('parametrage')->updateOrInsert(
                ['idparam' => $parametre['idparam']],
                $parametre
            );
        }
    }
}
