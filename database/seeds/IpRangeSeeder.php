<?php

use Illuminate\Database\Seeder;

class IpRangeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.0.0/22",
            'centre' => "PÚBLICA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.4.0/22",
            'centre' => "CNM",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.8.0/23",
            'centre' => "CVC",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.10.0/26",
            'centre' => "ICMAB (0..63)",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.10.128/25",
            'centre' => "TÉRMICA (128..255)",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.11.192/26",
            'centre' => "CIN2 (192..255)",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.15.0/26",
            'centre' => "MATGAS (0..63)",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.15.128/27",
            'centre' => "CRAG (128..159)",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.16.0/24",
            'centre' => "PROVES FW",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.17.0/24",
            'centre' => "ICMAB",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.18.0/23",
            'centre' => "ICMAB2",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.20.0/24",
            'centre' => "PROVES DHCP 2",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.23.0/24",
            'centre' => "CRM",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.28.0/22",
            'centre' => "HOTEL",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.36.0/24",
            'centre' => "IIIA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.40.0/21",
            'centre' => "CIÈNCIES NORD",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.48.0/20",
            'centre' => "CIÈNCIES",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.64.0/20",
            'centre' => "ETSE",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.79.0/24",
            'centre' => "ETSE - dEIC",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.88.0/23",
            'centre' => "UD VALL D'HEBRON ICF",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.90.0/24",
            'centre' => "UD HOSPITAL DEL MAR",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.91.0/23",
            'centre' => "CASA CONVALESCÈNCIA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.96.0/21",
            'centre' => "C EDUCACIÓ EGB",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.101.129/28",
            'centre' => "AULES EDUCACIÓ",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.104.0/21",
            'centre' => "VETERINÀRIA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.112.0/22",
            'centre' => "FTI",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.124.0/22",
            'centre' => "SAF/Eureka",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.128.0/19",
            'centre' => "LLETRES",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.160.0/23",
            'centre' => "ICTA/ICP",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.164.0/22",
            'centre' => "SI",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.168.0/23",
            'centre' => "Front-End",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.170.0/23",
            'centre' => "Back-End",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.172.0/23",
            'centre' => "Dead-End",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.174.0/23",
            'centre' => "Housing",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.182.0/23",
            'centre' => "MRA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.184.0/22",
            'centre' => "BIB HUMANITATS",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.188.0/22",
            'centre' => "WIRELESS",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.192.0/20",
            'centre' => "AULES",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.192.0/24",
            'centre' => "AULES CIÈNCIES BIOCIÈNCIES",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.193.0/24",
            'centre' => "AULES LIAM",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.194.0/24",
            'centre' => "AULES LLETRES",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.195.0/24",
            'centre' => "AULES PSICOLOGIA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.196.0/24",
            'centre' => "AULES PSICOLOGIA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.197.0/24",
            'centre' => "AULES EDUCACIÓ",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.198.0/23",
            'centre' => "AULES SOCIALS",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.200.0/23",
            'centre' => "AULES COMUNICACIÓ",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.202.0/23",
            'centre' => "AULES ENGINYERIA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.204.0/24",
            'centre' => "AULES MEDICINA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.205.0/24",
            'centre' => "AULES VETERINÀRIA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.206.0/24",
            'centre' => "AULES FTI",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.207.0/24",
            'centre' => "AULES FTI",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.208.0/21",
            'centre' => "MEDICINA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.216.0/21",
            'centre' => "CIÈNCIES COMUNICACIÓ",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.224.0/22",
            'centre' => "SOC-DRET",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.232.0/21",
            'centre' => "RECTORAT",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.240.0/22",
            'centre' => "SABADELL",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.242.0/23",
            'centre' => "AULES SABADELL",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.244.0/24",
            'centre' => "UD GTIP",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.248.0/24",
            'centre' => "UD SANT PAU",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.251.0/24",
            'centre' => "Proves Comms-SI",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.254.0/24",
            'centre' => "IGOP",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.224.0/22",
            'centre' => "DRET-PLAÇA CÍVICA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.228.0/24",
            'centre' => "DRET-PLAÇA CÍVICA",
        ]);
        DB::table('ip_ranges')->insert([
            'ip_range' => "158.109.246.0/24",
            'centre' => "UD PARC TAULÍ",
        ]);
    }
}
