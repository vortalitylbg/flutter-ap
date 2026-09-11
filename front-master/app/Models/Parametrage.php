<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Parametrage extends Model
{
    protected $table = 'parametrage';
    protected $primaryKey = 'idparam';
    public $timestamps = false;

    protected $fillable = [
        'libelleparam',
        'valeurparam',
        'uniteparam',
    ];

    /**
     * Retourne la valeur d'un paramètre par son libellé.
     * @param string $libelle
     * @return string|null
     */
    public static function getValeur(string $libelle): ?string
    {
        return self::where('libelleparam', $libelle)->value('valeurparam');
    }
}
