#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	dispositivos.pl
# DESCRIPTION:	muestra los dispositivos, permite la modificacion y borra los seleccionados
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

# enviar la cabecera html
print "Content-type: text/html\n\n";

# enviar la cabecera de la tabla
print "document.write('<table id=\"tdispositivos\" class=\"tablesorter-blue\">');\n";
print "document.write('<thead>');\n";
print "document.write('<tr>');\n";
print "document.write('<th id=\"nfilas\" class=\"group-false filter-false sorter-false\">Operación [ ]</th>');\n";
print "document.write('<th class=\"group-false\">Descripción</th>');\n";
print "document.write('<th class=\"group-false\">Tipo</th>');\n";
print "document.write('<th class=\"group-separator-1\">Centro</th>');\n";
print "document.write('<th class=\"group-false\">IP</th>');\n";
print "document.write('<th class=\"group-false\">Mac</th>');\n";
print "document.write('<th class=\"group-false\">Num Serie</th>');\n";
print "document.write('<th class=\"group-false sorter-diasuc\">Fecha Contacto [$diasctmin-$diasctmax]</th>');\n";
print "document.write('<th class=\"filter-false sorter-false\">Notas</th>');\n";
print "document.write('<th>notasoculto</th>');\n";
print "document.write('</tr>');\n";
print "document.write('</thead>');\n";
print "document.write('<tbody id=\"tabla\">');\n";

my ($anyo, $mes, $dia, $hora, $fucontacto, $ucontacto, $dias);

# dispositivos
my $orden="SELECT id,description,type,macaddr FROM network_devices";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {

	# ip
	my ($ip, $fecha);
	$orden="SELECT ip,date FROM netmap where mac='$row->{macaddr}'";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	my @row2 = $sth2->fetchrow_array;
	if ( defined($row2[0]) ) {
		$ip = $row2[0];
		$fecha = $row2[1];		
	} else {
		$ip = "&nbsp;";
		$fecha = "&nbsp;";		
	}

	my $bloque = findNetblock($ip);
	$centro = $bloque ? $bloque->tag('centro') : "ND";

	# descartar los equipos que no hayan contactado en el numero de dias indicado
	($anyo,$mes,$dia,$hora) = $fecha =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	$fucontacto = "$dia/$mes/$anyo $hora";
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	$ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);

	# diferencia de fechas
	$dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);

	# numero serie y notas
	$orden="SELECT numserie,notas FROM otrosdatosdisp where id='$row->{id}'";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	my $row2 = $sth2->fetchrow_hashref;

       $row2->{numserie}=decode("UTF-8",$row2->{numserie});
       $row2->{notas}=decode("UTF-8",caresp($row2->{notas}));
    

	print "document.write('<tr id=\"f$row->{id}\">".
#		"<td><button id=\"bb$row[0]\" eb=0 class=\"bborrar\"><img src=\"imagenes/papelera_g.png\" alt=\"\"></button><button id=\"bm$row[0]\" eb=0 class=\"bmodificar\"><img src=\"imagenes/table_edit.png\" alt=\"\"></button></td>".
		"<td><button eb=0 class=\"bborrar\"><img src=\"imagenes/papelera_g.png\" alt=\"\"></button><button eb=0 class=\"bmodificar\"><img src=\"imagenes/table_edit.png\" alt=\"\"></button></td>".
		"<td class=\"tddisp\">$row->{description}</td>".
		"<td>$row->{type}</td>".
		"<td>$centro</td>".
		"<td>$ip</td>".
		"<td>$row->{macaddr}</td>".
		"<td>$row2->{numserie}</td>".
		"<td>$fucontacto [$dias]</td>".
		"<td class=\"tdnotas\">Notas</td>".
		"<td>$row2->{notas}</td>".
		"</tr>');\n";
}


print "document.write('</tbody>');\n"; 
print "document.write('</table>');\n";

$dbh->disconnect( );
exit;

sub caresp{
  my $texto = shift;
  $texto =~ s/\n/<br>/g;
  $texto =~ s/\r/<br>/g;
  return $texto;
}
