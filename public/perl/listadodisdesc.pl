#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	listadodisdesc.pl
# DESCRIPTION:	genera Excel con la informacion de los dispositivos desconocidos
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use Encode;
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
my $nomlista = "Listado_dispositivos_desconocidos";

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
                        $centro=decode("UTF-8", $centro);
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

my @datos = ( "MAC", 15, "ID MAC", 20, "Centro", 15, "IP", 12, "Host", 15, "OS nombre", 15, "OS familia", 15, "OS tipo", 15, "OS empresa", 15, "Puerto abiertos", 25, "NetBios", 20, "SysName", 15, "SysDesc", 25, "Ultimo contacto", 15, "Datos NMAP", 250  );

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

# Crear una  hoja  "Dispositivos"  y darle titulo
my $hoja1 = $libroexcel->add_worksheet('Dispositivos');
    
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

# Columna de datos nmap sin autoajuste
my $formato_nmap  = $libroexcel->add_format( size => 8, align  => 'vcenter', text_wrap => 0);

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

my $fila=2;
my $row;
#my $orden="SELECT id.mac,id.os_nombre,id.os_familia,id.os_fabricante,id.os_tipo,id.puertosabiertos,id.sysDescr,id.sysName,id.nbdominio,id.nbnombre,np.ip,np.date,np.name FROM identificaciondisp AS id INNER JOIN netmap AS np ON id.mac=np.mac WHERE id.conocido='0'";
my $orden="SELECT id.mac,id.os_nombre,id.os_familia,id.os_fabricante,id.os_tipo,id.puertosabiertos,id.sysDescr,id.sysName,id.nbdominio,id.nbnombre,id.nmap,np.ip,np.date,np.name FROM identificaciondisp AS id,netmap AS np WHERE id.mac=np.mac AND id.conocido='0'";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	$hoja1 -> write("A$fila", $row->{'mac'});
	$hoja1 -> write("E$fila", $row->{'name'});
	$hoja1 -> write("F$fila", $row->{'os_nombre'});
	$hoja1 -> write("G$fila", $row->{'os_familia'});
	$hoja1 -> write("H$fila", $row->{'os_tipo'});
	$hoja1 -> write("I$fila", $row->{'os_fabricante'});
	$hoja1 -> write("J$fila", $row->{'puertosabiertos'});
	$hoja1 -> write("L$fila", $row->{'sysName'});
	$hoja1 -> write("M$fila", $row->{'sysDescr'});
	$hoja1 -> write("O$fila", $row->{'nmap'}, $formato_nmap);

	# nombre NetBios
	my $netbios	= $row->{nbdominio}."\\".$row->{nbnombre};
	$netbios = ( $netbios =~ /^\\$/ ) ? '' : $netbios;
	$hoja1 -> write("K$fila", $netbios);
	
	# ip, centro, fecha
	if ( defined($row->{ip}) ) {
		my $bloque = findNetblock($row->{ip});
		$centro = $bloque ? $bloque->tag('centro') : "ND";
		$hoja1 -> write("C$fila", $centro);
		$hoja1 -> write("D$fila", $row->{ip});
		my($anyo,$mes,$dia,$hora) = $row->{date} =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
		$hoja1 -> write("N$fila", "$dia/$mes/$anyo $hora");
	} else {
		$hoja1 -> write("D$fila", " ");
	}

		
		
	# averiguar el fabricante del dispositivo
	my $fabricante = "ND";
	my $mac = substr($row->{mac},0,8);
	$mac =~ s/://g;
	$orden="SELECT fabricante FROM macvendor WHERE mac='$mac'";
	my $sth3 = $dbh->prepare($orden);
	if ( $sth3->execute() > 0 ) {
		($fabricante) = $sth3->fetchrow_array;
#		$fabricante =~ s/'/&#x27;/g;
	}
	$sth3->finish();
	$hoja1 -> write("B$fila", $fabricante);

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
