#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	estadisticasav.pl
# DESCRIPTION:	genera los datos para los graficos del AntiVirus de Symantec Endpoint Protection
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Time::Local;
use version;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();


# hashes con datos para graficos
my %hgrafdias = ( 0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, '+7' => 0, '+30' => 0 );
my %hgrafvdat = ();
my %hgrafvmotor = ();
my %hgrafvav = ();

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
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $seguridad, $diasctmin, $diasctmax, $red, $centro);
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

# enviar la cabecera de la tabla
print "Content-type: text/html\n\n";



# datos PC y usuario
my ($row, $row2);
my ($anyoav, $mesav, $diaav, $vav, $vmotor, $vdat, $fechadat, $epocaav, $diasav);
my $orden="SELECT id,lastcome,deviceid FROM hardware";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	next if ($row->{deviceid} eq "_SYSTEMGROUP_"); # descartar grupos

	# descartar los equipos que no hayan contactado en el numero de dias indicado
	my($anyo,$mes,$dia,$hora) = $row->{lastcome} =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	my $ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);
	# diferencia de fechas
	my $dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);

	my $vav = "&nbsp;";	
	my $vmotor = "&nbsp;";
	my $vdat = "&nbsp;";
	my $fechadat = "&nbsp;";
	$anyoav = $mesav = $diaav = 0;

	# datos AV Symantec
	$orden="SELECT regvalue,name FROM registry WHERE hardware_id=$row->{id}";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while ($row2 = $sth2->fetchrow_hashref) {	
		# version AV Symantec SEP
		if ( $row2->{name} eq 'SEP_version' ) {
			if ( exists $row2->{regvalue} ) {
				$vav = $row2->{regvalue};
				$hgrafvav{$vav}++;
			}
		}

		# version motor		
		if ( $row2->{name} eq 'SEP_motor' ) {
			if ( exists $row2->{regvalue} ) {
				$vmotor = $row2->{regvalue};
				$hgrafvmotor{$vmotor}++;
			}
		}

		# version firmas
		if ( $row2->{name} eq 'SEP_firma' ) {
			if ( exists $row2->{regvalue} ) {
				($vdat) = $row2->{regvalue} =~ /.*\/(.*)/;
				$hgrafvdat{$vdat}++;
			}
		}
	}
	if ( $vav eq "&nbsp;" ) { $hgrafvav{'ND'}++ }
	if ( $vmotor eq "&nbsp;" ) { $hgrafvmotor{'ND'}++ }	
	if ( $vdat eq "&nbsp;" ) { $hgrafvdat{'ND'}++ }				
	
	
	# fecha firmas SEP
	if ( $vdat ne "&nbsp;" ) {
		($anyoav, $mesav, $diaav) = $vdat =~ /^(....)(..)(..)/;	
		$fechadat = "$diaav/$mesav/$anyoav";
	}

	# dias transcurridos
	if ( $anyoav ) {
		$mesav--;
		eval { timelocal(0, 0, 1, $diaav, $mesav, $anyoav) }; # hay fechas erroneas que abortan el programa
		$epocaav = $@ ? 0 : timelocal(0, 0, 1, $diaav, $mesav, $anyoav);
		$diasav = sprintf("%d",(time-$epocaav)/86400);
		if ( $diasav > 30 ) {
			$hgrafdias{'+30'}++
		} elsif ( $diasav > 7 ) {
			$hgrafdias{'+7'}++
		} else {
			$hgrafdias{$diasav}++
		}
	}

}

$dbh->disconnect( );

# pasar arrays con datos para graficos
my $idx = 0;
my @datosx = ( 0, 1, 2, 3, 4, 5, 6, 7, '+7', '+30' );
foreach my $valor ( @datosx ) {
	print "datos1[$idx] = ['$valor', $hgrafdias{$valor}]\n";
	$idx++;
}

$idx = 0;
foreach my $clave ( reverse sort keys %hgrafvdat ) {
	print "datos2[$idx] = ['$clave', $hgrafvdat{$clave}]\n";
	$idx++;
}

$idx = 0;
foreach my $clave ( reverse sort keys %hgrafvmotor ) {
	print "datos3[$idx] = ['$clave', $hgrafvmotor{$clave}]\n";
	$idx++;
}

$idx = 0;
foreach my $clave ( reverse sort (keys %hgrafvav) ) {
	print "datos4[$idx] = ['$clave', $hgrafvav{$clave}]\n";
	$idx++;
}

exit;

sub ordversion {
	my $c = version->parse( $a );
	my $d = version->parse( $b );
	$c <=> $d;
}
