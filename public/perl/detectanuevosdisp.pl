#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	detectanuevosdips.pl
# DESCRIPTION:	detecta nuevas macs en la tabla netmap y las graba en netmap_new
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();


# netmap
# ('192.168.156.113','00:10:40:11:30:D8','255.255.255.0','192.168.156.0','2013-05-08 06:10:55','192.168.156.113'),('192.168.156.113','00:10:40:11:31:1D','255.255.255.0','192.168.156.0','2013-07-03 06:07:14','192.168.156.113')
# 


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

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";


# buscar todos los dispositivos de netmap
my @row;
my $orden="SELECT ip,mac,mask,netid,date,name FROM netmap";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	# ver si existe la mac en la copia anterior
	$orden="SELECT mac FROM netmap_old where mac='$row[1]'";
	my $sth2 = $dbh->prepare($orden);
	if ( $sth2->execute() > 0 ) {

	} else {
		# averiguar el fabricante del dispositivo
		my $fabricante = "ND";
		my $mac = substr($row[1],0,8);
		$mac =~ s/://g;
		$orden="SELECT fabricante FROM macvendor WHERE mac='$mac'";
		my $sth3 = $dbh->prepare($orden);
		if ( $sth3->execute() > 0 ) {
			($fabricante) = $sth3->fetchrow_array;
			$fabricante =~ s/'/&#x27;/g;
		}
		$sth3->finish();

		# insertar el nuevo dispositivo en la copia antigua y en nuevos dispositivos
		$dbh->do("INSERT INTO netmap_old VALUES ( '$row[0]', '$row[1]', '$row[2]', '$row[3]', '$row[4]', '$row[5]' )");
		$dbh->do("INSERT INTO netmap_new VALUES ( '$row[0]', '$row[1]', '$row[2]', '$fabricante', '$row[4]', '$row[5]' )");
	}
	$sth2->finish();
}


$dbh->disconnect( );
exit;
