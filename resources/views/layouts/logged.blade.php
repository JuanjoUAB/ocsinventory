<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="content-type" content="text/html">

<title>OCS Inventory - @yield('title')</title>
<link rel="shortcut icon" href="{{ url('img/favicon.png') }}" />
{{--
<link rel="stylesheet" type="text/css" href="{{ url('css/inventario.css') }}">
<link rel="stylesheet" type="text/css" href="{{ url('css/theme.blue.css') }}">
<link rel="stylesheet" type="text/css" href="{{ url('css/jquery-ui.css') }}">
<link rel="stylesheet" type="text/css" href="{{ url('css/tablesorter-groups.css') }}">
<link rel="stylesheet" href="{{ url('css/font-awesome.min.css') }}">
--}}
    <!-- Bootstrap link: https://getbootstrap.com/docs/4.4/getting-started/download/ -->
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">

    <!-- DataTables link: https://datatables.net/download/ -->
    <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/dt/jszip-2.5.0/dt-1.10.22/b-1.6.5/b-colvis-1.6.5/b-flash-1.6.5/b-html5-1.6.5/b-print-1.6.5/datatables.min.css"/>
{{--
<style>
label {
    display: inline;
    margin-left: 50px;
		font-size: 16px;
		font-weight: normal;
	}
	#mostrar {
		border: 1px solid;
		border-radius: 3px;
		cursor: pointer;
		font-size: 16px;
		height: 36px;
		margin-bottom: 10px;
		padding: 4px;
	}
</style>
--}}



{{--
<script src="{{ url('lib/jquery.tablesorter.min.js') }}"></script>
<script src="{{ url('lib/jquery.tablesorter.widgets.min.js') }}"></script>
<script src="{{ url('lib/widgets/widget-grouping.js') }}"></script>
<script src="{{ url('lib/widgets/widget-stickyHeaders.min.js') }}"></script>
<script src="{{ url('lib/parsers/parser-network.min.js') }}"></script>

<script src="{{ url('js/inventario.js') }}"></script>
<script>
	var titulo = 'Listado equipos';

	function mostrar (modo){
        $("#tequipos").remove();
        var llamada = document.createElement('script');
        document.getElementById('cuadroespera').style.display='inline';
        llamada.src = '/perl/inventario/equipos.pl?modo='+modo;
        document.body.appendChild(llamada);
        llamada.parentNode.removeChild(llamada);
    }

	function mExcel () {
        var modo = $("#mostrar").val();
        exportar('listadoequgen.pl?modo=' + modo);
    }
</script>
--}}
    <!-- Link: https://codepen.io/surjithctly/pen/PJqKzQ -->
<style>
    .dropdown-submenu {
    position: relative;
    }

    .dropdown-submenu a::after {
    transform: rotate(-90deg);
    position: absolute;
    right: 6px;
    top: .8em;
    }

    .dropdown-submenu .dropdown-menu {
    top: 0;
    left: 100%;
    margin-left: .1rem;
    margin-right: .1rem;
    }
</style>

</head>

<body>
<!-- cabecera moderna -->
{{--
<div id="cabecera" style="position:relative">
	<script src="{{ url('js/cabecera.js') }}"></script>
</div>
--}}

<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <a class="navbar-brand" href="#">OCS Inventory</a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
        <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbarSupportedContent">
        <ul class="navbar-nav mr-auto">
            <li class="nav-item active">
                <a class="nav-link" href="#">Home <span class="sr-only">(current)</span></a>
            </li>
            <li class="nav-item dropdown">
                <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                    Listados
                </a>
                <div class="dropdown-menu" aria-labelledby="navbarDropdown">
                    <a class="dropdown-item" href="#">Equipos</a>
                    <a class="dropdown-item" href="#">Equipos con selección</a>
                    <div class="dropdown-divider"></div>
                    <a class="dropdown-item" href="#">Aplicaciones</a>
                    <div class="dropdown-divider"></div>
                    <a class="dropdown-item" href="#">Impresoras</a>
                    <a class="dropdown-item" href="#">Impresoras por pc</a>
                    <div class="dropdown-divider"></div>
                    <a class="dropdown-item" href="#">Monitores</a>
                    <a class="dropdown-item" href="#">Dispositivos</a>
                    <a class="dropdown-item" href="#">Dispositivos deconocidos</a>
                    <a class="dropdown-item" href="#">Dispositivos SNMP</a>
                    <a class="dropdown-item" href="#">Dispositivos nuevos</a>
                </div>
            </li>
            <li class="nav-item dropdown">
                <a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                    Administración
                </a>
                <div class="dropdown-menu" aria-labelledby="navbarDropdown">
                    <a class="dropdown-item" href="#">Otros datos PC</a>
                    <div class="dropdown-divider"></div>
                    <div class="dropdown-submenu">
                        <a class="dropdown-item dropdown-toggle" href="#">Dispositivos</a>
                        <div class="dropdown-menu">
                            <a class="dropdown-item" href="#">Modificar</a>
                            <a class="dropdown-item" href="#">Registrar</a>
                        </div>
                    </div>
                    <a class="dropdown-item" href="#">Dispositivos SC</a>
                    <div class="dropdown-divider"></div>
                    <div class="dropdown-submenu">
                        <a class="dropdown-item dropdown-toggle" href="#">Proveedores</a>
                        <div class="dropdown-menu">
                            <a class="dropdown-item" href="#">Modificar proveedores</a>
                            <a class="dropdown-item" href="#">Modificar contactos</a>
                        </div>
                    <div class="dropdown-divider"></div>
                    <a class="dropdown-item" href="#">Modificar documentos</a>
                </div>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="#">Configuración</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="#">Usuarios</a>
            </li>
            <li class="nav-item">
                <a class="nav-link disabled" href="#" tabindex="-1" aria-disabled="true">Disabled</a>
            </li>
        </ul>

        <div class="navbar-nav navbar-right">
            <a href="logout" class="btn btn-outline-success my-2 my-sm-0" role="button">Close session</a>
        </div>
    </div>
</nav>

@yield('content')
<!-- jQuery link: http://code.jquery.com -->
<script src="https://code.jquery.com/jquery-3.5.1.min.js" integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" crossorigin="anonymous"></script>
<script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" integrity="sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU=" crossorigin="anonymous"></script>
<!-- Bootstrap link: https://getbootstrap.com/docs/4.4/getting-started/download/ -->
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>
<!-- DataTables link: https://datatables.net/download/ -->
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.36/pdfmake.min.js"></script>
<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.1.36/vfs_fonts.js"></script>
<script type="text/javascript" src="https://cdn.datatables.net/v/dt/jszip-2.5.0/dt-1.10.22/b-1.6.5/b-colvis-1.6.5/b-flash-1.6.5/b-html5-1.6.5/b-print-1.6.5/datatables.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.3/jszip.min.js" type="text/javascript"></script>

<!-- Jquery blockUI link: https://cdnjs.com/libraries/jquery.blockUI -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.blockUI/2.70/jquery.blockUI.min.js" integrity="sha512-eYSzo+20ajZMRsjxB6L7eyqo5kuXuS2+wEbbOkpaur+sA2shQameiJiWEzCIDwJqaB0a4a6tCuEvCOBHUg3Skg==" crossorigin="anonymous"></script>
<script type="text/javascript" src="{{ url('js/helpers.js') }}"></script>
<!-- Link: https://codepen.io/surjithctly/pen/PJqKzQ -->
<script>
    $('.dropdown-menu a.dropdown-toggle').on('click', function(e) {
        if (!$(this).next().hasClass('show')) {
            $(this).parents('.dropdown-menu').first().find('.show').removeClass("show");
        }
        var $subMenu = $(this).next(".dropdown-menu");
        $subMenu.toggleClass('show');


        $(this).parents('li.nav-item.dropdown.show').on('hidden.bs.dropdown', function(e) {
            $('.dropdown-submenu .show').removeClass("show");
        });

        return false;
    });
</script>
@yield('bottom_javascript')
</body>
</html>
