<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Software extends Model
{
    protected $primaryKey = 'ID';
    protected $table = 'softwares';
    public function hardware() {
        return $this->belongsTo(Hardware::class, 'HARDWARE_ID');
    }
}
