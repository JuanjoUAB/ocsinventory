<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class OtherData extends Model
{
    protected $primaryKey = 'HARDWARE_ID';
    protected $table = 'otrosdatospc';
    public function provider() {
        return $this->belongsTo(Provider::class, 'PROVEEDOR');
    }
    public function type() {
        return $this->belongsTo(Type::class, 'ESTADO');
    }
    public function hardware() {
        return $this->belongsTo(Hardware::class, 'HARDWARE_ID');
    }
}
