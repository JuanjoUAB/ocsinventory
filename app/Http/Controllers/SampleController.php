<?php

namespace App\Http\Controllers;

use App\OtherData;
use App\Printer;
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
     * View to render the full devices section and to return the DataTables pagination server side data based on request variables
     *
     * Old perl script: equipos.pl
     * @author DRC
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


        $collectionKeys = array_keys($data->first()->toArray());
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

        // Apply search string to collection results

        if(!empty($request->search['value'])) {
            //TODO: Implement search function over collection
            $searchPhrase = $request->search['value'];
            $data = $data->filter(function($device, $key) use ($searchPhrase) {
                foreach($device as $keys=>$value) {
                    if (strpos($searchPhrase, $value) !== false) {
                        return $value;
                    }
                }
            });

            $numRecords = $data->count();
            $data->all();
        }

        // Apply order settings
        $orderIndexes = array();
        foreach($request->order as $order) {
            $orderIndexes[] = [
                (int)$order['column'],
                $order['dir']
            ];
        }
//dd($collectionKeys);
        //$data = collect($data->toArray());
        //dd($data);
        //dd($orderIndexes);
        //dd($orderIndexes);
//dump($data);
        foreach($orderIndexes as $order) {

            $order[0] = '4';
            //dd($order[0]);
            if($order[1] == 'asc')
                $sorted = $data->sortBy($collectionKeys[$order[0]]);
            else
                $sorted = $data->sortByDesc($collectionKeys[$order[0]]);
            //dd($collectionKeys[$order[0]]);
            //$sorted->values()->all();
            //dd($sorted);
            $data = $sorted->values();
            //dd($data);

            //$data = $sorted;
        }
//dd($data->toArray());
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
        $data = Printer::select('name', 'driver', 'port')->whereHardwareId($id)->get();


        return response()->json([
            'data' => $data->toArray()
        ]);
    }

    /**
     * Gets a device specific data from it's id in DataTable format
     * Old perl script: otrospc_u.pl
     * @param int $id The hardware id
     * @return \Illuminate\Http\JsonResponse
     */
    public function dtOther(int $id) {

        $data = OtherData::selectRaw('proveedores.nombre AS prov,otrosdatospc.pedido,otrosdatospc.factura,otrosdatospc.fechacompra,otrosdatospc.fingarantia,tipos.nombre AS type,otrosdatospc.notas')
            ->join('tipos', 'otrosdatospc.ESTADO', 'tipos.ID')
            ->join('proveedores', 'otrosdatospc.PROVEEDOR', 'proveedores.id')
            ->whereHardwareId($id)->get();


        return response()->json([
            'data' => $data->toArray()
        ]);
    }
}
