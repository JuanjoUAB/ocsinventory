#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	listadoequgen.pl
# DESCRIPTION:	genera Excel con la configuracion general de los equipos
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

my %hnombres;
my %hequipos;
my %hmacs;
my %hduplicados;

my %tipestpc=();
my %nproveedores=();

# leer los valores pasados por una qs
my $qs = $ENV{'QUERY_STRING'};

# separar los datos
my ($nombre,$modo) = split /=/,$qs;

my $dirficheros = "/tmp";
$dirficheros = "c:/xampp/cgi-bin/inventario" if ( $^O eq "MSWin32" );
my $nomlista = "Listado_equipos";

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
                        $centro=decode("UTF-8",$centro);
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

my @datos = ( "Nombre", 15, "Fabricante", 15, "Modelo", 14, "ID hardware", 10, "Tipo", 14, "CPU", 35, "Num CPU", 5, "MHz", 5, "Memoria", 5,
		"Disco Tamaño", 9, "Disco Libre", 9, "Dominio", 15,  "Usuario", 10, "Centro", 10, "SO", 25, "SP", 12, "Empresa Win", 15, "Propietario Win", 15,
		"Clave Windows", 30, "Tarjetas Red", 65, "Velocidad", 8, "MAC", 14, "IP", 12, "GW", 12, "Fecha Contacto", 15,
		"Proveedor", 15, "Pedido", 15, "Factura", 15, "Fecha Compra", 10, "Fin Garantía", 10, "Estado", 15, "Notas", 30);

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
# Crear una  hoja  "Equipos"  y darle titulo
my $hoja1 = $libroexcel->add_worksheet('Equipos');
    
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
my ($row, @row, @row2);

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
        $row[1]=decode("UTF-8",$row[1]);
	$nproveedores{$row[0]} = $row[1];
}

# $modo = 0 => mostramos todos los equipos
# $modo = 1 => mostramos los equipos sin duplicados. Si hay equipos con el mismo nombre o MAC dejamos solo el mas reciente
# $modo = 2 => mostramos solo los equipos duplicados
$orden="SELECT id,deviceid, name,ipaddr,lastcome FROM hardware";
$sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	next if ($row->{deviceid} eq "_SYSTEMGROUP_"); # descartar grupos
	if ( $modo == 0 ) {
		$hequipos{$row->{id}} = "1";
	} elsif ( $modo == 1 ) {
		my ($anyo1,$mes1,$dia1,$hora1,$min1) = $row->{lastcome} =~ /(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):\d+/;
		$mes1 = $mes1-1;
		eval { timelocal(0, $min1, $hora1, $dia1, $mes1, $anyo1) }; # hay fechas erroneas que abortan el programa
		my $ucontacto1 = $@ ? 0 : timelocal(0, $min1, $hora1, $dia1, $mes1, $anyo1);
		
		if ( exists $hnombres{$row->{name}} ) {
			my ($id,$ucontacto2) = split /;/,$hnombres{$row->{name}};
			if ( $ucontacto1 > $ucontacto2 ) {
				$hnombres{$row->{name}} = "$row->{id};$ucontacto1";
			}
		} else {
			$hnombres{$row->{name}} = "$row->{id};$ucontacto1";
		}
		
		my $orden = "SELECT macaddr FROM networks WHERE hardware_id=$row->{id} AND ipaddress='$row->{ipaddr}'";
		my $row2 = $dbh->selectrow_hashref($orden);
		if ( exists $hmacs{$row2->{macaddr}} ) {
			my ($id1,$ucontacto1) = split /;/,$hnombres{$row->{name}};
			my ($id2,$ucontacto2) = split /;/,$hnombres{$hmacs{$row2->{macaddr}}};
			if ( $ucontacto1 > $ucontacto2 ) {
				delete $hnombres{$hmacs{$row2->{macaddr}}};
			} else {
				delete $hnombres{$row->{name}};
				$hmacs{$row2->{macaddr}} = $row->{name};
			}
		} else {
			$hmacs{$row2->{macaddr}} = $row->{name};
		}

	} elsif ( $modo == 2 ) {
		if ( exists $hnombres{$row->{name}} ) {
			$hduplicados{$hnombres{$row->{name}}} = "1";			
			$hduplicados{$row->{id}} = "1";
		} else {
			$hnombres{$row->{name}} = "$row->{id}";
		}
		
		my $orden = "SELECT macaddr FROM networks WHERE hardware_id=$row->{id} AND ipaddress='$row->{ipaddr}'";
		my $row2 = $dbh->selectrow_hashref($orden);
		next unless ($row2->{macaddr} );
		if ( exists $hmacs{$row2->{macaddr}} ) {
#			$hduplicados{$hnombres{$row->{name}}} = "1";
			$hduplicados{$hnombres{$hmacs{$row2->{macaddr}}}} = "1";				
			$hduplicados{$row->{id}} = "1";
		} else {
			$hmacs{$row2->{macaddr}} = $row->{id};
		}
		
	}
}
# generamos hequipos con los que se han de mostrar
if ( $modo == 1 ) {
	foreach my $nombre ( keys %hnombres ) {
		my ($id,$ucontacto) = split /;/,$hnombres{$nombre};
		$hequipos{$id} = 1;
	}
}
if ( $modo == 2 ) {
	foreach my $id (keys %hduplicados) {
		$hequipos{$id} = '1';
	}
}

$orden="SELECT id,name,workgroup,userid,osname,oscomments,processort,processorn,processors,memory,wincompany,winowner,winprodkey,lastcome,deviceid,useragent,ipaddr FROM hardware";
$sth = $dbh->prepare($orden);
$sth->execute();
while (@row = $sth->fetchrow_array) {
next if ($row[14] eq "_SYSTEMGROUP_"); # descartar grupos
	# descartar los equipos que no hayan contactado en el numero de dias indicado
	my($anyo,$mes,$dia,$hora) = $row[13] =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
	my $fucontacto = "$dia/$mes/$anyo $hora";
	$mes = $mes-1;
	eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
	my $ucontacto = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);
	
	# diferencia de fechas
	my $dias = sprintf("%d",(time-$ucontacto)/86400);	
	next if ($dias > $diasctmax);
	next if ($dias < $diasctmin);
	
	next if ( !exists $hequipos{$row[0]} ); # comprobamos si hay que mostrar el equipo

	# centro
	my $bloque = findNetblock($row[16]);
	$centro = $bloque ? $bloque->tag('centro') : "ND";
	
	$hoja1 -> write("A$fila", $row[1]);
	$hoja1 -> write("F$fila", $row[6]);
	$hoja1 -> write("G$fila", $row[7]);
	$hoja1 -> write("H$fila", $row[8]);
	$hoja1 -> write("I$fila", $row[9]);
	$hoja1 -> write("L$fila", $row[2]);
	$hoja1 -> write("M$fila", $row[3]);
	$hoja1 -> write("N$fila", $centro);
	$hoja1 -> write("O$fila", $row[4]);
	$hoja1 -> write("P$fila", $row[5]);
	$hoja1 -> write("Q$fila", $row[10]);
	$hoja1 -> write("R$fila", $row[11]);
	$hoja1 -> write("S$fila", $row[12]);
	$hoja1 -> write("Y$fila", $fucontacto);
	
	# bios
	my $tipo;
	$orden="SELECT smanufacturer,smodel,ssn,type FROM bios where hardware_id=$row[0]";
	my $sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while (@row2 = $sth2->fetchrow_array) {
		$hoja1 -> write("B$fila", $row2[0]);
		$hoja1 -> write("C$fila", $row2[1]);
		$hoja1 -> write("D$fila", $row2[2]);
		$tipo = (lc($row2[0]) =~ /vmware/) ? "Virtual" : $row2[3];
		$hoja1 -> write("E$fila", $tipo);
	}
	
	# discos
	my $despacio = "";
	my $dlibre = "";
	$orden="SELECT letter,type,total,free FROM drives where hardware_id=$row[0]";
	$sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while (@row2 = $sth2->fetchrow_array) {
		if ( $row[15] =~ /windows/i ) {
			next if ( $row2[1] !~ /Hard Drive/); # descartar unidades de red, disqueteras y cd/dvds
			$despacio .= "$row2[0] ".sprintf ("%.0f",$row2[2]/1024)." GB\n";
			$dlibre .= "$row2[0] ".sprintf ("%.0f",$row2[3]/1024)." GB\n";
		} elsif ( ($row[15] =~ /unix/i) || ($row[15] =~ /android/i) ) {
			$despacio .= "($row2[1]) ".sprintf ("%.0f",$row2[2]/1024)." GB\n";
			$dlibre .= "($row2[1]) ".sprintf ("%.0f",$row2[3]/1024)." GB\n";
		}
	}
	chomp $despacio;
	chomp $dlibre;
	$hoja1 -> write("J$fila", $despacio);
	$hoja1 -> write("K$fila", $dlibre);
	
	# redes
	my $clave;
	my $ndescripcion = "";
	my $nvelo = "";
	my $nmac = "";
	my $nip = "";
	my $ngw = "";
	$orden="SELECT description,speed,macaddr,ipaddress,ipgateway FROM networks where hardware_id=$row[0]";
	$sth2 = $dbh->prepare($orden);
	$sth2->execute();
	while (@row2 = $sth2->fetchrow_array) {
		$ndescripcion .= "$row2[0]\n";
		$nvelo .= "$row2[1]\n";
		$nmac .= "$row2[2]\n";
		$nip .= "$row2[3]\n";
		$ngw .= "$row2[4]\n";
	}
	chomp $ndescripcion;
	chomp $nvelo;
	chomp $nmac;
	chomp $nip;
	chomp $ngw;
	$hoja1 -> write("T$fila", $ndescripcion);
	$hoja1 -> write("U$fila", $nvelo);
	$hoja1 -> write("V$fila", $nmac);
	$hoja1 -> write("W$fila", $nip);
	$hoja1 -> write("X$fila", $ngw);

	# otros datos
	$orden="SELECT proveedor,pedido,factura,fechacompra,fingarantia,estado,notas FROM otrosdatospc WHERE hardware_id='$row[0]'";
	$sth2 = $dbh->prepare($orden);
	$sth2->execute();
	@row2 = $sth2->fetchrow_array;
	
	# convertir formato fecha
	# fecha compra
	my $fcompra = "";
	if (defined $row2[3] ) {
		($anyo,$mes,$dia) = $row2[3] =~ /(\d+)-(\d+)-(\d+)/;
		$fcompra = "$dia/$mes/$anyo";
		if ( $fcompra eq "00/00/0000" ) { $fcompra = "" }
	} 
	
	# garantia
	my $fgarantia= "";
	my $formato_color = $formato_gen;
	if (defined $row2[4] ) {
		($anyo,$mes,$dia) = $row2[4] =~ /(\d+)-(\d+)-(\d+)/;
		my $fgarantia = "$dia/$mes/$anyo";
		if (  $fgarantia eq "00/00/0000" ) { 
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
	}

	$row2[6] =~ s/<br>/\n/gi; # cambiar los saltos de linea html en las Notas

        $row2[1]=decode("UTF-8",$row2[1]);
        $row2[2]=decode("UTF-8",$row2[2]);	
        $row2[6]=decode("UTF-8",$row2[6]);

	$hoja1 -> write("Z$fila", $nproveedores{$row2[0]});
	$hoja1 -> write("AA$fila", $row2[1]);
	$hoja1 -> write("AB$fila", $row2[2]);
	$hoja1 -> write("AC$fila", $fcompra);
	$hoja1 -> write("AD$fila", $fgarantia, $formato_color);
	$hoja1 -> write("AE$fila", $tipestpc{$row2[5]});
	$hoja1 -> write("AF$fila", $row2[6]);

	$fila++;
}

$libroexcel->close();
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
