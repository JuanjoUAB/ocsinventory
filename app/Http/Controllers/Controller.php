<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;

class Controller extends BaseController
{
    use AuthorizesRequests, DispatchesJobs, ValidatesRequests;

    /**
     * Checks request data validation for data tables server side request
     * @link https://datatables.net/manual/server-side
     */
    protected function checkDataTablesRules() {
        $rules = [
            'draw' => 'required|numeric|min:1',
            'start' => 'required|numeric|min:0',
            'length' => 'required|numeric|min:-1', //-1 means all records, > 1 the pagination records
            'search.value' => 'present|nullable|string',
            'search.regex' => 'present|string|in:true,false',
            'order.*.column' => 'required|numeric|min:0',
            'order.*.dir' => 'required|string|in:asc,desc',
            'columns.*.data' => 'present|nullable|string',
            'columns.*.name' => 'present|nullable|string',
            'columns.*.searchable' => 'required|string|in:true,false',
            'columns.*.orderable' => 'required|string|in:true,false',
            'columns.*.search.value' => 'present|nullable|string',
            'columns.*.search.regex' => 'required|string|in:true,false'
        ];
        request()->validate($rules);
    }

    protected function responseDataTables(array $data, int $draw, int $total, int $totalFiltered) {
        $dataSend = array();
        $dataSend['draw'] = $draw;
        $dataSend['recordsTotal'] = $total;
        $dataSend['recordsFiltered'] = $totalFiltered;
        $dataSend['data'] = $data;
        return response()->json($dataSend);
    }
}
