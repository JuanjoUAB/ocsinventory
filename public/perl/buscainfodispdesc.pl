#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	buscainfodispdesc.pl
# DESCRIPTION:	busca informacion adicional por namp de los dispositivos desconocidos (sin agente y no registrados)
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

# pendiente
# actualizar fecha para poder descartar o eliminar los que esten fuera de rango
# eliminar dispositivos que no hayan contactado antes de x dias para evitar que la tabla crezca

use strict;
#use warnings;
use DBI;
use Time::Local;
use Net::Ping;
use Crypt::Crypto;
use Nmap::Parser;
use Net::SNMP;
use Net::NBName;


# crear objetos 
my $ping = Net::Ping->new('icmp');
my $np = new Nmap::Parser;
my $cripto = Crypt::Crypto->new();
my $nb = Net::NBName->new;

my $nmap_path;
if ( $^O eq "linux" ) {
	$nmap_path = '/usr/bin/nmap';
} elsif ( $^O eq "MSWin32" ) {
	$nmap_path = '"C:/Archivos de programa/Nmap/nmap.exe"';
}
my $nmap_args = '-v -A -oX -';

my @comunidades = ('public','snmp2cug4t');
my $oidbase = '1.3.6.1.2.1.1';
my $oidsysDescr = "1.3.6.1.2.1.1.1.0";
my $oidsysName = "1.3.6.1.2.1.1.5.0";
my ($sysDescr, $sysName);

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
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $diasmax);
$diasmax = 30;
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
		elsif (/dias contacto max dispositivos desconocidos:(.*)/) {
			$diasmax = $1;
			$diasmax =~ s/^\s+//;
			$diasmax =~ s/\s+$//;
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


# buscar todos los dispositivos de la tabla netmap
# ('192.168.156.113','00:10:40:11:30:D8','255.255.255.0','192.168.156.0','2013-05-08 06:10:55','192.168.156.113'),('192.168.156.113','00:10:40:11:31:1D','255.255.255.0','192.168.156.0','2013-07-03 06:07:14','192.168.156.113')
# 
my $orden="SELECT ip,mac,mask,netid,date,name FROM netmap";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ( my $row = $sth->fetchrow_hashref) {
	# dias ultimo contacto
	my ($anyo,$mes,$dia,$hora) = $row->{'date'} =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	my $ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);
	# diferencia de fechas
	my $dias = sprintf("%d",(time-$ucontacto)/86400);	
	
	# ver si existe la mac en la tabla identificaciondisp
	$orden="SELECT mac,conocido FROM identificaciondisp WHERE mac='$row->{'mac'}'";
	my $sth2 = $dbh->prepare($orden);
	
	if ( $sth2->execute() > 0 ) {
		# ver si el equipo esta marcado como conocido
		my $row2 = $sth2->fetchrow_hashref;
		next if ( $row2->{'conocido'} == 1 );
	
		# ver si el equipo es conocido (esta en networks o network_devices)
		my $res = versiconocido($row->{'mac'});
		if ( $res ) {
#			$dbh->do("START TRANSACTION");
			my $res2 = $dbh->do("UPDATE identificaciondisp SET conocido='1' where mac='$row->{'mac'}'");
#			$dbh->do("COMMIT");
			if ( $res2 eq "0E0" ) {
				print "Error al actualizar Conocido para $row->{'mac'}\n";
			}
		}
		# si el equipo hace tiempo que no se comunica lo borramos
		if ( $dias > $diasmax ) {
			my $res = $dbh->do("DELETE FROM identificaciondisp WHERE mac='$row->{'mac'}'");
			if ( $res eq "0E0" ) {
				print "Error al borrar el dispositivo antiguo $row->{'mac'}\n";
			}
		}
	} else {
		# ver si el equipo es conocido (esta en networks o network_devices)
		my $res = versiconocido($row->{'mac'});

		if ( $res ) {
#			$dbh->do("START TRANSACTION");
			my $res2 = $dbh->do("INSERT INTO identificaciondisp (mac, conocido) VALUES( '$row->{'mac'}', '1' ) ");
#			$dbh->do("COMMIT");
			if ( $res2 eq "0E0" ) {
				print "Error al insertar el dispositivo conocido $row->{'mac'}\n";
			}
			next;
		}

		next if ( $dias > $diasmax );
		# obtener informacion del dispositivo
		# ping para comprobar si el equipo esta activo
		if ( $ping->ping($row->{'ip'}) ) {
			### NMAP
			my $resnmap = `$nmap_path $nmap_args $row->{'ip'}`;
			$np->parse($resnmap);
			my $host_obj = $np->get_host($row->{'ip'});
			my $os = $host_obj->os_sig();
			my $nombre = $host_obj->hostname();
			my $mac = $host_obj->mac_addr();
			my $os_nombre = $os->name;
			my $os_familia = $os->osfamily;
			my $os_fabricante = $os->vendor;
			my $os_tipo = $os->type;
			my $puertosaabi = ( join ',',$host_obj->tcp_ports('open') );

			### SNMP
			$sysDescr = '';
			$sysName = '';			
			foreach my $comunidad ( @comunidades) {
				my ($sesion, $error) = Net::SNMP->session(
					-hostname  => $row->{'ip'},
					-community => $comunidad,
				);

				if (defined $sesion) {
					my $resultado = $sesion->get_table($oidbase);
					if (defined $resultado) {
						$sysDescr = $resultado->{$oidsysDescr} ? $resultado->{$oidsysDescr} : '';
						$sysName = $resultado->{$oidsysName} ? $resultado->{$oidsysName} : '';
					} 
					$sesion->close();
				}
			}

			### NETBIOS
			my $nbdominio = '';
			my $nbnombre = '';
			my $nbmac = '';
			my $ns = $nb->node_status($row->{'ip'});
			if ($ns) {
				for my $rr ($ns->names) {
					if ($rr->suffix == 0 && $rr->G eq "GROUP") {
						$nbdominio = $rr->name;
					}
					if ($rr->suffix == 0 && $rr->G eq "UNIQUE") {
						$nbnombre = $rr->name unless $rr->name =~ /^IS~/;
					}
				}
				$nbmac = $ns->mac_address;
			}
			$mac = $nbmac unless $mac;
			$mac =~ tr/-/:/; # windows usa - como separador, cambiamos al estandar :
			
			# solo tendremos macs para el segmento del servidor ocs o si ha respondio a NetBios
			# comprobamos que si hay mac las macs coinciden para segurarnos de que hemos escaneado el equipo correcto, la ip puede variar.
			if ( !$mac || ( uc($mac) eq uc($row->{'mac'}) ) ) {
#				$dbh->do("START TRANSACTION");
				my $res2 = $dbh->do("INSERT INTO identificaciondisp VALUES( '$row->{'mac'}', '0', '$os_nombre', '$os_familia', '$os_fabricante', '$os_tipo', '$puertosaabi', '$resnmap', '$sysDescr', '$sysName', '$nbdominio', '$nbnombre' ) ");
#				$dbh->do("COMMIT");
				if ( $res2 eq "0E0" ) {
					print "Error al insertar el dispositivo desconocido $row->{'mac'}\n";
				}
			}
		} 
	}
		
}


$dbh->disconnect( );
exit;

sub versiconocido {
	my $mac = shift;
	# ver si esta en network_devices o network en cuyo caso lo marcaremos como conocido
	my $fconocido = 0;

	my $orden="SELECT macaddr FROM networks WHERE macaddr='$mac'";
	my $sth = $dbh->prepare($orden);
	$fconocido = 1 if ( $sth->execute() > 0 );

	$orden="SELECT macaddr FROM network_devices WHERE macaddr='$mac'";
	$sth = $dbh->prepare($orden);
	$fconocido = 1 if ( $sth->execute() > 0 );

	return $fconocido;
}
