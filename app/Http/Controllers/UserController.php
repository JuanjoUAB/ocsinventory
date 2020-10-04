<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index() {
        if(/*is logged*/true)
            return view('logged.dashboard');
        else {
            //TODO: Force phpCas login
        }

    }
}
