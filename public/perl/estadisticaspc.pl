#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	estadisticaspc.pl
# DESCRIPTION:	genera los datos para los graficos del PC
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0


use strict;
#use warnings;
use DBI;
use Time::Local;
use Net::Netmask;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

# hashes con datos para graficos
my %hgrafcentros = ();
my %hgrafcpu = ('Pentium' => 0, 'Celeron' => 0, 'Core2' => 0, 'Xeon' => 0, 'Core i3' => 0, 'Core i5' => 0, 'Core i7' => 0, 'Atom' => 0, 'Otras' => 0);
my %hgrafmem = ('-512MB' => 0, '512MB' => 0, '+512MB' => 0, '1GB' => 0, '+1GB' => 0, '2GB' => 0, '+2GB' => 0, '4GB' => 0, '+4GB' => 0, '8GB' => 0, '+8GB' => 0);
my %hgraftipopc = ('Sobremesa' => 0, 'Portatil' => 0, 'Virtual' => 0, 'Otro' => 0);
my %hgrafsobremesa = ();
my %hgrafportatil = ();
my %hgrafmarcas = ();
my %hgrafso = ();
my %hgrafsisop = ();
my %hgrafvelred = ();
my %hgrafdhcp = ();

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

# datos PC y usuario
my ($row, $row2);
my $orden="SELECT id,processort,memory,ipaddr,osname,oscomments,lastcome,deviceid FROM hardware";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	next if ($row->{deviceid} eq "_SYSTEMGROUP_"); # descartar grupos

	# descartar los equipos que no hayan contactado en el numero de dias indicado
	my ($anyo,$mes,$dia,$hora) = $row->{lastcome} =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	my $ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);
	# diferencia de fechas
	my $dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);


	# centro
	my $bloque = findNetblock($row->{'ipaddr'});
	$centro = $bloque ? $bloque->tag('centro') : "ND";
	if ( exists $hgrafcentros{$centro} ) {
		$hgrafcentros{$centro}++;
	} else {
		$hgrafcentros{$centro} = 1;
	}

	# tipo PC
	$orden="SELECT smanufacturer,type FROM bios where hardware_id=$row->{id}";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while ($row2 = $sth2->fetchrow_hashref) {
		my $fabricante = $row2->{smanufacturer} ? $row2->{smanufacturer} : 'ND';
		if ( exists $hgrafmarcas{$fabricante} ) {
			$hgrafmarcas{$fabricante}++;
		} else {
			$hgrafmarcas{$fabricante} = 1;
		}
	
		my $tipo = (lc($row2->{smanufacturer}) =~ /vmware/) ? "Virtual" : $row2->{type};
		if ( ( $tipo =~ /Desktop/i ) || ( $tipo =~ /Tower/i ) || ( $tipo =~ /Space-saving/i ) ) {
			$hgraftipopc{'Sobremesa'}++;
			$hgrafsobremesa{$centro}++;			
		} elsif ( ( $tipo =~ /Notebook/i ) || ( $tipo =~ /Portable/i ) || ( $tipo =~ /LapTop/i ) ) {
			$hgraftipopc{'Portatil'}++;
			$hgrafportatil{$centro}++;	
		} elsif ( $tipo =~ /Virtual/i ) {
			$hgraftipopc{'Virtual'}++
		} else {
			$hgraftipopc{'Otro'}++
		}
	}

	# CPU
	my $cpu = $row->{processort};
	if ( $cpu =~ /Xeon/ ) {
		$hgrafcpu{'Xeon'}++
	} elsif ( $cpu =~ /Pentium/i ) {
		$hgrafcpu{'Pentium'}++
	} elsif ( $cpu =~ /Core\(TM\) i3/i ) {
		$hgrafcpu{'Core i3'}++
	} elsif ( $cpu =~ /Core\(TM\) i5/i ) {
		$hgrafcpu{'Core i5'}++
	} elsif ( $cpu =~ /Core\(TM\) i7/i ) {
		$hgrafcpu{'Core i7'}++
	} elsif ( $cpu =~ /Core\(TM\)2/i ) {
		$hgrafcpu{'Core2'}++
	} elsif ( $cpu =~ /Celeron/i ) {
		$hgrafcpu{'Celeron'}++
	} elsif ( $cpu =~ /Atom/i ) {
		$hgrafcpu{'Atom'}++
	} else {
		$hgrafcpu{'Otras'}++
	}
	
	# Memoria
	my $memoria = $row->{memory};
	if ( $memoria > 8192 ) {
		$hgrafmem{'+8GB'}++
	} elsif ( $memoria == 8192 ) {
		$hgrafmem{'8GB'}++
	} elsif ( $memoria > 4096 ) {
		$hgrafmem{'+4GB'}++
	} elsif ( $memoria == 4096 ) {
		$hgrafmem{'4GB'}++
	} elsif ( $memoria > 2048 ) {
		$hgrafmem{'+2GB'}++
	} elsif ( $memoria == 2048 ) {
		$hgrafmem{'2GB'}++
	} elsif ( $memoria > 1024 ) {
		$hgrafmem{'+1GB'}++
	} elsif ( $memoria == 1024 ) {
		$hgrafmem{'1GB'}++
	} elsif ( $memoria > 512 ) {
		$hgrafmem{'+512MB'}++
	} elsif ( $memoria == 512 ) {
		$hgrafmem{'512MB'}++
	} else {
		$hgrafmem{'-512MB'}++
	}

	# SO
	my $so = $row->{osname};
	my $sp = $row->{oscomments};
	$so =~ s/microsoft//i; # acortar nombre
	$sp =~ s/service pack/SP/i; # acortar nombre
	if ( length($sp) > 10 ) {  # acortar nombre
		$sp = substr($sp,0,10);
		for ( my $x=9; $x>0; $x-- ) {
			if ( substr($sp,$x,1) eq ' ' ) {
				$sp = substr($sp,0,$x);
				last;
			}
		}
	}
	my $sisop = $so.' ['.$sp.']';
	if ( exists $hgrafso{$so} ) {
		$hgrafso{$so}++;
	} else {
		$hgrafso{$so} = 1;
	}
	
	if ( exists $hgrafsisop{$sisop} ) {
		$hgrafsisop{$sisop}++;
	} else {
		$hgrafsisop{$sisop} = 1;
	}

	# velocidad red
	$orden="SELECT speed,ipaddress,ipgateway,status,ipdhcp FROM networks where hardware_id=$row->{id}";
	$sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while ($row2 = $sth2->fetchrow_hashref) {
		next if ( $row2->{status} ne "Up" );
		my ($nvel, $tvel) =  $row2->{speed} =~ /(\d+) (\w)b\/s/; # 1 Gb/s
		if ($tvel eq 'G') { $nvel = $nvel*1000 }
		$hgrafvelred{$nvel}++;
		if (  $row2->{ipdhcp} && ($row2->{ipdhcp} ne '255.255.255.255') ) {	
			$hgrafdhcp{$row2->{ipdhcp}}++;
		} else {
			$hgrafdhcp{'estatica'}++;
		}
	}

}

$dbh->disconnect( );

# pasar arrays con datos para graficos
my @datosx;
my $idx = 0;
foreach my $centro ( sort keys %hgrafcentros ) {
	print "datos1[$idx] = ['$centro', $hgrafcentros{$centro}]\n";
	$idx++;
}

$idx = 0;
@datosx = ( 'Sobremesa', 'Portatil', 'Virtual', 'Otro' );
foreach my $valor ( @datosx ) {
	print "datos2[$idx] = ['$valor', $hgraftipopc{$valor}]\n";
	$idx++;
}

$idx = 0;
foreach my $centro ( sort keys %hgrafsobremesa ) {
	print "datos3[$idx] = ['$centro', $hgrafsobremesa{$centro}]\n";
	$hgrafportatil{$centro} = $hgrafportatil{$centro} || 0;
	print "datos4[$idx] = ['$centro', $hgrafportatil{$centro}]\n";
	$idx++;
}

$idx = 0;
@datosx = ( 'Core i7', 'Core i5', 'Core i3', 'Xeon', 'Core2', 'Pentium', 'Celeron', 'Atom', 'Otras' );
foreach my $valor ( @datosx ) {
	next if ( !$hgrafcpu{$valor} );
	print "datos5[$idx] = ['$valor', $hgrafcpu{$valor}]\n";
	$idx++;
}

$idx = 0;
@datosx = ( '-512MB', '512MB', '+512MB', '1GB', '+1GB', '2GB', '+2GB', '4GB', '+4GB', '8GB', '+8GB' );
foreach my $valor ( @datosx ) {
	next if ( !$hgrafmem{$valor} );
	print "datos6[$idx] = ['$valor', $hgrafmem{$valor}]\n";
	$idx++;
}

$idx = 0;
foreach my $marca ( sort keys %hgrafmarcas ) {
	print "datos7[$idx] = ['$marca', $hgrafmarcas{$marca}]\n";
	$idx++;
}

$idx = 0;
foreach my $so ( sort keys %hgrafso ) {
	print "datos8[$idx] = ['$so', $hgrafso{$so}]\n";
	$idx++;
}

$idx = 0;
foreach my $so ( sort keys %hgrafsisop ) {
	print "datos9[$idx] = ['$so', $hgrafsisop{$so}]\n";
	$idx++;
}

$idx = 0;
foreach my $velocidad ( reverse sort { $a <=> $b } keys %hgrafvelred ) {
	my $vel2;
	if ( $velocidad >= 1000 ) {
		$vel2 = ($velocidad/1000).' Gb/s'
	} else {
		$vel2 = $velocidad.' Mb/s'
	}
	print "datos10[$idx] = ['$vel2', $hgrafvelred{$velocidad}]\n";
	$idx++;
}

$idx = 0;
foreach my $dhcp ( sort keys %hgrafdhcp ) {
	print "datos11[$idx] = ['$dhcp', $hgrafdhcp{$dhcp}]\n";
	$idx++;
}

exit;

