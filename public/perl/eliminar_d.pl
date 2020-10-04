#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	eliminar_d.pl
# DESCRIPTION:	borra el dispositivo seleccionado de la base de datos
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my $terror = "";
my $c;

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

# leer la id de la estacion a borrar qs
my $iddispositivo = $ENV{'QUERY_STRING'};

# enviar la cabecera html
print "Content-type: text/html\n\n";

# conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# obtener la ID y descripcion del dispositivo
my $orden="SELECT description,macaddr FROM network_devices WHERE id='$iddispositivo'";
my $sth = $dbh->prepare($orden);
$sth->execute();
my ( $descdispositivo,$macdispositivo, ) = $sth->fetchrow_array;
$sth->finish();
			   
$dbh->do("START TRANSACTION");

# borrar de la tabla 'network_devices'
$c = $dbh->do("DELETE FROM network_devices WHERE id='$iddispositivo'");
if ( $c eq "0E0" ) { $terror .= "network_devices, " }

# borrar de la tabla 'netmap'
$c = $dbh->do("DELETE FROM netmap WHERE mac='$macdispositivo'");
if ( $c eq "0E0" ) { $terror .= "netmap, " }

# borrar de la tabla 'otrosdatosdisp'
# comprobar si hemos entrado datos anteriormente en cuyo caso existira la ID
my $orden="SELECT * FROM otrosdatosdisp WHERE id='$iddispositivo'";
my $sth = $dbh->prepare($orden);
if ( $sth->execute() > 0 ) {
	$c = $dbh->do("DELETE FROM otrosdatosdisp WHERE id='$iddispositivo'");
	if ( $c eq "0E0" ) { $terror .= "otrosdatosdisp, " }
}

$dbh->do("COMMIT");

if ( $terror ) {
	chop $terror;
	chop $terror;
	print "\$(\"#reseliminacion\").append(\"Errores al borrar $descdispositivo de las tablas $terror <br>\");\n";
} else {
	print "\$(\"#reseliminacion\").append(\"Dispositivo $descdispositivo borrado<br>\");\n";
}

$dbh->disconnect( );			   
exit;
