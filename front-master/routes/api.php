<?php

use App\Http\Controllers\Api\MobileController;
use Illuminate\Support\Facades\Route;

// Routes publiques (authentification mobile)
Route::post('/mobile/login', [MobileController::class, 'login'])->name('api.mobile.login');
Route::post('/mobile/verify-2fa', [MobileController::class, 'verify2FA'])->name('api.mobile.verify2fa');

// Routes protégées par Sanctum (usage staff terrain)
Route::middleware('auth:sanctum')->group(function () {
    // Profil du staff connecté (lecture complète, mise à jour du nom seulement pour l'instant)
    Route::get('/mobile/me', [MobileController::class, 'getMe'])->name('api.mobile.me');
    Route::put('/mobile/me', [MobileController::class, 'updateMe'])->name('api.mobile.me.update');
    Route::get('/mobile/rdv', [MobileController::class, 'prochainRdv'])->name('api.mobile.rdv');
    Route::post('/mobile/valider-presence', [MobileController::class, 'validerPresence'])->name('api.mobile.valider');

    // Informations du client rattaché à une réservation (id lu dans le QR code)
    Route::get('/mobile/reservation/{idreservation}/client', [MobileController::class, 'clientParReservation'])
        ->whereNumber('idreservation')
        ->name('api.mobile.reservation.client');
});
