#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	pc_u.pl
# DESCRIPTION:	llena el cuadro auxiliar de equipos con informacion varia del PC
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

my ($marca, $modelo, $nserie, $tipo);
my $orden="SELECT id,osname,oscomments,workgroup FROM hardware WHERE id=$id";
my $row = $dbh->selectrow_hashref($orden);

# bios
$orden="SELECT smanufacturer,smodel,ssn,type FROM bios where hardware_id=$row->{'id'}";
my $row2 = $dbh->selectrow_hashref($orden);
$tipo = (lc($row2->{'smanufacturer'}) =~ /vmware/) ? "Virtual" : $row2->{'type'};

print "document.getElementById('tr1pc').cells[0].innerHTML='$row2->{'smanufacturer'}';\n";
print "document.getElementById('tr1pc').cells[1].innerHTML='$row2->{'smodel'}';\n";
print "document.getElementById('tr1pc').cells[2].innerHTML='$tipo';\n";
print "document.getElementById('tr1pc').cells[3].innerHTML='$row2->{'ssn'}';\n";
print "document.getElementById('tr1pc').cells[4].innerHTML='$row->{osname}';\n";
print "document.getElementById('tr1pc').cells[5].innerHTML='$row->{oscomments}';\n";
print "document.getElementById('tr1pc').cells[6].innerHTML='$row->{workgroup}';\n";

$dbh->disconnect( );
exit;
