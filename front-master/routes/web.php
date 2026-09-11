<?php

use App\Http\Controllers\ConnexionController;
use App\Http\Controllers\EspaceController;
use App\Http\Controllers\HomeController;
use Illuminate\Support\Facades\Route;

// Page d'accueil publique
Route::get('/', [HomeController::class, 'index'])->name('home');
Route::get('/api-doc', [HomeController::class, 'apiDoc'])->name('api-doc');

// Authentification
Route::get('/connexion', [ConnexionController::class, 'index'])->name('connexion');
Route::post('/connexion', [ConnexionController::class, 'login'])->name('connexion.login');
Route::get('/connexion/verification', [ConnexionController::class, 'showVerification'])->name('connexion.verification');
Route::post('/connexion/verification', [ConnexionController::class, 'verify2FA'])->name('connexion.verify2fa');

Route::post('/deconnexion', [ConnexionController::class, 'logout'])->name('deconnexion');

Route::get('/mot-de-passe-oublie', [ConnexionController::class, 'showMotDePasseOublie'])->name('connexion.motdepasseoublie');
Route::post('/mot-de-passe-oublie', [ConnexionController::class, 'envoyerMotDePasseOublie'])->name('connexion.motdepasseoublie.envoyer');

Route::get('/reset-mot-de-passe/{token}', [ConnexionController::class, 'showResetMotDePasse'])->name('connexion.reset');
Route::post('/reset-mot-de-passe/{token}', [ConnexionController::class, 'resetMotDePasse'])->name('connexion.reset.enregistrer');

// Espace connecté (protégé par le middleware auth)
Route::middleware('auth')->group(function () {
    Route::get('/espace/tableau-de-bord', [EspaceController::class, 'dashboard'])->name('espace.dashboard');
    // API interne : retourne les créneaux de la semaine en JSON, consommée par le dashboard via fetch()
    Route::get('/espace/creneaux', [EspaceController::class, 'creneaux'])->name('espace.creneaux');
    Route::get('/espace/profil', [EspaceController::class, 'profil'])->name('espace.profil');
    Route::post('/espace/profil', [EspaceController::class, 'updateProfil'])->name('espace.profil.update');
    Route::get('/espace/qrcode', [EspaceController::class, 'qrcode'])->name('espace.qrcode');
});
