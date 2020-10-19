<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Hardware;
use App\IpRange;
use App\Network;
use App\Software;

class SampleController extends Controller
{
    public function equipos() {

        return view('samples.equipos');
    }

    /**
     * Old perl script: equipos.pl
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function dtEquipos(Request $request) {
        if(!$request->wantsJson()) {
            abort(404, 'Bad request');
        }
        self::checkDataTablesRules();
        $data = Hardware::selectRaw('id,name,workgroup,userid,ipaddr,osname,oscomments,processort,processorn,processors,memory,wincompany,winowner,winprodkey,lastcome,deviceid,useragent')->where('deviceid', '<>', '_SYSTEMGROUP_');

        $numTotal = $numRecords = $data->count();
        if($request->length > 0)
            $data = $data->offset($request->start)->limit($request->length);
        $data = $data->get();
        //dd($data->first());

        foreach($data as $row) {
            $despacio = $dlibre = "";

            $drives = Hardware::find($row->id)->drives;

            foreach($drives as $drive) {

                if (stripos($row->useragent, "windows") !== false && stripos($drive->TYPE, 'Hard drive') !== false) {
                    $despacio .= $drive->LETTER . " ". sprintf("%.0f", $drive->TOTAL / 1024) . " GB<br>";
                    $dlibre .= $drive->LETTER . " " . sprintf("%.0f", $drive->FREE / 1024) . " GB<br>";
                } elseif (stripos($row->useragent, "unix") !== false || stripos($row->useragent, "android") !== false) {
                    $despacio .= $drive->TYPE . " " . sprintf("%.0f", $drive->TOTAL / 1024) . " GB<br>";
                    $dlibre .= $drive->TYPE . " " . sprintf("%.0f", $drive->FREE / 1024) . " GB<br>";
                }
            }


            $row->hddspace = $despacio;
            $row->hddfree = $dlibre;
            if($row->ipaddr) {
                $centre = IpRange::getCentreFromIp($row->ipaddr);
                //$centre = '';
                if($centre)
                    $row->centre = $centre->centre;
                else
                    $row->centre = "Undefined";
            }
            else
                $row->centre = 'N/A';
            $row->processor = "[{$row->processorn}] [{$row->processort}] [{$row->processors}]";
            $row->days = sprintf("%d", time() - strtotime($row->lastcome)/86400);
        }
        if(request()->wantsJson()) {
            return self::responseDataTables($data->toArray(), (int)$request->draw, $numTotal, $numRecords);

        }
    }

    /**
     * Gets a device specific data from it's id in DataTable format
     * Old perl script: pc_u.pl
     * @param int $id The hardware id
     * @return \Illuminate\Http\JsonResponse
     */
    public function dtEquipo(int $id) {
        $data = Hardware::selectRaw('bios.smanufacturer, bios.smodel, bios.type, bios.ssn, hardware.osname,hardware.oscomments,hardware.workgroup, hardware.id')->whereId($id)->join('bios', 'bios.hardware_id', '=', 'hardware.id')->first();

        if(strpos($data->type, 'vmware') !== false)
            $data->type = "Virtual";
        return response()->json([
            'data' => [$data]
        ]);
    }

    /**
     * Gets a device specific data from it's id in DataTable format
     * Old perl script: redes_u.pl
     * @param int $id The hardware id
     * @return \Illuminate\Http\JsonResponse
     */
    public function dtNetwork(int $id) {
        $data = Network::selectRaw('description,speed,macaddr,ipaddress,ipgateway,status,ipdhcp')->whereHardwareId($id)->get();
        $dhcp = '';

        foreach($data as $row) {

            $dhcp = ($row->ipdhcp == "255.255.255.255") ? $row->ipdhcp : $dhcp . $row->ipdhcp;
            $row->ipdhcp = $dhcp;
        }

        return response()->json([
            'data' => $data->toArray()
        ]);
    }

    /**
     * Gets a device specific data from it's id in DataTable format
     * Old perl script: aplicaciones_u.pl
     * @param int $id The hardware id
     * @return \Illuminate\Http\JsonResponse
     */
    public function dtApplication(int $id) {
        $data = Software::selectRaw('publisher,name,version,folder,comments')->whereHardwareId($id)->get();

        foreach($data as $row) {
            $row->publisher = (empty($row->publisher)) ? "N/D" : $row->publisher;
        }

        return response()->json([
            'data' => $data->toArray()
        ]);
    }

    /**
     * Gets a device specific data from it's id in DataTable format
     * Old perl script: impresoras_u.pl
     * @param int $id The hardware id
     * @return \Illuminate\Http\JsonResponse
     */
    public function dtPrinter(int $id) {
        $data = Hardware::selectRaw('bios.smanufacturer, bios.smodel, bios.type, bios.ssn, hardware.osname,hardware.oscomments,hardware.workgroup, hardware.id')->whereId($id)->join('bios', 'bios.hardware_id', '=', 'hardware.id')->first();

        if(strpos($data->type, 'vmware') !== false)
            $data->type = "Virtual";
        return response()->json([
            'data' => [$data]
        ]);
    }

    /**
     * Gets a device specific data from it's id in DataTable format
     * Old perl script: otrospc_u.pl
     * @param int $id The hardware id
     * @return \Illuminate\Http\JsonResponse
     */
    public function dtOther(int $id) {
        $data = Hardware::selectRaw('bios.smanufacturer, bios.smodel, bios.type, bios.ssn, hardware.osname,hardware.oscomments,hardware.workgroup, hardware.id')->whereId($id)->join('bios', 'bios.hardware_id', '=', 'hardware.id')->first();

        if(strpos($data->type, 'vmware') !== false)
            $data->type = "Virtual";
        return response()->json([
            'data' => [$data]
        ]);
    }
}
