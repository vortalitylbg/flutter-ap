<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Reservation extends Model
{
    protected $table = 'reservation';
    protected $primaryKey = 'idreservation';
    public $timestamps = false;

    protected $fillable = [
        'idutilisateur',
        'idprestation',
        'datedebut',
        'heuredebut',
        'validationpresence',
        'evaluation_invitee_at',
    ];

    protected function casts(): array
    {
        return [
            'datedebut' => 'date',
            // Castée en datetime pour bénéficier du formatage Carbon (H:i)
            'heuredebut' => 'datetime:H:i',
            'validationpresence' => 'boolean',
        ];
    }

    /**
     * Retourne l'utilisateur associé à cette réservation.
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function utilisateur()
    {
        return $this->belongsTo(Utilisateur::class, 'idutilisateur', 'idutilisateur');
    }

    /**
     * Retourne la prestation associée à cette réservation.
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function prestation()
    {
        return $this->belongsTo(Prestation::class, 'idprestation', 'idprestation');
    }

    /**
     * Retourne l'évaluation associée à cette réservation.
     * @return \Illuminate\Database\Eloquent\Relations\HasOne
     */
    public function evaluation()
    {
        return $this->hasOne(Evaluation::class, 'idreservation', 'idreservation');
    }
}
