<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Network extends Model
{
    protected $primaryKey = 'ID';
    public function hardware() {
        return $this->belongsTo(Hardware::class,'HARDWARE_ID');
    }
}
