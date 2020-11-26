@extends('layouts/logged')

@section('title', 'Equipos')

@section('hidden')
    <div id="contenido">
        <div>
            <button type="button" name="Inicio" onClick="window.location.href='/inventario/menu.php'"><i class="fa fa-home fa-lg"></i> Inicio</button>
            <button type = "button" name = "Exportar" class = "bexcel" onClick = "mExcel()">Exportar a Excel</button>
            <button type = "button" style="margin-left: 30px;" class = "borrafiltros"><i class="fa fa-filter fa-lg"></i> Borrar Filtros</button>
            <label>Ver </label>
            <select name="mostrar" id="mostrar" onchange="mostrar(this.value)">
                <option value="0" selected>Todos</option>
                <option value="1">Unicos</option>
                <option value="2">Duplicados</option>
            </select>
        </div>

        <!-- marco ocultable con mensaje espera -->
    <!-- <div id="cuadroespera" class='cuadroespera'>
<table><tr>
<td><img src="{{ url('img/relojarena.gif') }}" alt="reloj"></td>
<td class='texespera'>Generando el listado...</td>
</tr></table>
</div> -->

        <!-- Cuadro Dialogo-UI para ver los datos del PC  -->
        <div id="datospc">
            <table class='tablesorter-blue'>
                <thead>
                <tr><th>Marca</th><th>Modelo</th><th>Tipo</th><th>Num Serie</th><th>Sistema</th><th>SP</th><th>Dominio</th></tr>
                </thead>
                <tbody>
                <tr id="tr1pc"><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
                </tbody>
            </table>
        </div>

        <!-- Cuadro Dialogo-UI para ver las redes del PC  -->
        <div id="redespc">
            <table class='tablesorter-blue'>
                <thead>
                <tr><th>IP</th><th>Mac</th><th>Mhz</th><th>Estado</th><th>GW</th><th>DHCP</th><th>Descripci&oacute;n</th></tr>
                </thead>
                <tbody>
                <tr id="tr1red"><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
                </tbody>
            </table>
        </div>

        <!-- Cuadro Dialogo-UI para ver los datos adicionales del PC  -->
        <div id="otrosdatospc">
            <table class='tablesorter-blue'>
                <thead>
                <tr><th>Proveedor</th><th>Pedido</th><th>Factura</th><th>Fecha Compra</th><th>Fin Garant&iacute;a</th><th>Estado</th><th>Notas</th></tr>
                </thead>
                <tbody>
                <tr id="tr1otrospc"><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
                </tbody>
            </table>
        </div>
        <script>
            // ocultar las tablas auxiliares para datos pc
            // cuadro datoscpc
            $( "#datospc" ).dialog({
                autoOpen: false,
                width: "80%",
            });
            // cuadro redespc
            $( "#redespc" ).dialog({
                autoOpen: false,
                width: "80%",
            });
            // cuadro otrosdatoscpc
            $( "#otrosdatospc" ).dialog({
                autoOpen: false,
                width: "80%",
            });

            //centrarEspera ();
        </script>

        <!-- <script src="/perl/inventario/equipos.pl"></script>  -->

        <div id="esptabla">
        </div>

        <script>
            function datoscargados() {
                esperarCargaPagina();

                $("#tequipos").tablesorter( {
//   	showProcessing: true,
                    widgets: [ "filter", "group", 'stickyHeaders' ],
                    widgetOptions: {
                        filter_columnFilters : true,
                        filter_reset : 'button.borrafiltros',
                        filter_searchDelay : 300,
                        // n es el numero de dias devuelto por nuestro parser parser-diasuc
                        // f es el valor introducido en el filtro
                        // la columna 14 es la fecha ultimo contacto
                        filter_functions : {
                            14 : function(e, n, f, i) {
                                var dias = /\[(\d+)\]/.exec(e)[1];

                                var fl = parseInt(f.replace( /\D+/g, ''));
                                if ( /^>/.test(f) ) {
                                    return dias >= fl;
                                } else {
                                    return dias <= fl;
                                }
                            }
                        },

                        group_collapsible : true,  // hacer clicable la cabecera del grupo y colapsar las filas por debajo de ella.
                        group_collapsed   : true, // comenzar con todos los grupos colapsados (si cierto)
                        group_saveGroups  : false,  // recordar los grupos colapsados
//			group_saveReset   : '.group_reset', // elemento para borrar los grupos colapsados guardados
                        group_count       : " ({num})", // si no falso, el texto "{num}" se reemplaza con el numero de filas del grupo
                        group_complete    : "groupingComplete",
                        group_separator   : '\n',
                    }
                })
                    .bind('filterEnd', { tabla: 'tequipos', texto: 'Nombre' }, finFiltro)
                    .bind('groupingComplete', { tabla: 'tequipos', texto: 'Nombre' }, finAgrupar);

                $("#tequipos").tablesorter().bind('groupingStart', function() {
                    $('#cuadroespera').find('td:eq(1)').html('Agrupando ...');
                    centrarEspera ();
                    $('#cuadroespera').show();
                });

                // gestion clics info adicional
                $('#tabla').click(function(event){
                    var $target = $(event.target);
                    var id = $target.closest("tr").attr("id");
                    var estacion = $target.closest("tr").find("td:eq(0)").html();
                    if($target.is('.tdpc')){
                        verPC(id, estacion)
                    } else if($target.is('.tdred')){
                        verRed(id, estacion)
                    } else if($target.is('.tdimp')){
                        verImpre(id, estacion)
                    } else if($target.is('.tdapli')){
                        verApli(id, estacion)
                    } else if($target.is('.tdotros')){
                        verOtros(id, estacion)
                    }
                });
            }

            if ( window.location.search ) {
                //document.write( '<script src="{{ url('perl/equiposfiltrado.pl') }}"' + window.location.search + '"></' + 'script>' ); // hay que separar el tag fin script para que funcione
            } else {
                //document.write( '<script src="{{ url('perl/equipos.pl') }}"></' + 'script>' );
            }
        </script>

    </div><!-- //id=contenido -->
    @endsection
@section('content')
<div class="content">
    <h1>Listado de equipos</h1>
    <hr>
    <div class="table-responsive">
    <table id="devices" class="table table-striped table-bordered small" style="width:100%">
        <thead>
        <tr>
            <th>MAC</th>
            <th>Login</th>
            <th>Centro</th>
            <th>[nCpu][CPU][MHz]</th>
            <th>RAM</th>
            <th>HDD</th>
            <th>Free HDD</th>
            <th>IP</th>
            <th>SO</th>
            <th>PC</th>
            <th>Redes</th>
            <th>Aplicaciones</th>
            <th>Impresoras</th>
            <th>Otros</th>
            <th>Fecha contacto [0-1080]</th>
        </tr>
        </thead>
        {{--
        <tbody>
        @foreach($data as $row)
        <tr id="{{ $row->id }}">
            <td>{{ $row->name }}</td>
            <td>{{ $row->userid }}</td>
            <td>{{ $row->centro }}</td>
            <td>[{{ $row->processorn }}] [{{ $row->processort }}] [{{ $row->processors }}]</td>
            <td>{{ $row->memory }}</td>
            <td>{{ $row->hddspace }}</td>
            <td>{{ $row->hddfree }}</td>
            <td>{{ $row->ipaddress }}</td>
            <td>{{ $row->osname }} [{{ $row->oscomments }}]</td>
            <td class="tdpc">PC</td>
            <td class="tdred">Red</td>
            <td class="tdapli">Aplicaciones</td>
            <td class="tdimp">Impresoras</td>
            <td class="tdotros">Otros</td>
            <td>{{ $row->lastcome }} [{{ $row->days }}]</td>
        </tr>
        @endforeach
        </tbody>
        --}}
    </table>
    </div>
</div><!-- //content -->

<div id="modal-device" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Modal title</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <h1>Datos de un equipo</h1>
                <hr>
                <div class="table-responsive">
                    <!-- Data loaded from pc_u.pl-->
                    <table id="device" class="table table-striped table-bordered" style="width:100%">
                        <thead>
                        <tr>
                            <th>Marca</th>
                            <th>Modelo</th>
                            <th>Tipo</th>
                            <th>Num serie</th>
                            <th>Sistema</th>
                            <th>SP</th>
                            <th>Dominio</th>
                        </tr>
                        </thead>
                    </table>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary">Save changes</button>
            </div>
        </div>
    </div>
</div><!-- //modal-device -->

<div id="modal-network" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Modal title</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <h1>Datos de un equipo</h1>
                <hr>
                <div class="table-responsive">
                    <!-- Data loaded from pc_u.pl-->
                    <table id="network" class="table table-striped table-bordered" style="width:100%">
                        <thead>
                        <tr>
                            <th>IP</th>
                            <th>Mac</th>
                            <th>MHz</th>
                            <th>State</th>
                            <th>GW</th>
                            <th>DHCP</th>
                            <th>Description</th>
                        </tr>
                        </thead>
                    </table>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary">Save changes</button>
            </div>
        </div>
    </div>
</div><!-- //modal-network -->

<div id="modal-apps" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Modal title</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <h1>Datos de un equipo</h1>
                <hr>
                <div class="table-responsive">
                    <!-- Data loaded from pc_u.pl-->
                    <table id="apps" class="table table-striped table-bordered" style="width:100%">
                        <thead>
                        <tr>
                            <th>Name [ ]</th>
                            <th>Company</th>
                            <th>Version</th>
                            <th>Folder</th>
                            <th>Comments</th>
                        </tr>
                        </thead>
                    </table>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary">Save changes</button>
            </div>
        </div>
    </div>
</div><!-- //modal-apps -->
<div id="modal-printers" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Modal title</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <h1>Datos de un equipo</h1>
                <hr>
                <div class="table-responsive">
                    <!-- Data loaded from pc_u.pl-->
                    <table id="printers" class="table table-striped table-bordered" style="width:100%">
                        <thead>
                        <tr>
                            <th>Nombre</th>
                            <th>Controlador</th>
                            <th>Puerto</th>
                        </tr>
                        </thead>
                    </table>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary">Save changes</button>
            </div>
        </div>
    </div>
</div><!-- //modal-printers -->

<div id="modal-others" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Modal title</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <h1>Datos de un equipo</h1>
                <hr>
                <div class="table-responsive">
                    <!-- Data loaded from pc_u.pl-->
                    <table id="others" class="table table-striped table-bordered" style="width:100%">
                        <thead>
                        <tr>
                            <th>Provider</th>
                            <th>Order</th>
                            <th>Invoice</th>
                            <th>Date purchase</th>
                            <th>End warranty</th>
                            <th>State</th>
                            <th>Note</th>
                        </tr>
                        </thead>
                    </table>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary">Save changes</button>
            </div>
        </div>
    </div>
</div><!-- //modal-others -->
@endsection
@section('bottom_javascript')
<script>
    $(document).ready(function () {

        $.fn.dataTable.ext.errMode = 'throw';
        let _table = $('#devices').DataTable({
            //searching: false,
            serverSide: true,
            ajax: "{{ url('sample/dtEquipos') }}",
            columns: [
                { data : 'name' },
                { data : 'userid' },
                { data : 'centre' },
                { data : 'processor' },
                { data : 'memory' },
                { data : 'hddspace', orderable: false},
                { data : 'hddfree', orderable: false },
                { data : 'ipaddr' },
                { data : 'osname' },
                { data : '_device', // Device column
                    render: function(data, type, row) {
                        return '<button type="button" class="btn btn-success btn-sm device-data" data-id="' + row.id + '">Mostrar</button>';
                    },
                    orderable: false
                },
                {
                    data: '_network', // Network column
                    render: function(data, type, row) {
                        return '<button type="button" class="btn btn-success btn-sm network-data" data-id="' + row.id + '">Mostrar</button>';
                    },
                    orderable: false
                },
                {
                    data: '_apps', // Applications column
                    render: function(data, type, row) {
                        return '<button type="button" class="btn btn-success btn-sm app-data" data-id="' + row.id + '">Mostrar</button>';
                    },
                    orderable: false
                },
                {
                    data: '_printers', // Printers column
                    render: function(data, type, row) {
                        return '<button type="button" class="btn btn-success btn-sm printer-data" data-id="' + row.id + '">Mostrar</button>';
                    },
                    orderable: false
                },
                {
                    data: '_others', // Others column
                    render: function(data, type, row) {
                        return '<button type="button" class="btn btn-success btn-sm other-data" data-id="' + row.id + '">Mostrar</button>';
                    },
                    orderable: false
                },
                { data : 'days'},

            ],
            /*
            columnDefs: [
                {
                    targets: 10,
                    className: 'tdpc',
                    data: null,
                    defaultContent: '<button type="button" class="btn btn-success device-data">Datos PC</button>',
                }
            ],*/
            dom: 'Blfrtip',
            lengthMenu: [[10, 25, 50, -1], [10, 25, 50, "All"]],
            buttons: [
                {
                    extend: 'excelHtml5',
                    text: 'Exportar a Excel',
                    exportOptions: {
                        modifier: {
                            page: 'all'
                        }
                    }
                }
            ],


        }).on('xhr.dt', function(e, settings, json, xhr) {
            //console.log("*********", xhr);
            let jsonResp = JSON.parse(xhr.responseText);
            if(jsonResp['errors'] !== undefined) {
                alert("Error processing data");
            }
        }).on('draw', () => {
            //console.log("Dt drawn");
            $('.device-data').click('button', function() {

                let dataId = $(this).data('id');
                console.log("Clicked id!", dataId);
                showDataInModalDT($(this).data('mac'), 'modal-device', function() {
                    let url = "{{ url('sample/dtEquipo/:id') }}";
                    url = url.replace(':id', dataId);
                    $('#device').DataTable({
                        retrieve: true,
                        paging:   false,
                        ordering: false,
                        info:     false,
                        searching: false,
                        ajax: url,
                        columns: [
                            {data: 'smanufacturer'},
                            {data: 'smodel'},
                            {data: 'type'},
                            {data: 'ssn'},
                            {data: 'osname'},
                            {data: 'oscomments'},

                            {data: 'workgroup'}
                        ]
                    }).on('init', function() {
                        //$.blockUI();
                    }).on('draw', function() {
                        console.log("Loaded submodal dt");
                        //.unblockUI();
                    });
                }, function() {
                    $('#device').DataTable().destroy();
                });
            });
            $('.network-data').click('button', function() {

                let dataId = $(this).data('id');
                console.log("Clicked id!", dataId);
                showDataInModalDT($(this).data('mac'), 'modal-network', function() {
                    let url = "{{ url('sample/dtNetwork/:id') }}";
                    url = url.replace(':id', dataId);
                    $('#network').DataTable({
                        retrieve: true,
                        paging:   false,
                        ordering: false,
                        info:     false,
                        searching: false,
                        ajax: url,
                        columns: [
                            {data: 'ipaddress'},
                            {data: 'macaddr'},
                            {data: 'speed'},
                            {data: 'status'},
                            {data: 'ipgateway'},
                            {data: 'ipdhcp'},
                            {data: 'description'}
                        ]
                    }).on('init', function() {
                        //$.blockUI();
                    }).on('draw', function() {
                        console.log("Loaded submodal dt");
                        //.unblockUI();
                    });
                }, function() {
                    $('#network').DataTable().destroy();
                });
            });
            $('.app-data').click('button', function() {

                let dataId = $(this).data('id');
                console.log("Clicked id!", dataId);
                showDataInModalDT($(this).data('mac'), 'modal-apps', function() {
                    let url = "{{ url('sample/dtApplication/:id') }}";
                    url = url.replace(':id', dataId);
                    $('#apps').DataTable({
                        retrieve: true,
                        paging:   true,
                        ordering: false,
                        info:     false,
                        searching: false,
                        ajax: url,
                        columns: [
                            {data: 'publisher'},
                            {data: 'name'},
                            {data: 'version'},
                            {data: 'folder'},
                            {data: 'comments'},

                        ]
                    }).on('init', function() {
                        //$.blockUI();
                    }).on('draw', function() {
                        console.log("Loaded submodal dt");
                        //.unblockUI();
                    });
                }, function() {
                    $('#apps').DataTable().destroy();
                });
            });
            $('.printer-data').click('button', function() {

                let dataId = $(this).data('id');
                console.log("Clicked id!", dataId);
                showDataInModalDT($(this).data('mac'), 'modal-printers', function() {
                    let url = "{{ url('sample/dtPrinter/:id') }}";
                    url = url.replace(':id', dataId);
                    $('#printers').DataTable({
                        retrieve: true,
                        paging:   false,
                        ordering: false,
                        info:     false,
                        searching: false,
                        ajax: url,
                        columns: [
                            {data: 'name'},
                            {data: 'driver'},
                            {data: 'port'},
                        ]
                    }).on('init', function() {
                        //$.blockUI();
                    }).on('draw', function() {
                        console.log("Loaded submodal printer dt");
                        //.unblockUI();
                    });
                }, function() {
                    $('#printers').DataTable().destroy();
                });
            });
            $('.other-data').click('button', function() {

                let dataId = $(this).data('id');
                console.log("Clicked id!", dataId);
                showDataInModalDT($(this).data('mac'), 'modal-others', function() {
                    let url = "{{ url('sample/dtOther/:id') }}";
                    url = url.replace(':id', dataId);
                    $('#others').DataTable({
                        retrieve: true,
                        paging:   false,
                        ordering: false,
                        info:     false,
                        searching: false,
                        ajax: url,
                        columns: [
                            {data: 'prov'},
                            {data: 'pedido'},
                            {data: 'factura'},
                            {data: 'fechacompra'},
                            {data: 'fingarantia'},
                            {data: 'type'},
                            {data: 'notas'}
                        ]
                    }).on('init', function() {
                        //$.blockUI();
                    }).on('draw', function() {
                        console.log("Loaded submodal dt");
                        //.unblockUI();
                    });
                }, function() {
                    $('#others').DataTable().destroy();
                });
            });
        });
    });
</script>
@endsection
