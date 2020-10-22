<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Type extends Model
{
    protected $primaryKey = 'ID';
    protected $table = 'tipos';

    public function otherData() {
        return $this->hasMany(OtherData::class, 'ESTADO');
    }
}
