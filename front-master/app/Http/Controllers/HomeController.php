<?php

namespace App\Http\Controllers;

use App\Models\Parametrage;

class HomeController extends Controller
{
    /**
     * Affiche la page d'accueil publique.
     */
    public function index()
    {
        // Récupère depuis la base de données le nom de la plateforme.
        $nomPlatform = Parametrage::getValeur('nomPlateforme');
        return view('home', ['nomPlatform' => $nomPlatform]);
    }

    /**
     * Affiche la documentation Swagger UI de l'API mobile.
     */
    public function apiDoc()
    {
        return view('api-doc');
    }
}
