<?php

namespace Database\Seeders;

use App\Models\Reservation;
use App\Models\Utilisateur;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // ---------------------------------------------------------------------
        // Données de référence
        // ---------------------------------------------------------------------
        // Rôles, paramétrage et prestations. Elles ne sont
        // plus créées par la migration, et les comptes comme les réservations
        // ci-dessous en dépendent par clé étrangère : cet appel doit rester en
        // premier.
        $this->call(ReferenceSeeder::class);

        // ---------------------------------------------------------------------
        // Comptes de test
        // ---------------------------------------------------------------------
        // Deux clients, pour que la grille de créneaux montre les deux cas de
        // figure : les réservations du client connecté, et celles des autres
        // clients (affichées comme "occupe", sans divulguer leur identité).
        //
        // Les mots de passe sont stockés en clair (voir UtilisateurFactory) car
        // la connexion compare les chaînes directement.
        $jean = Utilisateur::factory()->create([
            'nom'      => 'Dupont',
            'prenom'   => 'Jean',
            'email'    => 'test@example.com',
            'motpasse' => 'password',
            'idrole'   => 1,
        ]);

        $marie = Utilisateur::factory()->create([
            'nom'      => 'Martin',
            'prenom'   => 'Marie',
            'email'    => 'marie@example.com',
            'motpasse' => 'password',
            'idrole'   => 1,
        ]);

        $marie = Utilisateur::factory()->create([
            'nom'      => 'Bon',
            'prenom'   => 'Jean',
            'email'    => 'staff@example.com',
            'motpasse' => 'password',
            'idrole'   => 2,
        ]);

        // ---------------------------------------------------------------------
        // Réservations de démonstration
        // ---------------------------------------------------------------------
        // Les dates sont calculées au moment où le seeder est lancé, et non
        // écrites en dur : la grille du tableau de bord affiche J-1 à J+5, ces
        // réservations y restent donc visibles quelle que soit la date du jour.
        $veille    = (new \DateTime('yesterday'))->format('Y-m-d');
        $lendemain = (new \DateTime('tomorrow'))->format('Y-m-d');

        // Chaque client suit le même schéma : une réservation la veille, déjà
        // validée par le staff, et deux le lendemain, encore à honorer.
        // Les heures ne se chevauchent pas entre les deux clients, et sont
        // alignées sur la grille des créneaux (08:00 à 18:00, pas de 30
        // minutes) : en dehors de cette grille, elles n'apparaîtraient dans
        // aucune case du calendrier.
        //
        // validationpresence = true  : créneau passé, QR code scanné par le
        //                              staff, statut "valide" pour son
        //                              propriétaire.
        // validationpresence = false : créneau à venir, statut
        //                              "ma_reservation" pour son propriétaire.
        //
        // Vu par l'autre client, tous ces créneaux apparaissent en "occupe".
        $reservations = [
            // [utilisateur, date, heure, prestation, présence validée]
            [$jean,  $veille,    '09:00', 1, true],
            [$jean,  $lendemain, '10:30', 1, false],
            [$jean,  $lendemain, '14:00', 2, false],

            [$marie, $veille,    '11:00', 2, true],
            [$marie, $lendemain, '09:30', 1, false],
            [$marie, $lendemain, '15:30', 2, false],
        ];

        foreach ($reservations as [$client, $date, $heure, $prestation, $validee]) {
            Reservation::create([
                'idutilisateur'      => $client->idutilisateur,
                'idprestation'       => $prestation,
                'datedebut'          => $date,
                'heuredebut'         => $heure,
                'validationpresence' => $validee,
            ]);
        }
    }
}
