#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	listadootrosdatos.pl
# DESCRIPTION:	genera Excel con los datos manuales de los PCs
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

my %tipestpc = ();
my %nproveedores =( );
my $dirficheros = "/tmp";
$dirficheros = "c:/xampp/cgi-bin/inventario" if ( $^O eq "MSWin32" );
my $nomlista = "Listado_OtrosDatosPC";

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

my @datos = ( "Nombre", 30, "Proveedor", 15, "Pedido", 15, "Factura", 15, "Fecha Compra", 10, "Fin Garantía", 10, "Estado", 15, "Notas", 30, "Fecha Contacto", 16 );

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
my $hoja1 = $libroexcel->add_worksheet('Otros Datos PCs');
    
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

my $formato_rojo = $libroexcel->add_format( bg_color => 'red', size => 8 );
my $formato_verde = $libroexcel->add_format( bg_color => 'green', size => 8 );
my $formato_amarillo = $libroexcel->add_format( bg_color => 'yellow', size => 8 );
my $formato_naranja = $libroexcel->add_format( bg_color => 'orange', size => 8 );


# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

my $fila=2;
my (@row, @row2);

# leer tipos estado pc
my $orden="SELECT id,nombre FROM tipos WHERE tipo='ESTADO'";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$tipestpc{$row[0]} = $row[1];
}

# leer proveedores
$orden="SELECT id,nombre FROM proveedores";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	$nproveedores{$row[0]} = $row[1];
}


$orden="SELECT id,name,lastcome,deviceid FROM hardware";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	my ($anyo, $mes, $dia, $hora, $fucontacto, $ucontacto, $dias);
	my ($id, $nombre);

	next if ($row[3] eq "_SYSTEMGROUP_"); # descartar grupos

	# descartar los equipos que no hayan contactado en el numero de dias indicado
	($anyo,$mes,$dia,$hora) = $row[2] =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	$fucontacto = "$dia/$mes/$anyo $hora";
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	$ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);

	# diferencia de fechas
	$dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);
	
	$orden="SELECT proveedor,pedido,factura,fechacompra,fingarantia,estado,notas FROM otrosdatospc WHERE hardware_id='$row[0]'";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	@row2 = $sth2->fetchrow_array;
	
	# convertir formato fecha
	# fecha compra
	($anyo,$mes,$dia) = $row2[3] =~ /(\d+)-(\d+)-(\d+)/;
	my $fcompra = "$dia/$mes/$anyo";
	if ( ($fcompra eq "//") || ($fcompra eq "00/00/0000") ) { $fcompra = "" }

	# garantia
	my $formato_color = $formato_gen;
	($anyo,$mes,$dia) = $row2[4] =~ /(\d+)-(\d+)-(\d+)/;
	my $fgarantia = "$dia/$mes/$anyo";
	if ( ($fgarantia eq "//") || ($fgarantia eq "00/00/0000") ) {
		$fgarantia = ""
	} else {
		$mes = $mes-1;
		eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
		my $efingarantia = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);
		# diferencia de fechas
		if ( (time-$efingarantia)/86400 > 0 ) {
			$formato_color = $formato_rojo; # rojo
		} elsif ( ($efingarantia-time)/86400 < 30 ) {
			$formato_color = $formato_amarillo; # amarillo
		}
	}

	$hoja1 -> write("A$fila", $row[1]);
	$hoja1 -> write("B$fila", $nproveedores{$row2[0]});
	$hoja1 -> write("C$fila", $row2[1]);
	$hoja1 -> write("D$fila", $row2[2]);
	$hoja1 -> write("E$fila", $fcompra);
	$hoja1 -> write("F$fila", $fgarantia, $formato_color);
	$hoja1 -> write("G$fila", $tipestpc{$row2[5]});
	$row2[6] =~ s/<br>/\n/g;
	$hoja1 -> write("H$fila", $row2[6]);
	$hoja1 -> write("I$fila", $fucontacto);

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
