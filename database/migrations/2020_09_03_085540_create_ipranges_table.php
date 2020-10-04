<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schema;

class CreateIprangesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('ip_ranges', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('ip_range', 18);
            $table->string('centre', 50);
            $table->text('comments')->nullable();
            $table->timestamps();
        });
        //php artisan db:seed --class=IpRangeSeeder
        Artisan::call('db:seed', [
            '--class' => 'IpRangeSeeder',
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('ip_ranges');
    }
}
