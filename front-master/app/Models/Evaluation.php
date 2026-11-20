<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Evaluation extends Model
{
    protected $table = 'evaluation';
    protected $primaryKey = 'idevaluation';
    public $timestamps = false;

    protected $fillable = [
        'idreservation',
        'note',
        'commentaire',
        'dateevaluation',
    ];

    protected function casts(): array
    {
        return [
            'note' => 'integer',
            'dateevaluation' => 'datetime',
        ];
    }

    public function reservation()
    {
        return $this->belongsTo(Reservation::class, 'idreservation', 'idreservation');
    }
}
