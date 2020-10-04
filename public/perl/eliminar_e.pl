#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	eliminar_e.pl
# DESCRIPTION:	borra la estaciones seleccionada de la base de datos
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
my $estacion = $ENV{'QUERY_STRING'};

# enviar la cabecera html
print "Content-type: text/html\n\n";

# conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# obtener el nombre de la estacion
my $orden="SELECT name FROM hardware WHERE id='$estacion'";
my $sth = $dbh->prepare($orden);
$sth->execute();
( my $nestacion ) = $sth->fetchrow_array;
$sth->finish();

$dbh->do("START TRANSACTION");

# obtener todas las tablas de la base de datos
my @row;
$orden="SHOW TABLES";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	my $tabla = $row[0];
	my $orden="SHOW COLUMNS FROM $tabla LIKE 'hardware_id'";
	my $sth2 = $dbh->prepare($orden);
	my $cuenta = $sth2->execute(); # devuelve el numero de filas encontradas o 0E0 sin no hay ninguna
	if ( $cuenta ne "0E0" ) { 
		my $orden="SELECT hardware_id FROM $tabla where hardware_id='$estacion'";
		my $sth3 = $dbh->prepare($orden);
		$cuenta = $sth3->execute();
		if ( $cuenta ne "0E0" ) {
			$c = $dbh->do("DELETE FROM $tabla WHERE hardware_id='$estacion'");
			if ( $c eq "0E0" ) { $terror .= "$tabla, " }
		}
	}
}


# borrar de la tabla principal 'hardware' donde la identificacion es id en vez de hardware_id
$c = $dbh->do("DELETE FROM hardware WHERE id='$estacion'");
if ( $c eq "0E0" ) { $terror .= "hardware, " }

$dbh->do("COMMIT");

if ( $terror ) {
	chop $terror;
	chop $terror;
	print "\$(\"#reseliminacion\").append(\"Errores al borrar $nestacion de las tablas $terror <br>\");\n";
} else {
	print "\$(\"#reseliminacion\").append(\"Estación $nestacion borrada<br>\");\n";
}

$dbh->disconnect( );			   
exit;
