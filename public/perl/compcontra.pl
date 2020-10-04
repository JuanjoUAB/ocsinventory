#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	compcontra.pl
# DESCRIPTION:	comprueba la contraseña de borrado de estaciones
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0


use strict;
#use warnings;
use DBI;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my %datos=();

# leer los valores pasados por una qs
my $qs = $ENV{'QUERY_STRING'};
# convertir los caracteres especiales pasados como %xx donde xx es el valor hex
$qs =~ s/(%(..))/chr(hex($2))/ge;

# separar los datos
my @valores = split /&/,$qs;
foreach $qs ( @valores ) {
	my($columna,$dato) =  split /=/,$qs;
	$datos{$columna} = $dato;
}

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
 
# enviar la cabecera html
print "Content-type: text/html\n\n";

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# password sadmin
my $orden="SELECT PASSWD FROM operators WHERE ID='admin' AND ACCESSLVL='1'";
my $sth = $dbh->prepare($orden);
$sth->execute();
my @row = $sth->fetchrow_array;

if ( $row[0] eq $datos{md5} ) {
	if ( $datos{tipo} == 1 ) {
		print "eliminarDispositivosBD();\n";
	} elsif ( $datos{tipo} == 2 ) {
		print "eliminarDispositivosSCBD();\n";
	} elsif ( $datos{tipo} == 3 ) {
		print "eliminarEstacionesBD();\n";
	} elsif ( $datos{tipo} == 4 ) {
		print "eliminarProveedoresBD();\n";
	} elsif ( $datos{tipo} == 5 ) {
		print "eliminarContactosBD();\n";
	} elsif ( $datos{tipo} == 6 ) {
		print "eliminarDocumentosBD();\n";
	} elsif ( $datos{tipo} == 7 ) {
		print "eliminarDispositivosNuevosBD();\n";
	}
} else {
	print "\$( \"#errorcont\" ).dialog( \"open\" );\n"
}

exit;
