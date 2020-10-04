#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	leerdispsc.pl
# DESCRIPTION:	lee un dispositivo SC determinado para su modificacion
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

# leer los valores pasados por una qs
my $id = $ENV{'QUERY_STRING'};
# convertir los caracteres especiales pasados como %xx donde xx es el valor hex
$id =~ s/(%(..))/chr(hex($2))/ge;

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


# enviar la cabecera de la tabla
print "Content-type: text/html\n\n";

# tipos dispositivos
my $orden="SELECT id,nombre FROM tipos WHERE tipo='ESTADO'";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (my @row = $sth->fetchrow_array) {
	my $idtipodis = $row[0];
	my $tipodis = $row[1];
	print "\$(\"<option value='$row[0]'>$row[1]</option>\").appendTo(\"#tipodispositivo\")\n";
}

# dispositivos sin conexion
$orden="SELECT id,descripcion,tipo,ubicacion,estado,numserie,responsable,proveedor,fechacompra FROM dispositivossc WHERE ID='$id'";
$sth = $dbh->prepare($orden);
$sth->execute();
while (my @row = $sth->fetchrow_array) {
	# convertir formato fecha
	my ($anyo,$mes,$dia) = $row[8] =~ /(\d+)-(\d+)-(\d+)/;
	my $fcompra = "$dia/$mes/$anyo";

	print "\$('#tipodispositivo').val('$row[2]');\n";
	print "\$('#descripcion').val('$row[1]');\n";
	print "\$('#ubicacion').val('$row[3]');\n";
	print "\$('#numserie').val('$row[5]');\n";
	print "\$('#estado').val('$row[4]');\n";
	print "\$('#responsable').val('$row[6]');\n";
	print "\$('#proveedor').val('$row[7]');\n";
	print "\$('#fechacompra').val('$fcompra');\n";	
}


$dbh->disconnect( );
exit;
