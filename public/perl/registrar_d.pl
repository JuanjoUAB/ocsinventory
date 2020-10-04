#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	registrar_d.pl
# DESCRIPTION:	registra como dispositivos conocidos los dispositivos desconocidos seleccionados
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

# pendiente
# hay que crear una entrada en la tabla network_devices
# añadir las notas en 
# marcar como conocido el dispositivo entrado (solo marcar o borrar la info de nmap), mejor mantenerla 
# 

use strict;
#use warnings;
use DBI;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my ($linea, $macdispositivos);

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
	}
	close FILECONF;
}
else {
	print "No se ha encontrado el fichero de configuracion $fconf\n";
	exit(1);
}

# leer parametros pasados
if ($ENV{'REQUEST_METHOD'} eq "GET") {
	$macdispositivos = $ENV{'QUERY_STRING'};
} elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
	read(STDIN, $macdispositivos, $ENV{'CONTENT_LENGTH'}) || die "No puedo leer los parametros\n";
}

#$macdispositivos = 'Impresora;00:01:E6:6F:85:34;00:01:E6:71:9C:F5;00:14:38:9B:29:6E;00:17:A4:98:87:1A;00:23:7D:7B:73:06;AC:16:2D:3B:F5:E9;';
my @macdispositivos = split /;/,$macdispositivos;
my $tipodispositivo = shift @macdispositivos; # el primer elemento es el tipo de dispositivo

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 0, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# enviar la cabecera html
print "Content-type: text/html\n\n";

foreach my $macdisp (@macdispositivos) {
	# comprobar que no exista la mac en la tabla network_devices
	my $orden="SELECT id,description,type,macaddr FROM network_devices WHERE macaddr='$macdisp'";
	my $sth = $dbh->prepare($orden);
	if ( $sth->execute() > 0 ) {
		print "ERROR: El dispositivo con MAC=$macdisp ya esta registrado<br>\n";
		next;
	}

	$orden="SELECT id.mac,id.os_nombre,id.os_familia,id.os_fabricante,id.os_tipo,id.sysDescr,id.sysName,id.nbdominio,id.nbnombre,np.ip,np.date,np.name FROM identificaciondisp AS id,netmap AS np WHERE id.mac='$macdisp' AND np.mac='$macdisp'";
	$sth = $dbh->prepare($orden);
	$sth->execute();
	my $hinfodisp = $dbh->selectrow_hashref($orden);

	if ( !$hinfodisp->{sysName} ) {
		$hinfodisp->{sysName} = "$tipodispositivo $macdisp";
	}

	# nombre NetBios
	my $nombrenetbios = $hinfodisp->{nbdominio} ? "$hinfodisp->{nbdominio}"."&#92;"."$hinfodisp->{nbnombre}" : "$hinfodisp->{nbnombre}";
	$nombrenetbios =  $nombrenetbios ? "NetBios: $nombrenetbios" : '';

	my $notasdisp = "sysDescr: $hinfodisp->{sysDescr}<br>$nombrenetbios<br>Nombre SO: $hinfodisp->{os_nombre}<br>Tipo SO: $hinfodisp->{os_tipo}<br>Fabricante: $hinfodisp->{os_fabricante}";
	$notasdisp =~ s/(<br>){2,}/<br>/g; # eliminar saltos de linea multiples

	# insertar los datos modificados en la tabla dispositivos
	#(1,'SAI MGE Galaxy 3000 30 kVA ','SAIs','00:E0:D8:0A:53:9A','admin')
	my $res = $dbh->do("INSERT INTO network_devices VALUES ( '', '$hinfodisp->{sysName}', '$tipodispositivo', '$macdisp', 'admin' )");
	if ( $res eq "0E0" ) {
		print "ERROR: Error al registrar el dispositivo con MAC=$macdisp<br>\n";
		next;
	} else {
		# averiguar la ID del dispositivo recien creado
		$orden="SELECT id FROM network_devices WHERE macaddr='$macdisp'";
		$sth = $dbh->prepare($orden);
		$sth->execute();
		my ($idnuevodisp) = $dbh->selectrow_array($orden);
		# insertar los datos modificados en la tabla de otros datos del dispositivo
		$res = $dbh->do("INSERT INTO otrosdatosdisp VALUES ( '$idnuevodisp', '', '$notasdisp' )");
		if ( $res eq "0E0" ) {
			print "ERROR: Error al registrar el dispositivo con MAC=$macdisp<br>\n";
			next;
		}
	}
	
	# marcamos el dispositivo registrado como conocido
	my $res2 = $dbh->do("UPDATE identificaciondisp SET conocido='1' where mac='$macdisp'");
	if ( $res2 eq "0E0" ) {
		print "ERROR: Error al actualizar Conocido para $macdisp<br>\n";
	} else {
		print "Se ha registrado el dispositivo $tipodispositivo con MAC=$macdisp<br>\n";
	}
}


exit;
