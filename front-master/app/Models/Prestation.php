<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Prestation extends Model
{
    protected $table = 'prestation';
    protected $primaryKey = 'idprestation';
    public $timestamps = false;

    protected $fillable = [
        'libelleprestation',
        'montantprestation',
    ];

    protected function casts(): array
    {
        return [
            'montantprestation' => 'decimal:2',
        ];
    }

    /**
     * Retourne toutes les réservations associées à cette prestation.
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function reservations()
    {
        return $this->hasMany(Reservation::class, 'idprestation', 'idprestation');
    }
}
