#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	adminotrosdatospc.pl
# DESCRIPTION:	muestra y modifica los datos manuales de un PC
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0


use Encode;
use strict;
#use warnings;
use DBI;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my %tipestpc=();
my %nproveedores=();

# Detectar SO para ruta fichero configuracion
my $fconf;
if ( $^O eq "linux" ) {
	if ( $ENV{'SCRIPT_FILENAME'} ) {
		# ejecutamos desde Apache
		my ($dircgi) = $ENV{'SCRIPT_FILENAME'} =~ /^(.*)\//;
		$fconf = "$dircgi/inventario.cfg";
	} else {
		# ejecutamos fuera de Apache
		my ($rutarel) = $0 =~ /(.*)\//;
		if ( $rutarel =~ /^\// ) {
			$fconf = "$rutarel/inventario.cfg";
		} else {
			$fconf = "$ENV{'PWD'}/$rutarel/inventario.cfg";
		}
	}
} elsif ( $^O eq "MSWin32" ) {
	$fconf="c:\\xampp\\cgi-bin\\inventario\\inventario.cfg";
}

# Leer configuracion
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $seguridad, $diasctmin, $diasctmax);
if (-e $fconf) {
	open (FILECONF, "<", "$fconf");
	while (<FILECONF>) {
		chomp;
		if (/^#/) {next;}
		if (/servidor OCS:(.*)/) {
			$servidorocs = $1;
			$servidorocs =~ s/^\s+//;
			$servidorocs =~ s/\s+$//;
		}
		elsif (/empresa:(.*)/) {
			$empresa = $1;
			$empresa =~ s/^\s+//;
			$empresa =~ s/\s+$//;
		}
		elsif (/usuario MySQL:(.*)/) {
			$usuario = $1;
			$usuario =~ s/^\s+//;
			$usuario =~ s/\s+$//;
		}
		elsif (/password MySQL:(.*)/) {
			$tmp = $1;
			$tmp =~ s/^\s+//;
			$tmp =~ s/\s+$//;
			$password = $cripto->decryptA($tmp);
		}
		elsif (/base datos OCS:(.*)/) {
			$basedatos = $1;
			$basedatos =~ s/^\s+//;
			$basedatos =~ s/\s+$//;
		}
		elsif (/seguridad:(.*)/) {
			$seguridad = $1;
			$seguridad =~ s/^\s+//;
			$seguridad =~ s/\s+$//;
		}
		elsif (/dias contacto min:(.*)/) {
			$diasctmin = $1;
			$diasctmin =~ s/^\s+//;
			$diasctmin =~ s/\s+$//;
		}
		elsif (/dias contacto max:(.*)/) {
			$diasctmax = $1;
			$diasctmax =~ s/^\s+//;
			$diasctmax =~ s/\s+$//;
		}
	}
	close FILECONF;
}
else {
	print "No se ha encontrado el fichero de configuracion $fconf\n";
	exit(1);
}

# si hay seguridad comprobamos la galleta con la autorizacion
if  ( $seguridad == 1 ) {
	# comprobar autorizacion
	my $ipremota = $ENV{'REMOTE_ADDR'};
	my $galletas = $ENV{'HTTP_COOKIE'};

	# buscar galleta SESIONINV con el nombre del usuario, ip y la expiracion encriptados
	my @galletas = split /;/,$galletas;
	my $usuario = '';
	my $iporigen = '';
	foreach my $galleta ( @galletas ) {
		my ($nombre, $valor) = split /=/,$galleta;
		$nombre =~ s/^\s+//;
		if ( $nombre eq 'SESIONINV' ) {
			($usuario, $iporigen) = split /;/,$cripto->decryptA($valor)
		}
	}

	# comprobar si es la misma IP que autorizamos
	if ( $ipremota ne $iporigen ) {
		# saltar a la pagina de autorizacion
		print "Content-type: text/html\n\n";
		print "window.location='index.html';\n";
		exit;
	}
}

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";


# enviar la cabecera html
print "Content-type: text/html\n\n";

# leer tipos estado pc
my ($row, $row2);
my $orden="SELECT id,nombre FROM tipos WHERE tipo='ESTADO'";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	print "tiposestpc[$row->{id}]='$row->{nombre}';\n";
	$tipestpc{$row->{'id'}} = $row->{'nombre'};
}

# leer proveedores
my $pos = 1;
$orden="SELECT id,nombre FROM proveedores";
$sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
        $row->{nombre}=decode("UTF-8",$row->{nombre});
	print "idprov[$pos]='$row->{id}';\n";
	print "nomprov[$pos]='$row->{nombre}';\n";	
	$pos++;
	$nproveedores{$row->{'id'}} = $row->{'nombre'};
}


# enviar la cabecera de la tabla
print "document.write('<table id=\"tequipos\" class=\"tablesorter-blue\">');\n";
print "document.write('<thead>');\n";
print "document.write('<tr>');\n";
print "document.write('<th id=\"nfilas\" class=\"filter-false sorter-false\">Operación [ ]</th>');\n";
print "document.write('<th>Nombre</th>');\n";
print "document.write('<th>Proveedor</th>');\n";
print "document.write('<th>Pedido</th>');\n";
print "document.write('<th>Factura</th>');\n";
print "document.write('<th class=\"sorter-ddmmyyyy\">Fecha Compra</th>');\n";
print "document.write('<th class=\"sorter-ddmmyyyy\">En Garantía</th>');\n";
print "document.write('<th>Estado</th>');\n";
print "document.write('<th class=\"sorter-diasuc\">Fecha Contacto [$diasctmin-$diasctmax]</th>');\n";
print "document.write('<th class=\"filter-false sorter-false\">Notas</th>');\n";
print "document.write('<th>notasoculto</th>');\n";
print "document.write('</tr>');\n";
print "document.write('</thead>');\n";
print "document.write('<tbody id=\"tabla\">');\n";

$orden="SELECT id,name,lastcome,deviceid FROM hardware";
$sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	my ($anyo, $mes, $dia, $hora, $fucontacto, $ucontacto, $dias);
	my $efingarantia;

	next if ($row->{deviceid} eq "_SYSTEMGROUP_"); # descartar grupos

	# descartar los equipos que no hayan contactado en el numero de dias indicado
	($anyo,$mes,$dia,$hora) = $row->{'lastcome'} =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	$fucontacto = "$dia/$mes/$anyo $hora";
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	$ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);

	# diferencia de fechas
	$dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);
	
	$orden="SELECT proveedor,pedido,factura,fechacompra,fingarantia,estado,notas FROM otrosdatospc WHERE hardware_id='$row->{id}'";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	$row2 = $sth2->fetchrow_hashref;
	
	# convertir formato fechas
	# fecha compra
	my $fcompra = "";
	if (exists $row2->{'fechacompra'} ) {
		($anyo,$mes,$dia) = $row2->{'fechacompra'} =~ /(\d+)-(\d+)-(\d+)/;
		$fcompra = "$dia/$mes/$anyo";
		if ($fcompra eq "00/00/0000" ) { $fcompra = "" }
	}
	
	# garantia
	my $fgarantia= "";
	my $colorgar = "";
	if (exists $row2->{'fingarantia'} ) {
		($anyo,$mes,$dia) = $row2->{'fingarantia'} =~ /(\d+)-(\d+)-(\d+)/;
		$fgarantia = "$dia/$mes/$anyo";
		if ( $fgarantia eq "00/00/0000" ) {
			$fgarantia = ""
		} else {
			$mes = $mes-1;
			eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
			$efingarantia = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);
			# diferencia de fechas
			if ( (time-$efingarantia)/86400 > 0 ) {
				$colorgar = "red";
			} elsif ( ($efingarantia-time)/86400 < 30 ) {
				$colorgar = "yellow";
			}
		}
	}

       
	my $proveedor = $row2->{proveedor} ? $nproveedores{$row2->{proveedor}} : "";
	my $notas = $row2->{notas} ? $row2->{notas} : "";
	
	my $nombre = caresp($row->{name});
        
        $row2->{pedido}=decode("UTF-8", $row2->{pedido}); 
        $row2->{factura}=decode("UTF-8", $row2->{factura}); 
        $notas=decode("UTF-8", $notas); 

	print "document.write('<tr id=\"f$row->{id}\">".
#		"<td><button id=\"bb$row[0]\" data-eb=0 onClick=clicBotonEI(\"$row[0]\") class=\"botrosd\"><img src=\"imagenes/papelera_g.png\" alt=\"\"></button><button id=\"bm$row[0]\" data-eb=0 onClick=modOtrosDatos(\"$row[0]\") class=\"botrosd\"><img src=\"imagenes/table_edit.png\" alt=\"\"></button></td>".
		"<td><button eb=0 class=\"bborrar\"><img src=\"imagenes/papelera_g.png\" alt=\"\"></button><button eb=0 class=\"bmodificar\"><img src=\"imagenes/table_edit.png\" alt=\"\"></button></td>".
		"<td>$nombre</td>".
		"<td>$proveedor</td>".
		"<td>$row2->{pedido}</td>".
		"<td>$row2->{factura}</td>".
		"<td>$fcompra</td>".
		"<td style=\"background-color: $colorgar\">$fgarantia</td>".
		"<td>$tipestpc{$row2->{estado}}</td>".
		"<td>$fucontacto [$dias]</td>".
		"<td class=\"tdnotas\">Notas</td>".
		"<td>$notas</td>".
		"</tr>');\n";
}

print "document.write('</tbody>');\n"; 
print "document.write('</table>');\n"; 

$dbh->disconnect( );
exit;

# procesar caracteres que pueden confundir la orden document.write('... como ' < y >
sub caresp {
	my $texto = shift;
	$texto =~ s/'/&#x27;/g;
	$texto =~ s/"/&quot;/g;
	$texto =~ s/</&#x3c;/g;
	$texto =~ s/>/&#x3e;/g;
	$texto =~ s/\n/&#x0d;/g;	
	return $texto;
}
