<?php
// Jeu de données de démonstration pour les captures d'écran de la documentation.
// Exécuté via : php artisan tinker --execute="require 'doc/tools/seed-demo.php';"
// Le mot de passe est inséré en clair (comparaison directe dans ConnexionController).

use Illuminate\Support\Facades\DB;

DB::table('parametrage')->updateOrInsert(['libelleparam' => 'heureOuverture'], ['valeurparam' => '09:00', 'uniteparam' => null]);
DB::table('parametrage')->updateOrInsert(['libelleparam' => 'heureFermeture'], ['valeurparam' => '17:00', 'uniteparam' => null]);
DB::table('parametrage')->where('libelleparam', 'nomPlateforme')->update(['valeurparam' => 'ResaChev']);

DB::table('prestation')->where('idprestation', 1)->update(['libelleprestation' => 'Balade à cheval (1h)', 'montantprestation' => 25.00]);
DB::table('prestation')->where('idprestation', 2)->update(['libelleprestation' => 'Cours particulier', 'montantprestation' => 45.00]);

$now = now();
$idClient = DB::table('utilisateur')->insertGetId([
    'idrole' => 1, 'nom' => 'Dupont', 'prenom' => 'Jean', 'email' => 'jean.dupont@example.com',
    'motpasse' => 'demo1234', 'created_at' => $now, 'updated_at' => $now,
]);
$idAutre = DB::table('utilisateur')->insertGetId([
    'idrole' => 1, 'nom' => 'Martin', 'prenom' => 'Claire', 'email' => 'claire.martin@example.com',
    'motpasse' => 'demo1234', 'created_at' => $now, 'updated_at' => $now,
]);
DB::table('utilisateur')->insert([
    'idrole' => 2, 'nom' => 'Staff', 'prenom' => 'Sophie', 'email' => 'staff@example.com',
    'motpasse' => 'demo1234', 'created_at' => $now, 'updated_at' => $now,
]);

$d = fn (int $j) => (new DateTime('today'))->modify("+{$j} days")->format('Y-m-d');
DB::table('reservation')->insert([
    ['idutilisateur' => $idClient, 'idprestation' => 1, 'datedebut' => $d(-1), 'heuredebut' => '10:00:00', 'validationpresence' => 1],
    ['idutilisateur' => $idClient, 'idprestation' => 2, 'datedebut' => $d(1),  'heuredebut' => '14:30:00', 'validationpresence' => 0],
    ['idutilisateur' => $idClient, 'idprestation' => 1, 'datedebut' => $d(4),  'heuredebut' => '09:00:00', 'validationpresence' => 0],
    ['idutilisateur' => $idAutre,  'idprestation' => 1, 'datedebut' => $d(0),  'heuredebut' => '11:00:00', 'validationpresence' => 0],
    ['idutilisateur' => $idAutre,  'idprestation' => 2, 'datedebut' => $d(2),  'heuredebut' => '16:00:00', 'validationpresence' => 0],
    ['idutilisateur' => $idAutre,  'idprestation' => 1, 'datedebut' => $d(3),  'heuredebut' => '10:30:00', 'validationpresence' => 0],
]);
echo "Seed démo OK\n";
