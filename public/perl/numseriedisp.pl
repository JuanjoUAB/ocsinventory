#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:		numseriedisp.pl
# DESCRIPTION:	programa indepediente que intenta averiguar por snmp los numeros de serie de los dispositivos (usa cron)
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use DBI;
use Net::SNMP;
use Net::Ping;
use Crypt::Crypto;

# crear objetos 
my $ping = Net::Ping->new('icmp');
my $cripto = Crypt::Crypto->new();

my @comunidades = ('public','snmp2cug4t');

# lista mibs que pueden devolver el numero de serie
my @mibs = ( ".1.3.6.1.2.1.43.5.1.1.17.1" );

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
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $diasctmin, $diasctmax, $red, $centro);
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

# dispositivos
my $orden="SELECT id,type,macaddr FROM network_devices";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (my @row = $sth->fetchrow_array) {

	# ip
	$orden="SELECT ip FROM netmap where mac='$row[2]'";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	my ($ip) = $sth2->fetchrow_array;
	if ( defined($ip) ) {
		if ( $ping->ping($ip) ) {
			foreach my $comunidad ( @comunidades) {
				my ($sesion, $error) = Net::SNMP->session(
					-hostname  => $ip,
					-community => $comunidad,
				);

				if (defined $sesion) {
					foreach my $mib ( @mibs ) {
		#				$res = `snmpget -O T -v 1 -c public $ip $mib`;
						my $resultado = $sesion->get_request( $mib );
						if (defined $resultado) {
							my $numserie = $resultado->{$mib};
							# comprobar si hemos entrado datos anteriormente en cuyo caso existira la ID y haremos un UPDATE y si no un INSERT
							my $orden="SELECT * FROM otrosdatosdisp WHERE id='$row[0]'";
							my $sth3 = $dbh->prepare($orden);
							if ( $sth3->execute() > 0 ) {
								# actualizar los datos modificados en la tabla de otros datos del dispositivo
								$dbh->do("UPDATE otrosdatosdisp SET numserie='$numserie' WHERE ID='$row[0]'");
							} else {
								# insertar los datos modificados en la tabla de otros datos del dispositivo
								$dbh->do("INSERT INTO otrosdatosdisp VALUES ( '$row[0]', '$numserie', '' )");
							}
		#					last;
						} 
					}
					$sesion->close();
				}
			}
		}
	}
}


$dbh->disconnect( );
exit;
