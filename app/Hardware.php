<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Hardware extends Model
{
    protected $primaryKey = 'ID';
    public function drives() {
        return $this->hasMany(Drive::class);
    }
    public function networks() {
        return $this->hasMany(Network::class);
    }
    public function software() {
        return $this->hasMany(Software::class);
    }
    public function printers() {
        return $this->hasMany(Printer::class);
    }
}
