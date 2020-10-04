#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	redes_u.pl
# DESCRIPTION:	llena el cuadro auxiliar de equipos con informacion de las redes
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my $id = $ENV{'QUERY_STRING'};

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

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";


# enviar la cabecera html
print "Content-type: text/html\n\n";

# redes
my $row;
my $ndescripcion = "";
my $nvelo = "";
my $nmac = "";
my $nip = "";
my $ngw = "";
my $nstatus = "";
my $ndhcp = "";
my $orden="SELECT description,speed,macaddr,ipaddress,ipgateway,status,ipdhcp FROM networks where hardware_id=$id";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	$ndescripcion .= "$row->{description}<br>";
	$nvelo .= "$row->{speed}<br>";
	$nmac .= "$row->{macaddr}<br>";
	$nip .= "$row->{ipaddress}<br>";
	$ngw .= "$row->{ipgateway}<br>";
	$nstatus .= "$row->{status}<br>";
	$ndhcp = ($row->{ipdhcp} eq "255.255.255.255") ? "$ndhcp<br>":"$ndhcp$row->{ipdhcp}<br>"
}
print "document.getElementById('tr1red').cells[0].innerHTML='$nip';\n";
print "document.getElementById('tr1red').cells[1].innerHTML='$nmac';\n";
print "document.getElementById('tr1red').cells[2].innerHTML='$nvelo';\n";
print "document.getElementById('tr1red').cells[3].innerHTML='$nstatus';\n";
print "document.getElementById('tr1red').cells[4].innerHTML='$ngw';\n";
print "document.getElementById('tr1red').cells[5].innerHTML='$ndhcp';\n";
print "document.getElementById('tr1red').cells[6].innerHTML='$ndescripcion';\n";

$dbh->disconnect( );
exit;
