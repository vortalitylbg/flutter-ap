<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Role extends Model
{
    protected $table = 'role';
    protected $primaryKey = 'idrole';
    public $timestamps = false;

    protected $fillable = [
        'libellerole',
    ];

    /**
     * Retourne tous les utilisateurs ayant ce rôle.
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function utilisateurs()
    {
        return $this->hasMany(Utilisateur::class, 'idrole', 'idrole');
    }
}
