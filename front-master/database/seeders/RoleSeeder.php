<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Rôles applicatifs.
 *
 * Donnée de référence indispensable : `utilisateur.idrole` est une clé
 * étrangère vers cette table, aucun utilisateur ne peut être créé sans elle.
 */
class RoleSeeder extends Seeder
{
    public function run(): void
    {
        $roles = [
            ['idrole' => 1, 'libellerole' => 'client'],
            ['idrole' => 2, 'libellerole' => 'staff'],
        ];

        // updateOrInsert plutôt qu'insert : le seeder peut être relancé sur une
        // base déjà remplie sans provoquer d'erreur de clé primaire dupliquée.
        foreach ($roles as $role) {
            DB::table('role')->updateOrInsert(
                ['idrole' => $role['idrole']],
                $role
            );
        }
    }
}
