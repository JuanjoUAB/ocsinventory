<!doctype html>
<html>
<!--
TITLE:		Listados Inventario OCS
AUTHOR:		José Serena
DATE:		14/07/2014
VERSION:	3.0
CONTRIBUTOR:Daniel Requena Cevantes
LAST UPDATE:23/09/2020
-->
<head>
    <meta charset="utf-8">

    <title>{{ env('APP_NAME') }}</title>

    <link rel="stylesheet" type="text/css" href="{{ url('css/inventario.css') }}">
    <link rel="stylesheet" type="text/css" href="{{ url('css/theme.blue.css') }}">

    <style>
        body { background-image:url('img/control1.jpg'); }
        ul#nav {margin: 20px 0 0 100px; font-family: Verdana; font-size: 14px; text-decoration: none;}
        ul.drop a { display:block; color: #fff; text-decoration: none;}
        ul.drop, ul.drop li, ul.drop ul { list-style: none; margin: 0; padding: 0; border: 1px solid #fff; background: #555; color: #fff;}
        ul.drop { position: relative; z-index: 597; float: left; }
        ul.drop li { width: 150px; line-height: 1.3em; vertical-align: middle; zoom: 1; padding: 10px 10px; }
        ul.drop ul li { width: 300px; }
        ul.drop li.hover, ul.drop li:hover { position: relative; z-index: 599; cursor: default; background: #1e7c9a; }
        ul.drop ul { visibility: hidden; position: absolute; top: -2px; left: 100%; z-index: 598; background: #555; border: 1px solid #fff; }
        ul.drop li:hover > ul { visibility: visible }
        img { border: 0; margin-left: 17px; }
        #linea { width:100%; height:50px; background-color:#000000; margin-bottom:5px;}
        #titulo { float:left; width:45%; color:white; font-weight:bold; font-size:30px; line-height:50px; margin-left:20px; }
        #logo { width:30%; }
        #logo img { height:50px; }
        #exit { width:25%; }
    </style>
</head>

<body>
<div id="contenido">
    <!-- cabecera moderna -->
    <div id="cabecera" style="position:relative">
        <div id="linea">
            <span id="titulo">Inventario de dispositivos en red</span>
            <span id="logo"><img src="{{ url('img/logoUAB-BN.png') }}"></span>
            <span id="exit">&nbsp;</span>
        </div>
    </div>
    <div>
        <!--<IMG style="margin-left:0px;margin-top:20px;" SRC="inventario/imagenes/logo_escuda2.jpg" ALT="logo">-->
    </div>

    <ul id="nav" class="drop" style="margin-left:0px;">
        <li><a href="https://ocsuabt.uab.cat/ocsreports">OCS Inventory NG</a></li>
        <li><a href="{{ url('dashboard') }}">Listados y utilidades</a></li>
        <li><a href="{{ url('sample/equipos') }}">NEW: Exemple de mostra 2020!</a></li>
        <!--<li><a href="/phpmyadmin">Administració Base de dades</a></li>-->
    </ul>

    <!-- Detectar si JS esta activado -->
    <noscript>
        <style type="text/css">
            #content {display:none;}
        </style>
        <div class="avisonojs">
            Es necesario activar JavaScript para usar esta aplicación.
        </div>
    </noscript>
</div>
</body>
</html>

