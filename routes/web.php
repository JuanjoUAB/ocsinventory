<?php

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('index');
});

Route::get('dashboard', 'UserController@index');

Route::get('sample/equipos', 'SampleController@equipos');

// Ajax routes
Route::get('sample/dtEquipos', 'SampleController@dtEquipos');
Route::get('sample/dtEquipo/{id}', 'SampleController@dtEquipo');
