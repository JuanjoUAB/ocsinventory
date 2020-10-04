#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	listadodocumentos.pl
# DESCRIPTION:	genera Excel con los datos de los documentos
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

my %tiposdocumento = ();
my %nproveedores = ();

my $dirficheros = "/tmp";
$dirficheros = "c:/xampp/cgi-bin/inventario" if ( $^O eq "MSWin32" );
my $nomlista = "Listado_documentos";

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

my @datosdoc = ( "Tipo", 20, "Proveedor", 30, "Referencia", 30, "Fecha", 12, "Nombre", 50, "Notas", 100 );

my ($x, $y, @elementos, @anchos);
for ($x=0; $x<=$#datosdoc; $x += 2) {
	$y=$x/2;
	$elementos[$y]=$datosdoc[$x];
	$anchos[$y]=$datosdoc[$x+1];
}

my ($any, $mes, $dia, $hora, $min);
($min,$hora,$dia, $mes, $any) = (localtime)[1,2,3,4,5];
my $fecha = sprintf("%02d%02d%04d_%02d%02d", $dia,$mes+1,$any+1900,$hora,$min);

my $nomfic="$nomlista\_$fecha.xlsx";
my $fsalida="$dirficheros/$nomfic";


# Iniciar Excel
my $libroexcel = Excel::Writer::XLSX->new($fsalida);
# Crear una  hoja  "Documentos" y darle titulo
my $hoja1 = $libroexcel->add_worksheet('Documentos');
    
# Formato texto y columnas
my $formato_gen  = $libroexcel->add_format( size => 8, align  => 'vcenter', text_wrap => 1);
my $ucol="A";
for ($x=0; $x<=$#anchos; $x++) {
	$hoja1->set_column("$ucol:$ucol", $anchos[$x], $formato_gen);	
	$ucol++ unless $x==$#anchos;
}
	
# Grabar cabecera documentos en negrita y con fondo amarillo
my $formato_cab = $libroexcel->add_format(	bold => 1,
										bg_color => 'yellow',
										align  => 'center',
										rotation => 90,
										);
$hoja1->write_row('A1', \@elementos, $formato_cab);
$hoja1->freeze_panes(1, 1); # Inmovilizar al primera fila y columna


# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

			   
# tipos documento
my @row;
my $orden="SELECT id,nombre FROM tipos WHERE tipo='DOCUMENTO'";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$tiposdocumento{$row[0]} = $row[1];
}

# leer proveedores
$orden="SELECT id,nombre FROM proveedores";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$nproveedores{$row[0]} = $row[1];
}


my $fila=2;
$orden="SELECT id,tipodoc,proveedor,referencia,fechadoc,nfichero,notas FROM documentos";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	# convertir formato fecha
	my ($anyo,$mes,$dia) = $row[4] =~ /(\d+)-(\d+)-(\d+)/;
	my $fechadoc = "$dia/$mes/$anyo";
	if ( ($fechadoc eq "//") || ($fechadoc eq "00/00/0000") ) { $fechadoc = "" }

	$row[6] =~ s/<br>/\n/gi; # cambiar los saltos de linea html en las Notas
	
	$hoja1 -> write("A$fila", $tiposdocumento{$row[1]});
	$hoja1 -> write("B$fila", $nproveedores{$row[2]});
	$hoja1 -> write("C$fila", $row[3]);
	$hoja1 -> write("D$fila", $fechadoc);
	$hoja1 -> write("E$fila", $row[5]);
	$hoja1 -> write("F$fila", $row[6]);

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
