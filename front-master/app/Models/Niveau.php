<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Niveau extends Model
{
    protected $table = 'niveau';
    protected $primaryKey = 'idniveau';
    public $timestamps = false;

    protected $fillable = ['libniveau'];

    public function utilisateurs()
    {
        return $this->hasMany(Utilisateur::class, 'idniveau', 'idniveau');
    }
}
