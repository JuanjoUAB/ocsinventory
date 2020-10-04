#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	estadisticasav.pl
# DESCRIPTION:	genera los datos para los graficos del AntiVirus McAfee
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
my %hvmcafee = ( "8.7.0.570" => 'v8.7.0', "8.8.0.777" => 'v8.8.0', "8.8.0.849" => 'v8.8.0 SP1', "8.8.0.948" => 'v8.8.0 SP2',
				 "8.8.0.975" => 'v8.8.0 SP2', "8.8.0.1128" => 'v8.8.0 SP3', "8.8.0.1247" => 'v8.8.0 SP4', "8.8.0.1385" => 'v8.8.0 SP5' );

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
	my $diasav = "&nbsp;";

	# datos AV McAfee
	$orden="SELECT regvalue,name FROM registry WHERE hardware_id=$row->{id}";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while ($row2 = $sth2->fetchrow_hashref) {	
		# version AV McAfee
		if ( $row2->{name} eq 'Version McAfee 32b' || $row2->{name} eq 'Version McAfee 64b' ) {
			if ( exists $row2->{regvalue} ) {
				$vav = $row2->{regvalue};
				$vav = $hvmcafee{$vav} ? $hvmcafee{$vav} : $vav;
				$hgrafvav{$vav}++;
			}
		}
	
		# version motor
		if ( $row2->{name} eq 'Version Motor AV 32b' || $row2->{name} eq 'Version Motor AV 64b' ) {
			if ( exists $row2->{regvalue} ) {
				$vmotor = $row2->{regvalue};
				$hgrafvmotor{$vmotor}++;
			}
		}
		
		# version DAT
		if ( $row2->{name} eq 'Version DAT AV 32b' || $row2->{name} eq 'Version DAT AV 64b' ) {
			if ( exists $row2->{regvalue} ) {
				$vdat = $row2->{regvalue};
				$hgrafvdat{$vdat}++;
			}
		}

		# fecha DAT McAfee
		if ( $row2->{name} eq 'Firma Antivirus McAfee' || $row2->{name} eq 'Firma Antivirus McAfee64b' ) {
			if ( exists $row2->{regvalue} ) {
				my ($anyoav, $mesav, $diaav) = $row2->{regvalue} =~ /(.*?)\/(.*?)\/(.*)/;
				my $fechadat = "$diaav/$mesav/$anyoav";
				$mesav--;
				eval { timelocal(0, 0, 1, $diaav, $mesav, $anyoav) }; # hay fechas erroneas que abortan el programa
				my $epocaav = $@ ? 0 : timelocal(0, 0, 1, $diaav, $mesav, $anyoav);
				my $diasav = sprintf("%d",(time-$epocaav)/86400);
				
				if ( $diasav > 30 ) {
					$hgrafdias{'+30'}++
				} elsif ( $diasav > 7 ) {
					$hgrafdias{'+7'}++
				} else {
					$hgrafdias{$diasav}++
				}
			}
		}
		if ( $vav eq "&nbsp;" ) { $hgrafvav{'ND'}++ }
		if ( $vmotor eq "&nbsp;" ) { $hgrafvmotor{'ND'}++ }
		if ( $vdat eq "&nbsp;" ) { $hgrafvdat{'ND'}++ }
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
foreach my $clave ( reverse sort ordversion (keys %hgrafvav) ) {
	print "datos4[$idx] = ['$clave', $hgrafvav{$clave}]\n";
	$idx++;
}

exit;

sub ordversion {
	my $c = version->parse( $a );
	my $d = version->parse( $b );
	$c <=> $d;
}
