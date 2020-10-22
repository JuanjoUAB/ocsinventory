<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Printer extends Model
{
    protected $primaryKey = 'ID';
    protected $table = "printers";

    public function hardware() {
        return $this->belongsTo(Hardware::class, 'HARDWARE_ID');
    }
}
