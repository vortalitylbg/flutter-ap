<?php

namespace Database\Factories;

use App\Models\Utilisateur;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Utilisateur>
 */
class UtilisateurFactory extends Factory
{
    protected $model = Utilisateur::class;

    public function definition(): array
    {
        return [
            'idrole' => 1,
            'nom' => fake()->lastName(),
            'prenom' => fake()->firstName(),
            'email' => fake()->unique()->safeEmail(),

            // Mot de passe stocké EN CLAIR, volontairement.
            // La connexion compare les chaînes directement
            // (ConnexionController::connexion), un mot de passe haché ici
            // rendrait le compte généré impossible à utiliser.
            // TODO étudiant : repasser à Hash::make() le jour où le hachage
            // bcrypt sera implémenté côté connexion.
            'motpasse' => 'password',
        ];
    }
}
