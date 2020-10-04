<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Drive extends Model
{
    public $primaryKey = 'ID';
    public function hardware() {
        return $this->belongsTo(Hardware::class,'HARDWARE_ID');
    }
}
