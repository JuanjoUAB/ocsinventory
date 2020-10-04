#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	grabardocumento.pl
# DESCRIPTION:	graba en la BD el documento entrado
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

# convertir caracteres especiales
$datos{nfichero} =~ tr/ /_/;
$datos{nfichero} =~ tr/ÀÁÂÃÄÅàáâãäå/a/;
$datos{nfichero} =~ tr/ÈÉÊËèéêë/e/;
$datos{nfichero} =~ tr/ÌÍÎÏìíîï/i/;
$datos{nfichero} =~ tr/ÒÓÔÕÖØòóôõöø/o/;
$datos{nfichero} =~ tr/ÙÚÛÜùúûü/u/;
$datos{nfichero} =~ tr/ÇçÑñİıÿ/ccnnyyy/;
$datos{nfichero} =~ s/ß/ss/g;

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
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $diasctmin, $diasctmax, $red, $centro, $dirdocs);
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
		elsif (/dir documentos:(.*)/) {
			$dirdocs = $1;
			$dirdocs =~ s/^\s+//;
			$dirdocs =~ s/\s+$//;
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

# grabar los datos pasados en la tabla de documentos
my $res;
if ( $datos{fechadoc} ) {
	$res = $dbh->do("INSERT INTO documentos VALUES ( '', '$datos{tipodoc}', '$datos{proveedor}', '$datos{referencia}', '$datos{fechadoc}',
													'$datos{nfichero}', '$datos{notas}' )");
} else {
	$res = $dbh->do("INSERT INTO documentos VALUES ( '', '$datos{tipodoc}', '$datos{proveedor}', '$datos{referencia}', NULL,
													'$datos{nfichero}', '$datos{notas}' )");
}
										
if ( $res eq "0E0" ) {
	print "\$( \"#mensajegrabar\" ).html( \"Error al grabar la entrada del documento\" );\n";
} else {
	print "\$( \"#mensajegrabar\" ).html( \"Documento entrado\" );\n";
}
											
$dbh->disconnect( );



# esperar a que desaparezca el fichero de bloqueo
while ( -e $dirdocs.$datos{nfichero}.".lck" ) {
	sleep 1;
}

# renombrar el fichero grabado para incluir la id si no la tiene
if ( -e $dirdocs.$datos{nfichero} ) {
	my ($nuevonomfic, $extfic, $insertid);
	# averiguar la id asignada
	$insertid = $dbh->{'mysql_insertid'};

	if ( $datos{nfichero} =~ /\./ ) {
		($nuevonomfic, $extfic) = $datos{nfichero} =~ /(.*)\.(.*)/;
		$nuevonomfic .= "_$insertid.$extfic";	
	} else {
		$nuevonomfic = $datos{nfichero}."_$insertid";
	}
	rename $dirdocs.$datos{nfichero},$dirdocs.$nuevonomfic;
	
}
exit;
