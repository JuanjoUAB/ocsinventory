<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Hardware extends Model
{
    public $primaryKey = 'ID';
    public function drives() {
        return $this->hasMany(Drive::class);
    }
}
