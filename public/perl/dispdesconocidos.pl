#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	dispdesconocidos.pl
# DESCRIPTION:	lista por pantalla informacion adicional sobre los equipos desconocidos
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

# pendiente

use Encode;
use strict;
#use warnings;
use DBI;
use Time::Local;
use Net::Netmask;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

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
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $seguridad, $diasctmin, $diasctmax, $nb, $red, $centro);
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
		elsif (/red:(.*)/) {
			$tmp = $1;
			$tmp =~ s/^\s+//;
			$tmp =~ s/\s+$//;
			($red, $centro) = split /;/,$tmp;
                        $centro=decode("UTF-8", $centro);
			$nb = Net::Netmask->new2($red);
			if ($nb) {
				$nb->tag('centro', $centro);
				$nb->storeNetblock();
			}	
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

# enviar la cabecera de la tabla
print "document.write('<table id=\"tdispositivos\" class=\"tablesorter-blue\">');\n";
print "document.write('<thead>');\n";
print "document.write('<tr>');\n";
print "document.write('<th id=\"nfilas\" class=\"group-false\">MAC [ ]</th>');\n";
print "document.write('<th class=\"group-false\">ID MAC</th>');\n";
print "document.write('<th class=\"group-separator-1\">Centro</th>');\n";
print "document.write('<th class=\"group-false\">IP</th>');\n";
print "document.write('<th class=\"group-false\">Host</th>');\n";
print "document.write('<th class=\"group-false\">OS nombre</th>');\n";
print "document.write('<th class=\"group-false\">OS familia</th>');\n";
print "document.write('<th class=\"group-false\">OS tipo</th>');\n";
print "document.write('<th class=\"group-false\">OS empresa</th>');\n";
print "document.write('<th class=\"group-false\">Puertos</th>');\n";
print "document.write('<th class=\"group-false\">NetBios</th>');\n";
print "document.write('<th class=\"group-false\">sysName</th>');\n";
print "document.write('<th class=\"group-false\">sysDescr</th>');\n";
print "document.write('<th class=\"group-false sorter-diasuc\">Fecha Contacto [$diasctmin-$diasctmax]</th>');\n";
print "document.write('<th class=\"group-false\">Datos</th>');\n";
print "document.write('</tr>');\n";
print "document.write('</thead>');\n";
print "document.write('<tbody id=\"tabla\">');\n";

my ($anyo, $mes, $dia, $hora, $fucontacto, $ucontacto, $dias);

# dispositivos
#my $orden="SELECT id.mac,id.os_nombre,id.os_familia,id.os_fabricante,id.os_tipo,id.puertosabiertos,id.sysDescr,id.sysName,id.nbdominio,id.nbnombre,np.ip,np.date,np.name FROM identificaciondisp AS id INNER JOIN netmap AS np ON id.mac=np.mac WHERE id.conocido='0'";
my $orden="SELECT id.mac,id.os_nombre,id.os_familia,id.os_fabricante,id.os_tipo,id.puertosabiertos,id.sysDescr,id.sysName,id.nbdominio,id.nbnombre,np.ip,np.date,np.name FROM identificaciondisp AS id,netmap AS np WHERE id.mac=np.mac AND id.conocido='0'";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {

	if ( !defined($row->{ip}) ) {
		$row->{ip} = "&nbsp;";
	}
	
	my $bloque = findNetblock($row->{ip});
	$centro = $bloque ? $bloque->tag('centro') : "ND";

	# descartar los equipos que no hayan contactado en el numero de dias indicado
	($anyo,$mes,$dia,$hora) = $row->{date} =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	$fucontacto = "$dia/$mes/$anyo $hora";
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	$ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);

	# diferencia de fechas
	$dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);

	# averiguar el fabricante del dispositivo
	my $fabricante = "ND";
	my $mac = substr($row->{mac},0,8);
	$mac =~ s/://g;
	$orden="SELECT fabricante FROM macvendor WHERE mac='$mac'";
	my $sth3 = $dbh->prepare($orden);
	if ( $sth3->execute() > 0 ) {
		($fabricante) = $sth3->fetchrow_array;
		$fabricante =~ s/'/&#x27;/g;
	}
	$sth3->finish();

	# añadir espacios para que el tamaño de la columna se ajuste mejor
	$row->{puertosabiertos} =~ s/,/, /g;

	# hacer clicable el puerto 80
	if ( $row->{puertosabiertos} =~ /^80$/ ) {
		$row->{puertosabiertos} =~ s/80/<span class="tddisp">80<\/span>/;
	} elsif ( $row->{puertosabiertos} =~ /^80,/) {
		$row->{puertosabiertos} =~ s/80,/<span class="tddisp">80<\/span>,/;
	} elsif ( $row->{puertosabiertos} =~ /, 80,/) {
		$row->{puertosabiertos} =~ s/, 80,/, <span class="tddisp">80<\/span>,/;
	} elsif ( $row->{puertosabiertos} =~ /, 80$/) {
		$row->{puertosabiertos} =~ s/, 80$/, <span class="tddisp">80<\/span>/;
	}

	# nombre NetBios
	my $netbios	= $row->{nbdominio}."&#92;<br>".$row->{nbnombre};
	$netbios = ( $netbios =~ /^&#92;<br>$/ ) ? '' : $netbios;
	
	# saltos linea en sysDescr
	$row->{sysDescr} =~ s/\r//g;
	$row->{sysDescr} =~ s/\n/<br>/g;

	print "document.write('<tr>".
	"<td>$row->{mac}</td>".
	"<td>$fabricante</td>".
	"<td>$centro</td>".
	"<td>$row->{ip}</td>".
	"<td>$row->{name}</td>".
	"<td>$row->{os_nombre}</td>".
	"<td>$row->{os_familia}</td>".
	"<td>$row->{os_tipo}</td>".
	"<td>$row->{os_fabricante}</td>".
	"<td>$row->{puertosabiertos}</td>".
	"<td>$netbios</td>".
	"<td>$row->{sysName}</td>".
	"<td>$row->{sysDescr}</td>".
	"<td>$fucontacto [$dias]</td>".
	"<td class=\"tdnotas\">Datos</td>".
	"</tr>');\n";
}


print "document.write('</tbody>');\n"; 
print "document.write('</table>');\n";

$dbh->disconnect( );
exit;
