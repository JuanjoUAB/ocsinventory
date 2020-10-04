#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	eliminar_dnue.pl
# DESCRIPTION:	borra el dispositivo detectado como nuevo
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
my $macdispositivo = $ENV{'QUERY_STRING'};
$macdispositivo =~ tr/-/:/;

# enviar la cabecera html
print "Content-type: text/html\n\n";

# conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# obtener la ID y descripcion del dispositivo
my $orden="SELECT name FROM netmap_new WHERE mac='$macdispositivo'";
my $sth = $dbh->prepare($orden);
$sth->execute();
my ( $nombre ) = $sth->fetchrow_array;
$sth->finish();
			   
$dbh->do("START TRANSACTION");

# borrar de la tabla 'netmap_new'
$c = $dbh->do("DELETE FROM netmap_new WHERE mac='$macdispositivo'");
if ( $c eq "0E0" ) { $terror .= "netmap_new, " }

$dbh->do("COMMIT");

if ( $terror ) {
	chop $terror;
	chop $terror;
	print "\$(\"#reseliminacion\").append(\"Errores al borrar $nombre/$macdispositivo de las tablas $terror <br>\");\n";
} else {
	print "\$(\"#reseliminacion\").append(\"Dispositivo $nombre/$macdispositivo borrado<br>\");\n";
}

$dbh->disconnect( );			   
exit;
