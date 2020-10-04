#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	administrarproveedores.pl
# DESCRIPTION:	muestra los proveedores, permite la modificacion y borra los seleccionados
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0


use Encode;
use strict;
#use warnings;
use DBI;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

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
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $seguridad, $diasctmin, $diasctmax, $red, $centro);
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
		elsif (/seguridad:(.*)/) {
			$seguridad = $1;
			$seguridad =~ s/^\s+//;
			$seguridad =~ s/\s+$//;
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

# si hay seguridad comprobamos la galleta con la autorizacion
if  ( $seguridad == 1 ) {
	# comprobar autorizacion
	my $ipremota = $ENV{'REMOTE_ADDR'};
	my $galletas = $ENV{'HTTP_COOKIE'};

	# buscar galleta SESIONINV con el nombre del usuario, ip y la expiracion encriptados
	my @galletas = split /;/,$galletas;
	my $usuario = '';
	my $iporigen = '';
	foreach my $galleta ( @galletas ) {
		my ($nombre, $valor) = split /=/,$galleta;
		$nombre =~ s/^\s+//;
		if ( $nombre eq 'SESIONINV' ) {
			($usuario, $iporigen) = split /;/,$cripto->decryptA($valor)
		}
	}

	# comprobar si es la misma IP que autorizamos
	if ( $ipremota ne $iporigen ) {
		# saltar a la pagina de autorizacion
		print "Content-type: text/html\n\n";
		print "window.location='index.html';\n";
		exit;
	}
}

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# enviar la cabecera html
print "Content-type: text/html\n\n";

# enviar la cabecera de la tabla
print "document.write('<table id=\"tproveedores\" class=\"tablesorter-blue\">');\n";
print "document.write('<thead>');\n";
print "document.write('<tr>');\n";
print "document.write('<th id=\"nfilas\" class=\"filter-false sorter-false\">Operación [ ]</th>');\n";
print "document.write('<th>Nombre</th>');\n";
print "document.write('<th>Dirección</th>');\n";
print "document.write('<th>Población</th>');\n";
print "document.write('<th>Provincia</th>');\n";
print "document.write('<th>CP</th>');\n";
print "document.write('<th>Pais</th>');\n";
print "document.write('<th>NIF</th>');\n";
print "document.write('<th>Web</th>');\n";
print "document.write('<th>Teléfono 1</th>');\n";
print "document.write('<th>Teléfono 2</th>');\n";
print "document.write('<th>Fax</th>');\n";
print "document.write('<th>Correo</th>');\n";
print "document.write('<th class=\"filter-false sorter-false\">Notas</th>');\n";
print "document.write('<th>notasoculto</th>');\n";
print "document.write('</tr>');\n";
print "document.write('</thead>');\n";


# primera linea para insertar nuevos dispositivos
# tbody separado con class="no_ordenar" para que sus filas no se ordenen ni filtren
print "document.write('<tbody class=\"no_ordenar\"><tr id=\"f0\"><td><button class=\"binsertar\" eb=0><img style=\"margin: 0 18px 0 18px\" src=\"imagenes/table_add.png\" alt=\"\"></button></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td class=\"tdnotas\">Notas</td><td></td></tr></tbody>');\n";

# tbody tabla principal
print "document.write('<tbody id=\"tabla\">');\n";

# proveedores
my $orden="SELECT id,nombre,direccion,poblacion,provincia,codpostal,pais,NIF,web,telefono1,telefono2,fax,correo,notas FROM proveedores";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
        $row->{nombre}=decode("UTF-8", $row->{nombre});
        $row->{direccion}=decode("UTF-8", $row->{direccion});
        $row->{poblacion}=decode("UTF-8",$row->{poblacion});
        $row->{provincia}=decode("UTF-8", $row->{provincia});
        $row->{pais}=decode("UTF-8", $row->{pais});
	$row->{notas}=decode("UTF-8", $row->{notas});

	print "document.write('<tr id=\"f$row->{id}\">".
		"<td><button eb=0 class=\"bborrar\"><img src=\"imagenes/papelera_g.png\" alt=\"\"></button><button eb=0 class=\"bmodificar\"><img src=\"imagenes/table_edit.png\" alt=\"\"></button></td>".
		"<td>$row->{nombre}</td>".
		"<td>$row->{direccion}</td>".
		"<td>$row->{poblacion}</td>".
		"<td>$row->{provincia}</td>".
		"<td>$row->{codpostal}</td>".
		"<td>$row->{pais}</td>".
		"<td>$row->{NIF}</td>".
		"<td>$row->{web}</td>".
		"<td>$row->{telefono1}</td>".
		"<td>$row->{telefono2}</td>".
		"<td>$row->{fax}</td>".
		"<td>$row->{correo}</td>".
		"<td class=\"tdnotas\">Notas</td>".
		"<td>$row->{notas}</td>".
		"</tr>');\n";
}

print "document.write('</tbody>');\n"; 
print "document.write('</table>');\n"; 

$dbh->disconnect( );
exit;
