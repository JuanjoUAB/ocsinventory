#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	equipos.pl
# DESCRIPTION:	lista por pantalla los equipos que tienen instalada determinada aplicacion
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

# leer los valores pasados por una qs
my $valores = $ENV{'QUERY_STRING'};
my ($idapp) = $valores =~ /aplicacion=(.*)/;

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
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $diasctmin, $diasctmax, $nb, $red, $centro);
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
                        $centro=decode("UTF-8",$centro);
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

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# enviar la cabecera html
print "Content-type: text/html\n\n";

# obtener nombre aplicacion
my $orden = "SELECT name FROM softwares WHERE id='$idapp'";
my ($nomapp) = $dbh->selectrow_array($orden);

# mostrar el nombre en el titulo
# limitamos porque si el nombre es muy largo la cabecera se desborda
my $naplicacion = length($nomapp) > 36 ? substr($nomapp,0, 36).'...' : $nomapp;
$naplicacion = caresp($naplicacion);
print "\$(\"#titulo\").html('Equipos con la aplicación \"$naplicacion\" instalada');\n";

# escapamos los posibles apostrofes del nombre
$nomapp =~ s/'/''/g;

# enviar la cabecera de la tabla
print "document.write('<table id=\"tequipos\" class=\"tablesorter-blue\">');\n";
print "document.write('<thead>');\n";
print "document.write('<tr>');\n";
print "document.write('<th id=\"nfilas\" class=\"group-false\">Versi&oacuten [ ]</th>');\n";
print "document.write('<th class=\"group-false\">Nombre</th>');\n";
print "document.write('<th class=\"group-false\">Usuario</th>');\n";
print "document.write('<th class=\"group-separator-1\">Centro</th>');\n";
print "document.write('<th class=\"group-false\">[nCPUs] [CPU] [MHz]</th>');\n";
print "document.write('<th class=\"group-false\">Memoria MB</th>');\n";
print "document.write('<th class=\"group-false\">Disco total</th>');\n";
print "document.write('<th class=\"group-false\">Disco libre</th>');\n";
print "document.write('<th class=\"group-false\">IP</th>');\n";
print "document.write('<th class=\"group-false\">SO</th>');\n";
print "document.write('<th class=\"group-false sorter-diasuc\">Fecha Contacto [$diasctmin-$diasctmax]</th>');\n";
print "document.write('</tr>');\n";
print "document.write('</thead>');\n";
print "document.write('<tbody>');\n";

my ($row, $row2, $row3);
# contar las instalaciones
$orden = "SELECT DISTINCT version,hardware_id FROM softwares WHERE name='$nomapp' ORDER BY version";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	$orden="SELECT id,name,userid,ipaddr,osname,oscomments,processort,processorn,processors,memory,lastcome,deviceid,useragent FROM hardware WHERE id='$row->{hardware_id}'";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while ($row2 = $sth2->fetchrow_hashref) {
		my ($anyo, $mes, $dia, $hora, $fucontacto, $ucontacto, $dias);
		my ($sisop, $sp);
		my ($despacio, $dlibre);
		my ($nip, $clave);

		next if ($row2->{deviceid} eq "_SYSTEMGROUP_"); # descartar grupos

		# descartar los equipos que no hayan contactado en el numero de dias indicado
		($anyo,$mes,$dia,$hora) = $row2->{lastcome} =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
		$fucontacto = "$dia/$mes/$anyo $hora";
		$mes = $mes-1;
		eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
		$ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);

		# diferencia de fechas
		$dias = sprintf("%d",(time-$ucontacto)/86400);	
		next if ($dias > $diasctmax);
		next if ($dias < $diasctmin);

		# centro
		my $bloque = findNetblock($row2->{'ipaddr'});
		$centro = $bloque ? $bloque->tag('centro') : "ND";

		$sisop=$row2->{osname};
		$sisop =~ s/microsoft//i; # acortar nombre
		$sp=$row2->{oscomments};
		$sp =~ s/service pack/SP/i; # acortar nombre
		
		# discos
		$despacio = $dlibre = "";
		$orden="SELECT letter,type,total,free FROM drives where hardware_id=$row2->{id}";
		my $sth3 = $dbh->prepare($orden);
		$sth3->execute();
		while ($row3 = $sth3->fetchrow_hashref) {
			if ( $row2->{useragent} =~ /windows/i ) {
				next if ( $row3->{'type'} !~ /Hard Drive/); # descartar unidades de red, disqueteras y cd/dvds
				$despacio .= "$row3->{'letter'} ".sprintf ("%.0f",$row3->{'total'}/1024)." GB<br>";
				$dlibre .= "$row3->{'letter'} ".sprintf ("%.0f",$row3->{'free'}/1024)." GB<br>";
			} elsif ( ($row2->{useragent} =~ /unix/i) || ($row2->{useragent} =~ /android/i) ) {
				$despacio .= "($row3->{'type'}) ".sprintf ("%.0f",$row3->{'total'}/1024)." GB<br>";
				$dlibre .= "($row3->{'type'}) ".sprintf ("%.0f",$row3->{'free'}/1024)." GB<br>";
			}
		}
		$despacio =~ s/<br>$//;
		$dlibre =~ s/<br>$//;
		
		# redes
		$nip = "";
		$orden="SELECT ipaddress FROM networks where hardware_id=$row2->{id}";
		$sth3 = $dbh->prepare($orden);
		$sth3->execute();
		while ($row3 = $sth3->fetchrow_hashref) {
			if ( $row3->{'ipaddress'} ne "0.0.0.0" )  { $nip .= "$row3->{'ipaddress'}<br>" }
		}
		$nip =~ s/<br>$//;

		my $nombre = caresp($row2->{name});

		print "document.write('<tr>".
		"<td>$row->{version}</td>".
		"<td>$nombre</td>".
		"<td>$row2->{userid}</td>".
		"<td>$centro</td>".
		"<td>[$row2->{processorn}] [$row2->{processort}] [$row2->{processors}]</td>".
		"<td>$row2->{memory}</td>".
		"<td>$despacio</td>".
		"<td>$dlibre</td>".
		"<td>$nip</td>".
		"<td>$sisop [$sp]</td>".
		"<td>$fucontacto [$dias]</td>".
		"</tr>');\n";
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

