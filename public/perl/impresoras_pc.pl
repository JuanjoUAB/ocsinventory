#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	impresoras_pc.pl
# DESCRIPTION:	lista por pantalla todas las impresoras de todos los equipos
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

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

# enviar la cabecera de la tabla
print "Content-type: text/html\n\n";

print "document.write('<table id=\"timpresoraspc\" class=\"tablesorter-blue\">');\n";
print "document.write('<thead>');\n";
print "document.write('<tr>');\n";
print "document.write('<th id=\"nfilas\" class=\"group-false\">Nombre PC [ ]</th>');\n";
print "document.write('<th class=\"group-false\">Usuario</th>');\n";
print "document.write('<th class=\"group-separator-1\">Centro</th>');\n";
print "document.write('<th class=\"group-false\">IP</th>');\n";
print "document.write('<th class=\"group-false\">Impresora</th>');\n";
print "document.write('<th class=\"group-false\">Controlador</th>');\n";
print "document.write('<th class=\"group-false\">Puerto</th>');\n";
print "document.write('</tr>');\n";
print "document.write('</thead>');\n";
print "document.write('<tbody>');\n";

# usuarios
my (@row, @row2);
my $orden="SELECT id,name,userid,ipaddr,lastcome,deviceid FROM hardware";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	next if ($row[5] eq "_SYSTEMGROUP_"); # descartar grupos

	# descartar los equipos que no hayan contactado en el numero de dias indicado
	my ($anyo,$mes,$dia,$hora) = $row[4] =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	my $fucontacto = "$dia/$mes/$anyo $hora";
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	my $ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);

	# diferencia de fechas
	my $dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);

	my $bloque = findNetblock($row[3]);
	$centro = $bloque ? $bloque->tag('centro') : "ND";
		
	# impresoras
	$orden="SELECT name,driver,port FROM printers where hardware_id=$row[0]";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	my $fmulimp = 1;
	while (@row2 = $sth2->fetchrow_array) {
		next if ( lc($row2[1]) =~ /microsoft/ );
		next if ( lc($row2[1]) =~ /webex/ );
		next if ( lc($row2[1]) =~ /pdfcreator/ );
		
		my $nombrepc = caresp($row[1]);
		my $nombreimp = caresp($row2[0]);
		
		if ( $fmulimp ) {
			print "document.write('<tr><td>$nombrepc</td><td>$row[2]</td><td>$centro</td><td>$row[3]</td><td>$nombreimp</td><td>$row2[1]</td><td>$row2[2]</td></tr>');\n";
		} else {
			print "document.write('<tr><td class=\"lineaadicional\">$nombrepc</td><td class=\"lineaadicional\">$row[2]</td><td class=\"lineaadicional\">$centro</td><td class=\"lineaadicional\">$row[3]</td><td>$nombreimp</td><td>$row2[1]</td><td>$row2[2]</td></tr>');\n";
		}
		$fmulimp = 0;
	}

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
