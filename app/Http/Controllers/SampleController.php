<?php

namespace App\Http\Controllers;

use App\OtherData;
use App\Printer;
use Illuminate\Http\Request;
use App\Hardware;
use App\IpRange;
use App\Network;
use App\Software;
use Carbon\Carbon;

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
        $searchPhrase = $request->search['value'];
        // Abort query execution if search string is too short
        if(!empty($searchPhrase)) {
            // Minimum two digits or 3 letters to allow a search
            if(preg_match("/^([a-z\s]{1}|\d)\$/i", $searchPhrase)) {
                return response()->json(['data' => []]);
            }
        }
        $data = Hardware::selectRaw('hardware.id,name,workgroup,userid,ipaddr,osname,oscomments,processort,processorn,processors,memory,wincompany,winowner,winprodkey,lastcome,deviceid,useragent,ip_ranges.centre')->join('ip_ranges', 'hardware.ip_range_id', 'ip_ranges.id')->where('deviceid', '<>', '_SYSTEMGROUP_');

        $numTotal = $numRecords = $data->count();

        /**
         * Applying search filters over query result as it is was simple query
         */
        if(!empty($request->search['value'])) {

            // Search by ip address part (.234 or 234.)
            if(preg_match("/\.\d{1,3}|\d{1,3}\./", $searchPhrase, $matches)) {

                $data->where('IPADDR', 'like', '%' . $searchPhrase . '%');
                $numRecords = $data->count();
                //dd($numRecords);
            }
            // Search by mac address part or numeric ip address field
            elseif(preg_match("/\d{3}|[0-9a-f]{2,}\$/i", $searchPhrase)) {
                // Search by ip address 3 digit part or 2 mac address digits (234 or bc)

                $data->where(function($query) use ($searchPhrase) {
                    $query->orWhere('IPADDR', 'like', '%' . $searchPhrase . '%')
                        ->orWhere('name', 'like', '%' . $searchPhrase . '%');
                });
                $numRecords = $data->count();
            }
            // Search by a word or part of a phrase (center or user agent)
            elseif(preg_match("/^[a-z\s]{2,}\$/i", $searchPhrase)) {
                $data->where(function($query) use ($searchPhrase) {
                    $query->orWhere('centre', 'like', '%' . $searchPhrase . '%')
                        ->orWhere('osname', 'like', '%' . $searchPhrase . '%');
                });
                $numRecords = $data->count();
                //dd($numRecords);
            }
        }

        /**
         * Applying order methods
         */
        $orderList = $request->order;
        foreach($orderList as $orderSetting) {
            $indexCol = $orderSetting['column'];
            $dir = $orderSetting['dir'];

            if(isset($request->columns[$indexCol]['data'])) {
                $colName = $request->columns[$indexCol]['data'];
                $data->orderBy($colName, $dir);
                //dd("order by col " . $colName);
            }
        }
        \DB::enableQueryLog();

        if($request->length > 0)
            $data = $data->offset($request->start)->limit($request->length);
        $data = $data->get();
        //dd(\DB::getQueryLog());
        if($data->isEmpty()) {
            return response()->json(['data'=>[]]);
        }
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
            /*if($row->ipaddr) {
                $centre = IpRange::getCentreFromIp($row->ipaddr);
                //$centre = '';
                if($centre)
                    $row->centre = $centre->centre;
                else
                    $row->centre = "Undefined";
            }
            else
                $row->centre = 'N/A';*/
            $row->processor = "[{$row->processorn}] [{$row->processort}] [{$row->processors}]";

            $daysDiff = sprintf("%d", time() - strtotime($row->lastcome)/86400);
            $daysDiff = Carbon::now()->diffInDays($row->lastcome);
            //dd($row->n);
            $row->days = $row->lastcome . " [" . $daysDiff . "]";

        }

        // Apply search string to collection results

       /* if(!empty($request->search['value'])) {
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


            $columnName = $request->columns[$order[0]]['data'];

            if($order[1] == 'asc')
                $sorted = $data->sortBy($columnName);
            else
                $sorted = $data->sortByDesc($columnName);
            //dd($collectionKeys[$order[0]]);
            //$sorted->values()->all();
            //dd($sorted);
            $data = $sorted->values();
            //dd($data);

            //$data = $sorted;
        }*/
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
