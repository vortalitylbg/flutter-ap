<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('parametrage', function (Blueprint $table) {
            $table->increments('idparam');
            $table->string('libelleparam', 128);
            $table->string('valeurparam', 128);
            $table->string('uniteparam', 50)->nullable();
        });

        Schema::create('prestation', function (Blueprint $table) {
            $table->increments('idprestation');
            $table->string('libelleprestation', 128);
            $table->decimal('montantprestation', 5, 2)->nullable();
        });

        Schema::create('role', function (Blueprint $table) {
            $table->increments('idrole');
            $table->string('libellerole', 128);
        });

        Schema::create('utilisateur', function (Blueprint $table) {
            $table->increments('idutilisateur');
            $table->unsignedInteger('idrole')->nullable();
            $table->string('nom', 128);
            $table->string('prenom', 128);
            $table->string('email', 128)->nullable();
            $table->string('motpasse', 128)->nullable();
            $table->string('two_factor_code', 10)->nullable();
            $table->dateTime('two_factor_expires_at')->nullable();
            $table->timestamps();

            $table->foreign('idrole')->references('idrole')->on('role')
                ->onDelete('set null')->onUpdate('cascade');
        });

        Schema::create('reservation', function (Blueprint $table) {
            $table->increments('idreservation');
            $table->unsignedInteger('idutilisateur');
            $table->unsignedInteger('idprestation')->default(99);
            $table->date('datedebut');
            $table->time('heuredebut');
            $table->tinyInteger('validationpresence')->default(0);

            $table->foreign('idutilisateur')->references('idutilisateur')->on('utilisateur')
                ->onDelete('restrict')->onUpdate('cascade');
            $table->foreign('idprestation')->references('idprestation')->on('prestation')
                ->onDelete('restrict')->onUpdate('cascade');
        });

        // Cette migration ne crée que le schéma.
        // Les données de référence (role, parametrage,
        // prestation) sont dans database/seeders/ReferenceSeeder.php.
        // Sur un environnement neuf, la commande à lancer est donc :
        //   php artisan migrate:fresh --seed
        // ou, pour ne pas detruire des tables existantes :
        //   php artisan db:seed --class=ReferenceSeeder
        // Sans cela l'application ne démarre pas : `parametrage` est lu sans
        // valeur de repli et `role` est référencé par une clé étrangère.
    }

    public function down(): void
    {
        Schema::dropIfExists('reservation');
        Schema::dropIfExists('utilisateur');
        Schema::dropIfExists('role');
        Schema::dropIfExists('prestation');
        Schema::dropIfExists('parametrage');
    }
};
