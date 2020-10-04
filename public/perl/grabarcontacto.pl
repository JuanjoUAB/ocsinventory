#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	grabarcontacto.pl
# DESCRIPTION:	graba en la BD el contacto entrado
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my %datos=();

# leer los valores pasados por una qs
# tipo=1&descripcion=EPSON%20P-1234&ubicacion=Sala%20Verde&numserie=123456&responsable=Dpto%20TI&estado=Activo&fechacompra=01/01/2013
my $qs = $ENV{'QUERY_STRING'};
# convertir los caracteres especiales pasados como %xx donde xx es el valor hex
$qs =~ s/\+/ /g;
$qs =~ s/%(..)/chr(hex($1))/ge;

# separar los datos
my @valores = split /&/,$qs;
foreach $qs ( @valores ) {
	my($columna,$dato) =  split /=/,$qs;
	$datos{$columna} = $dato;
}

# recuperar posibles caracteres & y = en los datos
foreach my $clave (keys %datos) {
	$datos{$clave} =~ s/;amp;/&/g;
	$datos{$clave} =~ s/;igual;/=/g;
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
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $diasctmin, $diasctmax);
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

# enviar la cabecera de la tabla
print "Content-type: text/html\n\n";

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# grabar los datos pasados en la tabla de contactos
my $res = $dbh->do("INSERT INTO contactos VALUES ( '', '$datos{tipocont}', '$datos{nombre}', '$datos{apellidos}', '$datos{empresa}', '$datos{cargo}',
											'$datos{telefono1}', '$datos{telefono2}', '$datos{correo}', '$datos{notas}' )");
											
if ( $res eq "0E0" ) {
	print "\$( \"#resgrabar\" ).html( \"Error al grabar el contacto\" );\n";
	print "\$( \"#resgrabar\" ).dialog( \"open\" );\n";
} else {
	print "\$( \"#resgrabar\" ).html( \"Contacto grabado\" );\n";
	print "\$( \"#resgrabar\" ).dialog( \"open\" );\n";
}
											
$dbh->disconnect( );
exit;
