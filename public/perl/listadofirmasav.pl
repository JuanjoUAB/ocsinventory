#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	listadofirmasav.pl
# DESCRIPTION:	genera Excel con la version de firmas de Symantec Endpoint Protection
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Excel::Writer::XLSX;
use Time::Local;
use Net::Netmask;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my $dirficheros = "/tmp";
$dirficheros = "c:/xampp/cgi-bin/inventario" if ( $^O eq "MSWin32" );
my $nomlista = "Listado_firmas_AV";


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
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $diasctmin, $diasctmax, $nb, $red, $centro);
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
		elsif (/red:(.*)/) {
			$tmp = $1;
			$tmp =~ s/^\s+//;
			$tmp =~ s/\s+$//;
			($red, $centro) = split /;/,$tmp;
			$nb = Net::Netmask->new2($red);
			if ($nb) {
				$nb->tag('centro', $centro);
				$nb->storeNetblock();
			}	
		}
	}
	close FILECONF;
}
else {
	print "No se ha encontrado el fichero de configuracion $fconf\n";
	exit(1);
}

my @datos = ( "Nombre PC", 15, "Usuario", 12, "Centro", 12, "IP", 12, "Version SEP", 15, "Version Firmas", 15, "Fecha Firmas", 15, "Dias", 5 );

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
# Crear una  hoja  "Firmas AV"  y darle titulo
my $hoja1 = $libroexcel->add_worksheet('Firmas AV');
    
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

my $fila=2;
my (@row, @row2);

my $orden="SELECT id,name,userid,ipaddr,lastcome,deviceid FROM hardware";
my $sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
	next if ($row[5] eq "_SYSTEMGROUP_"); # descartar grupos
	
	# descartar los equipos que no hayan contactado en el numero de dias indicado
	my($anyo,$mes,$dia,$hora) = $row[4] =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	my $ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);

	# diferencia de fechas
	my $dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);

	# centro
	my $bloque = findNetblock($row[3]);
	$centro = $bloque ? $bloque->tag('centro') : "ND";
	$hoja1 -> write("C$fila", $centro);

	$hoja1 -> write("A$fila", $row[1]);
	$hoja1 -> write("B$fila", $row[2]);
	$hoja1 -> write("D$fila", $row[3]);

	# version AV Symantec SEP
	$orden="SELECT regvalue FROM registry WHERE hardware_id=$row[0] AND name='SEP_Version'";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();

	while (@row2 = $sth2->fetchrow_array) {
		if ( defined($row2[0]) ) {
			$hoja1 -> write("E$fila", $row2[0]);
			last;
		}
	}

	# version motor
	$orden="SELECT regvalue FROM registry WHERE hardware_id=$row[0] AND name='SEP_Motor'";
	$sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while (@row2 = $sth2->fetchrow_array) {
		if ( defined($row2[0]) ) {
			$hoja1 -> write("F$fila", $row2[0]);
			last;
		}
	}

	# version firmas
	my ($vdat, $anyoav, $mesav, $diaav);
	$orden="SELECT regvalue FROM registry WHERE hardware_id=$row[0] AND name='SEP_firma'";
	$sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while (@row2 = $sth2->fetchrow_array) {
		if ( defined($row2[0]) ) {
			($vdat) = $row2[0] =~ /.*\/(.*)/;
			$hoja1 -> write("F$fila", "$vdat "); # el espacio despues de $vdat es para que considere la celda comto texto y no redondee
			last;
		}
	}

	# fecha firmas SEP
	if ( $vdat ) {
		($anyoav, $mesav, $diaav) = $vdat =~ /^(....)(..)(..)/;
		$hoja1 -> write("G$fila", "$diaav/$mesav/$anyoav");		
	} else {
		$hoja1 -> write("G$fila", " ");	
	}

	# dias transcurridos
	if ( $anyoav ) {
		$mesav--;
		eval { timelocal(0, 0, 1, $diaav, $mesav, $anyoav) }; # hay fechas erroneas que abortan el programa
		my $epocaav = $@ ? 0 : timelocal(0, 0, 1, $diaav, $mesav, $anyoav);
		my $diasav = sprintf("%d",(time-$epocaav)/86400);
		$hoja1 -> write("H$fila", $diasav);		
	} else {
		$hoja1 -> write("H$fila", " ");	
	}


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
