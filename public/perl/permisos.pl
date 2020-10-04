#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	permisos.pl
# DESCRIPTION:	lista por pantalla los permisos de los usuarios
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Time::Local;
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

# leer usuarios y permisos
$orden="SELECT * FROM perm_usuarios";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_hashref) {
	print "tiposestpc[$row[0]]='$row[1]';\n";
	$tipestpc{$row[0]} = $row[1];
}


# enviar la cabecera de la tabla
print "\$(\"#esptabla\").html('";
print "<table id=\"tequipos\" class=\"tablesorter-blue\">";
print "<thead>";
print "<tr>";
print "<th id=\"nfilas\" class=\"group-false\">Nombre [ ]</th>";
print "<th class=\"group-false\">Usuario</th>";
#print "<th class=\"group-separator-1 filter-select\" data-placeholder=\"Todos\">Centro</th>";
print "<th class=\"group-separator-1\">Centro</th>";
print "<th class=\"group-false\">[nCPUs] [CPU] [MHz]</th>";
print "<th class=\"group-false\">Memoria MB</th>";
print "<th class=\"group-false\">Disco total</th>";
print "<th class=\"group-false\">Disco libre</th>";
print "<th class=\"group-false\">IP</th>";
print "<th class=\"group-false\">SO</th>";
print "<th class=\"group-false filter-false sorter-false\">PC</th>";
print "<th class=\"group-false filter-false sorter-false\">Redes</th>";
print "<th class=\"group-false filter-false sorter-false\">Aplicaciones</th>";
print "<th class=\"group-false filter-false sorter-false\">Impresoras</th>";
print "<th class=\"group-false filter-false sorter-false\">Otros</th>";
print "<th class=\"group-false sorter-diasuc\">Fecha Contacto [$diasctmin-$diasctmax]</th>";
print "</tr>";
print "</thead>";
print "<tbody id=\"tabla\">";

my ($row, $row2);
# $modo = 0 => mostramos todos los equipos
# $modo = 1 => mostramos los equipos sin duplicados. Si hay equipos con el mismo nombre o MAC dejamos solo el mas reciente
# $modo = 2 => mostramos solo los equipos duplicados
my $orden="SELECT id,deviceid, name,ipaddr,lastcome FROM hardware";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	next if ($row->{deviceid} eq "_SYSTEMGROUP_"); # descartar grupos
	if ( $modo == 0 ) {
		$hequipos{$row->{id}} = "1";
	} elsif ( $modo == 1 ) {
		my ($anyo1,$mes1,$dia1,$hora1,$min1) = $row->{lastcome} =~ /(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):\d+/;
		$mes1 = $mes1-1;
		eval { timelocal(0, $min1, $hora1, $dia1, $mes1, $anyo1) }; # hay fechas erroneas que abortan el programa
		my $ucontacto1 = $@ ? 0 : timelocal(0, $min1, $hora1, $dia1, $mes1, $anyo1);
		
		if ( exists $hnombres{$row->{name}} ) {
			my ($id,$ucontacto2) = split /;/,$hnombres{$row->{name}};
			if ( $ucontacto1 > $ucontacto2 ) {
				$hnombres{$row->{name}} = "$row->{id};$ucontacto1";
			}
		} else {
			$hnombres{$row->{name}} = "$row->{id};$ucontacto1";
		}
		
		my $orden = "SELECT macaddr FROM networks WHERE hardware_id=$row->{id} AND ipaddress='$row->{ipaddr}'";
		my $row2 = $dbh->selectrow_hashref($orden);
		if ( exists $hmacs{$row2->{macaddr}} ) {
			my ($id1,$ucontacto1) = split /;/,$hnombres{$row->{name}};
			my ($id2,$ucontacto2) = split /;/,$hnombres{$hmacs{$row2->{macaddr}}};
			if ( $ucontacto1 > $ucontacto2 ) {
				delete $hnombres{$hmacs{$row2->{macaddr}}};
			} else {
				delete $hnombres{$row->{name}};
				$hmacs{$row2->{macaddr}} = $row->{name};
			}
		} else {
			$hmacs{$row2->{macaddr}} = $row->{name};
		}

	} elsif ( $modo == 2 ) {
		if ( exists $hnombres{$row->{name}} ) {
			$hduplicados{$hnombres{$row->{name}}} = "1";			
			$hduplicados{$row->{id}} = "1";
		} else {
			$hnombres{$row->{name}} = "$row->{id}";
		}
		
		my $orden = "SELECT macaddr FROM networks WHERE hardware_id=$row->{id} AND ipaddress='$row->{ipaddr}'";
		my $row2 = $dbh->selectrow_hashref($orden);
		next unless ($row2->{macaddr} );
		if ( exists $hmacs{$row2->{macaddr}} ) {
#			$hduplicados{$hnombres{$row->{name}}} = "1";
			$hduplicados{$hnombres{$hmacs{$row2->{macaddr}}}} = "1";				
			$hduplicados{$row->{id}} = "1";
		} else {
			$hmacs{$row2->{macaddr}} = $row->{id};
		}
		
	}
}
# generamos hequipos con los que se han de mostrar
if ( $modo == 1 ) {
	foreach my $nombre ( keys %hnombres ) {
		my ($id,$ucontacto) = split /;/,$hnombres{$nombre};
		$hequipos{$id} = 1;
	}
}
if ( $modo == 2 ) {
	foreach my $id (keys %hduplicados) {
		$hequipos{$id} = '1';
	}
}

$orden="SELECT id,name,workgroup,userid,ipaddr,osname,oscomments,processort,processorn,processors,memory,wincompany,winowner,winprodkey,lastcome,deviceid,useragent FROM hardware";
$sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	my ($anyo, $mes, $dia, $hora, $fucontacto, $ucontacto, $dias);
	my ($despacio, $dlibre);
	my ($nip, $clave);

	next if ($row->{deviceid} eq "_SYSTEMGROUP_"); # descartar grupos

	next if ( !exists $hequipos{$row->{id}} ); # comprobamos si hay que mostrar el equipo

	
	# descartar los equipos que no hayan contactado en el numero de dias indicado
	($anyo,$mes,$dia,$hora) = $row->{lastcome} =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	$fucontacto = "$dia/$mes/$anyo $hora";
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	$ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);

	# diferencia de fechas
	$dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);

	
	# centro
	my $bloque = findNetblock($row->{'ipaddr'});
	$centro = $bloque ? $bloque->tag('centro') : "ND";
	
	my $sisop=$row->{osname};
	$sisop =~ s/microsoft//i; # acortar nombre
	my $sp=$row->{oscomments};
	$sp =~ s/service pack/SP/i; # acortar nombre
	
	# discos
	$despacio = $dlibre = "";
	$orden="SELECT letter,type,total,free FROM drives where hardware_id=$row->{id}";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while ($row2 = $sth2->fetchrow_hashref) {
		if ( $row->{useragent} =~ /windows/i ) {
			next if ( $row2->{'type'} !~ /Hard Drive/); # descartar unidades de red, disqueteras y cd/dvds
			$despacio .= "$row2->{'letter'} ".sprintf ("%.0f",$row2->{'total'}/1024)." GB<br>";
			$dlibre .= "$row2->{'letter'} ".sprintf ("%.0f",$row2->{'free'}/1024)." GB<br>";
		} elsif ( ($row->{useragent} =~ /unix/i) || ($row->{useragent} =~ /android/i) ) {
			$despacio .= "($row2->{'type'}) ".sprintf ("%.0f",$row2->{'total'}/1024)." GB<br>";
			$dlibre .= "($row2->{'type'}) ".sprintf ("%.0f",$row2->{'free'}/1024)." GB<br>";
		}
	}
	$despacio =~ s/<br>$//;
	$dlibre =~ s/<br>$//;
	
	# redes
	$nip = "";
	$orden="SELECT ipaddress FROM networks where hardware_id=$row->{id}";
	$sth2 = $dbh->prepare($orden);
	$sth2->execute();

	while ($row2 = $sth2->fetchrow_hashref) {
		if ( $row2->{'ipaddress'} ne "0.0.0.0" )  { $nip .= "$row2->{'ipaddress'}<br>" }
	}
	$nip =~ s/<br>$//;

	print "<tr id=\"$row->{id}\">".
		"<td>$row->{name}</td>".
		"<td>$row->{userid}</td>".
		"<td>$centro</td>".
		"<td>[$row->{processorn}] [$row->{processort}] [$row->{processors}]</td>".
		"<td>$row->{memory}</td>".
		"<td>$despacio</td>".
		"<td>$dlibre</td>".
		"<td>$nip</td>".
		"<td>$sisop [$sp]</td>".
		"<td class=\"tdpc\">PC</td>".
		"<td class=\"tdred\">Red</td>".
		"<td class=\"tdapli\">Aplicaciones</td>".
		"<td class=\"tdimp\">Impresoras</td>".
		"<td class=\"tdotros\">Otros</td>".
		"<td>$fucontacto [$dias]</td>".
		"</tr>";

}

print "</tbody>"; 
print "</table>');\n";
print "datoscargados();\n"; 

$dbh->disconnect( );
exit;
