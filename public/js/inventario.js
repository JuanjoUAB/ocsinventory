/*
TITLE:		Listados Inventario OCS
AUTHOR:		José Serena
DATE:		14/07/2014
VERSION:	3.0
*/

var version = 'v3.0';
var llamada;
var tiposestpc = new Array();
var tiposdispsc = new Array();
var tiposdisp = new Array();
var nomprov = new Array();
var idprov = new Array();
var idfilaerrval;
var tiposcontacto  = new Array();
var tiposdocumento  = new Array();
var ficactual;
var ficoriginal;

// añadir un analizador a tablesorter para ordenar por dias transcurridos 04/11/2015 06:15:13 [84]
// s=text from the cell, table=table DOM element, cell=current cell DOM element and $cell is the current cell as a jQuery object
$.tablesorter.addParser({
	id: 'diasuc',
	is: function(s, table, cell) {
		return false;
	},
	format: function(s, table, cell, cellIndex) {
		var partes = s.match(/(\d{2})\/(\d{2})\/(\d{4}) (\d{2}):(\d{2}):(\d{2})/);
		return Date.UTC(+partes[3], partes[2]-1, +partes[1], +partes[4], +partes[5], +partes[6]);
	},
	type: 'numeric'
});

function abrirVentanaWWW(id, dispositivo, ip) {
	if ( $("#bm"+id).attr('eb') == 1 ) {
		return false; // evitar saltar si estamos modificando
	}
	window.open("http://"+ip, dispositivo);
}

function arreglaFilaModDoc() {
	var filaid = document.getElementById('f'+idfilaerrval);
	filaid.cells[coltipodoc].innerHTML=$("#ltipodoc"+idfilaerrval+" option:selected").html(); // pone el texto del tipo y elimina la lista desplegable
	filaid.cells[colprov].innerHTML=$("#lproveedor"+idfilaerrval+" option:selected").html(); // pone el texto del proveedor y elimina la lista desplegable
//	filaid.cells[colfichero].innerHTML = '';
}

function avisoBorrado() {
	$( "#autorizarborrado" ).dialog( "open" );
}

function borraCuadroAux(cuadro) {
	document.getElementById(cuadro).style.display='none'; // ocultar el cuadro auxiliar
	llamada.parentNode.removeChild(llamada); // borrar script lee datos cuadro auxiliar
}

function borrarMarcadas() {
	$(".bsel").each( function () {
		if ( !$(this).parent().parent().hasClass('filtered') ) {
			$(this).find('img').attr('src','imagenes/pc_off.png');
			$(this).attr('eb', 0)
		}
	});
}

// cambiar los caracteres & y = de los datos para que no se confundan con los separadores de la qs
function cambiarCarEsp(texto) {
	if ( typeof texto  == 'string' ) {
		texto = texto.replace(/&/g,";amp;");
		texto = texto.replace(/=/g,";igual;");
	}
	return texto;
}

function centrarEspera() {
	// posicionar el mensaje de espera en el centro de la pantalla
	var w=window.innerWidth //Chrome, Firefox, Opera, and Safari
	|| document.documentElement.clientWidth //IE 5, 6, 7, 8
	|| document.body.clientWidth; //IE 5, 6, 7, 8

	var h=window.innerHeight //Chrome, Firefox, Opera, and Safari
	|| document.documentElement.clientHeight //IE 5, 6, 7, 8
	|| document.body.clientHeight; //IE 5, 6, 7, 8

	document.getElementById('cuadroespera').style.left=(w-500)/2+'px';
	document.getElementById('cuadroespera').style.top=(h-175)/2+'px';
}


function clicBotonPapelera($target) {
	if ( $target.attr('eb') == 0 ) {
		$target.find('img').attr('src','imagenes/papelera_r.png');
		$target.attr('eb', 1);
	} else {
		$target.find('img').attr('src','imagenes/papelera_g.png');
		$target.attr('eb', 0);
	}
}

function clicBotonSel($target) {
	if ( $target.attr('eb') == 0 ) {
                $target.attr('eb', 1); 
		$target.find('img').attr('src','imagenes/pc_on.png');
	} else {
		$target.find('img').attr('src','imagenes/pc_off.png');
		$target.attr('eb', 0);
	}
}

// Comprobar contraseña
function comprobarContra(tipo) {
	$( "#autorizarborrado" ).dialog( "close" );
	llamada = document.createElement('script');
//	llamada.src = '/perl/inventario/compcontra.pl?tipo=' + tipo + '&sha1=' + SHA1($( "#cadmin" ).val());
	llamada.src = '/perl/inventario/compcontra.pl?tipo=' + tipo + '&md5=' + MD5($( "#cadmin" ).val()); // OCS guarda valor MD5
	document.body.appendChild(llamada);
	llamada.parentNode.removeChild(llamada);
}

function despertarEstacion(event) {
	var marcadas = "";

	var difusion = document.getElementsByName("tipodifusion");
	for (var i=0; i<difusion.length; i++) {
		if ( difusion[i].checked ) {
			marcadas = marcadas + difusion[i].value + ";";
		}
	}

	$(".bsel").each( function () {
			if ( $(this).attr('eb') == 1 ) {
				marcadas += $(this).closest("td").text()+','+
							$(this).closest("tr").find("td:eq(3)").html()+','+
							$(this).closest("tr").find("td:eq(4)").html()+','+
							$(this).closest("tr").find("td:eq(5)").html()+';';
			}
		});
	if ( marcadas.length > 100000) {
		$( "#cuadrodemaesta" ).dialog( "open" );
		return false;	
	}

	$( "#enviopaquete" ).dialog( "open" );
	$( "#lineapaquete" ).html("");
	
	$.post(
		"/perl/inventario/despertar_e.pl",
		marcadas,
		function (html) {
			$('#lineapaquete').html( html );
		}
	);
}

function desTodosBotPap() {
	$(".bborrar").each( function () {
			$(this).find('img').attr('src','imagenes/papelera_g.png');
			$(this).attr('eb', 0)
		});
}

function eliminarContactos() {
	comprobarContra(5); // 5 identifica a Contactos
}

function eliminarContactosBD() {
	$("#contactoseliminados").dialog( "open" );
	$("#reseliminacion").html("");

	$(".bborrar").each( function() {
		if ( $(this).attr('eb') == 1 ) {
			var valor = $(this).closest("tr").attr("id").replace(/^f/,"");
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/eliminar_contacto.pl?' + valor;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		}
	} )
}

function eliminarDispositivos() {
	comprobarContra(1);
}

function eliminarDispositivosBD() {
	$("#dispeliminados").dialog( "open" );
	$("#reseliminacion").html("");

	$(".bborrar").each( function() {
		if ( $(this).attr('eb') == 1 ) {
			var valor = $(this).closest("tr").attr("id").replace(/^f/,"");
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/eliminar_d.pl?' + valor;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		}
	} )
}

function eliminarDispositivosNuevos() {
	comprobarContra(7);
}

function eliminarDispositivosNuevosBD() {
	$("#dispeliminados").dialog( "open" );
	$("#reseliminacion").html("");

	$(".bborrar").each( function() {
		if ( $(this).attr('eb') == 1 ) {
			var valor = $(this).closest("tr").attr("id").replace(/^f/,"");
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/eliminar_dnue.pl?' + valor;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		}
	} )
}

function eliminarDispositivosSC() {
	comprobarContra(2);
}

function eliminarDispositivosSCBD() {
	$("#dispeliminados").dialog( "open" );
	$("#reseliminacion").html("");

	$(".bborrar").each( function() {
		if ( $(this).attr('eb') == 1 ) {
			var valor = $(this).closest("tr").attr("id").replace(/^f/,"");
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/eliminar_dsc.pl?' + valor;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		}
	} )
}

function eliminarDocs() {
	comprobarContra(6); // 6 identifica a Documentos
}

function eliminarDocumentosBD() {
	$("#docseliminados").dialog( "open" );
	$("#reseliminacion").html("");

	$(".bborrar").each( function() {
		if ( $(this).attr('eb') == 1 ) {
			var valor = $(this).closest("tr").attr("id").replace(/^f/,"");
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/eliminar_doc.pl?' + valor;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		}
	} )
}

function eliminarEstaciones() {
	comprobarContra(3);
}

function eliminarEstacionesBD() {
	$("#estaeliminadas").dialog( "open" );
	$("#reseliminacion").html("");

	$(".bborrar").each( function() {
		if ( $(this).attr('eb') == 1 ) {
			var valor = $(this).closest("tr").attr("id").replace(/^f/,"");
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/eliminar_e.pl?' + valor;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		}
	} )
}

function eliminarProveedores() {
	comprobarContra(4);
}

function eliminarProveedoresBD() {
	$("#proveliminados").dialog( "open" );
	$("#reseliminacion").html("");

	$(".bborrar").each( function() {
		if ( $(this).attr('eb') == 1 ) {
			var valor = $(this).closest("tr").attr("id").replace(/^f/,"");
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/eliminar_prov.pl?' + valor;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		}
	} )
}

function esfechaok (fecha) {	
	var reModelofecha = /^(\d{1,2})(\/|-)(\d{1,2})(\/|-)(\d{4})$/; 	//Regex fecha

	fecha=fecha.replace(/<br>/g,""); // eliminar posibles saltos linea que darian fecha erronea
	if (fecha==null || fecha=="") {
		return '';
	}

	var fArray = fecha.match(reModelofecha); //es OK el formato?
	if (fArray == null) {
		return '';
	}

	//Comprobaciones para el formato mm/dd/yyyy
	fDia = fArray[1];
	fMes= fArray[3];
	fAnyo = fArray[5];

	if (fMes < 1 || fMes > 12) {
		return '';
	} else if (fDia < 1 || fDia> 31) {
		return '';
	} else if ((fMes==4 || fMes==6 || fMes==9 || fMes==11) && fDia ==31) {
		return '';
	} else if (fMes == 2) {
		var esbisiesto = (fAnyo % 4 == 0 && (fAnyo % 100 != 0 || fAnyo % 400 == 0));
		if (fDia> 29 || (fDia ==29 && !esbisiesto)) {
			return '';
		}
	}
	if ( fDia.length == 1 ) { fDia = '0'+ fDia }
	if ( fMes.length == 1 ) { fMes = '0'+ fMes }
	return fAnyo+'-'+fMes+'-'+fDia;

}

function esperarCargaPagina() {
//	document.getElementById('cuadroespera').style.display='none';
	$('#cuadroespera').hide();
}

function exportar(programa) {
	var llamada = document.createElement('script');
	document.getElementById('cuadroespera').style.display='inline';
	llamada.src = '/perl/inventario/'+programa;
	document.body.appendChild(llamada);
	llamada.parentNode.removeChild(llamada);
}

function fechaFormateada(fechaSF) {
	var fecha = new Date(fechaSF);

	return ("00" + (fecha.getMonth() + 1)).slice(-2) + "/" + 
    		("00" + fecha.getDate()).slice(-2) + "/" + 
    		fecha.getFullYear() + " " + 
    		("00" + fecha.getHours()).slice(-2) + ":" + 
    		("00" + fecha.getMinutes()).slice(-2) + ":" + 
    		("00" + fecha.getSeconds()).slice(-2)
}

function finAgrupar(evento) {
	// contar filas visibles
	var cfilas = 0;
	$('.group-count').each( function(){
		cfilas += parseInt( $(this).text().replace( /^\D+/g, '') );
	});
	$('#nfilas').html(evento.data.texto + ' [' + cfilas + ']');
	$('#'+ evento.data.tabla + '-sticky').find('th:first').text(evento.data.texto + ' [' + cfilas + ']');
	$('#cuadroespera').hide();
}

function finFiltro(evento) {
	// contar filas visibles
	var cfilas = $('#'+ evento.data.tabla + ' tr:visible').length;
	cfilas = cfilas > 1 ? cfilas-2 : 0;
	$('#nfilas').html(evento.data.texto + ' [' + cfilas + ']');
	$('#'+ evento.data.tabla + '-sticky').find('th:first').text(evento.data.texto + ' [' + cfilas + ']');

	cfilas = 0;
	$('.group-count').each( function(){
		cfilas += parseInt( $(this).text().replace( /^\D+/g, '') );
	});
	if ( cfilas ) { // si no estamos agrupando cfilas sera 0 y usaremos el valor de filas visibles
		$('#nfilas').html(evento.data.texto + ' [' + cfilas + ']');
		$('#'+ evento.data.tabla + '-sticky').find('th:first').text(evento.data.texto + ' [' + cfilas + ']');
	}
}

function formReset(formulario) {
	document.getElementById(formulario).reset();
}

function getGalleta(nombreG) {
	var i,x,y,ARRcookies=document.cookie.split(";");
	for (i=0;i<ARRcookies.length;i++) {
		x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="));
		y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1);
		x=x.replace(/^\s+|\s+$/g,"");
		if (x==nombreG) {
			return unescape(y);
		}
	}
}

function grabarconf() {
	var diasctmin = document.getElementById('diasctmin').value;
	var diasctmax = document.getElementById('diasctmax').value;
	var lista = $.map( $('#listaredes li'), function(elemento) { return $(elemento).text() }).join(',,');
	
	llamada = document.createElement('script');
	llamada.src = '/perl/inventario/grabarconf.pl?diasmin='+diasctmin+'&diasmax='+diasctmax+'&listaredes='+lista;
	document.body.appendChild(llamada);
	llamada.parentNode.removeChild(llamada);
}

function grabarcontacto() {
	var qsgrabarcontacto = ValidarFormContacto();
	if ( qsgrabarcontacto ) {
		llamada = document.createElement('script');
		llamada.src = '/perl/inventario/grabarcontacto.pl?'+qsgrabarcontacto;
		document.body.appendChild(llamada);
		llamada.parentNode.removeChild(llamada);
//		formReset();
	} else {
		return false;
	}
}

function grabardatosdispsc() {
	var qsgrabardispsc = ValidarFormSC();
	if ( qsgrabardispsc ) {
		llamada = document.createElement('script');
		llamada.src = '/perl/inventario/grabardispositivossc.pl?'+qsgrabardispsc;
		document.body.appendChild(llamada);
		llamada.parentNode.removeChild(llamada);
//		formReset();
	} else {
		return false;
	}
}

function grabarproveedor() {
	var qsgrabarproveedor = ValidarFormProv();
	if ( qsgrabarproveedor ) {
		llamada = document.createElement('script');
		llamada.src = '/perl/inventario/grabarproveedor.pl?'+qsgrabarproveedor;
		document.body.appendChild(llamada);
		llamada.parentNode.removeChild(llamada);
//		formReset();
	} else {
		return false;
	}
}

function insContacto(id) {
	colprov = 3; // columna del valor empresa seleccionado por lista
	coltipocont = 4; // columna del valor tipo contacto seleccionado por lista
	colnotas = 9; // columna de notas

	var botonins = $("#f"+id).find("button");
	var filaid = document.getElementById('f'+id);
	var ncols = filaid.getElementsByTagName('td').length;

	if ( botonins.attr('eb') == 0 ) {
		botonins.find('img').attr('src','imagenes/disk.png');
		botonins.attr('eb', 1);
		for (var j=1;j<ncols;j++) {
			if (j == colprov ) { continue };
			if (j == coltipocont ) { continue };
			if (j == colnotas ) { continue };
			filaid.cells[j].setAttribute("contentEditable", true);
		}
		modtipocontacto(id);
		modproveedor(id);
	} else {
		botonins.find('img').attr('src','imagenes/table_add.png');
		botonins.attr('eb', 0);
		for (var j=1;j<ncols;j++) {
			if (j == colprov ) { continue };
			if (j == coltipocont ) { continue };
			filaid.cells[j].setAttribute("contentEditable", false);
		}
		var qsgrabarcontacto = ValidarModCont(id);
		if ( qsgrabarcontacto ) {
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabarcontacto.pl?'+qsgrabarcontacto;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function insDispSC(id) {
	coltipo = 2; // columna del valor tipo seleccionado por lista
	colestado = 4; // columna del valor estado seleccionado por lista
	colprov = 7; // columna del valor proveedor seleccionado por lista
	colnotas = 11; // columna de notas

	var botonins = $("#f"+id).find("button");
	var filaid = document.getElementById('f'+id);
	var ncols = filaid.getElementsByTagName('td').length;

	if ( botonins.attr('eb') == 0 ) {
		botonins.find('img').attr('src','imagenes/disk.png');
		botonins.attr('eb', 1);
		for (var j=1;j<ncols;j++) {
			if (j == coltipo ) { continue };
			if (j == colestado ) { continue };
			if (j == colprov ) { continue };
			if (j == colnotas ) { continue };
			filaid.cells[j].setAttribute("contentEditable", true);
		}
		modtipodissc(id);
		modtipoestado(id);
		modproveedor(id);
	} else {
		botonins.find('img').attr('src','imagenes/table_add.png');
		botonins.attr('eb', 0);
		for (var j=1;j<ncols;j++) {
			if (j == coltipo ) { continue };
			if (j == colestado ) { continue };
			if (j == colprov ) { continue };
			filaid.cells[j].setAttribute("contentEditable", false);
		}
		var qsgrabardispsc = ValidarModSC(id);
		if ( qsgrabardispsc ) {
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabardispositivossc.pl?'+qsgrabardispsc;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function insDoc(id) {
	coltipodoc = 1; // columna del valor tipo documento seleccionado por lista
	colprov = 2; // columna del valor proveedor seleccionado por lista
	colfichero = 5; // columna del nombre fichero seleccionado por explorador
	colnotas = 6; // columna de notas

	var botonins = $("#f"+id).find("button");
	var filaid = document.getElementById('f'+id);
	var ncols = filaid.getElementsByTagName('td').length;

	if ( botonins.attr('eb') == 0 ) {
		botonins.find('img').attr('src','imagenes/disk.png');
		botonins.attr('eb', 1);
		for (var j=1;j<ncols;j++) {
			if (j == coltipodoc ) { continue };
			if (j == colprov ) { continue };
			if (j == colfichero ) { continue };
			if (j == colnotas ) { continue };
			filaid.cells[j].setAttribute("contentEditable", true);
		}
		insdocumento = true;
		modtipodoc(id);
		modproveedor(id);
		ficoriginal = '<a><\/a>';
		modfichero(id);
	} else {
		botonins.find('img').attr('src','imagenes/table_add.png');
		botonins.attr('eb', 0);
		for (var j=1;j<ncols;j++) {
			if (j == coltipodoc ) { continue };
			if (j == colprov ) { continue };
			if (j == colfichero ) { continue };
			filaid.cells[j].setAttribute("contentEditable", false);
		}

		var qsgrabardoc = ValidarModDoc(id);
		if ( qsgrabardoc ) {
			// grabar fichero .lck indicador de que estamos grabando
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/ponerlck.pl?'+ficactual;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
			// grabar el fichero que hemos seleccionado
			$("#resgrabar").dialog("open");
//			var opciones = { };
			var opciones = { 
				beforeSend: function() {
					var valPorcentaje = '0%';
					$('.barra').width(valPorcentaje)
					$('.porcentaje').html(valPorcentaje);
				},
				uploadProgress: function(event, position, total, percentComplete) {
					var valPorcentaje = percentComplete + '%';
					$('.barra').width(valPorcentaje)
					$('.porcentaje').html(valPorcentaje);
				},
				success: function() {
					var valPorcentaje = '100%';
					$('.barra').width(valPorcentaje)
					$('.porcentaje').html(valPorcentaje);
				}
			}
			$("#formselfic").ajaxSubmit( opciones );
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabardocumento.pl?'+qsgrabardoc;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			idfilaerrval = id;
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function insProv(id) {
	colnotas = 13; // columna de notas
	
	var botonins = $("#f"+id).find("button");
	var filaid = document.getElementById('f'+id);
	var ncols = filaid.getElementsByTagName('td').length;

	if ( botonins.attr('eb') == 0 ) {
		botonins.find('img').attr('src','imagenes/disk.png');
		botonins.attr('eb', 1);
		for (var j=1;j<ncols;j++) {
			if (j == colnotas ) { continue };
			filaid.cells[j].setAttribute("contentEditable", true);
		}
	} else {
		botonins.find('img').attr('src','imagenes/table_add.png');
		botonins.attr('eb', 0);
		for (var j=1;j<ncols;j++) {
			filaid.cells[j].setAttribute("contentEditable", false);
		}
		var qsgrabarproveedor = ValidarModProv(id);
		if ( qsgrabarproveedor ) {
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabarproveedor.pl?'+qsgrabarproveedor;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function lanzarClienteRVNC(estacion, ip) {
	window.open("rvncviewer://"+ip, estacion);
}

function lanzarClienteUVNC(estacion, ip) {
	window.open("uvncviewer://"+ip, estacion);
}

function marcarVisibles() {
	$(".bsel").each( function () {
		if ( !$(this).parent().parent().hasClass('filtered') ) {
			$(this).find('img').attr('src','imagenes/pc_on.png');
			$(this).attr('eb', 1)
		}
	});
}

function modAnchoTabla() {
	if ($('.tablesorter').width()-$(window).width() > 50 ) {
		$('.tablesorter').css('width','100%');
		$('.tablesorter .tablesorter-filter').css('width','100%');
	} else {
		$('.tablesorter').css('width','auto');
		$('.tablesorter .tablesorter-filter').css('width','auto');
	}
}

function modContacto(id) {
	colprov = 3; // columna del valor empresa seleccionado por lista
	coltipocont = 4; // columna del valor tipo contacto seleccionado por lista
	colnotas = 9; // columna de notas
	
	var botonid = $("#f"+id).find("td:eq(0) .bmodificar");
	var filaid = document.getElementById('f'+id);
	var ncols = filaid.getElementsByTagName('td').length;
	if ( botonid.attr('eb') == 0 ) {
		botonid.find('img').attr('src','imagenes/disk.png');
		botonid.attr('eb', 1);
		for (var j=1;j<ncols;j++) {
			if (j == colprov ) { continue };
			if (j == coltipocont ) { continue };
			if (j == colnotas ) { continue };
			filaid.cells[j].setAttribute("contentEditable", true);
		}
		modtipocontacto(id);
		modproveedor(id);
	} else {
		botonid.find('img').attr('src','imagenes/table_edit.png');
		botonid.attr('eb', 0);
		for (var j=1;j<ncols;j++) {
			if (j == colprov ) { continue };
			if (j == coltipocont ) { continue };
			filaid.cells[j].setAttribute("contentEditable", false);
		}
		var qsgrabarcontacto = ValidarModCont(id);
		if ( qsgrabarcontacto ) {
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabarcontmodif.pl?'+qsgrabarcontacto;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function modDisp(id) {
	coldescrip = 1; // columna descripcion
	colnumserie = 6; // columna del valor numero serie

	var botonid = $("#f"+id).find("td:eq(0) .bmodificar");
	var filaid = document.getElementById('f'+id);
	if ( botonid.attr('eb') == 0 ) {
		botonid.find('img').attr('src','imagenes/disk.png');
		botonid.attr('eb', 1);
		filaid.cells[coldescrip].setAttribute("contentEditable", true);
		filaid.cells[colnumserie].setAttribute("contentEditable", true);
	} else {
		botonid.find('img').attr('src','imagenes/table_edit.png');
		botonid.attr('eb', 0);
		filaid.cells[coldescrip].setAttribute("contentEditable", false);
		filaid.cells[colnumserie].setAttribute("contentEditable", false);
		var qsgrabardisp = ValidarModDisp(id);
		if ( qsgrabardisp ) {
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabardispmodif.pl?'+qsgrabardisp;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function modDispSC(id) {
	coltipo = 2; // columna del valor tipo seleccionado por lista
	colestado = 4; // columna del valor estado seleccionado por lista
	colprov = 7; // columna del valor proveedor seleccionado por lista
	colnotas = 11; // columna de notas

	var botonid = $("#f"+id).find("td:eq(0) .bmodificar");
	var filaid = document.getElementById('f'+id);
	var ncols = filaid.getElementsByTagName('td').length;
	if ( botonid.attr('eb') == 0 ) {
		botonid.find('img').attr('src','imagenes/disk.png');
		botonid.attr('eb', 1);
		for (var j=1;j<ncols;j++) {
			if (j == coltipo ) { continue };
			if (j == colestado ) { continue };
			if (j == colprov ) { continue };
			if (j == colnotas ) { continue };
			filaid.cells[j].setAttribute("contentEditable", true);
		}
		modtipodissc(id);
		modtipoestado(id);
		modproveedor(id);
	} else {
		botonid.find('img').attr('src','imagenes/table_edit.png');
		botonid.attr('eb', 0);
		for (var j=1;j<ncols;j++) {
			if (j == coltipo ) { continue };
			if (j == colestado ) { continue };
			if (j == colprov ) { continue };
			filaid.cells[j].setAttribute("contentEditable", false);
		}
		var qsgrabardispsc = ValidarModSC(id);
		if ( qsgrabardispsc ) {
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabardispscmodif.pl?'+qsgrabardispsc;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function modDoc(id) {
	coltipodoc = 1; // columna del valor tipo documento seleccionado por lista
	colprov = 2; // columna del valor proveedor seleccionado por lista
	colfichero = 5; // columna del nombre fichero seleccionado por explorador
	colnotas = 6; // columna de notas

	var botonid = $("#f"+id).find("td:eq(0) .bmodificar");;
	var filaid = document.getElementById('f'+id);
	var ncols = filaid.getElementsByTagName('td').length;

	if ( botonid.attr('eb') == 0 ) {
		botonid.find('img').attr('src','imagenes/disk.png');
		botonid.attr('eb', 1);
		for (var j=1;j<ncols;j++) {
			if (j == coltipodoc ) { continue };
			if (j == colprov ) { continue };
			if (j == colfichero ) { continue };
			if (j == colnotas ) { continue };
			filaid.cells[j].setAttribute("contentEditable", true);
		}
		modtipodoc(id);
		modproveedor(id);
		modfichero(id);
	} else {
		botonid.find('img').attr('src','imagenes/table_edit.png');
		botonid.attr('eb', 0);
			for (var j=1;j<ncols;j++) {
			if (j == coltipodoc ) { continue };
			if (j == colprov ) { continue };
			if (j == colfichero ) { continue };
			filaid.cells[j].setAttribute("contentEditable", false);
		}

		var qsgrabardoc = ValidarModDoc(id);
		if ( qsgrabardoc ) {
			if ( grabarfichero ) {
				// grabar fichero .lck indicador de que estamos grabando
				llamada = document.createElement('script');
				llamada.src = '/perl/inventario/ponerlck.pl?'+ficactual;
				document.body.appendChild(llamada);
				llamada.parentNode.removeChild(llamada);
				// grabar el fichero que hemos seleccionado
				$("#resgrabar").dialog("open");
//				var opciones = { };
				var opciones = { 
					beforeSend: function() {
						var valPorcentaje = '0%';
						$('.barra').width(valPorcentaje)
						$('.porcentaje').html(valPorcentaje);
					},
					uploadProgress: function(event, position, total, porcentajeCompletado) {
						var valPorcentaje = porcentajeCompletado + '%';
						$('.barra').width(valPorcentaje)
						$('.porcentaje').html(valPorcentaje);
					},
					success: function() {
						var valPorcentaje = '100%';
						$('.barra').width(valPorcentaje)
						$('.porcentaje').html(valPorcentaje);
					}
				}
				$("#formselfic").ajaxSubmit( opciones );
			}
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabardocmodif.pl?'+qsgrabardoc;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			idfilaerrval = id;
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function modfichero(id) {
	var filaid = document.getElementById('f'+id);
	var regex = /<a.*>(.*)<\/a>/;
	if ( regex.test(filaid.cells[colfichero].innerHTML) ){
		var tmp = regex.exec(filaid.cells[colfichero].innerHTML);
		ficactual = tmp[1];
		ficoriginal = filaid.cells[colfichero].innerHTML;		
	} else {
		var tmp = regex.exec(ficoriginal);
		ficactual = tmp[1];
	}
	filaid.cells[colfichero].innerHTML = '<input type="button" onclick="selecfichero()" value="Explorar" /><span id="nomficsel">&nbsp;'+ficactual+'</span>';
	document.getElementById('formselfic').reset();
}

function modOtrosDatos(id) {
	colprov = 2; // columna del valor proveedor seleccionado por lista
	colestado = 7; // columna del valor estado seleccionado por lista
	colnotas = 9; // columna de notas

	var colped = 3;
	var colfac = 4;
	var colfcompra = 5;
	var colgarantia = 6;

	var botonid = $("#f"+id).find("td:eq(0) .bmodificar");
	var filaid = document.getElementById('f'+id);
	var ncols = filaid.getElementsByTagName('td').length;
	if ( botonid.attr('eb') == 0 ) {
		botonid.find('img').attr('src','imagenes/disk.png');
		botonid.attr('eb', 1);
		filaid.cells[colped].setAttribute("contentEditable", true);
		filaid.cells[colfac].setAttribute("contentEditable", true);
		filaid.cells[colfcompra].setAttribute("contentEditable", true);
		filaid.cells[colgarantia].setAttribute("contentEditable", true);
		modproveedor(id);
		modtipoestado(id);
	} else {
		botonid.find('img').attr('src','imagenes/table_edit.png');
		botonid.attr('eb', 0);
		filaid.cells[colped].setAttribute("contentEditable", false);
		filaid.cells[colfac].setAttribute("contentEditable", false);
		filaid.cells[colfcompra].setAttribute("contentEditable", false);
		filaid.cells[colgarantia].setAttribute("contentEditable", false);

		var qsgrabarotrosd = ValidarOtrosDatos(id);
		if ( qsgrabarotrosd ) {
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabarotrosdatos.pl?'+qsgrabarotrosd;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function modProv(id) {
	colnotas = 13; // columna de notas
	
	var botonid = $("#f"+id).find("td:eq(0) .bmodificar");
	var filaid = document.getElementById('f'+id);
	var ncols = filaid.getElementsByTagName('td').length;
	if ( botonid.attr('eb') == 0 ) {
		botonid.find('img').attr('src','imagenes/disk.png');
		botonid.attr('eb', 1);
		for (var j=1;j<ncols;j++) {
			if (j == colnotas ) { continue };
			filaid.cells[j].setAttribute("contentEditable", true);
		}
	} else {
		botonid.find('img').attr('src','imagenes/table_edit.png');
		botonid.attr('eb', 0);
		for (var j=1;j<ncols;j++) {
			filaid.cells[j].setAttribute("contentEditable", false);
		}
		var qsgrabarproveedor = ValidarModProv(id);
		if ( qsgrabarproveedor ) {
			llamada = document.createElement('script');
			llamada.src = '/perl/inventario/grabarprovmodif.pl?'+qsgrabarproveedor;
			document.body.appendChild(llamada);
			llamada.parentNode.removeChild(llamada);
		} else {
			$( "#erroresval" ).dialog( "open" );
		}
	}
}

function modproveedor(id) {
	var filaid = document.getElementById('f'+id);
	var provactual = filaid.cells[colprov].innerHTML;
	filaid.cells[colprov].innerHTML='<select id="lproveedor'+id+'" size="1"></select>';
	for (i=1;i<nomprov.length;i++) {
		if ( nomprov[i] == provactual ) {
			$("<option value="+idprov[i]+' selected="selected">'+nomprov[i]+"</option>").appendTo("#lproveedor"+id);
		} else {
			$("<option value="+idprov[i]+">"+nomprov[i]+"</option>").appendTo("#lproveedor"+id);
		}
	}
}

function modtipocontacto(id) {
	var filaid = document.getElementById('f'+id);
	var tipoactual = filaid.cells[coltipocont].innerHTML
	filaid.cells[coltipocont].innerHTML='<select id="ltiposcontacto'+id+'" size="1"></select>';
	for (i=1;i<tiposcontacto.length;i++) {
		if ( tiposcontacto[i] == tipoactual ) {
			$("<option value="+i+' selected="selected">'+tiposcontacto[i]+"</option>").appendTo("#ltiposcontacto"+id);
		} else {
			$("<option value="+i+">"+tiposcontacto[i]+"</option>").appendTo("#ltiposcontacto"+id);
		}
	}
}

function modtipodissc(id) {
	var filaid = document.getElementById('f'+id);
	var tipoactual = filaid.cells[coltipo].innerHTML
	filaid.cells[coltipo].innerHTML='<select id="tipodissc'+id+'" size="1"></select>';
	for (i=1;i<tiposdispsc.length;i++) {
		if ( tiposdispsc[i] == tipoactual ) {
			$("<option value="+i+' selected="selected">'+tiposdispsc[i]+"</option>").appendTo("#tipodissc"+id);
		} else {
			$("<option value="+i+">"+tiposdispsc[i]+"</option>").appendTo("#tipodissc"+id);
		}
	}
}

function modtipodoc(id) {
	var filaid = document.getElementById('f'+id);
	var tipoactual = filaid.cells[coltipodoc].innerHTML
	filaid.cells[coltipodoc].innerHTML='<select id="ltipodoc'+id+'" size="1"></select>';
	for (i=1;i<tiposdocumento.length;i++) {
		if ( tiposdocumento[i] == tipoactual ) {
			$("<option value="+i+' selected="selected">'+tiposdocumento[i]+"</option>").appendTo("#ltipodoc"+id);
		} else {
			$("<option value="+i+">"+tiposdocumento[i]+"</option>").appendTo("#ltipodoc"+id);
		}
	}
}

function modtipoestado(id) {
	var filaid = document.getElementById('f'+id);
	var tipestactual = filaid.cells[colestado].innerHTML
	filaid.cells[colestado].innerHTML='<select id="tipoestado'+id+'" size="1"></select>';
	for (i=1;i<tiposestpc.length;i++) {
		if ( tiposestpc[i] == tipestactual ) {
			$("<option value="+i+' selected="selected">'+tiposestpc[i]+"</option>").appendTo("#tipoestado"+id);
		} else {
			$("<option value="+i+">"+tiposestpc[i]+"</option>").appendTo("#tipoestado"+id);
		}
	}
}

function mostrarficsel() {
	ficactual = document.getElementById("selfichero").files[0].name;
	var datfic = ' ' + ficactual + ' (' + document.getElementById("selfichero").files[0].size + ' Bytes)';
	document.getElementById("nomficsel").innerHTML = datfic;
}

function pingPC(fila, ip) {
	llamada = document.createElement('script');
	llamada.src = '/perl/inventario/ping_pc.pl?fila='+fila+'&ip='+ip;
	document.body.appendChild(llamada);
	llamada.parentNode.removeChild(llamada);
}

function registrarDispositivos(event) {
	var marcadas = "";

	var tipodisp = $("#ltipodisp option:selected").val();
	marcadas = marcadas + tipodisp + ";";	

	$(".bsel").each( function () {
			if ( $(this).attr('eb') == 1 ) {
				marcadas += $(this).closest("tr").find("td:eq(1)").html()+';';
			}
	});

	if ( marcadas.length > 100000) {
		$( "#cuadrodemadisp" ).dialog( "open" );
		return false;	
	}

	$( "#estaregis" ).dialog( "open" );
	$( "#lineadispositivo" ).html("");
	
	$.post(
		"/perl/inventario/registrar_d.pl",
		marcadas,
		function (html) {
			$('#lineadispositivo').html( html );
		}
	);
}

// obtener los valores pasados a traves de un query search  http://...?par1=val1&par2=val2&par3=val3...
var qs = (function(a) {
    if (a == "") return {};
    var b = {};
    for (var i = 0; i < a.length; ++i)
    {
        var p=a[i].split('=');
        if (p.length != 2) continue;
//        b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
        b[p[0]] = unescape(p[1].replace(/\+/g, " "));
    }
    return b;
})(window.location.search.substr(1).split('&'));

function selecfichero() {
	document.getElementById("selfichero").click();
}

function ValidarCampoMod (filaid, col, lgtd, oblig, campo) {
	var x=filaid.cells[col].innerHTML;
	x=x.replace(/<br>/g,"");
	if ( x==null || x=="" ) {
		if ( oblig ) {
			$("#resvaldatos").append("El campo " + campo + " es obligatorio<br>");
			filaid.cells[col].style.border="3px solid red";
			return -1;			
		}
		return x;
	} else if ( x.length > lgtd ) {
		$("#resvaldatos").append("El campo " + campo + " es demasiado largo<br>");
		filaid.cells[col].innerHTML = x.substring(0, lgtd);
		filaid.cells[col].style.border="3px solid red";	
		return -1;
	} else {
		filaid.cells[col].style.border="";
		return cambiarCarEsp(x);
	}
}

function ValidarModCont(id) {
	$("#resvaldatos").html(""); // borrar mensajes error anteriores
	var filaid = document.getElementById('f'+id);
	var esValido = true;
	
	$nombre = ValidarCampoMod(filaid,1,50,1,'nombre'); // nombre
	if ( $nombre < 0 ) { esValido = false; }

	$apellidos = ValidarCampoMod(filaid,2,255,1,'apellidos'); // apellidos
	if ( $apellidos < 0 ) { esValido = false; }

	$cargo = ValidarCampoMod(filaid,5,50,0,'cargo'); // cargo 
	if ( $cargo < 0 ) { esValido = false; }

	$telefono1 = ValidarCampoMod(filaid,7,25,0,'Teléfono1'); // telefono1 
	if ( $telefono1 < 0 ) { esValido = false; }

	$telefono2 = ValidarCampoMod(filaid,8,25,0,'Teléfono2'); // telefono2 
	if ( $telefono2 < 0 ) { esValido = false; }

	var regex = /^([a-zA-Z0-9_.+-])+\@(([a-zA-Z0-9-])+\.)+([a-zA-Z0-9]{2,4})+$/;
	x=filaid.cells[6].innerHTML; // correo
	x=x.replace(/<br>/g,"");
	if ( x.length > 50 ) {
		$("#resvaldatos").append("El campo Correo es demasiado largo<br>");
		filaid.cells[6].innerHTML = x.substring(0, 50);
		filaid.cells[6].style.border="3px solid red";		
		esValido = false;
	} else if ( x!="" && !regex.test(x) ) {	
		$("#resvaldatos").append("El campo Correo es inv&aacutelido<br>");
		filaid.cells[6].style.border="3px solid red";			
		esValido = false;
	} else {
		$correo = x;
		filaid.cells[6].style.border="";
	}
	
	x=filaid.cells[10].innerHTML; // notas (oculto)
	if ( x.length > 2500 ) {
		$("#resvaldatos").append("El campo Notas es demasiado largo<br>");
		filaid.cells[9].style.border="3px solid red";		
		esValido = false;
	} else {
		$notas = cambiarCarEsp(x);
		filaid.cells[9].style.border="";
	}

	if ( esValido ) {
		var $tipocont = $("#ltiposcontacto"+id+" option:selected").val();
		filaid.cells[coltipocont].innerHTML=$("#ltiposcontacto"+id+" option:selected").html(); // pone el texto del tipo y elimina la lista desplegable

		var $empresa = $("#lproveedor"+id+" option:selected").val();
		filaid.cells[colprov].innerHTML=$("#lproveedor"+id+" option:selected").html(); // pone el texto del estado y elimina la lista desplegable

		var qs = 'id='+id+'&nombre='+$nombre+'&apellidos='+$apellidos+'&cargo='+$cargo+'&tipocont='+$tipocont+'&empresa='+$empresa;
		qs += '&telefono1='+$telefono1+'&telefono2='+$telefono2+'&correo='+$correo+'&notas='+$notas;
		return qs;
	} else {
		return false;
	}
}

function ValidarModDisp(id) {
	$("#resvaldatos").html(""); // borrar mensajes error anteriores
	var filaid = document.getElementById('f'+id);
	var esValido = true;

	$descripcion = ValidarCampoMod(filaid,1,50,0,'descripcion');
	if ( $descripcion < 0 ) { esValido = false; }

	$numserie = ValidarCampoMod(filaid,6,25,0,'numserie');
	if ( $numserie < 0 ) { esValido = false; }
	
	x=filaid.cells[9].innerHTML; // notas (oculto)
	if ( x.length > 2500 ) {
		$("#resvaldatos").append("El campo Notas es demasiado largo<br>");
		filaid.cells[9].style.border="3px solid red";		
		esValido = false;
	} else {
		$notas = cambiarCarEsp(x);
		filaid.cells[9].style.border="";
	}
	
	if ( esValido ) {
		var qs = 'id='+id+'&descripcion='+$descripcion+'&numserie='+$numserie+'&notas='+$notas;
		return qs;
	} else {
		return false;
	}
}

function ValidarModDoc(id) {
	$("#resvaldatos").html(""); // borrar mensajes error anteriores
	var $nfichero;
	var filaid = document.getElementById('f'+id);
	var esValido = true;
	
	$referencia = ValidarCampoMod(filaid,3,50,0,'referencia');
	if ( $referencia < 0 ) { esValido = false; }

	var $fechadoc=esfechaok(filaid.cells[4].innerHTML);  // fechadoc
	if ( $fechadoc == -1 ) {
		$("#resvaldatos").append("La fecha del documento no es v&aacutelida<br>");
		filaid.cells[4].style.border="3px solid red";	
		esValido = false;
	} else  {
		filaid.cells[4].style.border="";
	}

	grabarfichero = 0; // no hay que grabar el fichero
	if (typeof document.getElementById("selfichero").files[0] === 'undefined') {
		if ( ficactual==null || ficactual=="" ) {
			$("#resvaldatos").append("No se ha seleccionado ningun fichero<br>");
			filaid.cells[colfichero].style.border="3px solid red";
			filaid.cells[colfichero].innerHTML = '';			
			esValido = false;
		} else {
			$nfichero = ficactual;
			var nombrefic = $nfichero;
			nombrefic = nombrefic.replace(/.[^.]+$/,'');
			var extfic = $nfichero;				
			extfic = extfic.replace(/^.*\./,'');
			filaid.cells[colfichero].innerHTML = '<a href="documentos/'+nombrefic+'_'+id+'.'+extfic+'">'+$nfichero+'</a>';	
			filaid.cells[colfichero].style.border="";
		}
	} else {
		tfichero = document.getElementById("selfichero").files[0].size;
		if ( tfichero > 10000000 ) {
			$("#resvaldatos").append("El fichero es demasiado grande<br>");
			filaid.cells[colfichero].style.border="3px solid red";
			filaid.cells[colfichero].innerHTML = ficactual;	
			esValido = false;		
		} else {
			$nfichero = ficactual;
			$nfichero = $nfichero.replace(/ /g,"_"); // reemplazamos los espacios por _ en el nombre
			var nombrefic = $nfichero;
			nombrefic = nombrefic.replace(/.[^.]+$/,'');
			var extfic = $nfichero;				
			extfic = extfic.replace(/^.*\./,'');
			filaid.cells[colfichero].innerHTML = '<a href="documentos/'+nombrefic+'_'+id+'.'+extfic+'">'+$nfichero+'</a>';	
			filaid.cells[colfichero].style.border="";
			grabarfichero = 1; // si que hay que grabar el fichero
		}
	}

	x=filaid.cells[7].innerHTML; // notas (oculto)
	if ( x.length > 2500 ) {
		$("#resvaldatos").append("El campo Notas es demasiado largo<br>");
		filaid.cells[6].style.border="3px solid red";		
		esValido = false;
	} else {
		$notas = cambiarCarEsp(x);
		filaid.cells[6].style.border="";
	}

	if ( esValido ) {
		var $tipodoc = $("#ltipodoc"+id+" option:selected").val();
		filaid.cells[coltipodoc].innerHTML=$("#ltipodoc"+id+" option:selected").html(); // pone el texto del tipo y elimina la lista desplegable

		var $proveedor = $("#lproveedor"+id+" option:selected").val();
		filaid.cells[colprov].innerHTML=$("#lproveedor"+id+" option:selected").html(); // pone el texto del proveedor y elimina la lista desplegable

		var qs = 'id='+id+'&tipodoc='+$tipodoc+'&proveedor='+$proveedor+'&referencia='+$referencia+'&fechadoc='+$fechadoc+'&nfichero='+$nfichero+'&notas='+$notas;
		return qs;
	} else {
		return false;
	}
}

function ValidarModProv(id) {
	$("#resvaldatos").html(""); // borrar mensajes error anteriores
	var filaid = document.getElementById('f'+id);
	var esValido = true;
	
//	var x= $("#f"+id+" td:eq(1)").html(); // nombre

	$nombre = ValidarCampoMod(filaid,1,255,1,'Nombre'); // nombre
	if ( $nombre < 0 ) { esValido = false; }

	$direccion = ValidarCampoMod(filaid,2,255,0,'Dirección'); // direccion
	if ( $direccion < 0 ) { esValido = false; }

	$poblacion = ValidarCampoMod(filaid,3,255,0,'Población'); // poblacion 
	if ( $poblacion < 0 ) { esValido = false; }

	$provincia = ValidarCampoMod(filaid,4,255,0,'Provincia'); // provincia 
	if ( $provincia < 0 ) { esValido = false; }

	$cp = ValidarCampoMod(filaid,5,10,0,'Código Postal'); //CP
	if ( $cp < 0 ) { esValido = false; }

	$pais = ValidarCampoMod(filaid,6,50,0,'Pais'); // pais 
	if ( $pais < 0 ) { esValido = false; }
	
	$nif = ValidarCampoMod(filaid,7,15,0,'NIF'); // nif 
	if ( $nif < 0 ) { esValido = false; }

	$web = ValidarCampoMod(filaid,8,255,0,'Web'); // web 
	if ( $web < 0 ) { esValido = false; }

	$telefono1 = ValidarCampoMod(filaid,9,25,0,'Teléfono1'); // telefono1 
	if ( $telefono1 < 0 ) { esValido = false; }

	$telefono2 = ValidarCampoMod(filaid,10,25,0,'Teléfono2'); // telefono2 
	if ( $telefono2 < 0 ) { esValido = false; }

	$fax = ValidarCampoMod(filaid,11,25,0,'Fax'); // fax 
	if ( $fax < 0 ) { esValido = false; }

	var regex = /^([a-zA-Z0-9_.+-])+\@(([a-zA-Z0-9-])+\.)+([a-zA-Z0-9]{2,4})+$/;
	x=filaid.cells[12].innerHTML; // correo
	x=x.replace(/<br>/g,"");
	if ( x.length > 50 ) {
		$("#resvaldatos").append("El campo Correo es demasiado largo<br>");
		filaid.cells[12].innerHTML = x.substring(0, 50);
		filaid.cells[12].style.border="3px solid red";		
		esValido = false;
	} else if ( x!="" && !regex.test(x) ) {	
		$("#resvaldatos").append("El campo Correo es inv&aacutelido<br>");
		filaid.cells[12].style.border="3px solid red";			
		esValido = false;
	} else {
		$correo = x;
		filaid.cells[12].style.border="";
	}
	
	x=filaid.cells[14].innerHTML; // notas (oculto)
	if ( x.length > 2500 ) {
		$("#resvaldatos").append("El campo Notas es demasiado largo<br>");
		filaid.cells[13].style.border="3px solid red";		
		esValido = false;
	} else {
		$notas = cambiarCarEsp(x);
		filaid.cells[13].style.border="";
	}

	if ( esValido ) {
		var qs = 'id='+id+'&nombre='+$nombre+'&direccion='+$direccion+'&poblacion='+$poblacion+'&provincia='+$provincia+'&cp='+$cp+'&pais='+$pais+'&nif='+$nif;
		qs += '&web='+$web+'&telefono1='+$telefono1+'&telefono2='+$telefono2+'&fax='+$fax+'&correo='+$correo+'&notas='+$notas;
		return qs;
	} else {
		return false;
	}
}


function ValidarModSC(id) {
	$("#resvaldatos").html(""); // borrar mensajes error anteriores
	var filaid = document.getElementById('f'+id);
	var esValido = true;

	$descripcion = ValidarCampoMod(filaid,1,255,1,'descripcion');
	if ( $descripcion < 0 ) { esValido = false; }

	$ubicacion = ValidarCampoMod(filaid,3,255,1,'ubicacion');
	if ( $ubicacion < 0 ) { esValido = false; }

	$numserie = ValidarCampoMod(filaid,5,25,0,'numserie');
	if ( $numserie < 0 ) { esValido = false; }

	$responsable = ValidarCampoMod(filaid,6,100,0,'responsable');
	if ( $responsable < 0 ) { esValido = false; }

	$pedido = ValidarCampoMod(filaid,8,50,0,'pedido');
	if ( $pedido < 0 ) { esValido = false; }

	$factura = ValidarCampoMod(filaid,9,50,0,'factura');
	if ( $factura < 0 ) { esValido = false; }

	var $fechacompra=esfechaok(filaid.cells[10].innerHTML);  // fechacompra	
	if ( $fechacompra == -1 ) {
		$("#resvaldatos").append("La fecha de compra no es v&aacutelida<br>");
		filaid.cells[10].style.border="3px solid red";	
		esValido = false;
	} else  {
		filaid.cells[10].style.border="";
	}
	
	x=filaid.cells[12].innerHTML; // notas (oculto)
	if ( x.length > 2500 ) {
		$("#resvaldatos").append("El campo Notas es demasiado largo<br>");
		filaid.cells[11].style.border="3px solid red";		
		esValido = false;
	} else {
		$notas = cambiarCarEsp(x);
		filaid.cells[11].style.border="";
	}
	
	if ( esValido ) {
		var $tipo = $("#tipodissc"+id+" option:selected").val();
		filaid.cells[coltipo].innerHTML=$("#tipodissc"+id+" option:selected").html(); // pone el texto del tipo y elimina la lista desplegable

		var $estado = $("#tipoestado"+id+" option:selected").val();
		filaid.cells[colestado].innerHTML=$("#tipoestado"+id+" option:selected").html(); // pone el texto del estado y elimina la lista desplegable

		var $valprov = $("#lproveedor"+id+" option:selected").val();
		filaid.cells[colprov].innerHTML=$("#lproveedor"+id+" option:selected").html(); // pone el texto del estado y elimina la lista desplegable

		var qs = 'id='+id+'&tipo='+$tipo+'&descripcion='+$descripcion+'&ubicacion='+$ubicacion+'&numserie='+$numserie+'&estado='+$estado+'&responsable='+$responsable+'&proveedor='+$valprov+'&pedido='+$pedido+'&factura='+$factura+'&fechacompra='+$fechacompra+'&notas='+$notas;
		return qs;
	} else {
		return false;
	}
}


function ValidarOtrosDatos(id) {
	$("#resvaldatos").html(""); // borrar mensajes error anteriores
	var filaid = document.getElementById('f'+id);
	var esValido = true;
	
	$pedido = ValidarCampoMod(filaid,3,50,0,'pedido');
	if ( $pedido < 0 ) { esValido = false; }
	
	$factura = ValidarCampoMod(filaid,4,50,0,'factura');
	if ( $factura < 0 ) { esValido = false; }


	var $fechacompra = esfechaok(filaid.cells[5].innerHTML); // fechacompra
	if ( $fechacompra == -1 ) {
		$("#resvaldatos").append("La fecha de compra no es v&aacutelida<br>");
		filaid.cells[5].style.border="3px solid red";	
		esValido = false;
	} else	{
		filaid.cells[5].style.border="";	
	} 

	var $fingarantia = esfechaok(filaid.cells[6].innerHTML); // fingarantia
	if ( $fingarantia == -1) {
		$("#resvaldatos").append("La fecha de garant&iacutea no es v&aacutelida<br>");
		filaid.cells[6].style.border="3px solid red";	
		esValido = false;
	} else  {
		filaid.cells[6].style.border="";
		if ( $fingarantia == '' ) {
			if ( $fechacompra ) {
				var res = new Date($fechacompra);
				res.setDate(res.getDate() + 365); // garantia por defecto fecha_compra+365 dias
				$fingarantia = res.getDate() + '/' + (res.getMonth() + 1) + '/' + res.getFullYear();

				filaid.cells[6].innerHTML = $fingarantia;
				$fingarantia =  res.getFullYear() + '-' + (res.getMonth() + 1) + '-' + res.getDate();
			}
		}	
	}

	x=filaid.cells[10].innerHTML; // notas 
	if ( x.length > 32000 ) {
		$("#resvaldatos").append("El campo Notas es demasiado largo<br>");
		filaid.cells[9].style.border="3px solid red";	
		esValido = false;
	} else {
		$notas = cambiarCarEsp(x);
		filaid.cells[9].style.border="";
	}
	
	if ( esValido ) {
		var $valprov = $("#lproveedor"+id+" option:selected").val();
		if ( $valprov ) {
			filaid.cells[colprov].innerHTML=$("#lproveedor"+id+" option:selected").html(); // pone el texto del proveedor y elimina la lista desplegable
		} else {
			filaid.cells[colprov].innerHTML=""; //si no hay proveedor elimina la lista desplegable
		}
		var $valestado = $("#tipoestado"+id+" option:selected").val();
		filaid.cells[colestado].innerHTML=$("#tipoestado"+id+" option:selected").html(); // pone el texto del estado y elimina la lista desplegable

		var qs = 'id='+id+'&proveedor='+$valprov+'&pedido='+$pedido+'&factura='+$factura+'&fechacompra='+$fechacompra+'&fingarantia='+$fingarantia+'&estado='+$valestado+'&notas='+$notas;
		return qs;
	} else {
		return false;
	}
}

function verApli(id, estacion) {
	window.open("aplicaciones_u.php?id="+id+"&estacion="+estacion,"Aplicaciones");
}

function verDatosDispDesc(mac) {
	$( "#datosdisp" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#datosdisp" ).dialog('option', 'title', 'MAC : '+ mac);
	$( "#datosdisp" ).dialog( 'open' );
	llamada = document.createElement('script');
	llamada.src = '/perl/inventario/datosdispdesc.pl?'+mac;
	document.body.appendChild(llamada);
	llamada.parentNode.removeChild(llamada);
}

function verImpre(id, estacion) {
	window.open("impresoras_u.php?id="+id+"&estacion="+estacion,"Impresoras");
}

function verNotasCont(id, contacto) {
	if ( !contacto ) { contacto = 'Nuevo contacto' }
	$( "#notascontacto" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#notascontacto" ).dialog('option', 'title', contacto);
	$( "#notascontacto" ).dialog( 'open' );
	$( "#tdnotascontacto" ).attr('contentEditable', false);
	$( "#tdnotascontacto" ).html( $("#f"+id+" td:eq(10)").html() );
	$( "#tdnotascontacto" ).attr( 'idnotas', id );

	// id=0 si estamos insertando un nuevo elemento
	if ( id ) {
		if ( $("#f"+id).find(".bmodificar").attr('eb') == 1 ) {
			$( "#tdnotascontacto" ).attr("contentEditable", true);
		}
	} else {
		if ( $("#f"+id).find("button").attr('eb') == 1 ) {
			$( "#tdnotascontacto" ).attr("contentEditable", true);
		}
	}
}

function verNotasDisp(id, nombre, col) {
	$( "#notasdisp" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#notasdisp" ).dialog('option', 'title', nombre);
	$( "#notasdisp" ).dialog( 'open' );
	$( "#tdnotasdisp" ).attr('contentEditable', false);
	$( "#tdnotasdisp" ).html( $("#f"+id+" td:eq("+col+")").html() );	
	$( "#tdnotasdisp" ).attr( 'idnotas', id );

	if (  $("#f"+id).find(".bmodificar").attr('eb') == 1 ) {
		$( "#tdnotasdisp" ).attr('contentEditable', true);
	}
}

function verNotasDoc(id, documento) {
	if ( !documento ) { documento = 'Nuevo documento' }
	$( "#notasdoc" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#notasdoc" ).dialog('option', 'title', documento);
	$( "#notasdoc" ).dialog( 'open' );
	$( "#tdnotasdoc" ).attr('contentEditable', false);
	$( "#tdnotasdoc" ).html( $("#f"+id+" td:eq(7)").html() );
	$( "#tdnotasdoc" ).attr( 'idnotas', id );

	// id=0 si estamos insertando un nuevo elemento
	if ( id ) {
		if ( $("#f"+id).find(".bmodificar").attr('eb') == 1 ) {
			$( "#tdnotasdoc" ).attr("contentEditable", true);
		}
	} else {
		if ( $("#f"+id).find("button").attr('eb') == 1 ) {
			$( "#tdnotasdoc" ).attr("contentEditable", true);
		}
	}
}

function verNotasPC(id, pc) {
	$( "#notasPC" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#notasPC" ).dialog('option', 'title', pc);
	$( "#notasPC" ).dialog( 'open' );
	$( "#tdnotasPC" ).attr('contentEditable', false);
	$( "#tdnotasPC" ).html( $("#f"+id+" td:eq(10)").html() );
	$( "#tdnotasPC" ).attr( 'idnotas', id );

	if ( $("#f"+id).find(".bmodificar").attr('eb') == 1 ) {
		$( "#tdnotasPC" ).attr('contentEditable', true);
	}
}

function verNotasProv(id, nprov) {
	if ( !nprov ) { nprov = 'Nuevo proveedor' }
	$( "#notasprov" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#notasprov" ).dialog('option', 'title', nprov);
	$( "#notasprov" ).dialog( 'open' );
	$( "#tdnotasprov" ).attr('contentEditable', false);
	$( "#tdnotasprov" ).html( $("#f"+id+" td:eq(14)").html() );
	$( "#tdnotasprov" ).attr( 'idnotas', id );

	// id=0 si estamos insertando un nuevo elemento
	if ( id ) {
		if ( $("#f"+id).find(".bmodificar").attr('eb') == 1 ) {
			$( "#tdnotasprov" ).attr("contentEditable", true);
		}
	} else {
		if ( $("#f"+id).find("button").attr('eb') == 1 ) {
			$( "#tdnotasprov" ).attr("contentEditable", true);
		}
	}
}

function verNotasSC(id, ddispsc) {
	if ( !ddispsc ) { ddispsc = 'Nuevo dispositivo SC' }
	$( "#notasSC" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#notasSC" ).dialog('option', 'title', ddispsc);
	$( "#notasSC" ).dialog( 'open' );
	$( "#tdnotasSC" ).attr('contentEditable', false);
	$( "#tdnotasSC" ).html( $("#f"+id+" td:eq(12)").html() );
	$( "#tdnotasSC" ).attr( 'idnotas', id );

	// id=0 si estamos insertando un nuevo elemento
	if ( id ) {
		if ( $("#f"+id).find(".bmodificar").attr('eb') == 1 ) {
			$( "#tdnotasSC" ).attr('contentEditable', true);
		}
	} else {
		if ( $("#f"+id).find("button").attr('eb') == 1 ) {
			$( "#tdnotasSC" ).attr('contentEditable', true);
		}
	}
}

function verOtros(id, estacion) {
	$( "#otrosdatospc" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#otrosdatospc" ).dialog('option', 'title', estacion);
	$( "#otrosdatospc" ).dialog( 'open' );
	llamada = document.createElement('script');
	llamada.src = '/perl/inventario/otrospc_u.pl?'+id;
	document.body.appendChild(llamada);
	llamada.parentNode.removeChild(llamada);
}

function verPC(id, estacion) {
	$( "#datospc" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#datospc" ).dialog('option', 'title', estacion);
	$( "#datospc" ).dialog( 'open' );
	llamada = document.createElement('script');
	llamada.src = '/perl/inventario/pc_u.pl?'+id;
	document.body.appendChild(llamada);
	llamada.parentNode.removeChild(llamada);
}

function verRed(id, estacion) {
	$( "#redespc" ).dialog( 'close' ); // cerrar posible dialogo anterior
	$( "#redespc" ).dialog('option', 'title', estacion);
	$( "#redespc" ).dialog( 'open' );
	llamada = document.createElement('script');
	llamada.src = '/perl/inventario/redes_u.pl?'+id;
	document.body.appendChild(llamada);
	llamada.parentNode.removeChild(llamada);
}

function verUsuApli(aplicacion) {
	window.open("u_aplicacion.php?aplicacion="+aplicacion,"Equipos");
}
