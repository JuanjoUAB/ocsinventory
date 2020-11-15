<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddIdRangeIdToHardwareTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('hardware', function (Blueprint $table) {

            $table->bigInteger('ip_range_id', false, true)->nullable()->default( NULL)->after('IPADDR');
            $table->index('ip_range_id');
            $table->foreign('ip_range_id')->references('id')->on('ip_ranges')->onDelete('set null')->onUpdate('cascade');

        });

    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('hardware', function (Blueprint $table) {
            $table->dropForeign('hardware_ip_range_id_foreign');
            $table->dropColumn('ip_range_id');
        });
    }
}
