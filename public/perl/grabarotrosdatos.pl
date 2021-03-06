#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	grabarotrosdatos.pl
# DESCRIPTION:	graba en la BD los datos manuales modificados de un equipo
# AUTHOR:		Jos� Serena
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
# id=348&proveedor=1&pedido=PED01&factura=FAC01&fechacompra=2014-01-3&fingarantia=2015-1-3&estado=1&notas=Nota%201%3Cbr%3EFin%20nota%3Cbr%3E
my $valor = $ENV{'QUERY_STRING'};
# convertir los caracteres especiales pasados como %xx donde xx es el valor hex
$valor =~ s/\+/ /g;
$valor =~ s/%(..)/chr(hex($1))/ge;

# separar los datos
my @valores = split /&/,$valor;
foreach $valor ( @valores ) {
	my($columna,$dato) =  split /=/,$valor;
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

# enviar la cabecera de la tabla
print "Content-type: text/html\n\n";

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# comprobar si hemos entrado datos anteriormente en cuyo caso existira la ID y haremos un UPDATE y si no un INSERT
my $orden="SELECT * FROM otrosdatospc WHERE hardware_id='$datos{id}'";
my $sth = $dbh->prepare($orden);

my $res;
if ( $sth->execute() > 0 ) {
	# actualizar los datos modificados en la tabla de otros datos
	$res = $dbh->do("UPDATE otrosdatospc SET proveedor='$datos{proveedor}', pedido='$datos{pedido}', factura='$datos{factura}', fechacompra='$datos{fechacompra}',
						fingarantia='$datos{fingarantia}',estado='$datos{estado}', notas='$datos{notas}'
						WHERE hardware_id='$datos{id}'");
} else {
	# insertar los datos modificados en la tabla de otros datos
	$res = $dbh->do("INSERT INTO otrosdatospc VALUES ( '$datos{id}', '$datos{proveedor}', '$datos{pedido}', '$datos{factura}', '$datos{fechacompra}', '$datos{fingarantia}', '$datos{estado}', '$datos{notas}' )");
}

if ( $res eq "0E0" ) {
	print "\$( \"#resgrabar\" ).html( \"Error al grabar los datos\" );\n";
	print "\$( \"#resgrabar\" ).dialog( \"open\" );\n";
}

$sth->finish();
$dbh->disconnect( );

exit;
