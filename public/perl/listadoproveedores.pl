#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	listadoproveedores.pl
# DESCRIPTION:	genera Excel con los datos de los proveedores y los contactos
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Excel::Writer::XLSX;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my %nempresa = ();
my %tiposcontacto = ();

my $dirficheros = "/tmp";
$dirficheros = "c:/xampp/cgi-bin/inventario" if ( $^O eq "MSWin32" );
my $nomlista = "Listado_proveedores";

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

my @datosprov = ( "Nombre", 20, "Dirección", 40, "Población", 30, "Provincia", 30, "CP", 10, "Pais", 15, "NIF", 15, "Web", 25, "Teléfono 1", 15, "Teléfono 2", 15, "Fax", 15, "Correo", 20, "Notas", 100 );
my @datoscont = ( "Nombre", 20, "Apellidos", 30, "Empresa", 20, "Contacto", 10, "Cargo", 15, "Correo", 25, "Teléfono 1", 15, "Teléfono 2", 15, "Notas", 100 );

my ($x, $y, @elementospr, @anchospr);
for ($x=0; $x<=$#datosprov; $x += 2) {
	$y=$x/2;
	$elementospr[$y]=$datosprov[$x];
	$anchospr[$y]=$datosprov[$x+1];
}

my (@elementosct, @anchosct);
for ($x=0; $x<=$#datosprov; $x += 2) {
	$y=$x/2;
	$elementosct[$y]=$datoscont[$x];
	$anchosct[$y]=$datoscont[$x+1];
}

my ($any, $mes, $dia, $hora, $min);
($min,$hora,$dia, $mes, $any) = (localtime)[1,2,3,4,5];
my $fecha = sprintf("%02d%02d%04d_%02d%02d", $dia,$mes+1,$any+1900,$hora,$min);

my $nomfic="$nomlista\_$fecha.xlsx";
my $fsalida="$dirficheros/$nomfic";


# Iniciar Excel
my $libroexcel = Excel::Writer::XLSX->new($fsalida);
# Crear una  hoja  "Proveedores" y darle titulo
my $hoja1 = $libroexcel->add_worksheet('Proveedores');
    
# Formato texto y columnas
my $formato_gen  = $libroexcel->add_format( size => 8, align  => 'vcenter', text_wrap => 1);
my $ucol="A";
for ($x=0; $x<=$#anchospr; $x++) {
	$hoja1->set_column("$ucol:$ucol", $anchospr[$x], $formato_gen);	
	$ucol++ unless $x==$#anchospr;
}
	
# Grabar cabecera proveedores en negrita y con fondo amarillo
my $formato_cab = $libroexcel->add_format(	bold => 1,
										bg_color => 'yellow',
										align  => 'center',
										rotation => 90,
										);
$hoja1->write_row('A1', \@elementospr, $formato_cab);
$hoja1->freeze_panes(1, 1); # Inmovilizar al primera fila y columna


# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

my $fila=2;
my @row;
my $orden="SELECT id,nombre,direccion,poblacion,provincia,codpostal,pais,NIF,web,telefono1,telefono2,fax,correo,notas FROM proveedores";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$row[13] =~ s/<br>/\n/gi; # cambiar los saltos de linea html en las Notas
	$hoja1 -> write("A$fila", $row[1]);
	$hoja1 -> write("B$fila", $row[2]);
	$hoja1 -> write("C$fila", $row[3]);
	$hoja1 -> write("D$fila", $row[4]);
	$hoja1 -> write("E$fila", $row[5]);
	$hoja1 -> write("F$fila", $row[6]);
	$hoja1 -> write("G$fila", $row[7]);
	$hoja1 -> write("H$fila", $row[8]);
	$hoja1 -> write("I$fila", $row[9]);
	$hoja1 -> write("J$fila", $row[10]);
	$hoja1 -> write("K$fila", $row[11]);
	$hoja1 -> write("L$fila", $row[12]);
	$hoja1 -> write("M$fila", $row[13]);

	$fila++;
}


# Crear una  hoja  "Contactos" y darle titulo
my $hoja2 = $libroexcel->add_worksheet('Contactos');
    
# Formato texto y columnas
$ucol="A";
for ($x=0; $x<=$#anchosct; $x++) {
	$hoja2->set_column("$ucol:$ucol", $anchosct[$x], $formato_gen);	
	$ucol++ unless $x==$#anchosct;
}

# cabecera contactos
$hoja2->write_row('A1', \@elementosct, $formato_cab);
$hoja2->freeze_panes(1, 1); # Inmovilizar al primera fila y columna

# tipos contacto
my $orden="SELECT id,nombre FROM tipos WHERE tipo='CONTACTO'";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$tiposcontacto{$row[0]} = $row[1];
}

# leer proveedores
$orden="SELECT id,nombre FROM proveedores";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$nempresa{$row[0]} = $row[1];
}

$fila=2;
$orden="SELECT id,tipocont,nombre,apellidos,empresa,cargo,telefono1,telefono2,correo,notas FROM contactos";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$row[9] =~ s/<br>/\n/gi; # cambiar los saltos de linea html en las Notas
	$hoja2 -> write("A$fila", $row[2]);
	$hoja2 -> write("B$fila", $row[3]);
	$hoja2 -> write("C$fila", $nempresa{$row[4]});
	$hoja2 -> write("D$fila", $tiposcontacto{$row[1]});
	$hoja2 -> write("E$fila", $row[5]);
	$hoja2 -> write("F$fila", $row[8]);
	$hoja2 -> write("G$fila", $row[6]);
	$hoja2 -> write("H$fila", $row[7]);
	$hoja2 -> write("I$fila", $row[9]);

	$fila++;
}

$libroexcel -> close();
$dbh->disconnect( );

# enviar la cabecera de la tabla
print "Content-type: text/html\n\n";

# Ocultar el mensaje de espera
print "document.getElementById('cuadroespera').style.display='none';\n";

# Descargar
print "window.location='/perl/inventario/descargarfic.pl?$fsalida';\n";

exit;

sub Error {
	print "Content-type: text/html\n\n";
	print "El servidor no puede $_[0] el $_[1]: $! \n";
	exit;
}
