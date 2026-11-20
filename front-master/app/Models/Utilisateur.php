<?php

namespace App\Models;

use Database\Factories\UtilisateurFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Utilisateur extends Authenticatable
{
    /** @use HasFactory<UtilisateurFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'utilisateur';
    protected $primaryKey = 'idutilisateur';

    // La table utilisateur dispose de created_at et updated_at
    public $timestamps = true;

    protected $fillable = [
        'idrole',
        'nom',
        'prenom',
        'email',
        'motpasse',
        'two_factor_code',
        'two_factor_expires_at',
        'reset_token',
        'reset_token_expires_at',
    ];

    // TODO: Hasher le mot de passe avant de le stocker en base.
    //   Dans LE BON CONTROLLER :
    //   À la création/modification : $utilisateur->motpasse = password_hash($motpasseEnClair, PASSWORD_BCRYPT);
    //   À la vérification (login)   : password_verify($motpasseSaisi, $utilisateur->motpasse)

    protected $hidden = [
        'motpasse',
        'two_factor_code',
    ];

    protected function casts(): array
    {
        return [
            'two_factor_expires_at' => 'datetime',
            'reset_token_expires_at' => 'datetime',
        ];
    }

    /**
     * Indique à Laravel que le mot de passe est stocké dans la colonne `motpasse`
     * et non dans la colonne `password` (convention Laravel par défaut).
     */
    public function getAuthPassword(): string
    {
        return $this->motpasse;
    }

    /**
     * Désactive le "remember me" : la table utilisateur ne possède pas
     * de colonne remember_token.
     */
    public function getRememberTokenName(): ?string
    {
        return null;
    }

    /**
     * Vérifie si le code 2FA fourni est valide et non expiré.
     * @param string $code
     * @return bool
     */
    public function verifierCode2FA(string $code): bool
    {
        return $this->two_factor_code === $code
            && $this->two_factor_expires_at !== null
            && $this->two_factor_expires_at->isFuture();
    }

    /**
     * Retourne le rôle de l'utilisateur.
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function role()
    {
        return $this->belongsTo(Role::class, 'idrole', 'idrole');
    }

    /**
     * Retourne toutes les réservations de l'utilisateur.
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function reservations()
    {
        return $this->hasMany(Reservation::class, 'idutilisateur', 'idutilisateur');
    }

    /**
     * Retourne la prochaine réservation à venir de l'utilisateur.
     * Utilisée pour l'affichage du tableau de bord.
     * @return \Illuminate\Database\Eloquent\Relations\HasOne
     */
    public function prochaineReservation()
    {
        return $this->hasOne(Reservation::class, 'idutilisateur', 'idutilisateur')
            ->where('datedebut', '>=', now()->toDateString())
            ->orderBy('datedebut')
            ->orderBy('heuredebut');
    }

    public function niveau()
    {
        return $this->belongsTo(Niveau::class, 'idniveau', 'idniveau');
    }

    public function reservationsEvalables()
    {
        return $this->reservations()
            ->where('validationpresence', 1)
            ->whereDoesntHave('evaluation')
            ->with('prestation')
            ->orderByDesc('datedebut')
            ->orderByDesc('heuredebut');
    }

    public function pointsFidelite(): int
    {
        return (int) $this->reservations()
            ->where('validationpresence', 1)
            ->count();
    }

    public function niveauFidelite(): array
    {
        $points = $this->pointsFidelite();

        if ($points >= 10) {
            return ['libelle' => 'Expert', 'suivant' => null, 'palier' => 10];
        }
        if ($points >= 6) {
            return ['libelle' => 'Confirmé', 'suivant' => 10, 'palier' => 6];
        }
        if ($points >= 3) {
            return ['libelle' => 'Intermédiaire', 'suivant' => 6, 'palier' => 3];
        }

        return ['libelle' => 'Débutant', 'suivant' => 3, 'palier' => 0];
    }
}
