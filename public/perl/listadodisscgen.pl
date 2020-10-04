#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	listadodisscgen.pl
# DESCRIPTION:	genera Excel con la configuracion general de los dispositivos SC
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use Encode;
use strict;
#use warnings;
use DBI;
use Excel::Writer::XLSX;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my %tiposdisp = ();
my %tipestpc=();
my %nproveedores=();

my $dirficheros = "/tmp";
$dirficheros = "c:/xampp/cgi-bin/inventario" if ( $^O eq "MSWin32" );
my $nomlista = "Listado_dispositivosSC";

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

my @datos = ( "Descripcion", 40, "Tipo", 12, "Ubicación", 25, "Estado", 15, "Número Serie", 15, "Responsable", 15, "Proveedor", 15, "Fecha Compra", 10, "Notas", 100 );

my ($x, $y, @elementos, @anchos);
for ($x=0; $x<=$#datos; $x += 2) {
	$y=$x/2;
	$elementos[$y]=$datos[$x];
	$anchos[$y]=$datos[$x+1];
}

my ($any, $mes, $dia, $hora, $min);
($min,$hora,$dia, $mes, $any) = (localtime)[1,2,3,4,5];
my $fecha = sprintf("%02d%02d%04d_%02d%02d", $dia,$mes+1,$any+1900,$hora,$min);

my $nomfic="$nomlista\_$fecha.xlsx";
my $fsalida="$dirficheros/$nomfic";


# Iniciar Excel
my $libroexcel = Excel::Writer::XLSX->new($fsalida);
# Crear una  hoja  "Dispositivos SC"  y darle titulo
my $hoja1 = $libroexcel->add_worksheet('Dispositivos SC');
    
# Formato texto y columnas
my $formato_gen  = $libroexcel->add_format( size => 8, align  => 'vcenter', text_wrap => 1);
my $ucol="A";
for ($x=0; $x<=$#anchos; $x++) {
	$hoja1->set_column("$ucol:$ucol", $anchos[$x], $formato_gen);	
	$ucol++ unless $x==$#anchos;
}
	
# Grabar cabecera general en negrita y con fondo amarillo
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

my @row;
# tipos dispositivos
my $orden="SELECT id,name FROM devicetype";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$tiposdisp{$row[0]} = $row[1];
}

# leer tipos estado pc
$orden="SELECT id,nombre FROM tipos WHERE tipo='ESTADO'";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$tipestpc{$row[0]} = $row[1];
}

# leer proveedores
$orden="SELECT id,nombre FROM proveedores";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
        $row[1]=decode("UTF-8",$row[1]);
	$nproveedores{$row[0]} = $row[1];
}

my $fila=2;
my @row;
$orden="SELECT id,descripcion,tipo,ubicacion,estado,numserie,responsable,proveedor,fechacompra,notas FROM dispositivossc";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	# convertir formato fecha
	my ($anyo,$mes,$dia) = $row[8] =~ /(\d+)-(\d+)-(\d+)/;
	my $fcompra = "$dia/$mes/$anyo";

	$row[1]=decode("UTF-8",$row[1]);
        $row[3]=decode("UTF-8",$row[3]);
	$row[5]=decode("UTF-8",$row[5]);
	$row[6]=decode("UTF-8",$row[6]);
	$row[9]=decode("UTF-8",$row[9]);
        
        $row[9] =~ s/<br>/\n/gi; # cambiar los saltos de linea html en las Notas
	
	$hoja1 -> write("A$fila", $row[1]);
	$hoja1 -> write("B$fila", $tiposdisp{$row[2]});
	$hoja1 -> write("C$fila", $row[3]);
	$hoja1 -> write("D$fila", $tipestpc{$row[4]});
	$hoja1 -> write("E$fila", $row[5]);
	$hoja1 -> write("F$fila", $row[6]);
	$hoja1 -> write("G$fila", $nproveedores{$row[7]});
	$hoja1 -> write("H$fila", $fcompra);
	$hoja1 -> write("I$fila", $row[9]);

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
