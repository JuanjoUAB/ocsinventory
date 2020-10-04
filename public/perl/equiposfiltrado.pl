#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	equiposfiltrado.pl
# DESCRIPTION:	lista por pantalla la configuracion general de los equipos
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

my %datos=();

# leer los valores pasados por una qs
my $qs = $ENV{'QUERY_STRING'};
# convertir los caracteres especiales pasados como %xx donde xx es el valor hex
$qs =~ s/%(..)/chr(hex($1))/ge;

# separar los datos
my @valores = split /&/,$qs;
foreach $qs ( @valores ) {
	my($columna,$dato) =  split /=/,$qs;
	$datos{$columna} = $dato;
}

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
		elsif (/dias contacto min:(.*)/) {
			$diasctmin = $1;
			$diasctmin =~ s/^\s+//;
			$diasctmin =~ s/\s+$//;
		}
		elsif (/seguridad:(.*)/) {
			$seguridad = $1;
			$seguridad =~ s/^\s+//;
			$seguridad =~ s/\s+$//;
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

# enviar la cabecera de la tabla
print "document.write('<table id=\"tequipos\" class=\"tablesorter-blue\">');\n";
print "document.write('<thead>');\n";
print "document.write('<tr>');\n";
print "document.write('<th id=\"nfilas\" class=\"group-false\">Nombre [ ]</th>');\n";
print "document.write('<th class=\"group-false\">Usuario</th>');\n";
print "document.write('<th class=\"group-word\">Centro</th>');\n";
print "document.write('<th class=\"group-false\">[nCPUs] [CPU] [MHz]</th>');\n";
print "document.write('<th class=\"group-false\">Memoria MB</th>');\n";
print "document.write('<th class=\"group-false\">Disco total</th>');\n";
print "document.write('<th class=\"group-false\">Disco libre</th>');\n";
print "document.write('<th class=\"group-false\">IP</th>');\n";
print "document.write('<th class=\"group-false\">SO</th>');\n";
print "document.write('<th class=\"group-false filter-false\">PC</th>');\n";
print "document.write('<th class=\"group-false filter-false\">Redes</th>');\n";
print "document.write('<th class=\"group-false filter-false\">Aplicaciones</th>');\n";
print "document.write('<th class=\"group-false filter-false\">Impresoras</th>');\n";
print "document.write('<th class=\"group-false filter-false\">Otros</th>');\n";
print "document.write('<th class=\"group-false sorter-diasuc\">Fecha Contacto [$diasctmin-$diasctmax]</th>');\n";
print "document.write('</tr>');\n";
print "document.write('</thead>');\n";
print "document.write('<tbody id=\"tabla\">');\n";

my ($row, $row2);
my $orden="SELECT id,name,workgroup,userid,ipaddr,osname,oscomments,processort,processorn,processors,memory,wincompany,winowner,winprodkey,lastcome,deviceid,useragent FROM hardware";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	my ($anyo, $mes, $dia, $hora, $fucontacto, $ucontacto, $dias);
	my ($despacio, $dlibre);
	my ($nip, $clave);

	next if ($row->{deviceid} eq "_SYSTEMGROUP_"); # descartar grupos

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
	
	# aplicar posible filtro cpu
	my $cpupc = 'Otras';
	if ( $row->{processort} =~ /Xeon/ ) {
		$cpupc = 'Xeon'
	} elsif ( $row->{processort} =~ /Pentium/i ) {
		$cpupc = 'Pentium'
	} elsif ( $row->{processort} =~ /Core\(TM\) i3/i ) {
		$cpupc = 'Core i3'
	} elsif ( $row->{processort} =~ /Core\(TM\) i5/i ) {
		$cpupc = 'Core i5'
	} elsif ( $row->{processort} =~ /Core\(TM\) i7/i ) {
		$cpupc = 'Core i7'
	} elsif ( $row->{processort} =~ /Core\(TM\)2/i ) {
		$cpupc = 'Core2'
	} elsif ( $row->{processort} =~ /Celeron/i ) {
		$cpupc = 'Celeron'
	} elsif ( $row->{processort} =~ /Atom/i ) {
		$cpupc = 'Atom'
	}
	next if ( ( exists $datos{'cpu'} ) && ( $datos{'cpu'} ne $cpupc ) );

	# aplicar posible filtro memoria
	my $memoriapc = '-512MB';
	if ( $row->{memory} > 8192 ) {
		$memoriapc = '+8GB'
	} elsif ( $row->{memory} == 8192 ) {
		$memoriapc = '8GB'
	} elsif ( $row->{memory} > 4096 ) {
		$memoriapc = '+4GB'
	} elsif ( $row->{memory} == 4096 ) {
		$memoriapc = '4GB'
	} elsif ( $row->{memory} > 2048 ) {
		$memoriapc = '+2GB'
	} elsif ( $row->{memory} == 2048 ) {
		$memoriapc = '2GB'
	} elsif ( $row->{memory} > 1024 ) {
		$memoriapc = '+1GB'
	} elsif ( $row->{memory} == 1024 ) {
		$memoriapc = '1GB'
	} elsif ( $row->{memory} > 512 ) {
		$memoriapc = '+512MB'
	} elsif ( $row->{memory} == 512 ) {
		$memoriapc = '512MB'
	}
	next if ( ( exists $datos{'memoria'} ) && ( $datos{'memoria'} ne $memoriapc ) );

	# aplicar posible filtro SO
	my $sopc = $row->{osname};
	$sopc =~ s/microsoft//i; # acortar nombre
	next if ( ( exists $datos{'sopc'} ) && ( $datos{'sopc'} ne $sopc ) );

	# aplicar posible filtro SO+SP
	$sopc = $row->{osname};
	my $sppc = $row->{oscomments};
	$sopc =~ s/microsoft//i; # acortar nombre
	$sppc =~ s/service pack/SP/i; # acortar nombre
	my $sisop = $sopc.' ['.$sppc.']';
	next if ( ( exists $datos{'sisoppc'} ) && ( $datos{'sisoppc'} ne $sisop ) );

	# bios
	my $tipo;
	my $marca;
	$orden="SELECT smanufacturer,type FROM bios where hardware_id=$row->{id}";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while ($row2 = $sth2->fetchrow_hashref) {
		$marca = $row2->{smanufacturer};
		$tipo = (lc($row2->{smanufacturer}) =~ /vmware/) ? "Virtual" : $row2->{type};
	}

	# aplicar posible filtro marca
	my $marcapc = $marca || 'ND';
	next if ( ( exists $datos{'marca'} ) && ( $datos{'marca'} ne $marcapc ) );

	# aplicar posible filtro tipo
	my $tipopc = 'Otro';
	if ( ( $tipo =~ /Desktop/i ) || ( $tipo =~ /Tower/i ) || ( $tipo =~ /Space-saving/i ) ) {
		$tipopc = 'Sobremesa';
	} elsif ( ( $tipo =~ /Notebook/i ) || ( $tipo =~ /Portable/i ) || ( $tipo =~ /LapTop/i ) ) {
		$tipopc = 'Portatil';
	} elsif ( $tipo =~ /Virtual/i ) {
		$tipopc = 'Virtual';
	} 
	next if ( ( exists $datos{'tipo'} ) && ( $datos{'tipo'} ne $tipopc ) );
	

	# discos
	$despacio = $dlibre = "";
	$orden="SELECT letter,type,total,free FROM drives where hardware_id=$row->{id}";
	$sth2 = $dbh->prepare($orden);
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
	my $fvred = 1;
	my $fsdhcp = 1;
	$orden="SELECT speed,ipaddress,status,ipdhcp FROM networks where hardware_id=$row->{id}";
	$sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while ($row2 = $sth2->fetchrow_hashref) {
		next if ( $row2->{'status'} ne "Up" );

		if ( ( exists $datos{'velred'} ) && ( $datos{'velred'} eq $row2->{'speed'} ) ) {
			$fvred = 0;
		}
		if ( ( $row2->{'ipdhcp'} eq '255.255.255.255') || (!$row2->{'ipdhcp'}) ) { $row2->{'ipdhcp'} = 'estatica' }
		if ( ( exists $datos{'dhcp'} ) && ( $datos{'dhcp'} eq $row2->{'ipdhcp'} ) ) {
			$fsdhcp = 0;
		}

		if ( $row2->{'ipaddress'} ne "0.0.0.0" )  { $nip .= "$row2->{'ipaddress'}<br>" }
	}
	$nip =~ s/<br>$//;

        # aplicar posible filtro centro
	my $bloque = findNetblock($row->{'ipaddr'});
	$centro = $bloque ? $bloque->tag('centro') : "ND";
	next if ( ( exists $datos{'centro'} ) && ( $datos{'centro'} ne $centro ) );

	# aplicar posible filtro velocidad red
	next if ( ( exists $datos{'velred'} ) &&  $fvred );

	# aplicar posible filtro servidor dhcp
	next if ( ( exists $datos{'dhcp'} ) &&  $fsdhcp );

	my $nombre = caresp($row->{name});

	print "document.write('<tr id=\"$row->{id}\">".
		"<td>$nombre</td>".
		"<td>$row->{userid}</td>".
		"<td>$centro</td>".
		"<td>[$row->{processorn}] [$row->{processort}] [$row->{processors}]</td>".
		"<td>$row->{memory}</td>".
		"<td>$despacio</td>".
		"<td>$dlibre</td>".
		"<td>$nip</td>".
		"<td>$sisop</td>".
		"<td class=\"tdpc\">PC</td>".
		"<td class=\"tdred\">Red</td>".
		"<td class=\"tdapli\">Aplicaciones</td>".
		"<td class=\"tdimp\">Impresoras</td>".
		"<td class=\"tdotros\">Otros</td>".
		"<td>$fucontacto [$dias]</td>".
		"</tr>');\n";
}

print "document.write('</tbody>');\n"; 
print "document.write('</table>');\n";
print "datoscargados();\n";

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

